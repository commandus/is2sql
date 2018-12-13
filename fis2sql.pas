unit fis2sql;
(*##*)
(*******************************************************************
*                                                                 *
*   F  I  S  2  S  Q  L        ISAPI/NSAPI DLL database gateway    *
*                                                                 *
*   Copyright © 1999- 2001 Andrei Ivanov                           *
*   main unit, part of is2sql                                     *
*   See readme.txt, history.txt, license.txt and comments in dpr   *
*   before use of it                                              *
*                                                                  *
*  /s[how]?dbs&form[&huser&hkey]&user&key[&hash][&pwd]            *
*  [&forminvalid][&push][&[family.]first&[family.]last]            *
*  [[&family.]param=..][&cp=eccxlat]                              *
*  huser,hkey uses if secure mode enabled                          *
*  push- minimal delay interval                                   *
*                                                                  *
*                                                                 *
*  /r[ec]?dbs&user&key&qry[[&family.]param=..][content-type=]      *
*      [&fld][&rec][&decode=z][&cp=eccxlat]                       *
*      default record #0, field #0, no transliterate               *
*      read 1 field from one record. Query- qry                   *
*                                                                  *
*                                                                 *
*  /setup?key=xx[&mode=content|name&newkey&banner                  *
*     &patternpath&                                               *
*                         &show=[list]                             *
*     &optionrec&optionhtml                                       *
*     &seccname&eccxlat|eccxlatno                                  *
*   admin password required, "key" changes password. key=no       *
*     disable password. Default admin password: MASTERKEY (or empty*
*     show=list- produce simple list of changes                   *
*                                                                  *
*   /info?key=xx&show=[threads,copyright,list]                    *
*   fill form tags:BANNER,SCRIPT,PATTERNPATH,                      *
*   CACHECONNECTIONS,MAXTHREADS,ACTIVETHREADS,                    *
*   INACTIVETHREADS                                                *
*   QUERIES,ECCNAME,ECCXLAT                                       *
*                                                                  *
*                                                                 *
*   OPTMKNULL,OPTIONHTML,FIRSTNO,LASTNO,STATUS                     *
*                                                                 *
*   /setup?mknull=True|False|1|0|Истина|Ложь                       *
*                                                                 *
*   /reload?key=<administrator password>                           *
*   reload settings                                               *
*   Registry:                                                      *
*                                                                 *
*   LogDLL, LogFunc, LogStartFunc, LogFile-                        *
*     logging library, function and file                          *
*                                                                  *
*   PatternPath Banner                                            *
*   User Key                                                       *
*   NoCacheConnections MaxConnections                             *
*   Short|LongTimeFormat  Short|LongTimeFormat DecimalSeparator    *
*   MkNull xlatName eccFileName                                   *
*   OptimizeDoc SQLCollection                                      *
*   \Virtual Roots list of web server alias names (in addition to *
* \SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\Virtual Roots*
*   \DbAlias - list if database aliases-for Interbase             *
*   \ReconnectError list of error headers (requires re-logon)      *
*   \ResponseCustomHeader customized strings send to browser      *
*   for more information see readme.txt                            *
*   http://cgi-bin/is2sql.dll/show=  default                      *
*   Conditional defines: MKCGI USE_BDE|USE_IB|USE_NCOCI            *
*   Based on ldbndx, Sep 22 1998 revision                         *
*   First release: Jan 18 1999                                     *
*                                                                 *
*   Last Revision: Oct 09 2001                                     *
*                                                                 *
*                                                                  *
*   Regular SQL expression .par:  parameter=expression %s         *
*                                 parameter delimiter=AND          *
*                                                                 *
*   Lines        : 3565                                            *
*   History      :                                                *
*   Printed      : ---                                             *
*   History:  Mar 03 1999 quotes funcs re-make                    *
*             Mar 17 hash&pwd&forminvalid                          *
*             Jan 07 2000 IBExpress                               *
*             May 11 2000 /Variable registry key added             *
*             May 17 2000 NC OCI8 Library, V 0.6.1 Beta           *
*                         by Dmitry Arefiev, N-Novgorod, Russia    *
*                         http://www.ncom.ru/diman/, www.torry.ru *
*                                                                  *
*                                                                 *
********************************************************************)
(*##*)
{ please do not use directives here, use Project|Options}
// Oracle 8.x access. Requires files you can download from www.torry.ru for free
{$IFNDEF USE_BDE}
{$IFNDEF USE_IB}
{$IFNDEF USE_NCOCI}
 Select menu Project|Options|Directories/Conditionals|Conditional defines,
 define USE_BDE, USE_IB or USE_NCOCI
{$ENDIF}
{$ENDIF}
{$ENDIF}
interface

uses
  Windows, Messages, SysUtils, Classes, Registry, Forms, { TDataModule }
  HTTPApp, { TWebModule & TWebApplication (Delphi4 only)}
  Psock, ISAPI2, NMsmtp,
  util1, cpcoll, isutil1, htmlprod, isemail, utilISAPI, ZDownload
{$IFDEF VER130}
  ,webbroker { TWebApplication (Delphi5 only)}
{$ENDIF}
{$IFDEF VER140}
  ,HTTPProd, WebBroker
{$ENDIF}
{$IFDEF USE_BDE}
  ,Db, DBTables, SPPrsr
{$ENDIF}
{$IFDEF USE_IB}
  ,IBSQL, IBDatabase
{$ENDIF}
{$IFDEF USE_NCOCI}
 ,NCOci, NCOciWrapper, NCOciDB,
 Db, DBTables,  // declarations of Db.TField, DbTables.TBlobStream
 SPPrsr
{$ENDIF}
  ;
{$IFDEF USE_BDE}
type
  TDS = TDataSet;
  TEDatabase = dbtables.TDatabase;
  TEQuery = TQuery;
  TFLD = TField;
  TETransIsolation = TTransIsolation;
const
  DBPAR_USERNAME = 'USER NAME';
  DBPAR_PASSWORD = 'PASSWORD';
  DBPAR_ROLE     = '';  // reserved
  DBSQLTRACE = [tfQPrepare, tfQExecute, tfError, tfStmt, tfConnect, tfTransact, tfBlob, tfMisc, tfVendor, tfDataIn, tfDataOut];
{$ENDIF}
{$IFDEF USE_IB}
type
  TEDatabase = TIBDatabase;
  TEQuery = TIBSQL;
  TDS = TIBSQL;
  TFLD = TIBXSQLVAR;
const
  DBPAR_USERNAME = 'user_name';
  DBPAR_PASSWORD = 'password';
  DBPAR_ROLE     = 'sql_role_name';  // reserved
  DBPAR_CP       = 'lc_ctype';       // WIN1251 - cyrillic
{$ENDIF}
{$IFDEF USE_NCOCI}
type
  TDS = TOCIDataSet;
  TEDatabase = TOCIDatabase;
  TEQuery = TOCIQuery;
  TEStoredProc = TOCIStoredProc;
  TFld = TField;
  TETransIsolation = TOCITransactionMode;
{$ENDIF}
const
  MAXCONTENTLEN  = MAXINT div 2; { about 2Gb /2 Content length limit (POST chunks) }
  SHORTCOPYRIGHT = 'Andrey Ivanov, http://ensen.8m.com';
  DEFAULTBANNER = 'Powered by is2sql (c) 1999, 2000 '+SHORTCOPYRIGHT;
  SERRB = '<html><body><hr>';
  SERRE = '</body></html>';
  { defaul error icon. Error descripton in alt }
  DEFERRICON = '/icons/err.gif';
  ERRTAG1 = '<img src="';
  ERRTAG2 = '" width="16" height="16" alt="sql error ';
  ERRTAG3 = '">';
  { push constants }
  PUSHBOUNDARY = 'EnSeN_UsEfUl_UtIlItIeS';
  DEFPUSHINTERVAL = 5/(60*24); { 5 minutes }

  DEFAULTPASSWORD = 'CHANGE_ON_INSTALL';
  DEFAULTSQLCOLLECTION = 'sql.txt'; { looks in }

  DEFAULTDBS = '';
  DEFAULTUSER = '';
  DEFAULTKEY = '';

  DEFAULTHASHUNIQUEID = ';)';      { default key hash string prefix }

  DEFBLOBRESULTBUFSIZE = $10000;
  MAXRECORDSPERPAGE = MaxLongInt;  { show records per page no limit (default) }
  { page line constants }
  DEF_SHOWSTEP   = 10;
  DEF_MAXSTEPS   = 10;

  optMkNull      = 1;
  { PathsList string array index constants }
  fpScript            = 0; // .dll file name
  fpBanner            = 1; // usually copyright
  fpStatus            = 2; // status of last operation
  fpUser              = 3; // user name
  fpKey               = 4; // password
  fpPatternPath       = 5; // absolute default path of any html forms

  { reserved }
  fpTagPrefix         = 6; // default value '#'

  fpReserved         =  7; //
  {
  fp                  = 8; //
  fp                  = 9; //
  fp                  = 10;//
  }                    // convert codepages settings
  fpEccPath           = 11;// /search html form suffix
  fpUserList          = 12;// list of <option>user name
  fpHash              = 13;// Hash string
  fpPwd               = 14;// password for verify with hash string
  fpRootPwd           = 15;// administrator password (позволяет смотреть все пароли)
  fpSQLCollection     = 16;// sql collection file ['sql.txt']
  fpHashUniqueID      = 17; // hash key prefix default ';)'
  fpDbs               = 18; // default database alias
  fpCurrFamily        = 19; // current family set by <#t> and <#e> tags
  fpExpiresMinutes    = 20; // expiration time in minutes, default 0
  fpAccessDeniedDef   = 21; // url of file contains default 'Access denied form' (set by <#r> tag)
  fpDBConnectFailForm = 22; // url of file contains 'Access denied form' (set by <#r> tag)
  fpAccessDeniedForm  = 23; // url of file contains 'Access denied form' (set by <#r> tag)
  fpDoTransaction     = 24; // do (1) or not transaction (0)
  fpDbSQLTrace        = 25; // trace SQL - reserved
  fpContentType       = 26; // responce Content-Type, usually 'text/html'
  fpDbTransIsolation  = 27; // BDE: tiDirtyRead, tiReadCommitted, tiRepeatableRead
                            // OCI: tmDefault, tmReadWrite, tmSerializable, tmReadOnly, tmDiscrete
  fpLogDLL            = 28; // LogDLL
  fpLogFunc           = 29; // LogFunc
  fpLogStartFunc      = 30; // LogStartFunc
  fpLogFile           = 31; // LogFile
  fpErrorIcon         = 32; // error icon
  fpFormatDll         = 33; // current BLOB formatting DLL file name
  fpNullContent       = 34;
  fpLast              = 34;

  DEFDATABASEERRPREFIX= 'ORA-';     { oracle error number prefix}
  { default logging DLL, log function and initialize }
  DEFLOGDLL  = 'islog.dll';         { default dll name }
  DEFLOGFUNC = 'logfunc';           { default dll function name }
  DEFLOGSTARTFUNC = 'logstartfunc'; { default start logging function name }

type
  TWebModule1 = class(TDataModule)
    WebDispatcher0: TWebDispatcher;
    procedure WebModule1Create(Sender: TObject);
    procedure WebModule1Destroy(Sender: TObject);
    { actions }
    procedure WebModule1actShowAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1actInfoAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1actSetupAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    { tag's parsers }
    procedure PgProdTblHTMLTag(Sender: TObject; Tag: TTag;
      const TagString: String; TagParams: TStrings; var ReplaceText: String);
    procedure PgProdFldHTMLTag(Sender: TObject; Tag: TTag;
      const TagString: String; TagParams: TStrings; var ReplaceText: String);
    procedure PgProdInfoHTMLTag(Sender: TObject; Tag: TTag;
      const TagString: String; TagParams: TStrings;
      var ReplaceText: String);
    procedure PgProdMailTag(Sender: TObject; Tag: TTag;
      const TagString: String; TagParams: TStrings;
      var ReplaceText: String);
    procedure WebModuleBeforeDispatch(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleAfterDispatch(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure NMSMTP1SendStart(Sender: TObject);
    procedure WebModule1actReloadAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1actRecAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
  private
    { -1 - no hash 0 - hash string NOT verified 1 - hash verified  2- admin }
    Fhashed: Integer;
    FpushCount: Integer;      { push counter multipart/x-mixed-replace; boundary=EnSeN_UsEfUl_UtIlItIeS }
    FpushInterval: TDateTime; { push minimum interval }
    PgProdTbl: TEPageProducer;
    PgProdFld: TEPageProducer;
    FFormAccessDenied,
    FCurrencySimple,
    FReconnectDbForEachError: Boolean;
    { current request pointer }
    FCurRequest: TWebRequest;
    { log structure }
    FLogStruc: TLogStruc;
    FLogFuncs: TLogThread;
    { current formatting dll handle }
    FFuncFmtDllHandle: THandle; // TFuncFmtDll

    FMetas,
    FSql,        { current sql template, form, 1-2-3 table templates }
    FForm,
    FFormInvalid,
    FRespBegin,
    FRespBody,
    FRespElse,
    FRespEnd: String;

    { mail gateway }
    FMailBody: String;
    Fmailcharset: String[12];

    { page line looks like | 1-10 | 11-20 | }
    FPageLineStart,
    FPageLineInactive,
    FPageLineActive,
    FPageLineDelimiter,
    FPageLineFinish: String;
    FPageLineLimit,
    FDefPageLineStep: Integer;

    FOptimizeDoc,
    FValidateQuote,
    FRecordsQtyCountDone: Boolean; { true- records qty count done }
    FRecordsQty: Integer; { how much records selected at last query }
    FFirstShowNo, FLastShowNo, FPageLineStep: Integer;
    ecc, xlatname: String;
    xlat256: Pointer;
    xlat256_1: Txlat;
    options: TBS;        { set of byte for some purposes }
    FxlatDefs: PCPDefinitions;

    PathsList,           { list of settings, filled by LoadIni() }
    FFullContent,        { collect client POST's chunks. Use instead ContentFields }
    FxlatNames,          { codepage translitaration schemes list }
    FGlobalVar,          { list of default variable's values for sql parser }
    FRegularSql,         { regular expression rules, loaded from .PAR file }
    SLAdditionalDBAlias, { list of direct DB access (IB) aliasesm, not used in BDE }
    SLAlias,             { list of web server directory aliases }
    FReconnectErrorList, { list of DB fatal errors requires reconnect }
    FResponseCustomHeaders: TStringList;

    FDbErrorPrefix: String[32]; { default 'ORA-'- oracle error number prefix }

    function CreateWebModuleComponents: Boolean;
    function DestroyWebModuleComponents: Boolean;
    // validate is Content completely loaded.
    // If Content is too big, no way to load chunks here.
    function FullContent: TStrings;
    {read/write database connection parameters }
    function IsThreadDbConnected(const cdbs, ckey, cuser: String): Boolean;
    function GetDatabaseAliasName: String;
    procedure SetDatabaseAliasName(ADbAliasName: String);
    function GetUserName: String;
    procedure SetUserName(AValue: String);
    function GetUserPassword: String;
    procedure SetUserPassword(AValue: String);
    function GetDbTransIsolation: Integer;
    procedure SetDbTransIsolation(AValue: Integer);
    function GetExpires: TDateTime;
    function PrepareRegularSql(const AStr: String; ARegularExprList: TStrings): String;

    function MkPageLine: String;  // return string like 1-20 20-21...
    procedure SetXlatColl(AxlatFN, ANewCP: String);
    procedure CalcFirstLastRows(const AFamilyName: String; AFoundCount: Integer);
    function SetxlatByName(ANewCP: String): Boolean;
    function GetQueryFields: TStrings;
    function GetQueryField(const name: String): String;
    { заменяет специальные символы разметки html, как кавычки, знаки больше и меньше }
    function GetQueryFieldHtml(const name: String): String;
    function LoadSelect(const AFamily: String): Boolean;
    function LoadExec: Boolean;
    function ParseSqlPar(AQuery: TDS): Boolean;
    function CalcRecordsQty: Integer;
    function MkErrStringIcon(ADesc: String): String;
    function DoLoadedFamily(AQuery: TDS): String;
    function DoLoadedExec(AQuery: TDS): Boolean;
    function TagIPOption(TagString: String; Request: TWebRequest; OtherTags: TStrings): String;
    function TagSystemOption(TagString: String; OtherTags: TStrings): String;
    function ProcessDBError(E: Exception): Boolean;
    function LoadRecFldSelect(AFld: String; ARecNo: Integer; ADecode: String): String;
    // procedure SetSmth(ANewValue: Integer);
    procedure LoadReconnectErrorList;
    function IsAccessDenied(Tags: TStrings): Boolean;
    function ParseFamilyName(ATagParams: TStrings): String; { parse <#t name=a$PAR$> or <#t name=/a$PAR/family>}
    function FormatBlobByDLL(const Adll, AFunc, Aspecifier: String; AFld: TFld): String;
    function Alias2FileName(const AFn: String): String;
    property QFlds: TStrings read GetQueryFields;
    property QFld[const name: String]: String read GetQueryField;
    { преобразует параметр в вид для отображения в тегах html:
      СП "123" -> СП &quot;123&quot;  }
    property QFldHtml[const name: String]: String read GetQueryFieldHtml;
    property DbAliasName: String read GetDatabaseAliasName write SetDatabaseAliasName;
    { database connection user name }
    property DbUserName: String read GetUserName write SetUserName;
    { database connection user password }
    property DbUserPassword: String read GetUserPassword write SetUserPassword;
    property DbTransIsolation: Integer read GetDbTransIsolation write SetDbTransIsolation;
  public
    { Public declarations }
    NMSMTP0: TNMSMTP;
    Database0: TEDatabase;         // TDatabase, TIbDatabase, TOCIDatabase
    Query0: TEQuery;               // TQuery, TIBSQL, TOCIQuery
{$IFDEF USE_BDE}
    Session0: TSession;
    StoredProc0: TEStoredProc;     // TStoredProc, TOCIStoredProc
{$ENDIF}
{$IFDEF USE_IB}
    Transaction0: TIBTransaction;
{$ENDIF}
{$IFDEF USE_NCOCI}
    Transaction0: TOCITransactionManager; // TOCITransactionManager
    StoredProc0: TEStoredProc;     // TStoredProc, TOCIStoredProc
{$ENDIF}
    function LoadIni(AForceStore: Boolean): Boolean;
    function StoreIni: Boolean;
    function LoadForms: Boolean;
  end;

{ procedure fill up TMBillInfo structure
 current state }
procedure GetWebInfo(var AMBill: TMBillInfo); stdcall;

exports
  GetWebInfo index 1;

var
  WebModule1: TWebModule1;
  FQueryCount: Integer;

implementation

{$R *.DFM}

uses
  Versions, Account;

const
  PARAMETER_NAME_CHARSET_NODOLLAR = ['_', '0'..'9', 'A'..'Z', 'a'..'z']; // nop system parameters
  PARAMETER_NAME_CHARSET = ['$']+ PARAMETER_NAME_CHARSET_NODOLLAR;       // with system parameters
{
var
  CriticalSection: _RTL_CRITICAL_SECTION;
}

procedure GetWebInfo(var AMBill: TMBillInfo);
begin
  with AMBill do begin
    MaxConnections:= Application.MaxConnections;
    ActiveCount:= Application.ActiveCount;
    InActiveCount:= Application.InActiveCount;
    QueryCount:= FQueryCount;
  end;
end;

// get string repesent of BLOB or field of other kinds
{$IFDEF USE_IB}
function GetBlob(AFld: TFld): String;
begin
  try
    Result:= AFld.AsString;  // Interbase is simple
  except
    Result:= '';             // in some cases raise Interbase exception
  end;
end;
{$ELSE}
function GetBlob(AFld: TFld): String;
var
  BlobStream: TBlobStream;
  StringStream: TStringStream;
begin
  Result:= '';
  StringStream:= TStringStream.Create('');
  try
    if AFld.IsBlob then begin
      BlobStream:= TBlobStream.Create(AFld as TBlobField, bmRead);
      StringStream.CopyFrom(BlobStream, BlobStream.Size);
      Result:= StringStream.DataString;
      BlobStream.Free;
    end else begin
      SetLength(Result, AFld.DataSize);
      AFld.GetData(@Result[1]);
    end;
  finally
    StringStream.Free;
  end;
end;
{$ENDIF}

function TWebModule1.Alias2FileName(const AFn: String): String;
begin
  if Pos('..', AFn) > 0
  then Result:= '' // return nothing, no '../..'
  else Result:= util1.ConCatAliasPath(SLAlias, PathsList[fpPatternPath], AFn);
end;

function TWebModule1.GetExpires: TDateTime;
begin
  Result:= Now;
  util1.IncTime(Result, 0, StrToIntDef(PathsList[fpExpiresMinutes], 0));
end;

function TWebModule1.FormatBlobByDLL(const Adll, AFunc, Aspecifier: String; AFld: TFld): String;
var
  DllName,
  S: String;
  FmtFunc: TFuncFmtDll;
  Buf: String;
begin
  Result:= '';
  DllName:= ReplaceExt('dll', Alias2FileName(ADll));
  if not ((FFuncFmtDllHandle<>0) and (ANSICompareText(DllName, PathsList[fpFormatDll]) = 0)) then begin
    FFuncFmtDllHandle:= LoadLibrary(PChar(DllName));
  end;
  if FFuncFmtDllHandle = 0 then begin
    // PathsList[fpFormatDll]:= ''; // no matter
    Result:= Format('No %s found (%s)', [ADll, DllName]);
    Exit;
  end else begin
    PathsList[fpFormatDll]:= ADll; // keeping ADLL value is better than DllName
  end;
  // library loaded allready
  @FmtFunc:= GetProcAddress(FFuncFmtDllHandle, PChar(AFunc));
  if not Assigned(FmtFunc) then begin
    Result:= Format('No function %s found in %s(%s)', [AFunc, ADll, DllName]);
    Exit;
  end;
  SetLength(Buf, DEFBLOBRESULTBUFSIZE);
  S:= GetBlob(AFld);
  try
    if FmtFunc(PChar(S), PChar(Aspecifier), @(Buf[1]), Length(Buf)) then begin
      Result:= PChar(@(Buf[1]));
    end else begin
      Result:= Format('Fault "%s", function %s of %s', [PChar(@(Buf[1])), AFunc, ADll]);
    end;
  except
    on E: Exception do begin
      Result:= Format('Exception "%s", function %s of %s', [E.Message, AFunc, ADll]);
    end;
  end;
end;

function TWebModule1.IsThreadDbConnected(const cdbs, ckey, cuser: String): Boolean;
begin
  Result:= Database0.Connected
    and (DbAliasname = cdbs) and (DbUserName = cuser) and (DbUserPassword = ckey);
end;

procedure TWebModule1.SetDatabaseAliasName(ADbAliasName: String);
{$IFNDEF USE_BDE}
var
  p2: Integer;
  S: String;
{$ENDIF}
begin
{$IFDEF USE_BDE}
  Database0.AliasName:= ADbAliasName;
{$ENDIF}
{$IFDEF USE_IB}
  S:= SLAdditionalDBAlias.Values[ADbAliasName];
  p2:= Pos(',', S);
  if p2 = 0 then begin
    Database0.DatabaseName:= S;
    p2:= Database0.Params.IndexOfName(DBPAR_CP);
    if p2 >= 0
    then Database0.Params.Delete(p2);
  end else begin
    Database0.DatabaseName:= Copy(S, 1, p2-1);
    Database0.Params.Values[DBPAR_CP]:= Copy(S, p2+1, MaxInt);
  end;
  if Length(Database0.DatabaseName) = 0 then begin
    Database0.DatabaseName:= ADbAliasName; // as is
  end;
{$ENDIF}
{$IFDEF USE_NCOCI}
  S:= SLAdditionalDBAlias.Values[ADbAliasName];
  p2:= Pos(',', S);
  if p2 = 0
  then Database0.ServerName:= S
  else Database0.ServerName:= Copy(S, 1, p2-1);
  if Length(Database0.ServerName) = 0
  then Database0.ServerName:= ADbAliasName; // as is
{$ENDIF}
  FResponseCustomHeaders.Values['dbs']:= ADbAliasName;
end;

function TWebModule1.GetDatabaseAliasName: String;
{$IFNDEF USE_BDE}
var
  p, p2, ind: Integer;
  // FCollateCodePage: String;
{$ENDIF}
begin
{$IFDEF USE_BDE}
  Result:= Database0.AliasName;
{$ELSE}
  // <Database Alias>=<physical database file path>[,<collate codepage>]
  Result:= '';
  for ind:= 0 to SLAdditionalDBAlias.Count - 1 do begin
    p:= Pos('=', SLAdditionalDBAlias[ind]);
    if (p > 0) then begin
      // looking for code page
      p2:= PosFrom(p+1, ',', SLAdditionalDBAlias[ind]);
      // if codepage start sign "," not specified..
      if p2 <= 0 then p2:= Length(SLAdditionalDBAlias[ind])+1;
      // compare database file name with value specified in Database0 component
      if (ANSICompareText(Copy(SLAdditionalDBAlias[ind], p+1, p2-p-1), Database0.DatabaseName)=0) then begin
        Result:= Copy(SLAdditionalDBAlias[ind], 1, p-1);
        Exit;
      end;
    end;
  end;
{$ENDIF}
end;

function TWebModule1.GetUserName: String;
begin
{$IFDEF USE_NCOCI}
  Result:= Database0.UserName;
{$ELSE}
  Result:= Database0.Params.Values[DBPAR_USERNAME];
{$ENDIF}
end;

procedure TWebModule1.SetUserName(AValue: String);
begin
{$IFDEF USE_NCOCI}
  Database0.UserName:= AValue;
{$ELSE}
  Database0.Params.Values[DBPAR_USERNAME]:= AValue;
{$ENDIF}
  FResponseCustomHeaders.Values[AValue]:= '';
end;

function TWebModule1.GetUserPassword: String;
begin
{$IFDEF USE_NCOCI}
  Result:= Database0.Password;
{$ELSE}
  Result:= Database0.Params.Values[DBPAR_PASSWORD];
{$ENDIF}
end;

procedure TWebModule1.SetUserPassword(AValue: String);
begin
{$IFDEF USE_NCOCI}
  Database0.Password:= AValue;
{$ELSE}
  Database0.Params.Values[DBPAR_PASSWORD]:= AValue;
{$ENDIF}
end;

function TWebModule1.GetDbTransIsolation: Integer;
begin
{$IFDEF USE_IB}
  Result:= 0;
{$ELSE}
  Result:= Ord(Database0.TransIsolation);
{$ENDIF}
end;

procedure TWebModule1.SetDbTransIsolation(AValue: Integer);
begin
  try
{$IFDEF USE_IB}
{$ELSE}
    Database0.TransIsolation:= TETransIsolation(AValue);
{$ENDIF}
{$IFDEF USE_BDE}
    Database0.TransIsolation:= TETransIsolation(AValue);
{$ENDIF}
{$IFDEF USE_NCOCI}
    Transaction0.TransIsolation:= Database0.TransIsolation
{$ENDIF}
  except
  end;
end;

procedure TWebModule1.LoadReconnectErrorList;
var
  Rg: TRegistry;
  i: Integer;
  cnt: Integer;
begin
  if FReconnectErrorList <> Nil
  then FReconnectErrorList.Free;
  FReconnectErrorList:= TStringList.Create;
  Rg:= TRegistry.Create;
  Rg.RootKey:= HKEY_LOCAL_MACHINE;
  try
    Rg.OpenKeyReadOnly(RGPATH+'\ReconnectError');
  except
    Exit;
  end;
  try
    FReconnectDbForEachError:= Rg.ReadBool('Each');
  except
    FReconnectDbForEachError:= False;
  end;
  try
    FDbErrorPrefix:= Rg.ReadString('DbErrorPrefix');
  except
    FDbErrorPrefix:= DEFDATABASEERRPREFIX;
  end;
  try
    cnt:= Rg.ReadInteger('Count');
  except
    cnt:= 0;
  end;
  for i:= 1 to cnt do begin
    try
      FReconnectErrorList.Add(Rg.ReadString(IntToStr(i)));
    except
    end;
  end;
  Rg.Free;
end;

// ORA-01041
function TWebModule1.ProcessDBError(E: Exception): Boolean;
var
  i: Integer;
  S: String;
  ORAErr: String;
begin
  Result:= True;
  i:= Pos(FDbErrorPrefix, E.Message);
  if i > 0
  then OraErr:= Copy(E.Message, i, 255)
  else OraErr:= Copy(E.Message, 1, 255);
  util1.DeleteControlsStr(OraErr);
  if FReconnectDbForEachError then begin
    // закрыть в случае любой ошибки SQL, если Each=0x1
    Database0.Close;
  end else begin
    for i:= 0 to FReconnectErrorList.Count - 1 do begin
      S:= FReconnectErrorList[i];
      if (Length(S) > 0) and (Pos(S, OraErr) > 0) then begin
        // закрыть в случае обнаружения включенной в список ошибки
        Database0.Close;
        Break;
      end;
    end;
  end;
  // ошибку записать в журнал
  FLogStruc.lst:= FLogStruc.lst + ' SQL: ' + ORAErr+' ('+PathsList[fpCurrFamily]+')';
end;

{ }
function TWebModule1.FullContent: TStrings;
var
  Bytes2Read: Integer;
  S: String;
begin
  with WebDispatcher0.Request do begin
    Bytes2Read:= ContentLength - Length(Content);
    if Bytes2Read > 0 then begin
      if Assigned(FFullContent) then begin
        Result:= FFullContent;
      end else begin
        if Bytes2Read > MAXCONTENTLEN then begin
          Result:= ContentFields;
          FLogStruc.lst:= Format('client''s content len: %d too long', [ContentLength]);
          LogStamp(FLogStruc, logstampDT);
          if Assigned (FLogFuncs.LogFunc)
          then FLogFuncs.LogFunc(FLogStruc);
        end else begin
          FFullContent:= TStringList.Create;
          SetLength(S, ContentLength);
          S:= Content;
          if not ReadStringSmallPortions(WebDispatcher0.Request, S) then begin
            FLogStruc.lst:= Format('Read chunked client content len: %d fault', [ContentLength]);
            LogStamp(FLogStruc, logstampDT);
            if Assigned (FLogFuncs.LogFunc)
            then FLogFuncs.LogFunc(FLogStruc);
          end;
          FFullContent.Text:= S;
          Result:= FFullContent;
        end;
      end;
    end else Result:= ContentFields;
  end;
end;

{ property QFlds используйте вместо QueryFields (для GET)
  и ContentFields (для POST)
}
function TWebModule1.GetQueryFields: TStrings;
begin
  with WebDispatcher0.Request do begin
    if MethodType = mtPost then begin
      Result:= FullContent;
    end else Result:= QueryFields;
    if FValidateQuote then begin
      // проверить параметры формы- если есть строки без кавычек, поставить их
     // не надо! ValidateQuoteStringValues(Result);
    end;
    { character entity in parameter?!! }
    // Result.Text:= WEBStyleAndControlString2ASCII(Result.Text);
  end;
end;

function TWebModule1.GetQueryField(const name: String): String;
var
  is_plus_sign: Boolean;
  QryFlds: TStrings;
  S: String;
  ind, n: Integer;
begin
  QryFlds:= GetQueryFields;
  n:= 0;
  ind:= NextValue(n, name, QryFlds, S);
  if (ind < 0) then begin
    // if nothing, try load variable from global variable pool
    Result:= FGlobalVar.Values[name];
    // если параметра нет или он пустой, вставить значение NULL
    if (Result = '') and (optMkNull in Options)
    then Result:= 'NULL';
  end else begin
    { if RemoveQuotes then ValidateQuotedStringValue(S); }
    { '...+' or '...\+' }
    is_plus_sign:= ValidateConcatenate(S);
    Result:= S;
    while True do begin
      Inc(n);
      ind:= NextValue(n, name, QryFlds, S);
      if ind >= 0 then begin
        { if RemoveQuotes then ValidateQuotedStringValue(S);  }
        if is_plus_sign
        then Result:= Result + S
        else Result:= Result + ', ' + S;
      end else Break;
    end;
  end;
end;

{ заменяет специальные символы разметки html, как кавычки, знаки больше и меньше
  " -> &quot; > -> &gt;
}
function TWebModule1.GetQueryFieldHtml(const name: String): String;
begin
  Result:= ASCII2HTML(GetQueryField(name));
end;

{ загружает настройки из реестра }
function TWebModule1.LoadIni(AForceStore: Boolean): Boolean;
var
  FN: array[0..MAX_PATH- 1] of Char;
  S: String;
  Rg: TRegistry;
  FOSVersionInfo: TOSVersionInfo;

function RgPar(ParamName, DefaultValue: String): String;
var
  S: String;
begin
  try
    S:= Rg.ReadString(ParamName);
  except
  end;
  if S = ''
  then RgPar:= DefaultValue
  else RgPar:= S;
end;

procedure AddPar(ParamName, DefaultValue: String);
begin
  PathsList.Add(RgPar(ParamName, DefaultValue));
end;

{ удаляет запятую из реестра типа: /,=c:\web\ }
procedure ValidateW3SvcColon(AVirtualRoots: TStringList);
var
  i, L: Integer;
  S: String;
begin
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
  then AVirtualRoots.Add('='+PathsList[fpPatternPath]);
  // set default "root" directory
  if AVirtualRoots.Values['/'] = ''
  then AVirtualRoots.Add('/='+PathsList[fpPatternPath]);
end;

begin
  Result:= False;
  try
    Rg:= TRegistry.Create;
    Rg.RootKey:= HKEY_LOCAL_MACHINE;
    if AForceStore then begin
      Rg.OpenKey(RGPATH, True);
    end else begin
      { get version }
      FOSVersionInfo.dwOSVersionInfoSize:= SizeOf(FOSVersionInfo);
      GetVersionEx(FOSVersionInfo);
      Rg.OpenKeyReadOnly(RGPATH);
    end;
  except
    Exit;
  end;
  // fill up list of files
  PathsList.Clear;
  // Lists aren't so long, no sort
  // SLAlias.Sorted:= True;             { True- for speed up web alias search on long list }
  // SLAdditionalDBAlias.Sorted:= True; { True- for speed up database alias search on long list }

  SetString(S, FN, GetModuleFileName(hInstance, FN, SizeOf(FN)));
  // fpSCRIPT (0) Script name используется для ссылок в HTML
  PathsList.Add(S);
  // copyright (1)
  AddPar('Banner', DEFAULTBANNER);
  // status (2)
  PathsList.Add('');
  // fpUser user name (3)
  AddPar('User', DEFAULTUSER);
  // fpKey password key (4)
  AddPar('Key', DEFAULTKEY);
  // fpPatternPath (5), if not specified or wrong folder - is2sql.DLL location
  AddPar('PatternPath', ExtractFilePath(PathsList[fpSCRIPT]));

  { read list of errors like LOSS CONNECTION TO DATABASE }
  LoadReconnectErrorList;
  { прочитать алиасы web сервера }
  { HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\Virtual Roots }
  SLAlias.Clear;
  AddEntireKey(RGW2SVCALIAS, SLAlias);
  AddEntireKey(RGPATH+'\Virtual Roots', SLAlias);
  ValidateW3SvcColon(SLAlias);

  SLAdditionalDBAlias.Clear;
  AddEntireKey(RGPATH+'\DbAlias', SLAdditionalDBAlias);  // not used in BDE

  // fpTagPrefix (6)
  AddPar('TagPrefix', '#'); // fpTagPrefix
  PgProdTbl.TagPrefix:= PathsList[fpTagPrefix];
  PgProdFld.TagPrefix:= PathsList[fpTagPrefix];

  // fpReserved (7)
  PathsList.Add('');  //
  // reserved (8, 9, 10)
  PathsList.Add('');  //
  PathsList.Add('');  //
  PathsList.Add('');  //

  // fpEccPath (11)
  AddPar('eccFileName', 'usr.epc');
  // fpUserList (12)
  PathsList.Add('<option>Homer');
  // fpHash (13)
  PathsList.Add('hash');
  // fpPwd (14)
  PathsList.Add('pwd');
  // fpRootPwd (15)
  AddPar('RootPwd', DEFAULTPASSWORD);
  // fpSQLCollection (16)
  AddPar('SQLCollection', DEFAULTSQLCOLLECTION);
  // fpHashUniqueID (17)
  AddPar('HashUniqueID', '');
  // unique hash string must contain non-empty string anyway
  if Length(PathsList[fpHashUniqueID]) = 0
  then PathsList[fpHashUniqueID]:= DEFAULTHASHUNIQUEID;
  // fpDbs (18)
  AddPar('Dbs', DEFAULTDBS);
  // fpCurrFamily (19)
  PathsList.Add('');       { fixed value }
  // fpExpiresMinutes (20) expiration time in minutes
  AddPar('ExpiresMinutes', '0');
  // fpAccessDeniedDef (21) url of file contains default 'Access denied form' (set by <#r ..form=>)
  AddPar('AccessDeniedForm', '');
  // fpDBConnectFailForm (22) url of file contains 'Access denied form' (set by forminvalid parameter)
  AddPar('DBConnectFailForm', '');
  // fpAccessDeniedForm (23) url of file contains current 'Access denied form' (set by <#r ..form=>)
  PathsList.Add('');
  // fpDoTransaction (24)
  AddPar('DoTransaction', '1');
{$IFNDEF USE_BDE}
//  PathsList[fpDoTransaction]:= '1'; // for sql servers
{$ENDIF}

  // fpDbSQLTrace (25)      - reserved, never used
  AddPar('DbSQLTrace', '0');
  // fpContentType (26)     - usually text/html
  AddPar('Content-Type', 'text/html');
  // fpDbTransIsolation (27)- // BDE and OCI transisolation
  AddPar('DbTransIsolation', '');
  if Util1.isDecimal(PathsList[fpDbTransIsolation])
  then DbTransIsolation:= StrToIntDef(PathsList[fpDbTransIsolation], 0);

  PathsList[fpSQLCollection]:= Alias2FileName(PathsList[fpSQLCollection]);
  if not SetFileCollection(PathsList[fpSQLCollection])
  then PathsList[fpSQLCollection]:= '';
  { журнал активности }
  // fpLogDLL (28)
  AddPar('LogDLL', DEFLOGDLL);
  // fpLogFunc (29)
  AddPar('LogFunc', DEFLOGFUNC);
  // fpLogStartFunc (30)
  AddPar('LogStartFunc', DEFLOGSTARTFUNC);
  // fpLogFile (31)
  AddPar('LogFile', '');
  { error icon }
  // fpErrorIcon (32)
  AddPar('ErrorIcon', DEFERRICON);
  // fpFormatDll (33)
  AddPar('', '');
  // fpNullContent (34)
  AddPar('NullContent', '');
  // xlat
  Ecc:= Alias2FileName(PathsList[fpEccPath]);
  SetXlatColl(Ecc, '0');
  // xlatName
  S:= RgPar('xlatName', '');
  if S <> '' then begin
    SetxlatByName(S);  // xlatIndex = 0 default
  end;
  // Options
  Options:= [];
  try
    if Rg.ReadBool('MkNull')
    then Options:= Options + [optMkNull];
  except
  end;
  {
  try
    if Rg.ReadBool('Option2')
    then Options:= Options + [2];
  except
  end;
  }
  try
    S:= '';
    S:= Rg.ReadString('LongDateFormat');
  except
  end;
  if S <> '' then begin
    LongDateFormat:= S;
  end;

  try
    S:= '';
    S:= Rg.ReadString('ShortDateFormat');
  except
  end;
  if S <> '' then begin
    ShortDateFormat:= S;
  end;

  try
    S:= '';
    S:= Rg.ReadString('LongTimeFormat');
  except
  end;
  if S <> '' then begin
    LongTimeFormat:= S;
  end;

  try
    S:= '';
    S:= Rg.ReadString('ShortTimeFormat');
  except
  end;
  if S <> '' then begin
    ShortTimeFormat:= S;
  end;

  try
    S:= '';
    S:= Rg.ReadString('DecimalSeparator');
  except
  end;
  if Length(S) >= 1 then begin
    DecimalSeparator:= S[1];
  end;

  try
    FCurrencySimple:= Rg.ReadBool('CurrencySimple');
  except
  end;

  try
    Application.CacheConnections:= not Rg.ReadBool('NoCacheConnections');
  except
  end;

  try
    Application.MaxConnections:= Rg.ReadInteger('MaxConnections');
  except
  end;

  try
    FValidateQuote:= Rg.ReadBool('ValidateQuoteChar');
  except
    FValidateQuote:= False;
  end;
  { оптимизация - замена двух и более повторяющихся управляющих символов на 1 пробел }
  try
    FOptimizeDoc:= Rg.ReadBool('OptimizeDoc');
  except
    FOptimizeDoc:= False;
  end;

  { page line settings }
  { FPageLineInactive }
  S:= RgPar('PageLineInactive', '');
  if S = ''
  then FPageLineInactive:= '<a href="%s">%d-%d</a>'
  else FPageLineInactive:= S;
  { FPageLineActive }
  S:= RgPar('PageLineActive', '');
  if S = ''
  then FPageLineActive:= '<input type=hidden value="%s">%d-%d</a>'
  else FPageLineActive:= S;
  { FPageLineStart }
  S:= RgPar('PageLineStart', '');
  if S = ''
  then FPageLineStart:= '<p>'
  else FPageLineStart:= S;
  { FPageLineDelimiter }
  S:= RgPar('PageLineDelimiter', '');
  if S = ''
  then FPageLineDelimiter:= ' | '
  else FPageLineDelimiter:= S;
  { PageLineFinish }
  S:= RgPar('PageLineFinish', '');
  if S = ''
  then FPageLineFinish:= '</p>'
  else FPageLineFinish:= S;
  { FDefPageLineStep }
  try
    FDefPageLineStep:= Rg.ReadInteger('PageLineStep');
  except
    FDefPageLineStep:= DEF_SHOWSTEP;
  end;
  if FDefPageLineStep < 1
  then FDefPageLineStep:= DEF_MAXSTEPS;
  { FPageLineLimit }
  try
    FPageLineLimit:= Rg.ReadInteger('PageLineLimit');
  except
    FPageLineLimit:= DEF_MAXSTEPS;
  end;
  if FPageLineLimit <= 3
  then FPageLineLimit:= DEF_MAXSTEPS;

  { FResponseCustomHeaders }
  FResponseCustomHeaders.Clear;
  AddEntireKey(RGPATH+'\ResponseCustomHeader', FResponseCustomHeaders);
  { add global variable list }
  AddEntireKey(RGPATH+'\Variables', FGlobalVar);
  { хост...алиас,имя,парольБД,форма,семейство,действие }
  if isutil1.StartLog(FLogStruc, PathsList[fpScript], PathsList[fpLogDLL],
    PathsList[fpLogFunc], PathsList[fpLogStartFunc], PathsList[fpLogFile], @FLogFuncs) then begin
  end;
  Rg.Free;
  Result:= True;
end; { LoadIni }

function TWebModule1.StoreIni: Boolean;
var
  Rg: TRegistry;
begin
  Result:= False;
  Rg:= TRegistry.Create;
  Rg.RootKey:= HKEY_LOCAL_MACHINE;
  Rg.OpenKey(RGPATH, True);
  try
    // registry keeps contents or file name
    Rg.WriteString('DLLName', PathsList[fpScript]);
    // store file names
    Rg.WriteString('PageLineActive', FPageLineActive);
    Rg.WriteString('PageLineInactive', FPageLineInactive);
    Rg.WriteString('PageLineStart', FPageLineStart);
    Rg.WriteString('PageLineDelimiter', FPageLineDelimiter);
    Rg.WriteString('PageLineFinish', FPageLineFinish);
    Rg.WriteInteger('PageLineStep', FDefPageLineStep);
    Rg.WriteInteger('PageLineLimit', FPageLineLimit);
    Result:= True;
  except
  end;
  Rg.Free;
end; { StoreIni }

function TWebModule1.LoadForms: Boolean;
begin
  LoadForms:= True;
  // cashe forms from template directory
end;

function TWebModule1.CreateWebModuleComponents: Boolean;
begin
  // WebDispatcher0:= TWebDispatcher.Create(WebModule1);
  { Do not call the constructor for TCustomWebDispatcher. Web applications automatically include a Web module. If the Web module is replaced by another data model, the Web dispatcher should be added to the new data module at design time. Objects placed at design time are created automatically. If an application tries to create a dispatcher object in a Web module, or in a data module that already has a Web dispatcher, an exception is raised.}
  with WebDispatcher0 do begin
    BeforeDispatch:= WebModuleBeforeDispatch;
    AfterDispatch:= WebModuleAfterDispatch;
    Actions.Add.PathInfo:= '/show';
    Actions[0].Default:= True;
    Actions[0].OnAction:= WebModule1actShowAction;
    Actions.Add.PathInfo:= '/s';
    Actions[1].OnAction:= Actions[0].OnAction;

    Actions.Add.PathInfo:= '/rec';
    Actions[2].OnAction:= WebModule1actRecAction;
    Actions.Add.PathInfo:= '/r';
    Actions[3].OnAction:= Actions[2].OnAction;

    Actions.Add.PathInfo:= '/info';
    Actions[4].OnAction:= WebModule1actInfoAction;
    Actions.Add.PathInfo:= '/setup';
    Actions[5].OnAction:= WebModule1actSetupAction;
    Actions.Add.PathInfo:= '/reload';
    Actions[6].OnAction:= WebModule1actReloadAction;
  end;
  NMSMTP0:= TNMSMTP.Create(WebModule1);
{$IFDEF USE_BDE}
  Session0:= TSession.Create(WebModule1);
  with Session0 do begin
    AutoSessionName:= True;   // AutoSessionName:= False; SessionName:= 'Session1_1';
    KeepConnections:= True;
    Active:= True;
  end;

  Database0:= TDatabase.Create(WebModule1);
  with Database0 do begin
    DatabaseName:= 'db_mts';
    SessionName:= Session0.SessionName;
    HandleShared:= True;
    LoginPrompt:= False;
  end;

  Query0:= TEQuery.Create(WebModule1);
  with Query0 do begin
    CachedUpdates:= False;
    DatabaseName:= Database0.DatabaseName;
    SessionName:= Session0.SessionName;
  end;

  StoredProc0:= TEStoredProc.Create(WebModule1);
  with StoredProc0 do begin
    CachedUpdates:= False;
    DatabaseName:= Database0.DatabaseName;
    SessionName:= Session0.SessionName;
    ParamBindMode:= pbByNumber; // pbByName - default, pbByNumber
  end;
{$ENDIF}
{$IFDEF USE_IB}
  Transaction0:= TIBTransaction.Create(WebModule1);
  Database0:= TIBDatabase.Create(WebModule1);
  with Transaction0 do begin
    IdleTimer:= 0; // default- no time out. in seconds?
    DefaultDatabase:= Database0;
  end;
  with Database0 do begin
    // IdleTimer:= 0; SQLDialect:= 1;
    DefaultTransaction:= Transaction0;
    LoginPrompt:= False;
  end;

  Query0:= TIBSQL.Create(WebModule1);
  with Query0 do begin
    // GoToFirstRecord:= True;
    // ParamCheck:= True;
    Database:= Database0;
    Transaction:= Transaction0;
  end;
{$ENDIF}
{$IFDEF USE_NCOCI}
  Database0:= TOCIDatabase.Create(WebModule1);
  Transaction0:= TOCITransactionManager.Create(WebModule1);
  with Database0 do begin
    DatabaseName:= 'db_mts';
    LoginPrompt:= False;
  end;
  Transaction0.DatabaseName:= Database0.DatabaseName;

  Query0:= TOCIQuery.Create(WebModule1);
  with Query0 do begin
    DatabaseName:= Database0.DatabaseName;
    TransactionManager:= Transaction0;
  end;

  StoredProc0:= TOCIStoredProc.Create(WebModule1);
  with StoredProc0 do begin
    DatabaseName:= Database0.DatabaseName;
    TransactionManager:= Transaction0;
  end;
{$ENDIF}
  { two page producers - table and field }
  PgProdTbl:= TEPageProducer.Create(Self);
  PgProdTbl.OnHTMLTag:= PgProdTblHTMLTag;
  PgProdFld:= TEPageProducer.Create(Self);
  PgProdFld.OnHTMLTag:= PgProdFldHTMLTag;
  // allow collect store old values (PgProdFld.OldValue)
  PgProdFld.EnableCollectOldValues:= True;
  Result:= True;
end;

function TWebModule1.DestroyWebModuleComponents: Boolean;
begin
{$IFDEF USE_BDE}
  StoredProc0.Free;
  Query0.Free;
  Database0.Free;
  Session0.Free;
{$ENDIF}
{$IFDEF USE_IB}
  Query0.Free;
  Transaction0.Free;
  Database0.Free;
{$ENDIF}
{$IFDEF USE_NCOCI}
  StoredProc0.Free;
  Query0.Free;
  Database0.Free;
  Transaction0.Free;
{$ENDIF}
  NMSMTP0.Free;
  Result:= True;
end;

procedure TWebModule1.WebModule1Create(Sender: TObject);
var
  i: Integer;
begin
  FFullContent:= Nil;
  CreateWebModuleComponents;
  LogStamp(FLogStruc, logstampT0);
  {}
  FReconnectErrorList:= Nil;
  { список алиасов web сервера }
  SLAlias:= TStringList.Create;
  SLAdditionalDBAlias:= TStringList.Create;
  FResponseCustomHeaders:= TStringList.Create;
  xlat256:= Nil;
  FxlatDefs:= Nil;
  FxlatNames:= TStringList.Create;
  PathsList:= TStringList.Create;
  FGlobalVar:= TStringList.Create;
  FRegularSql:= TStringList.Create;
  FFuncFmtDllHandle:= 0;
  if LoadIni(False) then begin // заполняет FLogStruc
    if LoadForms then begin
    end else begin
      PathsList[fpStatus]:= 'Loading forms with errors';
      FLogStruc.lst:= PathsList[fpStatus];
    end;
  end else begin
    for i:= PathsList.Count to fpLast + 1
    do PathsList.Add('');

    PathsList[fpStatus]:= 'Loading parameters from registry with errors';
    FLogStruc.lst:= PathsList[fpStatus];
  end;
  { отметить старт (заполняется из LoadIni) }
  LogStamp(FLogStruc, logstampDT);
  { и записать его в журнал }
  if Assigned(FLogFuncs.LogFunc)
  then FLogFuncs.LogFunc(FLogStruc);
end;

procedure TWebModule1.WebModule1Destroy(Sender: TObject);
begin
  { FFullContent collects POST chunks, freezes in ..After.. }
  // if FFullContent <> Nil then FFullContent.Free;
  try
{$IFDEF USE_IB}
    if Database0.Connected then with Transaction0 do begin
      Active:= True;
      with Database0 do if InTransaction then begin
        Commit;
      end;
    end;
{$ELSE}
    if Database0.InTransaction
    then Database0.Commit;
{$ENDIF}
{$IFDEF USE_NCOCI}
    Transaction0.CommitAll;
{$ENDIF}
  except
  end;
  LogStamp(FLogStruc, logstampT0);
  FRegularSql.Free;
  FGlobalVar.Free;
  PathsList.Free;
  { free up buffers }
  LoadEcc('', False, FxlatDefs, FxlatNames);
  FxlatNames.Free;
  PgProdFld.Free;
  PgProdTbl.Free;

  FLogStruc.lst:= 'stop'#9;
  LogStamp(FLogStruc, logstampDT);
  if Assigned(FLogFuncs.LogFunc) then begin
    FLogFuncs.LogFunc(FLogStruc);
    StopLog(@FLogFuncs);
  end;

  FResponseCustomHeaders.Free;
  SLAdditionalDBAlias.Free;
  SLAlias.Free;
  FReconnectErrorList.Free;
  FReconnectErrorList:= Nil;
  DestroyWebModuleComponents;
end;

{ /setup?key=<Administrator password>&...: setup parameters
  newkey
  banner
  PatternPath
  MkNull=<BOOL>
  MaxThreads=<maximum number of threads>
  CacheConnections=<BOOL> <
     BOOL:= 1,0 Yes,No Checked, True,False
}
procedure TWebModule1.WebModule1actSetupAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  S: String;
  i: Integer;
begin
  Handled:= True;
  S:= QFld['key'];
  if (PathsList[fpKey] <> '') and (S <> PathsList[fpKey]) then begin
    Response.Content:= Format(SERRB+'Invalid administrator password'+SERRE, [s]);
    FLogStruc.lst:= FLogStruc.lst + 'setup invalid password'#9;
  end else begin
    // change password if required
    if QFlds.IndexOfName('newkey') >= 0 then begin
      PathsList[fpKey]:= QFld['new'];
    end;
    S:= QFld['banner'];
    if S <> ''
    then PathsList[fpBanner]:= S;
    S:= QFld['PatternPath'];
    if S <> '' then begin
      PathsList[fpPatternPath]:= S;
    end;
    S:= QFld['MkNull'];
    if S <> '' then begin
      if Upcase(S[1]) in ['1', 'T', 'C', 'И']
      then Options:= Options+[optMkNull]
      else Options:= Options-[optMkNull];
    end;

    S:= QFld['MaxThreads'];
    i:= StrToIntDef(S, 0);
    if i > 0 then begin
      Application.MaxConnections:= i;
    end;

    S:= QFld['CacheConnections'];
    if S <> '' then begin
      if Upcase(S[1]) in ['1', 'T', 'C', 'И']
      then Application.CacheConnections:= True
      else Application.CacheConnections:= False;
    end; //  else Application.CacheConnections:= False;

    if StoreIni then begin;     // save settings
      PathsList[fpStatus]:= 'Changes made, ';
      if LoadForms then begin;  // take effects
        PathsList[fpStatus]:= PathsList[fpStatus] + 'OK';
      end else begin
        PathsList[fpStatus]:= PathsList[fpStatus] + 'some files not loaded';
      end;
      FLogStruc.lst:= FLogStruc.lst + 'setup store new values in registry'#9;
    end else begin
      PathsList[fpStatus]:= 'insufficient rights to save setup';
      FLogStruc.lst:= FLogStruc.lst + PathsList[fpStatus] + #9;
    end;
    Response.Content := Format(SERRB+'%s<p>'+
      '<p>'+PathsList[fpBanner]+'</p>'+
      '<p><H2>Today '+DateTimeToStr(Now) + '</H2></p>'+
      '<p><H3>Threads</H3></p><table>'+
      '<tr><td>max:</td><td>'+IntToStr(Application.MaxConnections)+'</td></tr>'+
      '<tr><td>active:</td><td>'+IntToStr(Application.ActiveCount)+'</td></tr>'+
      '<tr><td>inactive:</td><td>'+IntToStr(Application.InActiveCount)+'</td></tr>'+
      '<tr><td>cache connections on:</td><td>'+BoolToStr1(Application.CacheConnections)+'</td></tr>'+
      '<tr><td>queries:</td><td>'+IntToStr(FQueryCount)+'</td></tr>'+
      '</table><hr>'+SERRE, [PathsList[fpStatus]])
  end;
end;

{   вызывается из
    вызывает SetxlatByName(ANewCP: String): Boolean;
}
procedure TWebModule1.SetXlatColl(AxlatFN, ANewCP: String);
begin
  xlat256:= Nil;
  // LoadEcc reallocate FxlatDefs memory and clear FxlatNames if fails
  if LoadEcc(AxlatFN, False, FxlatDefs, FxlatNames) <= 0
  then Exit;
  SetXlatByName('0');
end;

{ установить xlat по ее имени (или по номеру ["0"])
  вызывается из SetXlatColl
}
function TWebModule1.SetxlatByName(ANewCP: String): Boolean;
var
  ind: Integer;
begin
  SetxlatByName:= False;
  if (FxlatNames = Nil) or (FxlatNames.Count <=0)
  then Exit;
  ind:= FxlatNames.IndexOf(ANewCP);
  if ind = -1 then begin
    // try convert to integer
    ind:= StrToIntDef(ANewCP, -1);
    // validate index range
    if ind >= FxlatNames.Count
    then ind:= -1;
  end;
  if ind >= 0 then begin
    xlat256:= @(FxlatDefs^[ind].xlat);
    XlatInverse(xlat256, @xlat256_1);
    xlatname:= FxlatNames.Names[ind];
    SetxlatByName:= True;
  end;
end;

{ вычисляет FFirstShowNo и FLastShowNo, определеяет FPageLineStep.
}
procedure TWebModule1.CalcFirstLastRows(const AFamilyName: String; AFoundCount: Integer);
var
  familyName: String;
  fs: String;
begin
  familyName:= util1.ExtractUnixDosFileName(PathsList[fpCurrFamily]) + '.';
  { first }
  fs:= familyName+'first';
  if QFld[fs] <> ''
  then FFirstShowNo:= StrToIntDef(QFld[fs], 1)
  else FFirstShowNo:= StrToIntDef(QFld['first'], 1);
  { step }
  fs:= familyName+'step';
  if QFld[fs] <> ''
  then FPageLineStep:= StrToIntDef(QFld[fs], FDefPageLineStep)
  else FPageLineStep:= StrToIntDef(QFld['step'], FDefPageLineStep);
  if FPageLineStep = 0
  then FPageLineStep:= MaxInt;
  { last }
  fs:= familyName+'last';
  if QFld[fs] <> ''
  then FLastShowNo:= StrToIntDef(QFld[fs], 0)
  else begin
    if QFld['last'] <> ''
    then FLastShowNo:= StrToIntDef(QFld['last'], 0)
    else begin
      if (QFld['step'] <> '') or (QFld[familyName+'step'] <> '')
      then FLastShowNo:= FPageLineStep
      else FLastShowNo:= 0;
    end;
  end;

  { validate first&last }
  if AFoundCount > 0 then begin { если число записей подсчитано }
    if FLastShowNo = 0          { последний номер по умолчанию  }
    then FLastShowNo:= AFoundCount;
    if FLastShowNo < FFirstShowNo
    then FLastShowNo:= FFirstShowNo;
    if FLastShowNo > AFoundCount
    then FLastShowNo:= AFoundCount;
  end else begin
    // FLastShowNo:= FFirstShowNo; 0
  end;
  { user specify 1.., start from 0 }
  Dec(FLastShowNo);
  if FLastShowNo < 0
  then FLastShowNo:= 0;
  Dec(FFirstShowNo);
end;

{ /show?dbs&form&user&key[&first&last][&table.param=..][&cp=eccxlat]
  показывает таблицу(ы)
}
procedure TWebModule1.WebModule1actShowAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  i: Integer;
  s, cdbs, cuser, ckey: String;
  cvrt: Boolean;

procedure LoadFormInvalid;
var
  s: String;
begin
  FFormInvalid:= '';
  s:= QFld['forminvalid']; { database connection failure form url specified in parameter }
  if Length(s) > 0 then begin
  { if smth is specified, try to load it }
    try
      s:= LoadCacheString(Alias2FileName(s));
    except
    end;
  end;
  { if no (name specified or load error), get default from registry }
  if Length(s) <= 0 then begin
    s:= PathsList[fpDBConnectFailForm];
    try
      s:= LoadCacheString(Alias2FileName(s));
    except
    end;
  end;
  { include information about why access denied cause has been performed in <#metas> tag }
  while util1.ReplaceStr(S, False, '<#metas>', PathsList[fpStatus]) do;
  FFormInvalid:= S;
end;

begin
  Fmetas:= '<META NAME="Generator" CONTENT="' +  DEFAULTBANNER + '">'#13#10 +
    '<META NAME="Request" CONTENT="' +
    ASCII2HTML(QFlds.CommaText) + '">'#13#10;
  Fmetas:= FMetas + '<META NAME="form" CONTENT="' + QFld['form']  + '">'#13#10 +
                    '<META NAME="reqFrom" CONTENT="' + Request.From  + '">'#13#10 +
                    '<META NAME="reqHost" CONTENT="' + Request.Host  + '">'#13#10 +
                    '<META NAME="reqScriptName" CONTENT="' + Request.ScriptName  + '">'#13#10 +
                    '<META NAME="reqPathInfo" CONTENT="' + Request.PathInfo  + '">'#13#10 +
                    '<META NAME="reqQuery" CONTENT="' + Request.Query + '">'#13#10 +
                    '<META NAME="reqReferer" CONTENT="' + Request.Referer  + '">'#13#10 +
                    '<META NAME="reqRDerivedFrom" CONTENT="' + Request.DerivedFrom  + '">'#13#10;
  { search query }
  Handled:= True;
  { установить нужную перекодировочную таблицу по cp }
  { ! НА Web сервере хранятся CP1251 }
  s:= QFld['cp'];   { }
  cvrt:= (s <> '') and (FxlatDefs <> Nil) and SetxlatByName(s);
  { ! перекодировать параметры браузера в CP1251 }
  if cvrt then begin
    for i:= 0 to QFlds.Count - 1 do begin
      s:= QFlds[i];
      strxlat(xlat256^, s);
      QFlds[i]:= s;
    end;
  end;

  S:= Qfld['push'];
  if S = '' then begin
    FpushCount:= 0;
  end else begin
    FpushCount:= 1;
    try
      FpushInterval:= StrToTime(S);
    except
      FpushInterval:= DEFPUSHINTERVAL;
    end;
  end;

  { load invalid second-password (golden-hash) form }
  { -1 - no hash 0 - hash string NOT verified 1 - hash verified }
  Fhashed:= -1;
  PathsList[fpPwd]:= QFld['pwd'];
  PathsList[fpHash]:= QFld['hash'];

  if (PathsList[fpHash] <> '') then begin
    { ok, now verify.. }
    { -1 - no hash 0 - hash string NOT verified 1 - hash verified }
    if PathsList[fpPwd] = PathsList[fpRootPwd] then begin
      { указан пароль администратора }
      PathsList[fpPwd]:= CalcHashAccount(PathsList[fpHashUniqueID], PathsList[fpHash]); { вычисленный пароль доступен }
      { разрешить тег <#a name=sys value=pwd hash=номер тел.> }
      Fhashed:= 2;
    end else begin
      Fhashed:= VerifyHashAccount(PathsList[fpHashUniqueID], PathsList[fpHash], PathsList[fpPwd]);
      if Fhashed = 0 then begin
        { загрузить форму сообщения об ошибке "Неверный пароль или БД", если задано в параметрах }
        LoadFormInvalid;
        if FFormInvalid = '' then begin
          { form does not loaded properly }
          FFormInvalid:= Format(SERRB+'Пароль неверен. Предупр. форма %s (%s): не загружена'+SERRE,
            [s, Alias2FileName(s)]);
        end;
        PgProdTbl.HTMLDoc:= FFormInvalid;
        Response.Content:= PgProdTbl.Content;
        Exit;
      end;
    end;
  end;

  { load main form }
  s:= QFld['form'];

  if s = '' then begin
    { form does not specified }
    Response.Content:= Format(SERRB+'Не задан обязательный параметр form. <p>Информация: /info?show=[threads,copyright,list]'+SERRE,[]);
    Exit;
  end;
  try
    FForm:= LoadCacheString(Alias2FileName(s));
  except
    { form does not loaded properly }
    Response.Content:= Format(SERRB+'Форма %s (%s): I/O ошибка'+SERRE,
      [s, Alias2FileName(s)]);
    Exit;
  end;
  { parse main .htm form..  }
  PgProdTbl.HTMLDoc:= FForm;
  { ..parsed }
  { get dbs&user&key parameters }
  cdbs:= QFld['dbs'];
  cuser:= QFld['user'];
  ckey:= QFld['key'];
  { if user&key does not specified, use default values }
  if cdbs  = '' then cdbs := PathsList[fpDbs];
  if cuser = '' then cuser:= PathsList[fpUser];
  if ckey  = '' then ckey := PathsList[fpKey];
  with FLogStruc do begin
    { хост..алиас,имя,парольБД,форма,семейство...действие }
    lst:= lst + cdbs + #9 + cuser + #9 + ckey + #9 + QFld['form'] + #9;
    empno:= StrToIntDef(QFld['empno'], -1);
  end;
  { validate database name, user&key }
  if IsThreadDbConnected(cdbs, cuser, ckey)
  then begin
    { nothing to do }
    Fmetas:= Fmetas+Format('<META NAME=CONNECTED VALUE=%s>',['allready']);
  end else begin
    { set up database name, user&key }
    with Database0 do begin
      Database0.Close;
      try
        // IB: this statement set Collate Code Page database parameter to appropriate value too
        DbAliasname:= cdbs;
        DbUserName:= cuser;
        DbUserPassword:= ckey;
        Connected:= True; //Open
      except
        on E: Exception do begin
          ProcessDBError(E);
          PathsList[fpStatus]:= E.Message;
        end;
      end;
      if Connected then begin
        { nothing to do }
        Fmetas:= Fmetas+
          Format('<META NAME="CONNECTED" VALUE="%s">', [DateTimeToStr(Now)]);
      end else begin
        // FLogStruc.lst:= FLogStruc.lst + 'user '+QFld['user']+' connect database '+QFld['dbs']+' failure';
        FLogStruc.lst:= FLogStruc.lst + 'user '+DbUserName+'/'+DbUserPassword+' connect database '+DbAliasname+' failure';
        { загрузить форму сообщения об ошибке "Неверный пароль или БД", если задано в параметрах }
        LoadFormInvalid;
        if Length(FFormInvalid) = 0 then begin
          Response.Content:= Response.Content+Format(PathsList[fpStatus] +
          ' Invalid database alias (%s), user name (%s) or password (%s)'+SERRE,
            [DbAliasname, DbUserName, DbUserPassword]);
{$IFDEF USE_IB}
            Response.Content:= Response.Content+
            '<p>Interbase database ['+Database0.DatabaseName+
            '],<p>collate code page ['+Database0.Params.Values[DBPAR_CP]+']';
{$ENDIF}
        end else begin
          { error form specified in parameters }
          Response.Content:= FFormInvalid;
        end;
        Exit;
      end;
    end;
  end;
  Fmetas:= Fmetas+Format('<META NAME=DB VALUE=%s>', [QFld['dbs']]);
{$IFDEF USE_IB}
  with Transaction0 do begin
    try
      Active:= True;
      if InTransaction
      then Commit;
      StartTransaction;
    except
    end;
  end;
{$ELSE}
  if PathsList[fpDoTransaction] = '1' then begin
    try
      with Database0 do if InTransaction then begin
        Commit;
      end;
      Database0.StartTransaction;
    except
      on E: Exception do begin
        ProcessDBError( E);
        PathsList[fpStatus]:= E.Message;
        if PathsList[fpErrorIcon] = ''  { if no error icon specified in registry }
        then Response.Content:= SERRB+'<b>Start transaction failed: ' + PathsList[fpStatus]+'</b>+SERRE'
        else Response.Content:= SERRB+ERRTAG1+PathsList[fpErrorIcon]+ERRTAG2+PathsList[fpStatus]+ERRTAG3+SERRE;
        Exit;
      end;
    end;
  end;
{$ENDIF}
 { show records FFirstShowNo..FLastShowNo }
  FFormAccessDenied:= False;
  Response.Content:= Response.Content+PgProdTbl.Content;
  if FFormAccessDenied then begin
     try
       S:= LoadCacheString(Alias2FileName(PathsList[fpAccessDeniedForm]));
       { include information about why access denied cause has been performed in <#metas> tag }
       while util1.ReplaceStr(S, False, '<#metas>', PathsList[fpStatus]) do;
       Response.Content:= S;
     except
     end;
     if Length(Response.Content) <= 0
     then Response.Content:=   SERRB + 'Access form denied' + SERRE;
  end;
  if cvrt then begin
    s:= Response.Content;
    strxlat(xlat256_1, s);
    Response.Content:= s;
  end;
{$IFDEF USE_IB}
  try
    with Transaction0 do begin
      Commit;
    end;
  except
  end;
{$ELSE}
    if PathsList[fpDoTransaction] = '1' then begin
      try
        with Database0 do begin
          Commit;
        end;
      except
        on E: Exception do begin
          ProcessDBError(E);
          PathsList[fpStatus]:= PathsList[fpStatus]+ ' '+ E.Message;
        end;
      end;
    end;
{$ENDIF}
  { в журнал длину возвращаемого текста }
  FLogStruc.len:= Length(Response.Content);
end;

{ /INFO: get information about settings }
procedure TWebModule1.WebModule1actInfoAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  optno, i: Integer;
  S: String;
  Tok: String[80];
  R: String;
  FOSVersionInfo: TOSVersionInfo;
begin
  S:= QFld['key'];
  if (PathsList[fpRootPwd] <> '') and (S <> PathsList[fpRootPwd]) then begin
    Response.Content:= Format(SERRB+'Invalid administrator password'+SERRE, [s]);
    FLogStruc.lst:= FLogStruc.lst + 'dll information request with wrong password '+s+#9;
    Exit;
  end;
  FLogStruc.lst:= FLogStruc.lst + 'dll information request'#9;
  Handled:= True;
  R:= SERRB;
  S:= QFld['show'];
  optno:= 1;
  repeat
    Tok:= UpperCase(GetToken(optno, ',', S));
    if Tok = 'COPYRIGHT' then begin
      {------------------------------it does not works in Delphi4 }
      R:= R +
        '<p>Location: '+PathsList[fpPatternPath]+'</p>'+
        '<p>'+Versions.GetVersionInfo(LNG, 'ProductName')+'</p>'+
        '<p>'+GetVersionInfo(LNG, 'LegalCopyright')+'</p>'+
        '<p>File version: '+GetVersionInfo(LNG, 'FileVersion')+'</p>'+
        '<hr>';
    end;
    if Tok = 'LIST' then begin
      R:= R +
        '<p>'+PathsList[fpBanner]+'</p>'+
        '<p>NSAPI/ISAPI .dll file name: '+PathsList[fpScript]+'</p>'+
        '<p>Pattern directory path: '+PathsList[fpPatternPath]+'</p>'+
        '<p>ecc convertor file path: '+PathsList[fpEccPath]+'</p>'+
        '<p>current ecc xlat name: '+ xlatname +
        '<p>Make NULL on empty parameter: '+BoolToStr1(optmkNull in Options) +'</p>'+
        '<p>option 2: '+BoolToStr1(2 in Options)+'</p>';
{$IFNDEF USE_BDE}
      R:= R + '<hr><p>database aliases: '+ IntToStr(SLAdditionalDBAlias.Count)+'</p>';
      for i:= 0 to SLAdditionalDBAlias.Count - 1
      do R:= R + '<p>' + SLAdditionalDBAlias[i] + '</p>';
{$ENDIF}
      R:= R + '<hr><p>Global variables</p>';
      for i:= 0 to FGlobalVar.Count - 1
      do R:= R + '<p>' + FGlobalVar[i] + '</p>';
    end;
    if Tok = 'THREADS' then begin
      R:= R +
        '<p>'+PathsList[fpBanner]+'</p>'+
        '<p><H2>Today '+DateTimeToStr(Now) + '</H2></p>'+
        '<p><H3>Threads</H3></p><table>'+
        '<tr><td>max:</td><td>'+IntToStr(Application.MaxConnections)+'</td></tr>'+
        '<tr><td>active:</td><td>'+IntToStr(Application.ActiveCount)+'</td></tr>'+
        '<tr><td>inactive:</td><td>'+IntToStr(Application.InActiveCount)+'</td></tr>'+
        '<tr><td>cache connections on:</td><td>'+BoolToStr1(Application.CacheConnections)+'</td></tr>'+
        '<tr><td>queries:</td><td>'+IntToStr(FQueryCount)+'</td></tr>'+
        '</table><hr>';
    end;
    Inc(optno);
  until Tok = '';
  { get version }
  FOSVersionInfo.dwOSVersionInfoSize:= SizeOf(FOSVersionInfo);
  GetVersionEx(FOSVersionInfo);
  R:= R + '<table><tr><td>MSWindows version:</td><td>'+
    IntToStr(FOSVersionInfo.dwMajorVersion)+'.'+IntToStr(FOSVersionInfo.dwMinorVersion)+
    '</td></tr><tr><td>service pack:</td><td>'+ String(FOSVersionInfo.szCSDVersion)+
    '</td></tr><tr><td>build:</td><td>'+ IntToStr(FOSVersionInfo.dwBuildNumber)+'</td></tr><table>';
  Response.Content:= R + SERRE;
end;

{ /reload?key=<administrator password>
  There are big mistake! Do not use /reload!
}
procedure TWebModule1.WebModule1actReloadAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  S: String;
  i: Integer;
  Instance: TComponent;
begin
  Handled:= True;
  S:= QFld['key'];
  if (PathsList[fpRootPwd] <> '') and (S <> PathsList[fpRootPwd]) then begin
    Response.Content:= Format(SERRB+'Invalid administrator password'+SERRE, [s]);
    FLogStruc.lst:= FLogStruc.lst + 'setup invalid password'#9;
    Exit;
  end;
  // i do that later in right way
  for i:= 0 to Application.ComponentCount - 1 do begin
    Instance:= Application.Components[i];
    if Instance is TWebModule then begin
      TWebModule1(Instance).LoadIni(False);
    end;
  end;
  LoadIni(False);
  Response.Content:= 'reloaded'
end;

{ called from PageProducer. Parse tag <#T name=family>
  open query .sql, template .htt files, try to open regular expression .par file
  Template .htt contains 3 or 4 parts, delimited by <#@>..<#!@>..<#/@>
  ELSE part (<#!@>) may be omitted
}
function TWebModule1.LoadSelect(const AFamily: String): Boolean;
var
  p1, p2, p3: Integer;
  FTemplateSql, FTemplateRegularSql, FTemplate: String;
begin
  LoadSelect:= False;
  FTemplateSql:= ReplaceExt('.sql', Alias2FileName(AFamily));
  FTemplateRegularSql:= ReplaceExt('.par', FTemplateSql);
  FTemplate:= ReplaceExt('.htt', FTemplateSql);
  try { load forms }
    { sql file }
    FSql:= LoadCacheString(FTemplateSql);
    { sql regular expression file }
    FRegularSql.Text:= LoadCacheString(FTemplateRegularSql);
    { parse expressions (find and replace parameters :PAR) stored in PAR file }
    FRegularSql.Text:= PrepareRegularSql(FRegularSql.Text, FRegularSql);
    { template file }
    FRespBegin:= LoadCacheString(FTemplate);
    { delete lead spaces and control chars. }
    // util1.DeleteLeadSpaceStr(FSQL);
    if (FSQL = '') or (FRespBegin = '')
    then Exit;

    p1:= Pos('<#@>', FRespBegin);
    if p1 <= 0 then begin
      { если BODY <#@> опущен, считать совпадающим с началом }
      { от 1 - 1 = 0 то есть нет части BEGIN }
      FRespEnd:= '';
      FRespElse:= '';
      FRespBody:= FRespBegin;
      FRespBegin:= '';
    end else begin
      p2:= PosFrom(p1, '<#!@>', FRespBegin);
      p3:= PosFrom(p1, '<#/@>', FRespBegin);
      if p3 <= 0 then begin { если  END <#/@> опущен, то считать его в самом конце }
        p3:= Length(FRespBegin); { от LEN - LEN = 0 то есть нет части END }
      end;
      if p2 <= 0 then begin { если ELSE <#!@> опущен, то считать совпадающим с END }
        p2:= p3;  { 0 - то есть нет части ELSE }
      end;
      FRespEnd:= Copy(FRespBegin, p3 + 5, MaxInt);
      FRespElse:= Copy(FRespBegin, p2 + 5, p3 - p2 - 5);
      FRespBody:= Copy(FRespBegin, p1 + 4, p2 - p1 - 4);
      FRespBegin:= Copy(FRespBegin, 1, p1 - 1);
    end;
  except
  end;
  LoadSelect:= True;
end;

{ возвращает '' если нет параметров или длина их короче 3 (без '%') или заданного }
function ReplRegular(Apar: String; ARegularList: TStrings; AValue: String): String;
var
  i, percentcount, minParameterLen: Integer;
  RegExpr, Value1, Delimiter, PercentChars, fmtoptions, EmptyParameter: String;
  charset: set of Char;
begin
  RegExpr:= NoQuotes(ARegularList.Values[APar]);
  // DeleteLeadTerminateSpaceStr(RegExpr);
  if RegExpr > '' then begin
    Delimiter:= NoQuotes(ARegularList.Values[APar+' delimiter']);
    PercentChars:= NoQuotes(ARegularList.Values[APar+' %chars']);
    minParameterLen:= StrToIntDef(NoQuotes(ARegularList.Values[APar+' min']), 3);
    EmptyParameter:= NoQuotes(ARegularList.Values[APar+' empty']);
    fmtoptions:= NoQuotes(ARegularList.Values[APar+' fmt']);
    String2SetOfChar(PercentChars, charset);
    if Delimiter = ''
    then Delimiter:= #32;
    i:= 1;
    Result:= '';
    repeat
      Value1:= GetToken(i, #32, AValue);
      { заменить символы типа '~' на sql % }
      percentcount:= ReplaceChars(charset, '%', Value1);
      { число символов (без знаков '%' ) должна быть не меньше трех или заданного числа }
      if Length(Value1) - percentcount < minParameterLen
      then Break;
      if i > 1
      then Result:= Result + Delimiter;
      if Pos('UPPER', Uppercase(fmtOptions)) > 1
      then Value1:= ANSIUppercase(Value1);
      if Pos('LOWER', Uppercase(fmtOptions)) > 1
      then Value1:= ANSILowercase(Value1);
      Result:= Result + Format(RegExpr, [Value1]);
      Inc(i);
    until False;
  end else begin
    Result:= AValue;
  end;
  if Result = ''
  then Result:= EmptyParameter;
end;

{ ParseSqlPar allways return True
  AFamilyName - form's parameter prefix for loaded into SLSql sql query
}
function TWebModule1.ParseSqlPar(AQuery: TDS): Boolean;
var
  i: Integer;
  par: Boolean;
  curpar, rslt, vl, fparameter: String;
{$IFNDEF USE_IB}
  spp: TStoredProcParser;
  // parlist: TStrings;
{$ENDIF}
procedure DoPar;
var
  S: String;
begin
  { insert parameter into sql statement }
  // quote=True in sql statement "'" or """ - delete it
  fparameter:= QFld[util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.'+curpar];
  { если не указано семейство, попробовать вставить параметр без семейства }
  if fparameter = ''
  then fparameter:= QFld[curpar];

  if (Length(fparameter) = 0) and (Length(curpar) > 0) and (curpar[1]='$') then begin
    S:= Copy(curpar, 2, MaxInt);
    fparameter:= TagSystemOption(S, SLAlias);
    if fparameter = ''
    then fparameter:= TagIPOption(S, FCurRequest, SLAlias);
  end;
  rslt:= rslt + ReplRegular(curpar, FRegularSql, fparameter);
end;

begin
  { looking for :PAR and replace it }
  i:= 1;
  par:= False;
  curpar:= '';
  rslt:= '';
  // quote:= false; { just for disable compiler warning }
  { поставить сторож на случай если параметр в самом конце FSql: "WHERE 12=:PAR"}
  vl:= FSql+#32;
  while i <= Length(vl) do begin
    case vl[i] of
    ':':
      begin
        { insert parameter }
        if par then begin
          if (curpar = '') then begin { mask parameter prefix '::' => ':' }
            rslt:= rslt + ':';
            par:= False;
          end else DoPar;
        end else begin
          curpar:= '';
          par:= true;
        end;
        // quote:= (i > 1) and (vl[i-1] in ['''', '"']);
      end;
    else
      begin
        if par and (vl[i] in PARAMETER_NAME_CHARSET) then begin
          curpar:= curpar + vl[i];
        end else begin
          if par then begin
            DoPar;
            par:= false;
          end;
          rslt:= rslt + vl[i];
          curpar:= '';
        end;
      end;
    end;
    Inc(i);
  end;
{$IFDEF USE_IB}
  AQuery.SQL.Text:= Rslt;
{$ELSE}
  if AQuery is TEQuery then begin
    TEQuery(AQuery).SQL.Text:= Rslt;
  end;
  if AQuery is TEStoredProc then begin
    spp:= SPPrsr.TStoredProcParser.Create;
    spp.Text:= Rslt;
{$IFDEF USE_NCOCI}
    // can't assign TOCIStoredProc.StoredProcName w/o nullify OPackageName
    TEStoredProc(AQuery).OProcedureName:= spp.SetStoredProc(TEStoredProc(AQuery));
    TEStoredProc(AQuery).OPackageName:= '';
{$ENDIF}
{$IFDEF USE_BDE}
    // Oracle: there is bug in TStoredProc
    // Note: setting Oracle's schema in TOCIStoredProc.StoredProcName cause fault in ExecProc
    TEStoredProc(AQuery).StoredProcName:= spp.SetStoredProc(TEStoredProc(AQuery));
{$ENDIF}
    // spp.ParNames(parList);
    for i:= 0 to TEStoredProc(AQuery).Params.Count - 1 do begin
      if TEStoredProc(AQuery).Params[I].ParamType in [ptInput, ptInputOutput] then begin
        // curpar:= parlist.Names[i];
        curpar:= TEStoredProc(AQuery).Params[I].Name;
        { это потенциально может привести к конфликту - один параметр может действовать на несколько семейств }
        fparameter:= QFld[util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.'+curpar];
        if fparameter = '' { если не указано семейство, попробовать вставить параметр без семейства }
        then fparameter:= QFld[curpar];
        try
          // do not set value like this: TEStoredProc(AQuery).Params[I].Value:= fparameter;
          //  because w/o setting ole-type of Value. More simple:
          TEStoredProc(AQuery).Params[I].AsString:= fparameter;
        except
        end;
      end;
    end;
    // parlist.Free;
    spp.Free;
  end;
{$ENDIF}
  Result:= True;
end;

{ DoLoadedExec execute SQL statement,
  called from PageProducer (parse tag <#E name=family> and load .sql file
}
function TWebModule1.DoLoadedExec(AQuery: TDS): Boolean;
var
  FamilyName: String;
begin
  Result:= False;
  { AfamilyName и familyName aren't empty- don't check! }
  familyName:= PathsList[fpCurrFamily] + '.';
  AQuery.Close;
  if ParseSqlPar(AQuery) then begin  { параметры переданы, выполнить запрос }
    try
{$IFDEF USE_IB}
      Transaction0.Active:= True;
      AQuery.ExecQuery;
{$ELSE}
      if AQuery is TEQuery
      then TEQuery(AQuery).ExecSQL;
      if AQuery is TEStoredProc
      then TEStoredProc(AQuery).ExecProc;
{$ENDIF}
      Result:= True;
    except
      on E: Exception do begin
        ProcessDBError(E);
        PathsList[fpStatus]:= E.Message;
      end;
    end;
    AQuery.Close;
  end;
{$IFDEF USE_IB}
  Transaction0.Active:= True;
{$ENDIF}
end;

{ Note if database is SQL based: 
  use <#a name=sys value=qty> and/or <#a name=pageline> after appropriate <#t>
  because query's cursor moved to eof ().
}
function TWebModule1.CalcRecordsQty: Integer;
var
  QueryOpened: Boolean;
begin
  Result:= FRecordsQty;
  QueryOpened:= False;
  if FRecordsQtyCountDone
  then Exit;
  try
{$IFDEF USE_IB}
    Query0.ExecQuery;
    QueryOpened:= Query0.Open;
    if QueryOpened then begin
      while not Query0.Eof do begin
        Inc(FRecordsQty);
        Query0.Next;
      end;
{$ELSE}
    Query0.Active:= True;
    if Query0.Active then begin
      if Database0.IsSQLBased then begin
        while not Query0.Eof do begin
          Inc(FRecordsQty);
          Query0.Next;
        end;
      end else begin
        // desktop database
        FRecordsQty:= Query0.RecordCount;
      end;
{$ENDIF}
      { query allready parsed }
      FRecordsQtyCountDone:= True;
      Result:= FRecordsQty;
    end;
  except
    on E: Exception do begin
      ProcessDBError(E);
      FRecordsQtyCountDone:= True;
      FRecordsQty:= 0;
      Result:= 0;
    end;
  end;
  if not QueryOpened
  then Query0.Close;
end;

function TWebModule1.MkErrStringIcon(ADesc: String): String;
var
  FErrTemplate: String;
begin
  FErrTemplate:= ReplaceExt('.err',
    Alias2FileName(PathsList[fpCurrFamily]));
  try { load error template }
    Result:= LoadCacheString(FErrTemplate);
  except
  end;
  if Length(Result) = 0 then begin
    if PathsList[fpErrorIcon] = ''  { if no error icon specified in registry }
    then Result:= '<b>server side error: ' + PathsList[fpStatus]+': ' + ADesc + '</b>'
    else Result:= ERRTAG1+PathsList[fpErrorIcon]+ERRTAG2+PathsList[fpStatus]+': ' + ADesc + ERRTAG3;
  end;
end;

{ DoLoadedFamily выполняет запрос и выдает строки таблицы }
function TWebModule1.DoLoadedFamily(AQuery: TDS): String;
var
  row: Integer;
  FamilyName, S: String;
{$IFDEF USE_IB}
  i: Integer;
{$ENDIF}
begin
  { clear up records counter }
  FRecordsQty:= 0;
  FRecordsQtyCountDone:= False; { qty of records NOT calculated yet }
  { AfamilyName и familyName не пустые- нет смысла проверять }
  familyName:= PathsList[fpCurrFamily] + '.';
  { header }
  PgProdFld.HTMLDoc:= FRespBegin;
  Result:= PgProdFld.Content;
  { body!else}
  PgProdFld.HTMLDoc:= FRespBody;
  // AQuery.Close;
  if ParseSqlPar(AQuery) then begin  { parameters passed, execute }
{$IFDEF USE_IB}
    if IsEmptyString(AQuery.SQL.Text) then begin
{$ELSE}
    if (AQuery is TEQuery) and IsEmptyString(TEQuery(AQuery).SQL.Text) then begin
{$ENDIF}
      { if no sql statement }
      PgProdFld.HTMLDoc:= FRespEnd;
      Result:= Result + FRespElse + PgProdFld.Content;
    end else begin
      { sql statement }
      try
{$IFDEF USE_IB}
        with Transaction0 do begin
          Active:= True;
          AQuery.ExecQuery;
        end;
{$ELSE}
        AQuery.Open;
{$ENDIF}
      except
        on E: Exception do begin
          ProcessDBError(E);
          PathsList[fpStatus]:= E.Message;
          S:= '';
{$IFDEF USE_IB}
          S:= AQuery.Sql.Text;
{$ELSE}
          if AQuery is TEQuery
          then S:= (AQuery as TEQuery).Sql.Text;
          if AQuery is TEStoredProc
          then S:= 'stored procedure';
{$ENDIF}
          Result:= Result + MkErrStringIcon(S);
        end;
      end;
      try
{$IFDEF USE_IB}
        if AQuery.Open then begin
{$ELSE}
        if AQuery.Active then begin
{$ENDIF}
          { get first&last parameters.. }
          CalcFirstLastRows(FamilyName, 0);
          { returns FLastShowNo zero if last parameter is not specified }
          if FLastShowNo = 0
          then FLastShowNo:= MAXRECORDSPERPAGE;
          { сформировать строку }
          row:= FFirstShowNo;
{$IFDEF USE_IB}
          if AQuery.EOF then begin
{$ELSE}
          if AQuery.IsEmpty then begin
{$ENDIF}
            // FRecordsQty:= 0; { allredy set, no records }
            FRecordsQtyCountDone:= True;
            Result:= Result + FRespElse;
          end else begin
            // AQuery.Prepare;
            // AQuery.First;
{$IFDEF USE_IB}
            for i:= 1 to FFirstShowNo
            do AQuery.Next;  // 0..
{$ELSE}
            AQuery.MoveBy(FFirstShowNo);
{$ENDIF}
            { clear up stored old values from producer. (Old values keeping for implementation
              of <#f .. replace=emptysame> tag emptysame specifier)
            }
            PgProdFld.ClearOldValues;
            repeat
              if AQuery.Eof then begin
                FRecordsQtyCountDone:= True;
                Break;
              end;
              Result:= Result + PgProdFld.Content;
              AQuery.Next;
              Inc(row);
              if (row > FLastShowNo)
              then Break;
            until False;
            { there is bug, if first= parameter more than actual record's qty }
            FRecordsQty:= row; { 0 if no first record }
          end;
        end else begin
          S:= '';
{$IFDEF USE_IB}
          S:= AQuery.SQL.Text;
{$ELSE}
          if AQuery is TEQuery
          then S:= (AQuery as TEQuery).Sql.Text;
          if AQuery is TEStoredProc
          then S:= 'stored procedure';
{$ENDIF}
          Result:= Result + MkErrStringIcon(S);
        end;
      except
        on E: Exception do begin
          ProcessDBError(E);
          PathsList[fpStatus]:= E.Message;
          S:= '';
{$IFDEF USE_IB}
          S:= AQuery.SQL.Text;
{$ELSE}
          if AQuery is TEQuery
          then S:= (AQuery as TEQuery).Sql.Text;
          if AQuery is TEStoredProc
          then S:= 'stored procedure';
{$ENDIF}
          Result:= Result + MkErrStringIcon(S);
        end;
      end;
    end;
  end;
  { finish }
  PgProdFld.HTMLDoc:= FRespEnd;
  Result:= Result + PgProdFld.Content;
  try
    AQuery.Close;
  except
  end;
end;

{ versus LoadSelect load .sql file only (w/o templates) }
function TWebModule1.LoadExec: Boolean;
begin
  Result:= False;
  FSql:= ReplaceExt('.sql', Alias2FileName(PathsList[fpCurrFamily]));
  { load forms }
  FSql:= LoadCacheString(FSql);
  if FSQL = ''
  then Exit;
  Result:= True;
end;

{ page producer handlers ------------------------------------------------------}

{ <#F name=ИМЯПОЛЯ [fmt=currency|money][http=encode|encodehtml]>
  <#P name=ИМЯПАРАМЕТРА [http=encode]>
  <#H>
}
procedure TWebModule1.PgProdFldHTMLTag(Sender: TObject; Tag: TTag;
  const TagString: String; TagParams: TStrings;var ReplaceText: String);
var
  TagUp, FldName, mdf: String;
  i: Integer;
  fldExists: Boolean;
  fldRemoveDoubles: Boolean;
  HFld: TFLD;
begin
  TagUp:= ANSIUpperCase(TagString);
  if Length(TagUp) <=0 then begin
    Exit;
  end;
  if Length(TagUp) = 1 then begin
  case TagUp[1] of
  'F':begin
        FldName:= NoQuotes(TagParams.Values['NAME']);
{$IFDEF USE_IB}
        i:= Query0.FieldIndex[FldName];
        fldExists:= i >= 0;
{$ELSE}
        fldExists:= Query0.FieldDefs.IndexOf(FldName) >= 0;
{$ENDIF}
        { <#F> должен бы иметь параметр name }
        if (FldName <> '') and fldExists then begin
          try
            fldRemoveDoubles:= ANSICompareText('emptysame', NoQuotes(TagParams.Values['replace'])) = 0;
            mdf:= NoQuotes(TagParams.Values['fmt']);
{$IFDEF USE_IB}
            HFld:= Query0.Fields[i];
{$ELSE}
            HFld:= Query0.FindField(FldName);
{$ENDIF}
            if (HFld <> Nil) then begin
              if (not HFld.IsNull) then begin
                if ANSICompareText('currency', mdf) = 0 then begin
                  ReplaceText:= cyrmoney(HFld.AsCurrency);
                end else begin
                  if ANSICompareText('money', mdf) = 0 then begin
                    ReplaceText:= MoneyStr(HFld.AsCurrency, FCurrencySimple);
                  end else begin
                    if ANSICompareText('hash', mdf) = 0 then begin
                      if Fhashed = 2 then begin
                        PathsList[fpHash]:= HFld.AsString;
                        PathsList[fpPwd]:= CalcHashAccount(PathsList[fpHashUniqueID], PathsList[fpHash]);
                        ReplaceText:= PathsList[fpPwd];
                      end else begin
                        ReplaceText:= 'wrong_administrator_password';
                      end;
                    end else begin
                      if ANSICompareText('datetime', mdf) = 0 then begin
                        ReplaceText:= FormatDateTime(NoQuotes(TagParams.Values['specifier']),
                          HFld.AsDateTime);
                      end else begin
                        if ANSICompareText('external', mdf) = 0 then begin
                          ReplaceText:= FormatBlobByDLL(NoQuotes(TagParams.Values['dll']),
                            NoQuotes(TagParams.Values['func']),
                            NoQuotes(TagParams.Values['specifier']), HFld);
                        end else begin
                          ReplaceText:= HFld.AsString;
                        end;
                      end;
                    end;
                  end;
                end;
                { delete doubles records as requested }
                if fldRemoveDoubles then begin
                  if ReplaceText = (Sender as TECustomPageProducer).OldValue[FldName]
                  then ReplaceText:= ''
                  else (Sender as TECustomPageProducer).OldValue[FldName]:= ReplaceText;
                end;
              end else begin
                if ANSICompareText('currency', mdf) = 0 then begin
                  ReplaceText:= 'ноль рублей 00 копеек';
                end else begin
                  if ANSICompareText('money', mdf) = 0 then begin
                    ReplaceText:= MoneyStr(0.0, FCurrencySimple);
                  end else begin
                    ReplaceText:= '';
                  end;
                end;
              end;
            end;
          except
            ReplaceText:= FldName +'_string_conversion_error';
          end;
          mdf:= NoQuotes(TagParams.Values['http']);
          if ANSICompareText('encode', mdf) = 0
          then ReplaceText:= HTTPEncode(ReplaceText);
          mdf:= NoQuotes(TagParams.Values['copy']);
          if mdf <> ''
          then QFlds.Values[TagParams.Values['copy']]:= ReplaceText;
        end else begin
          ReplaceText:= FldName + '_doesn''t_exists';
        end;
      end;
  'P':begin { вставить переданный параметр }
        mdf:= NoQuotes(TagParams.Values['fmt']);
        if ANSICompareText('currency', mdf) = 0 then begin
          ReplaceText:= cyrmoney(StrToIntDef(QFld[NoQuotes(TagParams.Values['NAME'])], 0));
        end else begin
          if ANSICompareText('money', mdf) = 0 then begin
            ReplaceText:= MoneyStr(StrToIntDef(QFld[NoQuotes(TagParams.Values['NAME'])], 0), FCurrencySimple);
          end else begin
            ReplaceText:= QFld[NoQuotes(TagParams.Values['NAME'])];
          end;
        end;
        mdf:= NoQuotes(TagParams.Values['http']);
        if ANSICompareText('encode', mdf) = 0
        then ReplaceText:= HTTPEncode(ReplaceText);
        if ANSICompareText('encodehtml', mdf) = 0
        then ReplaceText:= ASCII2HTML(ReplaceText);
      end;
  'H':begin { вставить скрытый "наследуемый" параметр }
        { преобразовать параметр для в помещения в тег hidden:
        СП "123" -> СП &quot;123&quot;  }
        i:= 1;
        ReplaceText:= '';
        repeat
          mdf:= GetToken(i, ',', NoQuotes(TagParams.Values['name']));
          if Length(mdf) = 0
          then Break;
          ReplaceText:= ReplaceText + '<input type=hidden name='+ mdf +
            ' value="' + QFldHtml[mdf] + '">';
          Inc(i);
        until False;
      end;
  'A':begin { всякое }
        //  <#A name=sys value=>
        if ANSICompareStr(TagParams.Values['name'], 'sys') = 0 then begin
          ReplaceText:= FormatFmt(TagSystemOption(TagParams.Values['value'], TagParams),
            NoQuotes(TagParams.Values['fmt']));
          //WEBStyleString2ASCII('<'+TagParams+'>')
        end;
        if ANSICompareStr(TagParams.Values['name'], 'ip') = 0 then begin
          ReplaceText:= TagIPOption(TagParams.Values['value'], WebDispatcher0.Request, TagParams);
          //WEBStyleString2ASCII('<'+TagParams+'>')
        end;
      end;
    end; { case }
  end else begin
    ReplaceText:= TagSystemOption(TagString, TagParams);
  end;
end;

function TWebModule1.ParseFamilyName(ATagParams: TStrings): String;
begin
  // Try to find :parameter in name of family Nil- no regular expression
  // call ExtractFileNameWOext after PrepareRegularSql because family name can
  // contains :parameter :$sys_or_ip_parameter with colon
  Result:= util1.ExtractFileNameWOext(
    PrepareRegularSql(NoQuotes(ATagParams.Values['name']), Nil));
end;

{ <#T table=family[:parameter]> family name: query .sql, template .htt
  Then call PgProdFld <#F name=ИМЯПОЛЯ view=ОТОБРАЖАЕМОЕ_ИМЯ [attr=атрибуты]>
  <#E>  <#P>  <#H>  <#A>  <#C>  <#X>  <#list>
  <#FIRSTNO> <#LASTNO> <#METAS>
}
procedure TWebModule1.PgProdTblHTMLTag(Sender: TObject; Tag: TTag;
  const TagString: String; TagParams: TStrings; var ReplaceText: String);
var
  TagUp, S, mdf: String;
  isStoredProc: Boolean;
  ind: Integer;
begin
  ReplaceText:= '';
  TagUp:= ANSIUpperCase(TagString);
  if Length(tagup) <= 0
  then Exit;
  case TagUp[1] of
  'A':begin { всякое }
        //  <#A name=sys value=>
        if ANSICompareStr(TagParams.Values['name'], 'sys') = 0 then begin
          ReplaceText:= FormatFmt(TagSystemOption(TagParams.Values['value'], TagParams),
            NoQuotes(TagParams.Values['fmt']));
          //WEBStyleString2ASCII('<'+TagParams+'>')
        end;
        if ANSICompareStr(TagParams.Values['name'], 'ip') = 0 then begin
          ReplaceText:= TagIPOption(TagParams.Values['value'], WebDispatcher0.Request, TagParams);
          //WEBStyleString2ASCII('<'+TagParams+'>')
        end;
      end;                   
  'C':begin { операции с параметрами }
        //  <#C name=oldname action="=" value=newname> - скопировать в новый параметр
        if ANSICompareStr(TagParams.Values['action'], '=') = 0 then begin
          { добавить новое значение - скопировать }
          QFlds.Values[TagParams.Values['value']]:= QFld[TagParams.Values['name']];
        end;
        if ANSICompareStr(TagParams.Values['action'], '++') = 0 then begin
          { increment value }
          mdf:= TagParams.Values['type']+#32;
          S:= QFlds.Values[TagParams.Values['value']];
          case Upcase(mdf[1]) of
          'F':begin
                try
                  mdf:= FloatToStr(StrToFloat(S)+1);
                except
                  mdf:= '0.0';
                end;
            end;
          'D':begin
                try
                  mdf:= DateToStr(StrToDate(S)+1);
                except
                  mdf:= DateToStr(0);
                end;
            end;
          'T':begin
                try
                  mdf:= DateTimeToStr(StrToDateTime(S)+1);
                except
                  mdf:= DateTimeToStr(0);
                end;
            end;
          else mdf:= IntToStr(StrToIntDef(S, 0)+1);
          end; { case }
          QFlds.Values[TagParams.Values['value']]:= mdf;
        end;
        if ANSICompareStr(TagParams.Values['action'], '==') = 0 then begin
          { немедленно значение }
          QFlds.Values[TagParams.Values['value']]:= TagParams.Values['name'];
        end;

      end;
  'X':begin { параметр по подстановке %s (**) }
        ind:= TagParams.IndexOfName('replace2fld');
        if ind >= 0 then begin
          { новый стиль (без <>) }
          mdf:= TagParams.Values['replace2fld'];
          TagParams.Delete(ind);
          ind:= TagParams.IndexOfName('tag');
          TagUp:= NoQuotes(TagParams.Values['tag']);
          TagParams.Delete(ind);

          MkValuesQuote(TagParams as TStrings);
          S:= WEBStyleString2ASCII(ChangeChars(#10, #32, ChangeChars(#13, #32, TagParams.Text)));
          DeleteLeadTerminateDoubledSpaceStr(S);
          ReplaceStr(S, false, '**', '%s');
          { специальные случаи - name=sys|ip -как специальные поля }
          if ANSICompareStr(mdf, 'sys') = 0 then begin
            ReplaceText:= Format(S, [TagSystemOption(TagParams.Values['value'], TagParams)]);
          end else begin
            if ANSICompareStr(mdf, 'ip') = 0 then begin
              ReplaceText:= Format(S, [TagIPOption(TagParams.Values['value'], WebDispatcher0.Request, TagParams)]);
            end else begin
              { все остальное- как поля таблицы }
              ReplaceText:= Format(S, [QFldHtml[mdf]]);
            end;
          end;
          ReplaceText:= '<'+ TagUp + #32 + ReplaceText + '>';
        end else begin
          { старый стиль - ошибки при парсировании }
          TagUp:= ExtractFirstInTag(TagParams.Text, S);
          ReplaceStr(S, false, '**', '%s');
          if (Length(tagup) > 1) and (tagup[1] in ['A', 'a']) and (tagup[2] = #32)then begin
            { like '<#a name=...>'}
            //  <#A name=sys value=>
            Delete(TagUp, 1, 2);
            ChangeChar(#32, #13, TagUp);
            TagParams.Text:= tagup;
            if ANSICompareStr(TagParams.Values['name'], 'sys') = 0 then begin
              ReplaceText:= Format(S, [TagSystemOption(TagParams.Values['value'], TagParams)]);
            end;
            if ANSICompareStr(TagParams.Values['name'], 'ip') = 0 then begin
              ReplaceText:= Format(S, [TagIPOption(TagParams.Values['value'], WebDispatcher0.Request, TagParams)]);
            end;
          end else begin
            { like <#P name=xxx> }
            { преобразовать параметр для в помещения в тег
            СП "123" -> СП &quot;123&quot;  }
            ReplaceText:= Format(S, [QFldHtml[TagUp]]);
          end;
        end;
      end;

  'P':begin { вставить переданный параметр }
        mdf:= NoQuotes(TagParams.Values['fmt']);
        if ANSICompareText('currency', mdf) = 0 then begin
          ReplaceText:= cyrmoney(StrToIntDef(QFld[NoQuotes(TagParams.Values['NAME'])], 0));
        end else begin
          if ANSICompareText('money', mdf) = 0 then begin
            ReplaceText:= MoneyStr(StrToIntDef(QFld[NoQuotes(TagParams.Values['NAME'])], 0), FCurrencySimple);
          end else begin
            ReplaceText:= QFld[NoQuotes(TagParams.Values['NAME'])];
          end;
        end;
        mdf:= NoQuotes(TagParams.Values['http']);
        if ANSICompareText('encode', mdf) = 0
        then ReplaceText:= HTTPEncode(ReplaceText);
        if ANSICompareText('encodehtml', mdf) = 0
        then ReplaceText:= ASCII2HTML(ReplaceText);
      end;
  'R':begin
        if not FFormAccessDenied then begin { allready in access denied state }
          PathsList[fpCurrFamily]:= ParseFamilyName(TagParams);
          FFormAccessDenied:= IsAccessDenied(TagParams);
          if FFormAccessDenied then begin
            PathsList[fpAccessDeniedForm]:= NoQuotes(TagParams.Values['form']);
            if Length(PathsList[fpAccessDeniedForm]) = 0 then begin
              { specify default access denied form }
              PathsList[fpAccessDeniedForm]:= PathsList[fpAccessDeniedDef];
            end;
          end;
        end;
      end;
  'H':begin { вставить скрытый "наследуемый" параметр }
        { преобразовать параметр для в помещения в тег
        СП "123" -> СП &quot;123&quot;  }
        ind:= 1;
        ReplaceText:= '';
        repeat
          mdf:= GetToken(ind, ',', NoQuotes(TagParams.Values['name']));
          if Length(mdf) = 0
          then Break;
          ReplaceText:= ReplaceText + '<input type=hidden name='+ mdf +
            ' value="' + QFldHtml[mdf] + '">';
          Inc(ind);
        until False;
      end;
  'T':begin   { select clause }
        if FFormAccessDenied
        then Exit;
        PathsList[fpCurrFamily]:= ParseFamilyName(TagParams);
        mdf:= NoQuotes(TagParams.Values['stored']);
        isStoredProc:= (Length(mdf)>0) and (mdf[1] in ['T','t','Y','y','1','Д','д']);
        if LoadSelect(PathsList[fpCurrFamily]) then begin
          { из шаблонов пишется заголовок и окончание таблицы }
          { выполнить запрос и выдать строки таблицы }
{$IFDEF USE_IB}
          ReplaceText:= DoLoadedFamily(Query0);
          if isStoredProc then;  //
{$ELSE}
          if isStoredProc then begin
            ReplaceText:= DoLoadedFamily(StoredProc0);
          end else begin
            ReplaceText:= DoLoadedFamily(Query0);
          end;
{$ENDIF}
          // Fmetas:= Fmetas+Format('<META NAME=SQLSELECT VALUE=%s>',[Query0.SQL.Text]);
        end else begin
          ReplaceText:= MkErrStringIcon('select sql ' + PathsList[fpCurrFamily] + ' not found');
        end;
      end;
  'E':begin { update,.. Records Qty allways 0 }
        if FFormAccessDenied then begin
          Exit;
        end;
        PathsList[fpCurrFamily]:= ParseFamilyName(TagParams);
        mdf:= NoQuotes(TagParams.Values['stored']);
        isStoredProc:= (Length(mdf)>0) and (mdf[1] in ['T','t','Y','y','1','Д','д']);
        if LoadExec then begin
          if isStoredProc then begin
{$IFDEF USE_IB}
            if DoLoadedExec(Query0) then begin
              ReplaceText:= '';
            end else begin
              ReplaceText:= MkErrStringIcon(' stored procedure ' + Query0.SQL.Text + ' not loaded');
            end;
{$ELSE}
            if DoLoadedExec(StoredProc0) then begin
              ReplaceText:= '';
            end else begin
              ReplaceText:= MkErrStringIcon(' stored procedure ' + StoredProc0.StoredProcName + ' not loaded');
            end;
{$ENDIF}
          end else begin
            if DoLoadedExec(Query0) then begin
              ReplaceText:= '';
            end else begin
              ReplaceText:= MkErrStringIcon(' update query ' + Query0.Sql.Text + ' not loaded');
            end;
          end;
        end else begin
          ReplaceText:= MkErrStringIcon(' update query or stored procedure ' + PathsList[fpCurrFamily] + ' not found');
        end;
      end;
  else begin
      { теги подлиннее (но не начинающиеся с символов A C E H P R T X) }
      if TagUp = 'LIST'
      then ReplaceText:= PathsList[fpUserList];
      if TagUp = '_HASH_'
      then ReplaceText:= PathsList[fpHash];
      if TagUp = '_PWD_'
      then ReplaceText:= PathsList[fpPwd];

      if TagUp = 'FIRSTNO'
      then ReplaceText:= IntToStr(FFirstShowNo);
      if TagUp = 'LASTNO'
      then ReplaceText:= IntToStr(FLastShowNo);
      if TagUp = 'METAS'
      then ReplaceText:= FMetas;
      { page line }
      { if TagUp = 'PAGELINE' then ReplaceText:= MkPageLine; }
    end;
  end;
end;

{ вызывается при разборе тега <#A name=ip value=PAR>
  и возвращает всякие параметры
  PAR=USERAGENT|FROM|HOST|REFERER|DERIVEDFROM|CONNECTION|REMOTEADDR|REMOTEHOST|SERVERPORT|SCRIPTNAME|EXPIRES|SERVERVARLIST
}
function TWebModule1.TagIPOption(TagString: String; Request: TWebRequest; OtherTags: TStrings): String;
var
  TagUp: String;
  SL: TStrings;
  S: String;
begin
  Result:= '';
  TagUp:= ANSIUpperCase(TagString);
  if Length(OtherTags.Values['newvalue'])>0 then begin
    S:= OtherTags.Values['newvalue'];
    with WebDispatcher0 do begin
    end;
    Result:= 'no supported';
  end else begin
    with WebDispatcher0 do begin
      if TagUp = 'USERAGENT'
      then Result:= Request.UserAgent;
      if TagUp = 'FROM'
      then Result:= Request.From;
      if TagUp = 'HOST'
      then Result:= Request.Host;
      if TagUp = 'REFERER'
      then Result:= Request.Referer;
      if TagUp = 'DERIVEDFROM'
      then Result:= Request.DerivedFrom;
      if TagUp = 'CONNECTION'
      then Result:= Request.Connection;
      if TagUp = 'REMOTEADDR'
      then Result:= Request.RemoteAddr;
      //  convert to ip? inet_addr(PChar(Request.RemoteAddr)
      if TagUp = 'REMOTEHOST'
      then Result:= Request.RemoteHost;
      if TagUp = 'SERVERPORT'
      then Result:= IntToStr(Request.ServerPort);
      if TagUp = 'SCRIPTNAME'
      then Result:= Request.ScriptName;
      if TagUp = 'EXPIRES'
      then Result:= DateTimeToStr(Request.Expires);
      if TagUp = 'SERVERVARLIST' then begin
        SL:= GetServerVarList(Request);
        Result:= SL.Text;
        SL.Free;
      end;
    end;
  end;
end;

{ find first=xx&last=xx and delete it
}
procedure DelFirstLastUrl(const AFamilyName: String; var AUrl: String);
var
  p1, p2, cnt, L: Integer;
begin
  p1:= ANSIPos(AFamilyName+'.first=', AURL);
  if p1 > 0 then begin
    cnt:= PosFrom(p1, '&', AURL);
    if cnt <= 0
    then cnt:= Length(AURL);
    Delete(AURL, p1, cnt - p1 + 1);
  end;
  p2:= ANSIPos(AFamilyName+'.last=', AURL);
  if p2 > 0 then begin
    cnt:= PosFrom(p2, '&', AURL);
    if cnt <= 0
    then cnt:= Length(AURL);
    Delete(AURL, p2, cnt - p2 + 1);
  end;
  L:= Length(AURL);
  if (L > 0) and (AURL[L] = '&')
  then Delete(AURL, L, 1)
end;

function TWebModule1.MkPageLine: String;
var
  i, cnt, st0, st1, First10, Last10: Integer;
  HasMore: Boolean;
  S, get_query: String;
  FormatString: ^String;
begin
  Result:= '';
  if not FRecordsQtyCountDone
  then CalcRecordsQty;
  cnt:= FRecordsQty div FPageLineStep;
  if (FRecordsQty mod FPageLineStep) <> 0
  then Inc(cnt);

  HasMore:= cnt > FPageLineLimit;
  if HasMore then begin
    if FFirstShowNo >= (FPageLineLimit * FPageLineStep) then begin
      { больше 10*10=100 }
      First10:= (FFirstShowNo div FPageLineStep) - 1;
      Last10:= FPageLineLimit + First10 - 1;
      if Last10 > cnt
      then Last10:= cnt;
    end else begin
      { 1-ая сотня }
      if FFirstShowNo >= (FPageLineStep * (FPageLineLimit - 1)) then begin
        { последняя десятка, сдвинуть на 10-20 }
        First10:= 2;
        Last10:= FPageLineLimit + 1;
      end else begin
        { не последняя десятка в первой сотне }
        First10:= 1;
        Last10:= FPageLineLimit;
      end;
    end;
  end else begin
    First10:= 1;
    Last10:= cnt;
  end;

  with WebDispatcher0.Request do begin
    if MethodType = mtPost
    then get_query:= query + Content
    else get_query:= query;
    DelFirstLastUrl(ExtractUnixDosFileName(PathsList[fpCurrFamily]), get_query);
  end;

  Result:= FPageLineStart;
  for i:= First10 to Last10 do begin
    st0:= (i - 1) * FPageLineStep + 1;
    st1:= i * FPageLineStep;
    if (FFirstShowNo + 1 >= st0) and (FFirstShowNo + 1 <= st1)
    then FormatString:= @FPageLineActive
    else FormatString:= @FPageLineInactive;
    with WebDispatcher0.Request do begin
      if (Length(host) <= 0) or (host = '/') then begin
        S:= scriptname + pathinfo + '?' + get_query +
        '&'+util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.first=' + IntToStr(st0) +
        '&'+util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.last=' + IntToStr(st1);
      end else begin
        S:= 'http://' + host + scriptname + pathinfo + '?' + get_query +
          '&'+util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.first=' + IntToStr(st0) +
          '&'+util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.last=' + IntToStr(st1);
      end;
    end; { with }
    Result:= Result + Format(FormatString^, [S, st0, st1]);
    if i < cnt
    then Result:= Result + FPageLineDelimiter;
  end;
  Result:= Result + FPageLineFinish;
end;

{ вызывается при разборе тега <#A name=sys value=>
  и возвращает всякие параметры
}
function TWebModule1.TagSystemOption(TagString: String; OtherTags: TStrings): String;
var
  ind: Integer;
  HFld: TFLD;
  MailAddress,
  From, FromName,
  MailSubj,
  MailBanner,
  TagUp: String;
  fldExists: Boolean;
begin
  Result:= '';
  TagUp:= ANSIUpperCase(TagString);
  ind:= -1;
  if TagUp = 'STATUS'
  then ind:= fpStatus;
  if TagUp = 'BANNER'
  then ind:= fpBanner;
  if TagUp = 'SCRIPT'
  then ind:= fpScript;
  if TagUp = 'PATTERNPATH'
  then ind:= fpPatternPath;
  if TagUp = 'ECCNAME'
  then ind:= fpEccPath;
  if TagUp = 'CONTENT-TYPE'
  then ind:= fpContentType;

  if ind > -1 then begin
    if Length(OtherTags.Values['newvalue'])>0 then begin
      PathsList[ind]:= OtherTags.Values['newvalue'];
      Result:= '';
    end else begin
      Result:= PathsList[ind];
    end;
  end else begin
    if TagUp = 'OPTMKNULL'
    then Result:= Bool2Checked(optMkNull in Options);  // "Checked" or empty string
    if TagUp = 'OPTIONHTML'
    then Result:= Bool2Checked(2 in Options); // "Checked" or empty string
    if TagUp = 'ECCXLAT'
    then Result:= xlatName;
    { qty of all found entries in all families }
    if TagUp = 'FIRSTNO'
    then Result:= IntToStr(FFirstShowNo);
    if TagUp = 'LASTNO'
    then Result:= IntToStr(FLastShowNo);
    if TagUp = 'TODAY'
    then Result:= DateToStr(Now);
    if TagUp = 'NOW'
    then Result:= DateTimeToStr(Now);
    if TagUp = 'TIME'
    then Result:= TimeToStr(Now);
    { количество отобранных записей последним select'ом }
    if TagUp = 'QTY'
    then Result:= IntToStr(CalcRecordsQty);
    if TagUp = 'MAXTHREADS'
    then Result:= IntToStr(Application.MaxConnections);
    if TagUp = 'ACTIVETHREADS'
    then Result:= IntToStr(Application.ActiveCount);
    if TagUp = 'INACTIVETHREADS'
    then Result:= IntToStr(Application.InactiveCount);
    if TagUp = 'CACHECONNECTIONS'
    then Result:= Bool2Checked(Application.CacheConnections);
    if TagUp = 'QUERIES'
    then Result:= IntToStr(FQueryCount);
    { page line }
    if TagUp = 'PAGELINE'
    then Result:= MkPageLine;
    if TagUp = 'PAGELINELIMIT'
    then Result:= IntTostr(FPageLineLimit);
    if TagUp = 'PAGELINESTEP'
    then Result:= IntTostr(FDefPageLineStep);

    if (TagUp = 'PWD') and (Fhashed = 2) then begin
      { вычислить пароль }
      PathsList[fpHash]:= OtherTags.Values['hash'];
      PathsList[fpPwd]:= CalcHashAccount(PathsList[fpHashUniqueID], PathsList[fpHash]);
      { вернуть }
      Result:= PathsList[fpPwd];
    end;

    { отправить сообщение почтой по указанному адресу }
    if (TagUp = 'MAIL') then begin
      Fmailcharset:= OtherTags.Values['charset'];
      if Fmailcharset = ''
      then Fmailcharset:= 'win-1251';
      { body-- }
      { body сначала искать в переданных параметрах }
      FMailBody:= QFld[OtherTags.Values['body']];
      { body пытаться загрузить как файл }
      try
        FMailBody:= LoadCacheString(Alias2FileName(FMailBody));
      except
        FMailBody:= 'Mail robot internal error: can''t load '+ OtherTags.Values['body'];
      end;
      if FMailBody = ''
      then FMailBody:= QFld[OtherTags.Values['body']]; { если нет то как есть }
      { --body }
      { присоединить банер. Сначала из файла template, затем, если нет, как есть }
      MailBanner:= OtherTags.Values['banner'];
      try
        MailBanner:= LoadCacheString(Alias2FileName(MailBanner));
      except
      end;
      if MailBanner = '' then begin
        MailBanner:= OtherTags.Values['banner'];
      end;
      FMailBody:= MailBanner + FMailBody;
      { subj сначала искать в поле таблицы }
      MailSubj:= OtherTags.Values['subj'];
      if (MailSubj <> '') then begin
{$IFDEF USE_IB}
        ind:= Query0.FieldIndex[MailSubj];
        fldExists:= ind >= 0;
{$ELSE}
        fldExists:= Query0.FieldDefs.IndexOf(MailSubj) >= 0;
{$ENDIF}
        if fldExists then begin
          try
{$IFDEF USE_IB}
            HFld:= Query0.Fields[ind];
{$ELSE}
            HFld:= Query0.FindField(MailSubj);
{$ENDIF}
            if (HFld <> Nil) and (not HFld.IsNull) then begin
              MailSubj:= HFld.AsString;
            end;
          except
            MailSubj:= 'Рассылка';
          end;
        end;
      end;
      if (Pos('=?', MailSubj) <> 1) and (IsExtendedASCII(MailSubj)) then begin
        MailSubj:= '=?Windows-1251?Q?' + MailSubj + '?=';
      end;
      { address сначала искать в поле таблицы }
      MailAddress:= OtherTags.Values['address'];
{$IFDEF USE_IB}
      ind:= Query0.FieldIndex[MailAddress];
      fldExists:= ind >= 0;
{$ELSE}
      fldExists:= Query0.FieldDefs.IndexOf(MailAddress) >= 0;
{$ENDIF}
      if (MailAddress <> '') and fldExists then begin
        try
{$IFDEF USE_IB}
          HFld:= Query0.Fields[ind];
{$ELSE}
          HFld:= Query0.FindField(MailAddress);
{$ENDIF}
          if (HFld <> Nil) and (not HFld.IsNull) then begin
            MailAddress:= HFld.AsString;
          end;
        except
          MailAddress:= '';
        end;
      end;
      if (Pos('=?', MailAddress) <> 1 ) and (IsExtendedASCII(MailAddress)) then begin
        MailAddress:= '=?Windows-1251?Q?' + MailAddress + '?=';
      end;
      { from сначала искать в поле таблицы }
      From:= OtherTags.Values['from'];
      if (From <> '') then begin
{$IFDEF USE_IB}
        ind:= Query0.FieldIndex[From];
        fldExists:= ind >= 0;
{$ELSE}
        fldExists:= Query0.FieldDefs.IndexOf(From) >= 0;
{$ENDIF}
        if fldExists then begin
          try
{$IFDEF USE_IB}
            HFld:= Query0.Fields[ind];
{$ELSE}
            HFld:= Query0.FindField(From);
{$ENDIF}
            if (HFld <> Nil) and (not HFld.IsNull) then begin
              From:= HFld.AsString;
            end;
          except
            From:= '';
          end;
        end;
      end;
      { fromname сначала искать в поле таблицы }
      FromName:= OtherTags.Values['fromname'];
      if (FromName <> '') then begin
{$IFDEF USE_IB}
        ind:= Query0.FieldIndex[FromName];
        fldExists:= ind >= 0;
{$ELSE}
        fldExists:= Query0.FieldDefs.IndexOf(FromName) >= 0;
{$ENDIF}
        if fldExists then begin
          try
{$IFDEF USE_IB}
            HFld:= Query0.Fields[ind];
{$ELSE}
            HFld:= Query0.FindField(FromName);
{$ENDIF}
            if (HFld <> Nil) and (not HFld.IsNull) then begin
              FromName:= HFld.AsString;
            end;
          except
            FromName:= '';
          end;
        end;
      end;
      if (Pos('=?', FromName) <> 1 ) and (IsExtendedASCII(FromName)) then begin
        FromName:= '=?Windows-1251?Q?' + FromName + '?=';
      end;

      Result:= SendEMail(OtherTags.Values['host'],
        OtherTags.Values['port'],
        OtherTags.Values['userid'],
        OtherTags.Values['timeout'],
        From,
        FromName,
        OtherTags.Values['mime'],
        MailSubj, FMailBody, MailAddress, NMSMTP0, PgProdMailTag,
        PathsList[fpPatternPath],
        OtherTags.Values['ok'], OtherTags.Values['fail']);
    end;
  end;
end;

procedure TWebModule1.PgProdInfoHTMLTag(Sender: TObject; Tag: TTag;
  const TagString: String; TagParams: TStrings; var ReplaceText: String);
begin
  ReplaceText:= TagSystemOption(TagString, TagParams);
  { no ip equiv. }
end;

{
procedure TWebModule1.SetSmth(ANewValue: Integer);
begin
  EnterCriticalSection(CriticalSection);
  LeaveCriticalSection(CriticalSection);
end;
}

procedure TWebModule1.WebModuleBeforeDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  PathsList[fpStatus]:= '';
  PathsList[fpCurrFamily]:= '';
  PathsList[fpContentType]:= 'text/html';
  FCurRequest:= Request;
  with FLogStruc do begin
    LogStamp(FLogStruc, logstampT0);
    remoteIP:= Request.RemoteAddr;// inet_addr(PChar(Request.RemoteAddr)); // convert to ip
    { хост...алиас,имя,парольБД,форма,семейство,действие }
    lst:= Request.Host + #9;
  end;
  Inc(FQueryCount);
end;

{ удаляет из Response лишние пробелы и CRLF
  для повышения скорости передачи.
  Для отладки лучше отключить (как после mangler- ничего будет не прочитать)
}
function Delete_Controls(const S: String): String;
var
  i, L: Integer;
begin
  Result:= S;
  L:= Length(S);
  i:= 1;
  while (i <= L) do begin
    if (Result[i] <= #32) and (i+1 <=L) and (Result[i+1] <= #32) then begin
      Result[i]:= #32;  { единообразно заменить 2 упр. символа на пробелы }
      Delete(Result, i+1, 1);
      Dec(L);      { нельзя переходить дальше- вдруг несколько пробелов подряд}
    end else Inc(i);
  end;
end;

procedure TWebModule1.WebModuleAfterDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  if FFullContent <> Nil then begin
    FFullContent.Free;
    FFullContent:= Nil;
  end;
  LogStamp(FLogStruc, logstampDT);
  if FpushCount = 1 then begin
    Response.ContentType:= 'multipart/x-mixed-replace; boundary=' + PUSHBOUNDARY;
  end else begin
    Response.ContentType:= PathsList[fpContentType];  // default value 'text/html'
  end;
  if PathsList[fpExpiresMinutes] <> '-1' then begin
    Response.LastModified:= Now;
    Response.Expires:= GetExpires;
  end;
  with Response do begin
    { оптимизация - замена двух и более повторяющихся управляющих символов на 1 пробел }
    if FOptimizeDoc
    then Content:= Delete_Controls(Content);
    if Length(Content) = 0
    then Content:= PathsList[fpNullContent];
    Server:= PathsList[fpBanner];
    { указать текушую кодовую страницу и поддерживаемые кодовые страницы }
{$IFDEF USE_IB}
    Title:= 'is2sql.dll, '+SHORTCOPYRIGHT+' Interbase rel., CP: ' + xlatname;
{$ELSE}
    Title:= 'is2sql.dll, '+SHORTCOPYRIGHT+' BDE rel., CP: ' + xlatname;
{$ENDIF}
    { add header loaded from registry }
    CustomHeaders:= FResponseCustomHeaders;
    { show available codepages xlat tables }
    CustomHeaders.Add('CPs=' + FxlatNames.CommaText);
    { indicate is any error exists }
    if Length(PathsList[fpStatus]) > 0 then begin
      // CustomHeaders.Add('Error=' + Copy(PathsList[fpStatus], 1, 255));
      CustomHeaders.Add('Error=1');
    end;
  end;
  if Assigned(FLogFuncs.LogFunc)
  then FLogFuncs.LogFunc(FLogStruc);
end;

procedure TWebModule1.NMSMTP1SendStart(Sender: TObject);
begin
  CheckMailHeader(Fmailcharset, '', NMSMTP0.FinalHeader);
end;

procedure TWebModule1.PgProdMailTag(Sender: TObject; Tag: TTag;
  const TagString: String; TagParams: TStrings; var ReplaceText: String);
var
  TagUp, FldName, mdf: String;
  HFld: TFLD;
  fldExists: Boolean;
{$IFDEF USE_IB}
  ind: Integer;
{$ENDIF}
begin
  TagUp:= ANSIUpperCase(TagString);
  if Length(TagUp) <=0 then begin
    Exit;
  end;
  if Length(TagUp) = 1 then begin
  case TagUp[1] of
  'F':begin
        FldName:= NoQuotes(TagParams.Values['NAME']);
        if (FldName <> '') then begin
{$IFDEF USE_IB}
          ind:= Query0.FieldIndex[FldName];
          fldExists:= ind >= 0;
{$ELSE}
          fldExists:= Query0.FieldDefs.IndexOf(FldName) >= 0;
{$ENDIF}
          if fldExists then begin
            try
              mdf:= NoQuotes(TagParams.Values['fmt']);
{$IFDEF USE_IB}
              HFld:= Query0.Fields[ind];
{$ELSE}
              HFld:= Query0.FindField(FldName);
{$ENDIF}
              if (HFld <> Nil) then begin
                if (not HFld.IsNull) then begin
                  if ANSICompareText('currency', mdf) = 0 then begin
                    ReplaceText:= cyrmoney(HFld.AsCurrency);
                  end else begin
                    if ANSICompareText('money', mdf) = 0 then begin
                      ReplaceText:= MoneyStr(HFld.AsCurrency, FCurrencySimple);
                    end else begin
                      if ANSICompareText('hash', mdf) = 0 then begin
                        if Fhashed = 2 then begin
                          PathsList[fpHash]:= HFld.AsString;
                          PathsList[fpPwd]:= CalcHashAccount(PathsList[fpHashUniqueID], PathsList[fpHash]);
                          ReplaceText:= PathsList[fpPwd];
                        end else begin
                          ReplaceText:= 'Неверный_пароль_администратора';
                        end;
                      end else begin
                        if ANSICompareText('datetime', mdf) = 0 then begin
                          ReplaceText:= FormatDateTime(NoQuotes(TagParams.Values['specifier']), HFld.AsDateTime);
                        end else begin
                          if ANSICompareText('external', mdf) = 0 then begin
                            ReplaceText:= FormatBlobByDLL(NoQuotes(TagParams.Values['dll']),
                              NoQuotes(TagParams.Values['func']),
                              NoQuotes(TagParams.Values['specifier']), HFld);
                          end else begin
                            ReplaceText:= HFld.AsString;
                          end;
                        end;
                      end;
                    end;
                  end;
                end else begin
                  if ANSICompareText('currency', mdf) = 0 then begin
                    ReplaceText:= 'ноль рублей 00 копеек';
                  end else begin
                    if ANSICompareText('money', mdf) = 0 then begin
                      ReplaceText:= MoneyStr(0, FCurrencySimple);
                    end else begin
                      ReplaceText:= '';
                    end;
                  end;
                end;
              end;
            except
              ReplaceText:= 'Значение нельзя привести к строковому представлению';
            end;
            mdf:= NoQuotes(TagParams.Values['http']);
            if ANSICompareText('encode', mdf) = 0
            then ReplaceText:= HTTPEncode(ReplaceText);
            mdf:= NoQuotes(TagParams.Values['copy']);
            if mdf <> ''
            then QFlds.Values[TagParams.Values['copy']]:= ReplaceText;
          end;
        end;
      end;
    end;
  end;
end;

function TWebModule1.LoadRecFldSelect(AFld: String; ARecNo: Integer; ADecode: String): String;
{$IFDEF USE_IB}
var
  i: Integer;
{$ENDIF}
begin
  Result:= '';
  { AfamilyName и familyName не пустые- нет смысла проверять }
  if not LoadExec then begin
    Result:= Result + MkErrStringIcon('select sql ' + PathsList[fpCurrFamily] + ' not found');
    Exit;
  end;
  // Query0.Close;
  if ParseSqlPar(Query0) then begin  { параметры переданы, выполнить запрос }
    try
{$IFDEF USE_IB}
      with Transaction0 do begin
        Active:= True;
      end;
      Query0.ExecQuery;
{$ELSE}
      Query0.Open;
{$ENDIF}
    except
      on E: Exception do begin
        ProcessDBError(E);
        PathsList[fpStatus]:= E.Message;
        Result:= Result + MkErrStringIcon('sql error [' + Query0.Sql.Text + ']');
      end;
    end;
    try
{$IFDEF USE_IB}
      if Query0.Open then begin
        for i:= 1 to ARecNo do begin
          Query0.Next;  // 0..
        end;
{$ELSE}
      if Query0.Active then begin
        Query0.MoveBy(ARecNo);
{$ENDIF}
      end else begin
        Result:= Result +  MkErrStringIcon('No record '+ IntToStr(ARecNo)+' found');
      end;
    except
      on E: Exception do begin
        ProcessDBError(E);
        PathsList[fpStatus]:= E.Message;
        Result:= Result +  MkErrStringIcon(' one record sql ['+ Query0.Sql.Text +']');
      end;
    end;
  end;
  try
    if (Length(AFld) = 0) then begin
{$IFDEF USE_IB}
      try
        AFld:= Query0.Fields[0].Name;
      except
      end;
{$ELSE}
      if (Query0.FieldCount > 0) then begin
        AFld:= Query0.Fields[0].FieldName;
      end;
{$ENDIF}
    end;
    Result:= Query0.FieldByName(AFld).AsString;
    // decode field if required
    if Length(ADecode) > 0 then begin
      case ADecode[1] of
      '1', 'Z', 'z': Result:= zDownLoad.DecompressString(1, Result);
      else begin
        // Result:= Result;
      end;
      end;
    end;
  except
    Result:= Result + MkErrStringIcon('1 record, No field  '+  AFld + ' exists');
  end;
  Query0.Close;
end;

{/rec?dbs&user&key&cp&qry[&param=..][&rec][&fld][&decode=z][&content-type=]
  читает одно поле из одной записи [0..] запроса qry
}
procedure TWebModule1.WebModule1actRecAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  i: Integer;
  s, cdbs, cuser, ckey: String;
  cvrt: Boolean;
begin
  Response.Content:= '';
  { search query }
  // PathsList[fpCurrFamily]:= '';
  Handled:= True;
  { установить нужную перекодировочную таблицу по cp }
  { ! НА Web сервере хранятся CP1251 }
  s:= QFld['cp'];   { }
  cvrt:= (s <> '') and (FxlatDefs <> Nil) and SetxlatByName(s);
  { ! перекодировать параметры браузера в CP1251 }
  if cvrt then begin
    for i:= 0 to QFlds.Count - 1 do begin
      s:= QFlds[i];
      strxlat(xlat256^, s);
      QFlds[i]:= s;
    end;
  end;
  { get user&key parameters }
  cdbs:= QFld['dbs'];
  cuser:= QFld['user'];
  ckey:= QFld['key'];
  { if user&key does not specified, use default values }
  if cdbs  = '' then cdbs := PathsList[fpDbs];
  if cuser = '' then cuser:= PathsList[fpUser];
  if ckey  = '' then ckey := PathsList[fpKey];
  with FLogStruc do begin
    { хост..алиас,имя,парольБД,форма,семейство...действие }
    lst:= lst + cdbs + #9 + cuser + #9 + ckey + #9 + QFld['form'] + #9;
    empno:= StrToIntDef(QFld['empno'], -1);
  end;
  { validate database name, user&key }
{}
  if IsThreadDbConnected(cdbs, cuser, ckey)
  then begin
    { nothing to do }
  end else begin
    { set up database name, user&key }
    with Database0 do begin
      Close;
      try
        // IB: this statement set Collate Code Page database parameter to appropriate value too
        DbAliasname:= cdbs;
        DbUserName:= cuser;
        DbUserPassword:= ckey;
        Open;
      except
        on E: Exception do begin
          PathsList[fpStatus]:= E.Message;
        end;
      end;
      if Connected then begin
        { nothing to do }
      end else begin
        FLogStruc.lst:= FLogStruc.lst + 'user ' + cuser + ' connect database ' + cdbs + ' failure';
        Response.Content:= Response.Content+Format(PathsList[fpStatus] + ' Invalid user name (%s)'+
          ', password or database alias (%s)'+SERRE, [cuser, cdbs]);
        Exit;
      end;
    end;
  end;
  PathsList[fpCurrFamily]:= NoQuotes(QFld['qry']);
  { select clause }
  Response.Content:= LoadRecFldSelect(NoQuotes(QFld['fld']), StrToIntDef(NoQuotes(QFld['rec']), 0), NoQuotes(QFld['decode']));
  if cvrt then begin
    s:= Response.Content;
    strxlat(xlat256_1, s);
    Response.Content:= s;
  end;
  if Length(QFld['Content-Type']) > 0
  then PathsList[fpContentType]:= QFld['Content-Type'];
  { store returned text length to log }
  FLogStruc.len:= Length(Response.Content);
end;

{ return true if user is not permitted to load form
  Called from <#r name=family gid=group [form=accessdeniedform_url] [encode=0|1] [code=1|0]>
  default code=1 (access granted if sql statement returns 1 or greater)
  code=0- access granted if sql statement returns 0 or less)
  (user identifier AUID and user password AUKEY passed thru form parameters)
  encode 0 - password stored in table as is
         1 - password encoded. HashUniqueID prefix does not used in de/encoding (default)
  if password encoded, AEncode converts into hash string for comparison.
  SELECT sql clause must return one field encoded(or not) password.
  SQL parameters must be :GID :UID :UKEY
  IsAccessDenied() take first returned field in first record and try convert it
  into integer. If fails or zero returns, access denied and function returns True.
  If 1st field in 1st record contains value greater than zero, access granted and
  function returns False.
}
function TWebModule1.IsAccessDenied(Tags: TStrings): Boolean;
var
  FSqlFN, FFld, DecodedPwd: String;
  code, AEncode: Integer;
begin
  AEncode:= StrToIntDef(NoQuotes(Tags.Values['encode']), 1);
  code:= StrToIntDef(NoQuotes(Tags.Values['code']), 1);
  PathsList[fpStatus]:= '';
  FSqlFN:= ReplaceExt('.sql', Alias2FileName(PathsList[fpCurrFamily]));
  { load forms }
  FSql:= LoadCacheString(FSqlFN);
  Result:= True; { fail }
  if FSQL = '' then begin
    PathsList[fpStatus]:= 'No sql ' + PathsList[fpCurrFamily] + ' found';
    Exit;
  end;
  try
{$IFDEF USE_IB}
    if Query0.Open
    then Query0.Close;
{$ELSE}
    if Query0.Active
    then Query0.Close;
{$ENDIF}
  except
  end;
  if AEncode = 1 then begin
    DecodedPwd:= CalcHashAccount(PathsList[fpHashUniqueID], QFld['ukey']);
    repeat until util1.ReplaceStr(FSql, False, ':UPWD', DecodedPwd);
  end;
   ParseSqlPar(Query0);
  try
{$IFDEF USE_IB}
    Transaction0.Active:= True;
    Query0.ExecQuery;
    FFld:= Query0.Fields[0].Name;  // just call for except
{$ELSE}
    Query0.Open;
    if (Query0.FieldCount <= 0) then begin
      PathsList[fpStatus]:= 'SQL does not return any field';
      Query0.Close;
      Exit;
    end;
    FFld:= Query0.Fields[0].FieldName;
{$ENDIF}
    if code > 0
    then Result:= not (Query0.FieldByName(FFld).AsInteger > 0)  { False- ok }
    else Result:= not (Query0.FieldByName(FFld).AsInteger <= 0);{ code = 0 }
    if Result
    then PathsList[fpStatus]:= Format('Access to this page is restricted by %s',
      [PathsList[fpCurrFamily]]);
    Query0.Close;
  except
    on E: Exception do begin
      ProcessDBError(E);
{$IFDEF USE_IB}
      if Query0.Open
{$ELSE}
      if Query0.Active
{$ENDIF}
      then Query0.Close;
      Result:= True; { deny access if sql or database fault }
      PathsList[fpStatus]:= 'Access denied with sql error: '+E.Message;
      Exit;
    end;
  end;
end;

function TWebModule1.PrepareRegularSql(const AStr: String; ARegularExprList: TStrings): String;
var
  i: Integer;
  par: Boolean;
  curpar, vl: String;

function DoPar: String;
var
  S: String;
begin
  Result:= QFld[util1.ExtractUnixDosFileName(PathsList[fpCurrFamily])+'.'+curpar];
  if Result = ''
  then Result:= QFld[curpar];
  if (Length(Result) = 0) and (Length(curpar) > 0) and (curpar[1]='$') then begin
    S:= Copy(curpar, 2, MaxInt);
    Result:= TagSystemOption(S, SLAlias);
    if Result = ''
    then Result:= TagIPOption(S, FCurRequest, SLAlias);
  end;
  if Assigned(ARegularExprList)
  then Result:= ReplRegular(curpar, ARegularExprList, Result);
end;

begin
  if Pos(':', AStr)<=0 then begin
    Result:= AStr;
    Exit;
  end;
  Result:= '';
  i:= 1;
  par:= False;
  curpar:= '';
  // quote:= false; { just for disable compiler warning }
  { поставить сторож на случай если параметр в самом конце AStr: "WHERE 12=:PAR"}
  vl:= AStr+#32;
  while i <= Length(vl) do begin
    case vl[i] of
    ':':
      begin
        { insert parameter }
        if par then begin
          if (curpar = '') then begin { mask parameter prefix '::' => ':' }
            Result:= Result + ':';
            par:= False;
          end else Result:= Result + DoPar();
        end else begin
          curpar:= '';
          par:= true;
        end;
        // quote:= (i > 1) and (vl[i-1] in ['''', '"']);
      end;
    else
      begin
        if par and (vl[i] in PARAMETER_NAME_CHARSET) then begin
          curpar:= curpar + vl[i];
        end else begin
          if par then begin
            Result:= Result + DoPar();
            par:= false;
          end;
          Result:= Result + vl[i];
          curpar:= '';
        end;
      end;
    end;
    Inc(i);
  end;
  Delete(Result, Length(Result), 1);
end;

{
function TWebModule1.GetExtensionVersion(var Ver: THSE_VERSION_INFO): BOOL;
var
  Title: String;
begin
  Title:= 'is2sql database gateway';
  try
    Ver.dwExtensionVersion := MakeLong(HSE_VERSION_MINOR, HSE_VERSION_MAJOR);
    StrLCopy(Ver.lpszExtensionDesc, PChar(Title), HSE_MAX_EXT_DLL_NAME_LEN);
    Result := BOOL(1); // This is so that the Apache web server will know what "True" really is
  except
    Result := False;
  end;
end;
}

initialization
  // InitializeCriticalSection(CriticalSection);
  FQueryCount:= 0;

finalization
  // DeleteCriticalSection(CriticalSection);

end.



