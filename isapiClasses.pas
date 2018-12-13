unit isapiClasses;

interface

uses
  SysUtils, Windows, Classes, Contnrs, Isapi2;

type
  TMethodType = (mtAny, mtGet, mtPut, mtPost, mtHead);

const
  MAX_STRINGS = 12;
  MAX_INTEGERS = 1;
  MAX_DATETIMES = 3;
  sDateFormat = '"%s", dd "%s" yyyy hh:mm:ss';

type
  TWebResponse = class;
  TAbstractContentParser = class;
  TAbstractWebRequestFiles = class;

  { TWebRequest }

  TWebRequest = class(TObject)
  private
    FContentParser: TAbstractContentParser;
    FMethodType: TMethodType;
    FContentFields,
    FCookieFields,
    FQueryFields: TStrings;
    function GetContentParser: TAbstractContentParser;
    function GetContentFields: TStrings;
    function GetCookieFields: TStrings;
    function GetQueryFields: TStrings;
    function GetFiles: TAbstractWebRequestFiles;
  protected
    function GetStringVariable(Index: Integer): string; virtual; abstract;
    function GetDateVariable(Index: Integer): TDateTime; virtual; abstract;
    function GetIntegerVariable(Index: Integer): Integer; virtual; abstract;
    function GetInternalPathInfo: string; virtual;
    function GetInternalScriptName: string; virtual;
    procedure UpdateMethodType;
  public
    constructor Create;
    destructor Destroy; override;
    // Read count bytes from client
    function ReadClient(var Buffer; Count: Integer): Integer; virtual; abstract;
    // Read count characters as a string from client
    function ReadString(Count: Integer): string; virtual; abstract;
    // Translate a relative URI to a local absolute path
    function TranslateURI(const URI: string): string; virtual; abstract;
    // Write count bytes back to client
    function WriteClient(var Buffer; Count: Integer): Integer; virtual; abstract;
    // Write string contents back to client
    function WriteString(const AString: string): Boolean; virtual; abstract;
    // Write HTTP header string
    function WriteHeaders(StatusCode: Integer; const ReasonString, Headers: string): Boolean; virtual; abstract;
    // Utility to extract fields from a given string buffer
    procedure ExtractFields(Separators, WhiteSpace: TSysCharSet;
      Content: PChar; Strings: TStrings);
    // Fills the given string list with the content fields as the result
    // of a POST method
    procedure ExtractContentFields(Strings: TStrings);
    // Fills the given string list with values from the cookie header field
    procedure ExtractCookieFields(Strings: TStrings);
    // Fills the given TStrings with the values from the Query data
    // (ie: data following the "?" in the URL)
    procedure ExtractQueryFields(Strings: TStrings);
    // Read an arbitrary HTTP/Server Field not lists here
    function GetFieldByName(const Name: string): string; virtual; abstract;
    // The request method as an enumeration
    property MethodType: TMethodType read FMethodType;
    // Content parser
    property ContentParser: TAbstractContentParser read GetContentParser;
    // Field lists
    property ContentFields: TStrings read GetContentFields;
    property CookieFields: TStrings read GetCookieFields;
    property QueryFields: TStrings read GetQueryFields;
    // HTTP header Fields
    property Method: string index 0 read GetStringVariable;
    property ProtocolVersion: string index 1 read GetStringVariable;
    property URL: string index 2 read GetStringVariable;
    property Query: string index 3 read GetStringVariable;
    property PathInfo: string index 4 read GetStringVariable;
    property PathTranslated: string index 5 read GetStringVariable;
    property Authorization: string index 28 read GetStringVariable;
    property CacheControl: string index 6 read GetStringVariable;
    property Cookie: string index 27 read GetStringVariable;
    property Date: TDateTime index 7 read GetDateVariable;
    property Accept: string index 8 read GetStringVariable;
    property From: string index 9 read GetStringVariable;
    property Host: string index 10 read GetStringVariable;
    property IfModifiedSince: TDateTime index 11 read GetDateVariable;
    property Referer: string index 12 read GetStringVariable;
    property UserAgent: string index 13 read GetStringVariable;
    property ContentEncoding: string index 14 read GetStringVariable;
    property ContentType: string index 15 read GetStringVariable;
    property ContentLength: Integer index 16 read GetIntegerVariable;
    property ContentVersion: string index 17 read GetStringVariable;
    property Content: string index 25 read GetStringVariable;
    property Connection: string index 26 read GetStringVariable;
    property DerivedFrom: string index 18 read GetStringVariable;
    property Expires: TDateTime index 19 read GetDateVariable;
    property Title: string index 20 read GetStringVariable;
    property RemoteAddr: string index 21 read GetStringVariable;
    property RemoteHost: string index 22 read GetStringVariable;
    property ScriptName: string index 23 read GetStringVariable;
    property ServerPort: Integer index 24 read GetIntegerVariable;
    property InternalPathInfo: string read GetInternalPathInfo;
    property InternalScriptName: string read GetInternalScriptName;
    property Files: TAbstractWebRequestFiles read GetFiles;
  end;

  TAbstractContentParser = class(TObject)
  private
    FWebRequest: TWebRequest;
  protected
    property WebRequest: TWebRequest read FWebRequest;
    function GetContentFields: TStrings; virtual; abstract;
    function GetFiles: TAbstractWebRequestFiles; virtual; abstract;
  public
    constructor Create(AWebRequest: TWebRequest); virtual;
    class function CanParse(AWebRequest: TWebRequest): Boolean; virtual;
  end;

  TContentParser = class(TAbstractContentParser)
  private
    FContentFields: TStrings;
  public
    function GetContentFields: TStrings; override;
    function GetFiles: TAbstractWebRequestFiles; override;
    class function CanParse(AWebRequest: TWebRequest): Boolean; override;
  end;

  TContentParserClass = class of TAbstractContentParser;

  TAbstractWebRequestFile = class;
  TAbstractWebRequestFiles = class(TObject)
  protected
    function GetCount: Integer; virtual; abstract;
    function GetItem(I: Integer): TAbstractWebRequestFile; virtual; abstract;
  public
    property Items[I: Integer]: TAbstractWebRequestFile read GetItem; default;
    property Count: Integer read GetCount;
  end;

  TAbstractWebRequestFile = class(TObject)
  protected
    function GetFieldName: string; virtual; abstract;
    function GetFileName: string; virtual; abstract;
    function GetStream: TStream; virtual; abstract;
    function GetContentType: string; virtual; abstract;
  public
    property FieldName: string read GetFieldName;
    property FileName: string read GetFileName;
    property Stream: TStream read GetStream;
    property ContentType: string read GetContentType;
  end;


  { TCookie }

  TCookie = class(TCollectionItem)
  private
    FName: string;
    FValue: string;
    FPath: string;
    FDomain: string;
    FExpires: TDateTime;
    FSecure: Boolean;
  protected
    function GetHeaderValue: string;
  public
    constructor Create(Collection: TCollection); override;
    procedure AssignTo(Dest: TPersistent); override;
    property Name: string read FName write FName;
    property Value: string read FValue write FValue;
    property Domain: string read FDomain write FDomain;
    property Path: string read FPath write FPath;
    property Expires: TDateTime read FExpires write FExpires;
    property Secure: Boolean read FSecure write FSecure;
    property HeaderValue: string read GetHeaderValue;
  end;

  { TCookieCollection }

  TCookieCollection = class(TCollection)
  private
    FWebResponse: TWebResponse;
  protected
    function GetCookie(Index: Integer): TCookie;
    procedure SetCookie(Index: Integer; Cookie: TCookie);
  public
    constructor Create(WebResponse: TWebResponse; ItemClass: TCollectionItemClass);
    function  Add: TCookie;
    property WebResponse: TWebResponse read FWebResponse;
    property Items[Index: Integer]: TCookie read GetCookie write SetCookie; default;
  end;

  { TWebResponse }

  TWebResponse = class(TObject)
  private
    FContentStream: TStream;
    FCookies: TCookieCollection;
    procedure SetCustomHeaders(Value: TStrings);
  protected
    FHTTPRequest: TWebRequest;
    FCustomHeaders: TStrings;      
    procedure AddCustomHeaders(var Headers: string);
    function GetStringVariable(Index: Integer): string; virtual; abstract;
    procedure SetStringVariable(Index: Integer; const Value: string); virtual; abstract;
    function GetDateVariable(Index: Integer): TDateTime; virtual; abstract;
    procedure SetDateVariable(Index: Integer; const Value: TDateTime); virtual; abstract;
    function GetIntegerVariable(Index: Integer): Integer; virtual; abstract;
    procedure SetIntegerVariable(Index: Integer; Value: Integer); virtual; abstract;
    function GetContent: string; virtual; abstract;
    procedure SetContent(const Value: string); virtual; abstract;
    procedure SetContentStream(Value: TStream); virtual;
    function GetStatusCode: Integer; virtual; abstract;
    procedure SetStatusCode(Value: Integer); virtual; abstract;
    function GetLogMessage: string; virtual; abstract;
    procedure SetLogMessage(const Value: string); virtual; abstract;
  public
    constructor Create(HTTPRequest: TWebRequest);
    destructor Destroy; override;
    function GetCustomHeader(const Name: string): String;
    procedure SendResponse; virtual; abstract;
    procedure SendRedirect(const URI: string); virtual; abstract;
    procedure SendStream(AStream: TStream); virtual; abstract;
    function Sent: Boolean; virtual;
    procedure SetCookieField(Values: TStrings; const ADomain, APath: string;
      AExpires: TDateTime; ASecure: Boolean);
    procedure SetCustomHeader(const Name, Value: string);
    property Cookies: TCookieCollection read FCookies;
    property HTTPRequest: TWebRequest read FHTTPRequest;
    property Version: string index 0 read GetStringVariable write SetStringVariable;
    property ReasonString: string index 1 read GetStringVariable write SetStringVariable;
    property Server: string index 2 read GetStringVariable write SetStringVariable;
    property WWWAuthenticate: string index 3 read GetStringVariable write SetStringVariable;
    property Realm: string index 4 read GetStringVariable write SetStringVariable;
    property Allow: string index 5 read GetStringVariable write SetStringVariable;
    property Location: string index 6 read GetStringVariable write SetStringVariable;
    property ContentEncoding: string index 7 read GetStringVariable write SetStringVariable;
    property ContentType: string index 8 read GetStringVariable write SetStringVariable;
    property ContentVersion: string index 9 read GetStringVariable write SetStringVariable;
    property DerivedFrom: string index 10 read GetStringVariable write SetStringVariable;
    property Title: string index 11 read GetStringVariable write SetStringVariable;

    property StatusCode: Integer read GetStatusCode write SetStatusCode;
    property ContentLength: Integer index 0 read GetIntegerVariable write SetIntegerVariable;

    property Date: TDateTime index 0 read GetDateVariable write SetDateVariable;
    property Expires: TDateTime index 1 read GetDateVariable write SetDateVariable;
    property LastModified: TDateTime index 2 read GetDateVariable write SetDateVariable;

    property Content: string read GetContent write SetContent;
    property ContentStream: TStream read FContentStream write SetContentStream;

    property LogMessage: string read GetLogMessage write SetLogMessage;

    property CustomHeaders: TStrings read FCustomHeaders write SetCustomHeaders;
  end;

  TISAPIRequest = class(TWebRequest)
  private
    FECB: PEXTENSION_CONTROL_BLOCK;
  protected
    function GetStringVariable(Index: Integer): string; override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetIntegerVariable(Index: Integer): Integer; override;
  public
    constructor Create(AECB: PEXTENSION_CONTROL_BLOCK);
    function GetFieldByName(const Name: string): string; override;
    function ReadClient(var Buffer; Count: Integer): Integer; override;
    function ReadString(Count: Integer): string; override;
    function TranslateURI(const URI: string): string; override;
    function WriteClient(var Buffer; Count: Integer): Integer; override;
    function WriteString(const AString: string): Boolean; override;
    function WriteHeaders(StatusCode: Integer; const StatusString, Headers: string): Boolean; override;
    property ECB: PEXTENSION_CONTROL_BLOCK read FECB;
  end;

  TISAPIResponse = class(TWebResponse)
  private
    FStatusCode: Integer;
    FStringVariables: array[0..MAX_STRINGS - 1] of string;
    FIntegerVariables: array[0..MAX_INTEGERS - 1] of Integer;
    FDateVariables: array[0..MAX_DATETIMES - 1] of TDateTime;
    FContent: string;
    FSent: Boolean;
  protected
    function GetContent: string; override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetIntegerVariable(Index: Integer): Integer; override;
    function GetLogMessage: string; override;
    function GetStatusCode: Integer; override;
    function GetStringVariable(Index: Integer): string; override;
    procedure SetContent(const Value: string); override;
    procedure SetDateVariable(Index: Integer; const Value: TDateTime); override;
    procedure SetIntegerVariable(Index: Integer; Value: Integer); override;
    procedure SetLogMessage(const Value: string); override;
    procedure SetStatusCode(Value: Integer); override;
    procedure SetStringVariable(Index: Integer; const Value: string); override;
    procedure InitResponse; virtual;
  public
    constructor Create(HTTPRequest: TWebRequest);
    procedure SendResponse; override;
    procedure SendRedirect(const URI: string); override;
    procedure SendStream(AStream: TStream); override;
    function Sent: Boolean; override;
  end;

  EWebBrokerException = class(Exception)
  end;

function DosPathToUnixPath(const Path: string): string;
function HTTPDecode(const AStr: String): string;
function HTTPEncode(const AStr: String): string;
function ParseDate(const DateStr: string): TDateTime;
procedure ExtractHTTPFields(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings; StripQuotes: Boolean = False);
procedure ExtractHeaderFields(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings; Decode: Boolean; StripQuotes: Boolean = False);
function StatusString(StatusCode: Integer): string;
function UnixPathToDosPath(const Path: string): string;
function MonthStr(DateTime: TDateTime): string;
function DayOfWeekStr(DateTime: TDateTime): string;

procedure RegisterContentParser(AClass: TContentParserClass);

implementation

uses
  WebConst, BrkrConst;

const
  ServerVariables: array[0..28] of string = (
    '',
    'SERVER_PROTOCOL',
    'URL',
    '',
    '',
    '',
    'HTTP_CACHE_CONTROL',
    'HTTP_DATE',
    'HTTP_ACCEPT',
    'HTTP_FROM',
    'HTTP_HOST',
    'HTTP_IF_MODIFIED_SINCE',
    'HTTP_REFERER',
    'HTTP_USER_AGENT',
    'HTTP_CONTENT_ENCODING',
    'CONTENT_TYPE',
    'CONTENT_LENGTH',
    'HTTP_CONTENT_VERSION',
    'HTTP_DERIVED_FROM',
    'HTTP_EXPIRES',
    'HTTP_TITLE',
    'REMOTE_ADDR',
    'REMOTE_HOST',
    'SCRIPT_NAME',
    'SERVER_PORT',
    '',
    'HTTP_CONNECTION',
    'HTTP_COOKIE',
    'HTTP_AUTHORIZATION');

var
  ContentParsers: TList;

function HTTPDecode(const AStr: String): String;
var
  Sp, Rp, Cp: PChar;
  S: String;
begin
  SetLength(Result, Length(AStr));
  Sp := PChar(AStr);
  Rp := PChar(Result);
  Cp := Sp;
  try
    while Sp^ <> #0 do
    begin
      case Sp^ of
        '+': Rp^ := ' ';
        '%': begin
               // Look for an escaped % (%%) or %<hex> encoded character
               Inc(Sp);
               if Sp^ = '%' then
                 Rp^ := '%'
               else
               begin
                 Cp := Sp;
                 Inc(Sp);
                 if (Cp^ <> #0) and (Sp^ <> #0) then
                 begin
                   S := '$' + Cp^ + Sp^;
                   Rp^ := Chr(StrToInt(S));
                 end
                 else
                   raise EWebBrokerException.CreateFmt(sErrorDecodingURLText, [Cp - PChar(AStr)]);
               end;
             end;
      else
        Rp^ := Sp^;
      end;
      Inc(Rp);
      Inc(Sp);
    end;
  except
    on E:EConvertError do
      raise EConvertError.CreateFmt(sInvalidURLEncodedChar,
        ['%' + Cp^ + Sp^, Cp - PChar(AStr)])
  end;
  SetLength(Result, Rp - PChar(Result));
end;

function HTTPEncode(const AStr: String): String;
const
  NoConversion = ['A'..'Z','a'..'z','*','@','.','_','-',
                  '0'..'9','$','!','''','(',')'];
var
  Sp, Rp: PChar;
begin
  SetLength(Result, Length(AStr) * 3);
  Sp := PChar(AStr);
  Rp := PChar(Result);
  while Sp^ <> #0 do
  begin
    if Sp^ in NoConversion then
      Rp^ := Sp^
    else
      if Sp^ = ' ' then
        Rp^ := '+'
      else
      begin
        FormatBuf(Rp^, 3, '%%%.2x', 6, [Ord(Sp^)]);
        Inc(Rp,2);
      end;
    Inc(Rp);
    Inc(Sp);
  end;
  SetLength(Result, Rp - PChar(Result));
end;

procedure ExtractHeaderFields(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings; Decode: Boolean; StripQuotes: Boolean = False);
var
  Head, Tail: PChar;
  EOS, InQuote, LeadQuote: Boolean;
  QuoteChar: Char;

  function DoStripQuotes(const S: string): string;
  var
    I: Integer;
  begin
    Result := S;
    if StripQuotes then
      for I := Length(Result) downto 1 do
        if Result[I] in ['''', '"'] then
          Delete(Result, I, 1);
  end;

begin
  if (Content = nil) or (Content^ = #0) then Exit;
  Tail := Content;
  QuoteChar := #0;
  repeat
    while Tail^ in WhiteSpace + [#13, #10] do Inc(Tail);
    Head := Tail;
    InQuote := False;
    LeadQuote := False;
    while True do
    begin
      while (InQuote and not (Tail^ in [#0, #13, #10, '"'])) or
        not (Tail^ in Separators + [#0, #13, #10, '"']) do Inc(Tail);
      if Tail^ = '"' then
      begin
        if (QuoteChar <> #0) and (QuoteChar = Tail^) then
          QuoteChar := #0
        else
        begin
          LeadQuote := Head = Tail;
          QuoteChar := Tail^;
          if LeadQuote then Inc(Head);
        end;
        InQuote := QuoteChar <> #0;
        if InQuote then
          Inc(Tail)
        else Break;
      end else Break;
    end;
    if not LeadQuote and (Tail^ <> #0) and (Tail^ = '"') then
      Inc(Tail);
    EOS := Tail^ = #0;
    Tail^ := #0;
    if Head^ <> #0 then
      if Decode then
        Strings.Add(DoStripQuotes(HTTPDecode(Head)))
      else Strings.Add(DoStripQuotes(Head));
    Inc(Tail);
  until EOS;
end;

procedure ExtractHTTPFields(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings; StripQuotes: Boolean = False);
begin
  ExtractHeaderFields(Separators, WhiteSpace, Content, Strings, True, StripQuotes);
end;

function StatusString(StatusCode: Integer): string;
begin
  case StatusCode of
    100: Result := 'Continue';
    101: Result := 'Switching Protocols';
    200: Result := 'OK';
    201: Result := 'Created';
    202: Result := 'Accepted';
    203: Result := 'Non-Authoritative Information';
    204: Result := 'No Content';
    205: Result := 'Reset Content';
    206: Result := 'Partial Content';
    300: Result := 'Multiple Choices';
    301: Result := 'Moved Permanently';
    302: Result := 'Moved Temporarily';
    303: Result := 'See Other';
    304: Result := 'Not Modified';
    305: Result := 'Use Proxy';
    400: Result := 'Bad Request';
    401: Result := 'Unauthorized';
    402: Result := 'Payment Required';
    403: Result := 'Forbidden';
    404: Result := 'Not Found';
    405: Result := 'Method Not Allowed';
    406: Result := 'None Acceptable';
    407: Result := 'Proxy Authentication Required';
    408: Result := 'Request Timeout';
    409: Result := 'Conflict';
    410: Result := 'Gone';
    411: Result := 'Length Required';
    412: Result := 'Unless True';
    500: Result := 'Internal Server Error';
    501: Result := 'Not Implemented';
    502: Result := 'Bad Gateway';
    503: Result := 'Service Unavailable';
    504: Result := 'Gateway Timeout';
  else
    Result := '';
  end
end;

function TranslateChar(const Str: string; FromChar, ToChar: Char): string;
var
  I: Integer;
begin
  Result := Str;
  for I := 1 to Length(Result) do
    if Result[I] = FromChar then
      Result[I] := ToChar;
end;

function UnixPathToDosPath(const Path: string): string;
begin
  Result := TranslateChar(Path, '/', '\');
end;

function DosPathToUnixPath(const Path: string): string;
begin
  Result := TranslateChar(Path, '\', '/');
end;

const
// These strings are NOT to be resourced

  Months: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec');
  DaysOfWeek: array[1..7] of string = (
    'Sun', 'Mon', 'Tue', 'Wed',
    'Thu', 'Fri', 'Sat');

function ParseDate(const DateStr: string): TDateTime;
var
  Month, Day, Year, Hour, Minute, Sec: Integer;
  Parser: TParser;
  StringStream: TStringStream;

  function GetMonth: Boolean;
  begin
    if Month < 13 then
    begin
      Result := False;
      Exit;
    end;
    Month := 1;
    while not Parser.TokenSymbolIs(Months[Month]) and (Month < 13) do Inc(Month);
    Result := Month < 13;
  end;

  procedure GetTime;
  begin
    with Parser do
    begin
      Hour := TokenInt;
      NextToken;
      if Token = ':' then NextToken;
      Minute := TokenInt;
      NextToken;
      if Token = ':' then NextToken;
      Sec := TokenInt;
      NextToken;
    end;
  end;

begin
  Month := 13;
  StringStream := TStringStream.Create(DateStr);
  try
    Parser := TParser.Create(StringStream);
    with Parser do
    try
      Month := TokenInt;
      NextToken;
      if Token = ':' then NextToken;
      NextToken;
      if Token = ',' then NextToken;
      if GetMonth then
      begin
        NextToken;
        Day := TokenInt;
        NextToken;
        GetTime;
        Year := TokenInt;
      end else
      begin
        Day := TokenInt;
        NextToken;
        if Token = '-' then NextToken;
        GetMonth;
        NextToken;
        if Token = '-' then NextToken;
        Year := TokenInt;
        if Year < 100 then Inc(Year, 1900);
        NextToken;
        GetTime;
      end;
      Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Minute, Sec, 0);
    finally
      Free;
    end;
  finally
    StringStream.Free;
  end;
end;

function MonthStr(DateTime: TDateTime): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  Result := Months[Month];
end;

function DayOfWeekStr(DateTime: TDateTime): string;
begin
  Result := DaysOfWeek[DayOfWeek(DateTime)];
end;

procedure RegisterContentParser(AClass: TContentParserClass);
begin
  ContentParsers.Add(AClass);
end;

{ TWebRequest }

constructor TWebRequest.Create;
begin
  inherited Create;
  UpdateMethodType;
end;

procedure TWebRequest.UpdateMethodType;
begin
  if CompareText(Method, 'GET') = 0 then
    FMethodType := mtGet
  else if CompareText(Method, 'PUT') = 0 then
    FMethodType := mtPut
  else if CompareText(Method, 'POST') = 0 then
    FMethodType := mtPost
  else if CompareText(Method, 'HEAD') = 0 then
    FMethodType := mtHead;
end;

destructor TWebRequest.Destroy;
begin
  FContentFields.Free;
  FCookieFields.Free;
  FQueryFields.Free;
  FContentParser.Free;
  inherited Destroy;
end;

procedure TWebRequest.ExtractFields(Separators, WhiteSpace: TSysCharSet;
  Content: PChar; Strings: TStrings);
begin
  ExtractHTTPFields(Separators, WhiteSpace, Content, Strings);
end;

procedure TWebRequest.ExtractContentFields(Strings: TStrings);
var
  ContentStr: string;
begin
  if ContentLength > 0 then
  begin
    ContentStr := Content;
    if Length(ContentStr) < ContentLength then
      ContentStr := ContentStr + ReadString(ContentLength - Length(ContentStr));
    ExtractFields(['&'], [], PChar(ContentStr), Strings);
  end;
end;


procedure TWebRequest.ExtractCookieFields(Strings: TStrings);
var
  CookieStr: string;
begin
  CookieStr := Cookie;
  ExtractHeaderFields([';'], [' '], PChar(CookieStr), Strings, True);
end;

procedure TWebRequest.ExtractQueryFields(Strings: TStrings);
var
  ContentStr: string;
begin
  ContentStr := Query;
  ExtractFields(['&'], [], PChar(ContentStr), Strings);
end;

function TWebRequest.GetContentFields: TStrings;
begin
  Result := ContentParser.GetContentFields;
end;
 
function TWebRequest.GetCookieFields: TStrings;
begin
  if FCookieFields = nil then
  begin
    FCookieFields := TStringList.Create;
    ExtractCookieFields(FCookieFields);
  end;
  Result := FCookieFields;
end;

function TWebRequest.GetQueryFields: TStrings;
begin
  if FQueryFields = nil then
  begin
    FQueryFields := TStringList.Create;
    ExtractQueryFields(FQueryFields);
  end;
  Result := FQueryFields;
end;

function TWebRequest.GetInternalPathInfo: string;
begin
  Result := PathInfo;
end;

function TWebRequest.GetInternalScriptName: string;
begin
  Result := ScriptName;
end;

function TWebRequest.GetFiles: TAbstractWebRequestFiles;
begin
  Result := ContentParser.GetFiles;
end;

function TWebRequest.GetContentParser: TAbstractContentParser;
var
  I: Integer;
  C: TContentParserClass;
begin
  if FContentParser = nil then
  begin
    for I := ContentParsers.Count - 1 downto 0 do
    begin
      C := TContentParserClass(ContentParsers[I]);
      if C.CanParse(Self) then
      begin
        FContentParser := C.Create(Self);
        Break;
      end;
    end;
  end;
  if FContentParser = nil then
    FContentParser := TContentParser.Create(Self);
  Result := FContentParser;
end;

{ TCookie }

constructor TCookie.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FExpires := -1;
end;

procedure TCookie.AssignTo(Dest: TPersistent);
begin
  if Dest is TCookie then
    with TCookie(Dest) do
    begin
      Name := Self.FName;
      Value := Self.FValue;
      Domain := Self.FDomain;
      Path := Self.FPath;
      Expires := Self.FExpires;
      Secure := Self.FSecure;
    end else inherited AssignTo(Dest);
end;

function TCookie.GetHeaderValue: string;
begin
  Result := Format('%s=%s; ', [HTTPEncode(FName), HTTPEncode(FValue)]);
  if Domain <> '' then
    Result := Result + Format('domain=%s; ', [Domain]);
  if Path <> '' then
    Result := Result + Format('path=%s; ', [Path]);
  if Expires > -1 then
    Result := Result +
      Format(FormatDateTime('"expires="' + sDateFormat + ' "GMT; "', Expires),
        [DayOfWeekStr(Expires), MonthStr(Expires)]);
  if Secure then Result := Result + 'secure';
  if Copy(Result, Length(Result) - 1, MaxInt) = '; ' then
    SetLength(Result, Length(Result) - 2);
end;

{ TCookieCollection }

constructor TCookieCollection.Create(WebResponse: TWebResponse; ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
  FWebResponse := WebResponse;
end;

function TCookieCollection.Add: TCookie;
begin
  Result := TCookie(inherited Add);
end;

function TCookieCollection.GetCookie(Index: Integer): TCookie;
begin
  Result := TCookie(inherited Items[Index]);
end;

procedure TCookieCollection.SetCookie(Index: Integer; Cookie: TCookie);
begin
  Items[Index].Assign(Cookie);
end;

{ TWebResponse }

constructor TWebResponse.Create(HTTPRequest: TWebRequest);
begin
  inherited Create;
  FHTTPRequest := HTTPRequest;
  FCustomHeaders := TStringList.Create;
  FCookies := TCookieCollection.Create(Self, TCookie);
end;

destructor TWebResponse.Destroy;
begin
  FContentStream.Free;
  FCustomHeaders.Free;
  FCookies.Free;
  inherited Destroy;
end;

procedure TWebResponse.AddCustomHeaders(var Headers: string);
var
  I: Integer;
  Name, Value: string;
begin
  for I := 0 to FCustomHeaders.Count - 1 do
  begin
    Name := FCustomHeaders.Names[I];
    Value := FCustomHeaders.values[Name];
    Headers := Headers + Name + ': ' + Value + #13#10;
  end;
end;

function TWebResponse.GetCustomHeader(const Name: string): string;
begin
  Result := FCustomHeaders.Values[Name];
end;

function TWebResponse.Sent: Boolean;
begin
  Result := False;
end;

procedure TWebResponse.SetContentStream(Value: TStream);
begin
  if Value <> FContentStream then
  begin
    FContentStream.Free;
    FContentStream := Value;
    if FContentStream <> nil then
      ContentLength := FContentStream.Size
    else ContentLength := Length(Content);
  end;
end;

procedure TWebResponse.SetCookieField(Values: TStrings; const ADomain,
  APath: string; AExpires: TDateTime; ASecure: Boolean);
var
  I: Integer;
begin
  for I := 0 to Values.Count - 1 do
    with Cookies.Add do
    begin
      Name := Values.Names[I];
      Value := Values.Values[Values.Names[I]];
      Domain := ADomain;
      Path := APath;
      Expires := AExpires;
      Secure := ASecure;
    end;
end;

procedure TWebResponse.SetCustomHeader(const Name, Value: string);
begin
  FCustomHeaders.Values[Name] := Value;
end;

procedure TWebResponse.SetCustomHeaders(Value: TStrings);
begin
  FCustomHeaders.Assign(Value);
end;

{ TISAPIRequest }

constructor TISAPIRequest.Create(AECB: PEXTENSION_CONTROL_BLOCK);
begin
  FECB := AECB;
  inherited Create;
end;

function TISAPIRequest.GetFieldByName(const Name: string): string;
var
  Buffer: array[0..4095] of Char;
  Size: DWORD;
begin
  Size := SizeOf(Buffer);
  if ECB.GetServerVariable(ECB.ConnID, PChar(Name), @Buffer, Size) or
     ECB.GetServerVariable(ECB.ConnID, PChar('HTTP_' + Name), @Buffer, Size) then
  begin
    if Size > 0 then Dec(Size);
    SetString(Result, Buffer, Size);
  end else Result := '';
end;

function TISAPIRequest.GetStringVariable(Index: Integer): string;
begin
  case Index of
    0: Result := ECB.lpszMethod;
    3: Result := ECB.lpszQueryString;
    4: Result := ECB.lpszPathInfo;
    5: Result := ECB.lpszPathTranslated;
    1..2, 6..24, 26..28: Result := GetFieldByName(ServerVariables[Index]);
    25: if ECB.cbAvailable > 0 then
      SetString(Result, PChar(ECB.lpbData), ECB.cbAvailable);
   else
      Result := '';
  end;
end;

function TISAPIRequest.GetDateVariable(Index: Integer): TDateTime;
var
  Value: string;
begin
  Value := GetStringVariable(Index);
  if Value <> '' then
    Result := ParseDate(Value)
  else Result := -1;
end;

function TISAPIRequest.GetIntegerVariable(Index: Integer): Integer;
var
  Value: string;
begin
  Value := GetStringVariable(Index);
  if Value <> '' then
    Result := StrToInt(Value)
  else Result := -1;
end;

function TISAPIRequest.ReadClient(var Buffer; Count: Integer): Integer;
begin
  Result := Count;
  if not ECB.ReadClient(ECB.ConnID, @Buffer, DWORD(Result)) then
    Result := -1;
end;

function TISAPIRequest.ReadString(Count: Integer): string;
var
  Len: Integer;
begin
  SetLength(Result, Count);
  Len := ReadClient(Pointer(Result)^, Count);
  if Len > 0 then
    SetLength(Result, Len)
  else Result := '';
end;

function TISAPIRequest.TranslateURI(const URI: string): string;
var
  PathBuffer: array[0..1023] of Char;
  Size: Integer;
begin
  StrCopy(PathBuffer, PChar(URI));
  Size := SizeOf(PathBuffer);
  if ECB.ServerSupportFunction(ECB.ConnID, HSE_REQ_MAP_URL_TO_PATH,
    @PathBuffer, @Size, nil) then
    Result := PathBuffer
  else Result := '';
end;

function TISAPIRequest.WriteClient(var Buffer; Count: Integer): Integer;
begin
  Result := Count;
  if not ECB.WriteClient(ECB.ConnID, @Buffer, DWORD(Result), 0) then
    Result := -1;
end;

function TISAPIRequest.WriteString(const AString: string): Boolean;
begin
  Result := WriteClient(Pointer(AString)^, Length(AString)) = Length(AString);
end;

function TISAPIRequest.WriteHeaders(StatusCode: Integer;
  const StatusString, Headers: string): Boolean;
begin
  TISAPIRequest(Self).ECB.dwHttpStatusCode := StatusCode;
  with TISAPIRequest(Self) do
    ECB.ServerSupportFunction(ECB.ConnID, HSE_REQ_SEND_RESPONSE_HEADER,
      PChar(StatusString), nil, LPDWORD(Headers));
  Result := True;
end;

{ TISAPIResponse }

constructor TISAPIResponse.Create(HTTPRequest: TWebRequest);
begin
  inherited Create(HTTPRequest);
  InitResponse;
end;

procedure TISAPIResponse.InitResponse;
begin
  if FHTTPRequest.ProtocolVersion = '' then
    Version := '1.0';
  StatusCode := 200;
  LastModified := -1;
  Expires := -1;
  Date := -1;
  ContentType := 'text/html';
end;

function TISAPIResponse.GetContent: string;
begin
  Result := FContent;
end;

function TISAPIResponse.GetDateVariable(Index: Integer): TDateTime;
begin
  if (Index >= Low(FDateVariables)) and (Index <= High(FDateVariables)) then
    Result := FDateVariables[Index]
  else Result := 0.0;
end;

function TISAPIResponse.GetIntegerVariable(Index: Integer): Integer;
begin
  if (Index >= Low(FIntegerVariables)) and (Index <= High(FIntegerVariables)) then
    Result := FIntegerVariables[Index]
  else Result := -1;
end;

function TISAPIResponse.GetLogMessage: string;
begin
  Result := TISAPIRequest(HTTPRequest).ECB.lpszLogData;
end;

function TISAPIResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

function TISAPIResponse.GetStringVariable(Index: Integer): string;
begin
  if (Index >= Low(FStringVariables)) and (Index <= High(FStringVariables)) then
    Result := FStringVariables[Index];
end;

function TISAPIResponse.Sent: Boolean;
begin
  Result := FSent;
end;

procedure TISAPIResponse.SetContent(const Value: string);
begin
  FContent := Value;
  if ContentStream = nil then
    ContentLength := Length(FContent);
end;

procedure TISAPIResponse.SetDateVariable(Index: Integer; const Value: TDateTime);
begin
  if (Index >= Low(FDateVariables)) and (Index <= High(FDateVariables)) then
    if Value <> FDateVariables[Index] then
      FDateVariables[Index] := Value;
end;

procedure TISAPIResponse.SetIntegerVariable(Index: Integer; Value: Integer);
begin
  if (Index >= Low(FIntegerVariables)) and (Index <= High(FIntegerVariables)) then
    if Value <> FIntegerVariables[Index] then
      FIntegerVariables[Index] := Value;
end;

procedure TISAPIResponse.SetLogMessage(const Value: string);
begin
  StrPLCopy(TISAPIRequest(HTTPRequest).ECB.lpszLogData, Value, HSE_LOG_BUFFER_LEN - 1);
end;

{!! Strings not to be resourced !!}
procedure TISAPIResponse.SetStatusCode(Value: Integer);
begin
  if FStatusCode <> Value then
  begin
    FStatusCode := Value;
    ReasonString := StatusString(Value);
  end;
end;

procedure TISAPIResponse.SetStringVariable(Index: Integer; const Value: string);
begin
  if (Index >= Low(FStringVariables)) and (Index <= High(FStringVariables)) then
    FStringVariables[Index] := Value;
end;

procedure TISAPIResponse.SendResponse;
var
  StatusString: string;
  Headers: string;
  I: Integer;

  procedure AddHeaderItem(const Item, FormatStr: string);
  begin
    if Item <> '' then
      Headers := Headers + Format(FormatStr, [Item]);
  end;

begin
  if HTTPRequest.ProtocolVersion <> '' then
  begin
    if (ReasonString <> '') and (StatusCode > 0) then
      StatusString := Format('%d %s', [StatusCode, ReasonString])
    else StatusString := '200 OK';
    AddHeaderItem(Location, 'Location: %s'#13#10);
    AddHeaderItem(Allow, 'Allow: %s'#13#10);
    for I := 0 to Cookies.Count - 1 do
      AddHeaderItem(Cookies[I].HeaderValue, 'Set-Cookie: %s'#13#10);
    AddHeaderItem(DerivedFrom, 'Derived-From: %s'#13#10);
    if Expires > 0 then
      Headers := Headers +
        Format(FormatDateTime('"Expires: "' + sDateFormat + ' "GMT"'#13#10, Expires),
          [DayOfWeekStr(Expires), MonthStr(Expires)]);
    if LastModified > 0 then
      Headers := Headers +
        Format(FormatDateTime('"Last-Modified: "' + sDateFormat + ' "GMT"'#13#10,
          LastModified), [DayOfWeekStr(LastModified), MonthStr(LastModified)]);
    AddHeaderItem(Title, 'Title: %s'#13#10);
    AddHeaderItem(WWWAuthenticate, 'WWW-Authenticate: %s'#13#10);
    AddCustomHeaders(Headers);
    AddHeaderItem(ContentVersion, 'Content-Version: %s'#13#10);
    AddHeaderItem(ContentEncoding, 'Content-Encoding: %s'#13#10);
    AddHeaderItem(ContentType, 'Content-Type: %s'#13#10);
    if (Content <> '') or (ContentStream <> nil) then
      AddHeaderItem(IntToStr(ContentLength), 'Content-Length: %s'#13#10);
    Headers := Headers + 'Content:'#13#10#13#10;
    HTTPRequest.WriteHeaders(StatusCode, StatusString, Headers);
  end;
  if ContentStream = nil then
    HTTPRequest.WriteString(Content)
  else if ContentStream <> nil then
  begin
    SendStream(ContentStream);
    ContentStream := nil; // Drop the stream
  end;
  FSent := True;
end;

procedure TISAPIResponse.SendRedirect(const URI: string);
begin
  with TISAPIRequest(FHTTPRequest) do
    ECB.ServerSupportFunction(ECB.ConnID, HSE_REQ_SEND_URL_REDIRECT_RESP,
      PChar(URI), nil, nil);
  FSent := True;
end;

procedure TISAPIResponse.SendStream(AStream: TStream);
var
  Buffer: array[0..8191] of Byte;
  BytesToSend: Integer;
begin
  while AStream.Position < AStream.Size do
  begin
    BytesToSend := AStream.Read(Buffer, SizeOf(Buffer));
    FHTTPRequest.WriteClient(Buffer, BytesToSend);
  end;
end;

{ TAbstractContentParser }

class function TAbstractContentParser.CanParse(
  AWebRequest: TWebRequest): Boolean;
begin
  Result := False;
end;

constructor TAbstractContentParser.Create(AWebRequest: TWebRequest);
begin
  FWebRequest := AWebRequest;
  inherited Create;
end;

{ TContentParser }

class function TContentParser.CanParse(AWebRequest: TWebRequest): Boolean;
begin
  Result := True;
end;

function TContentParser.GetContentFields: TStrings;
begin
  if FContentFields = nil then
  begin
    FContentFields := TStringList.Create;
    WebRequest.ExtractContentFields(FContentFields);
  end;
  Result := FContentFields;
end;

type
  TEmptyRequestFiles = class(TAbstractWebRequestFiles)
  protected
    function GetCount: Integer; override;
    function GetItem(I: Integer): TAbstractWebRequestFile; override;
  end;

function TEmptyRequestFiles.GetCount: Integer;
begin
  Result := 0;
end;

function TEmptyRequestFiles.GetItem(I: Integer): TAbstractWebRequestFile;
begin
  Result := nil;
end;

function TContentParser.GetFiles: TAbstractWebRequestFiles;
begin
  Result := TEmptyRequestFiles.Create;
end;

initialization
  ContentParsers := TClassList.Create;
finalization
  ContentParsers.Free;
end.
