unit
  ISAPIExtensionThread;

interface

uses
  Windows, SyncObjs, Classes, Isapi2;

const
  esCreated    = -2;
  esStartExecute = -1;
  esExecuted = 0;

type
  TOnSendRawData = function (Sender: TObject; var Apfc: THTTP_FILTER_CONTEXT; NotificationType: DWORD; ApvNotification: Pointer): DWORD;
  TISAPIExtensionThread = class;

  TISAPIExtensionThreadPool = class(TObject)
  private
    FThreadPool: TList;
    FLock: TCriticalSection;
    FPoolIndex: Integer;
    FMin: Integer;
    FMax: Integer;
    FOnSendRawDataProc: TOnSendRawData;
    procedure AdjustThreadPool;
    procedure Clear;
    function  CreateThread: TISAPIExtensionThread;
    function  GetThreadCount: Integer;
    procedure SetMin(Value: Integer);
    procedure SetMax(Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function DispatchThread(var AECB: TEXTENSION_CONTROL_BLOCK): TISAPIExtensionThread;
    function RemoveThread(AISAPIFilterThread: TISAPIExtensionThread): Boolean;
    property Min: Integer read FMin write SetMin default 1;
    property Max: Integer read FMax write SetMax default 32;
    property ThreadCount:Integer read GetThreadCount;
    property OnSendRawDataProc: TOnSendRawData read FOnSendRawDataProc write FOnSendRawDataProc;
  end;

   TISAPIExtensionThread = class(TObject)
   private
     FHandle: THandle;
     FThreadID: THandle;
     FSuspended: Boolean;
     FTerminated: Boolean;

     FWebModule: TPersistent;

     FPECB: PEXTENSION_CONTROL_BLOCK;
     FISAPIFilterThreadPool: TISAPIExtensionThreadPool;
     FExecuteState: Integer;  // <0= in execute, 0- executed
   public
     constructor Create(AISAPIFilterThreadPool: TISAPIExtensionThreadPool);
     destructor Destroy; override;
     procedure Execute;
     procedure Suspend;
     procedure Resume;

     function SendRawData(var AECB: TEXTENSION_CONTROL_BLOCK): DWORD; virtual;

     property Suspended: Boolean read FSuspended;
     property Terminated: Boolean read FTerminated write FTerminated;
     // property ECB: TEXTENSION_CONTROL_BLOCK read FECB write FECB;
     property ExecuteState: Integer read FExecuteState write FExecuteState;
   end;

implementation

uses
  SysUtils,
  fis2sql;

procedure HandleServerException(E: Exception; var ECB: TEXTENSION_CONTROL_BLOCK);
var
  ResultText, ResultHeaders: string;
  Size: DWORD;
begin
  ECB.dwHTTPStatusCode := 500;
  ResultText := Format('Internal is2sql gateway error.', [E.ClassName, E.Message]);
  ResultHeaders := Format(
    'Content-Type: text/html'#13#10 +     //Not resourced
    'Content-Length: %d'#13#10 +          //Not resourced
    'Content:'#13#10#13#10, [Length(ResultText)]); //Not resourced
  ECB.ServerSupportFunction(ECB.ConnID, HSE_REQ_SEND_RESPONSE_HEADER,
    PChar('500 ' + E.Message), @Size, LPDWORD(ResultHeaders));
  Size := Length(ResultText);
  ECB.WriteClient(ECB.ConnID, Pointer(ResultText), Size, 0);
end;

constructor TISAPIExtensionThreadPool.Create;
begin
  inherited Create;
  FThreadPool := TList.Create;
  FLock := TCriticalSection.Create;
  FPoolIndex := 0;
  FMin := 1;
  FMax := 32;
  FOnSendRawDataProc:= Nil;
  AdjustThreadPool;
end;

destructor TISAPIExtensionThreadPool.Destroy;
begin
  Clear;
  while FThreadPool.Count > 0 do sleep(0);
  FLock.Free;
  FThreadPool.Free;
  inherited Destroy;
end;

function TISAPIExtensionThreadPool.DispatchThread(var AECB: TEXTENSION_CONTROL_BLOCK): TISAPIExtensionThread;
begin
  FLock.Acquire;
  try
    Result:= CreateThread;
    if Assigned(Result) then with Result do begin
      // bug in there. Do not assigned and copied.
      FPECB:= @AECB;
      Resume;
    end;
  finally
    FLock.Release;
  end;
end;

function TISAPIExtensionThreadPool.RemoveThread(AISAPIFilterThread: TISAPIExtensionThread): Boolean;
begin
  FLock.Acquire;
  try
    Result := FThreadPool.Remove(AISAPIFilterThread) >= 0;
  finally
    FLock.Release;
  end;
end;

procedure TISAPIExtensionThreadPool.AdjustThreadPool;
begin
  FLock.Acquire;
  try
    while FMin > FThreadPool.Count do
    FThreadPool.Add(TISAPIExtensionThread.Create(Self));
  finally
    FLock.Release;
  end;
end;

procedure TISAPIExtensionThreadPool.Clear;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    for I := FThreadPool.Count - 1 downto 0 do with TISAPIExtensionThread(FThreadPool[I]) do begin
      Terminated:= True;
      if Suspended
      then Resume;
    end;
  finally
    FLock.Release;
  end;
end;

function TISAPIExtensionThreadPool.CreateThread: TISAPIExtensionThread;
var
  IndexRef: Integer;
begin
  IndexRef := FPoolIndex;
  repeat
    FPoolIndex := (FPoolIndex + 1) mod FThreadPool.Count;
    Result := FThreadPool[FPoolIndex];
  until (FPoolIndex = IndexRef) or Result.Suspended;

  if not Result.Suspended then begin
    if ThreadCount < FMax then begin
      Result:= TISAPIExtensionThread.Create(Self);
      FThreadPool.Add(Result);
    end
    else Result := nil;
  end;
end;

function TISAPIExtensionThreadPool.GetThreadCount: Integer;
begin
  Result:= FThreadPool.Count;
end;

procedure TISAPIExtensionThreadPool.SetMin(Value: Integer);
begin
  if FMin <> Value then
  begin
    if Value < 1 then
      Value := 1;
    FMin := Value;
    AdjustThreadPool;
  end;
end;

procedure TISAPIExtensionThreadPool.SetMax(Value: Integer);
begin
  if FMax <> Value then begin
    if  FMin > Value then
      Value := FMin;
    FMax := Value;
    AdjustThreadPool;
  end;
end;

{ TISAPIExtensionThread }

function ThreadProc(ISAPIFilterThread: TISAPIExtensionThread): Integer;
begin
  Result := 0;
  try
    if not ISAPIFilterThread.Terminated then
      try
        ISAPIFilterThread.Execute;
      except
        AcquireExceptionObject;
      end;
  finally
    ISAPIFilterThread.Free;
    EndThread(Result);
  end;
end;

constructor TISAPIExtensionThread.Create(AISAPIFilterThreadPool: TISAPIExtensionThreadPool);
begin
  inherited Create;
  FWebModule:= fis2sql.TWeb2DBModule.Create(AISAPIFilterThreadPool);
  FSuspended := True;
  FTerminated := False;
  FExecuteState:= esCreated;
  // FillChar(FECB, Sizeof(FECB), 0);
  FPECB:= Nil;
  FISAPIFilterThreadPool:= AISAPIFilterThreadPool;
  FHandle:= BeginThread(nil, 0, @ThreadProc, Pointer(Self), CREATE_SUSPENDED, FThreadID);
end;

destructor TISAPIExtensionThread.Destroy;
begin
  if Assigned(FISAPIFilterThreadPool) then
    FISAPIFilterThreadPool.RemoveThread(Self);
  FWebModule.Free;
  inherited Destroy;
end;

function TISAPIExtensionThread.SendRawData(var AECB: TEXTENSION_CONTROL_BLOCK): DWORD;
var
  rawStruct: PHTTP_FILTER_RAW_DATA;
  s: String;
begin
  Result:= SF_STATUS_REQ_NEXT_NOTIFICATION;
  with AECB do begin
  end;
end;

procedure TISAPIExtensionThread.Execute;
begin
  while not Terminated do begin
    FExecuteState:= esStartExecute;
    try
      fis2sql.TWeb2DBModule(FWebModule).HandleRequest(FPECB^);
      {
      then Result:= HSE_STATUS_SUCCESS
      else Result:= HSE_STATUS_ERROR;
      }
    except
      HandleServerException(Exception(ExceptObject), FPECB^);
    end;
    FExecuteState:= esExecuted;
    if not Terminated
    then Suspend;
  end;
end;

procedure TISAPIExtensionThread.Suspend;
begin
  FSuspended := True;
  SuspendThread(FHandle);
end;

procedure TISAPIExtensionThread.Resume;
begin
  FSuspended := False;
  ResumeThread(FHandle);
end;

initialization

finalization

end.
