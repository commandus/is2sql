unit fmain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Menus, ComCtrls, ToolWin, StdCtrls, Registry,
  util1, utilHttp, UtilISAPI,
  SrvHttp, SrvLog, xBase, xContType;

const
  LNVERSION = '1.0';
  RGPATH = '\Software\ensen\rprdsgn\'+ LNVERSION;

  JiptoBannerRequest = 'http://www.lbe.ru/cgi-bin/banner/ensen?100';
  JiptoBannerUrl     = 'http://ensen.8m.com';
  JiptoSubscribeUrl  = 'http://www.sitc.ru/cgi-bin/jipto?subscribe&name=%s&password=%s&email=%s';
  FIRSTBANNER        = 'banner.gif';
  // Microsoft web servers virtual roots registry path
  RGW2SVCALIAS = '\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\Virtual Roots';
  RGIS2SQLVIRTALIAS = 'Software\ensen\is2sql\1.0\Virtual Roots';
  { registry parameters }
  RgRoot          = 'Root';
  RgBindIP        = 'BindIP';
  RgBindPort      = 'BindPort';
  RgShell         = 'Use shell content types';
  RgIISaliases    = 'IIS aliases';
  Rgis2sqlaliases = 'is2sql aliases';

resourcestring
  MSG_PluginsFolder = 'Library &folder: %s';
  
type
  TFormMain = class(TForm)
    PanelBanner: TPanel;
    Timer1: TTimer;
    CoolBar1: TCoolBar;
    ToolBar1: TToolBar;
    TBFile: TToolButton;
    TBOptions: TToolButton;
    pmFile: TPopupMenu;
    pmOptions: TPopupMenu;
    pmOptionsLibraryFolder: TMenuItem;
    pmFileD1: TMenuItem;
    pmFileExit: TMenuItem;
    CBDll: TComboBox;

    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure OnClickFBanner(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pmOptionsLibraryFolderClick(Sender: TObject);
    procedure pmFileExitClick(Sender: TObject);
    procedure CBDllChange(Sender: TObject);

  private
    { Private declarations }
    FBanner: THttpGifLoader;
    FFirstTime: Boolean;
    FWorkDir: String;
    procedure MyRequestFileEvent(Sender: TObject; const AFileName: String;
      var AFileInfo: TFileInfo; var AHandled: Boolean);
  public
    { Public declarations }
    FPluginsFolder: String;
    FPlugins: TStrings;
    FPluginIdx: Integer;
    { web server }
    //Logger: THttpFileLogger;
    HttpServ: THttpServ;
    FAliases: TStrings;
    FContentTypes: TStrings;
    FIISAliases: Boolean;
    Fis2sqlAliases: Boolean;
    FUseShellContentTypes: Boolean;

    procedure ActivateBanner;
    function LocateISAPI(const APath: String): Integer;
    function LoadIni: Boolean;
    procedure StoreIni;
    function SetPlugins(const APath: String; AIndex: Integer): Integer;
    { web server }
    procedure Start;
    procedure Stop;
    function DispatchRequests(const ARequest: String; var AFileInfo: TFileInfo): String;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.DFM}

procedure TFormMain.ActivateBanner;
begin
  FBanner:= THttpGifLoader.Create(Self);
  try
    FBanner.Picture.LoadFromFile(ConcatPath(FWorkDir, FIRSTBANNER));
  except
  end;
  with FBanner do begin
    Parent:= PanelBanner;
    Align:= alNone;
    Left:= 0;
    Top:= 0;
    Width:= 468;
    Height:= 60;
    url:= JiptoBannerRequest;
    Hint:= JiptoBannerUrl;
    Cursor:= crHandPoint;
    OnClick:= OnClickFBanner;
    ReadProxySettings;
    TimeOutSec:= 20;
    NextTimeOutSec:= 2 * 60;
  end;
end;

procedure ValidateW3SvcColon(ACurDir: String; AVirtualRoots: TStrings);
var
  i, L: Integer;
  S: String;
begin
  if AVirtualRoots is TStringList then begin
    TStringList(AVirtualRoots).Sorted:= False;
  end;
  for i:= 0 to AVirtualRoots.Count - 1 do begin
    repeat
      S:= AVirtualRoots.Names[i];
      L:= Length(S);
      if (L < 0) or (not(S[L] in [#0..#32, ',']))
      then Break;
      S:= AVirtualRoots[i];
      Delete(S, L, 1);
      AVirtualRoots[i]:= S;
    until False;
  end;
  // set default "current" directory

  if AVirtualRoots.Values[''] = ''
  then AVirtualRoots.Values['']:= ACurDir;
  // set default "root" directory
  if AVirtualRoots.Values['/'] = ''
  then AVirtualRoots.Values['/']:= ACurDir;
  if AVirtualRoots is TStringList then begin
    TStringList(AVirtualRoots).Duplicates:= dupIgnore;
    TStringList(AVirtualRoots).Sorted:= True;
  end;
end;

function TFormMain.LoadIni: Boolean;
var
  Rg: TRegistry;
  i: Integer;
  n: String;
begin
  Result:= False;
  Rg:= TRegistry.Create;
  try
    Rg.RootKey:= HKEY_LOCAL_MACHINE;
    Rg.OpenKeyReadOnly(RGPATH);
    FPluginsFolder:= Rg.ReadString('Plugins Folder');
    FPluginIdx:= Rg.ReadInteger('Plugin');

    { proxy }
    {
    FProxyEnabled:= Rg.ReadString('Use proxy') = '1';
    FProxyName:= Rg.ReadString('Proxy');
    FProxyPort:= StrToIntDef(Rg.ReadString('Proxy port'), 8080);
    }
    if FPluginsFolder = ''
    then FPluginsFolder:= 'plugins';
    { web server }
    HttpServ.BindIP:= Rg.ReadString(RGBindIP);
    HttpServ.BindPort:= StrToIntDef(Rg.ReadString(RgBindPort), 81);
    n:= Rg.ReadString(RgRoot);
    if n <> ''
    then HttpServ.fn_root:= n;
    { read aliases }
    FAliases.Clear;
    if FIISAliases
    then util1.AddEntireKey(RGW2SVCALIAS, FAliases);
    if Fis2sqlAliases
    then util1.AddEntireKey(RGIS2SQLVIRTALIAS, FAliases);
    util1.AddEntireKey(RGPATH+'\Virtual Roots', FAliases);
    ValidateW3SvcColon(FWorkDir, FAliases);
    { read file associations }
    FContentTypes.Clear;
    if FUseShellContentTypes
    then xContType.regReadContentTypes(FContentTypes);

  except
  end;
  { fill FPlugins }
  SetPlugins(FPluginsFolder, FPluginIdx);
  Rg.Free;
end;

procedure TFormMain.StoreIni;
var
  Rg: TRegistry;
  i: Integer;
begin
  Rg:= TRegistry.Create;
  try
    Rg.RootKey:= HKEY_LOCAL_MACHINE;
    Rg.OpenKey(RGPATH, True);
    Rg.WriteString('Plugins Folder', FPluginsFolder);
    Rg.WriteInteger('Plugin', FPluginIdx);
    { proxy }
    {
    if FProxyEnabled
    then Rg.WriteString('Use proxy', '1')
    else Rg.WriteString('Use proxy', '0');
    Rg.WriteString('Proxy', FProxyName);
    Rg.WriteString('Proxy port', IntToStr(FProxyPort));
    }
    Rg.WriteString(RgBindIP, HttpServ.BindIP);
    Rg.WriteString(RgBindPort, IntToStr(HttpServ.BindPort));
    Rg.WriteString(RgRoot, HttpServ.fn_root);
    if FIISAliases
    then Rg.WriteString(RgIISaliases, '1')
    else Rg.WriteString(RgIISaliases, '0');
    if Fis2sqlAliases
    then Rg.WriteString(Rgis2sqlaliases, '1')
    else Rg.WriteString(Rgis2sqlaliases, '0');
    if FUseShellContentTypes
    then Rg.WriteString(RgShell, '1')
    else Rg.WriteString(RgShell, '0');
  except
  end;
  Rg.Free;
end;

function TFormMain.SetPlugins(const APath: String; AIndex: Integer): Integer;
var
  i: Integer;
  SearchRec: TSearchRec;
  Mask: String;
  Ver: String;
begin
  Result:= 0;
  FPlugins.Clear;
  FPluginsFolder:= APath;
  Mask:= ConcatPath(APath, '*.dll');
  try
    if FindFirst(Mask, faAnyFile, SearchRec) = 0 then begin
      try
        Ver:= UtilISAPI.GetVersionISAPI(ConcatPath(APath, SearchRec.Name));
        FPlugins.Add(Ver + '=' + SearchRec.Name);
      except
      end;
      while FindNext(SearchRec) = 0 do begin
        try
          Ver:= UtilISAPI.GetVersionISAPI(ConcatPath(APath, SearchRec.Name));
        FPlugins.Add(Ver + '=' + SearchRec.Name);
        except
        end;
      end;
    end;
  except
  end;
  Windows.FindClose(SearchRec.FindHandle);

  pmOptionsLibraryFolder.Caption:= Format(MSG_PluginsFolder,[FPluginsFolder]);
  with CBDll.Items do begin
    Clear;
    for i:= 0 to FPlugins.Count - 1 do begin
      AddObject(FPlugins.Names[i], Nil);
    end;
  end;
  if (AIndex >=0) and (AIndex < FPlugins.Count) then begin
    FPluginIdx:= AIndex;
    CBDll.ItemIndex:= FPluginIdx;
  end;
  Result:= FPlugins.Count;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  FN: array[0..511] of Char;
begin
  FFirstTime:= True;
  FBanner:= Nil;
  FPluginIdx:= -1;
  SetString(FWorkDir, FN, GetModuleFileName(hInstance, FN, SizeOf(FN)));
  FWorkDir:= ExtractFilePath(FWorkDir);
  FPlugins:= TStringList.Create;
  Timer1.Enabled:= True;
  { web server }
  FAliases:= TStringList.Create;
  TStringList(FAliases).Duplicates:= dupIgnore;
  TStringList(FAliases).Sorted:= True;

  FContentTypes:= TStringList.Create;
  TStringList(FContentTypes).Duplicates:= dupIgnore;
  TStringList(FContentTypes).Sorted:= True;

  HttpServ:= THttpServ.Create;
end;

procedure TFormMain.FormActivate(Sender: TObject);
begin
  if FFirstTime then begin
    if LoadIni then;
    ActivateBanner;
    FFirstTime:= False;
  end;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  FBanner.Left:= (PanelBanner.Width - FBanner.Width) div 2;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  FBanner.Started:= Assigned(FBanner) and IsIPPresent;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  StoreIni;
  FPlugins.Free;
  { web server }
  HttpServ.Free;
  FAliases.Free;
  FContentTypes.Free;
end;

procedure TFormMain.OnClickFBanner(Sender: TObject);
var
  op, fn, opt, wdir: PChar;
begin
  op:= StrAlloc(4);  op:= 'open';
  fn:= StrAlloc(Length(JiptoBannerUrl)); fn:= PChar(JiptoBannerUrl);
  wdir:= StrAlloc(Length(FWorkDir)); wdir:= PChar(FWorkDir);
  opt:= StrAlloc(1); opt:= #32;
  {
  if ShellAPI.ShellExecute(Application.Handle, op, fn, opt, wdir, 0) <=32 then begin
  end;
  }
end;

function TFormMain.LocateISAPI(const APath: String): Integer;
var
  i: Integer;
  SearchRec: TSearchRec;
  Mask: String;
  Ver: String;
begin
  Result:= 0;
  FPlugins.Clear;
  Mask:= ConcatPath(APath, '*.dll');
  try
    if FindFirst(Mask, faAnyFile, SearchRec) = 0 then begin
      try
        Ver:= UtilISAPI.GetVersionISAPI(ConcatPath(APath, SearchRec.Name));
        FPlugins.Add(Ver + '=' + SearchRec.Name);
      except
      end;
      while FindNext(SearchRec) = 0 do begin
        try
          Ver:= UtilISAPI.GetVersionISAPI(ConcatPath(APath, SearchRec.Name));
          FPlugins.Add(Ver + '=' + SearchRec.Name);
        except
        end;
      end;
    end;
  except
  end;
  Windows.FindClose(SearchRec.FindHandle);
  Result:= FPlugins.Count;
end;

procedure TFormMain.pmFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.pmOptionsLibraryFolderClick(Sender: TObject);
begin
  {}
  with OpenDialog1 do begin
    InitialDir:= FPluginsFolder;
    Filter:= 'Library files (*.dll)|*.dll|All files|*.*';
    DefaultExt:= 'dll';
    Title:= 'Select any DLL';
    if Execute
    then SetPlugins(ExtractFilePath(FileName), -1);
  end;
end;

procedure TFormMain.CBDllChange(Sender: TObject);
begin
  FPluginIdx:= CBDll.ItemIndex;
end;

// web server
procedure TFormMain.Start;
begin
  with HttpServ do begin
    // logger:= logger;
    ContentTypes:= FContentTypes;
    RequestFileEvent:= MyRequestFileEvent;
    Started:= True;
  end;
end;

procedure TFormMain.Stop;
begin
  HttpServ.Started:= False;
end;

function TFormMain.DispatchRequests(const ARequest: String; var AFileInfo: TFileInfo): String;
var
  p: Integer;
  SL: TStrings;
begin
  Result:= '';
  SL:= TStringList.Create;
  if Pos(#13#10, ARequest) <=0
  then SL.CommaText:= UpperCase(ARequest)
  else SL.Text:= UpperCase(ARequest);
  if SL.Count <=0 then begin
    SL.Free;
    Exit;
  end;
  // delete "/scripts/jipto.dll/pathcmd?" from url 
  p:= Pos('?', SL[0]);
  if p > 0
  then SL[0]:= Copy(SL[0], p+1, MaxInt);
  Result:= 'Nothing';
  // ShowFile(SL[0], SL, AFileInfo);
  AFileInfo.Time:= Now;
  SL.Free;
end;

procedure TFormMain.MyRequestFileEvent(Sender: TObject; const AFileName: String;
  var AFileInfo: TFileInfo; var AHandled: Boolean);
begin
  AFileInfo.FStream:= TStringStream.Create(DispatchRequests(AFileName, AFileInfo));
end;

end.
