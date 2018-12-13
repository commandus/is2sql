library is2sql; { program is2sql; } //  Set manually program/library clause !!!
(*##*)
(********************************************************************
*                                                                  *
*   I  S  2  S  Q  L   v. 1.11   ISAPI/NSAPI DLL                    *
*                                                                  *
*   Copyright (c) 1999, 2000, 2001 Andrei Ivanov                    *
*                                                                  *
*   Conditional defines: MKCGI USE_BDE|USE_IB|USE_NCOCI             *
*   Based on ldbndx, Sep 22 1998 revision                          *
*   Last Revision: Jan 18 1999                                      *
*   Last fix     : Oct 09 2001                                     *
*   Lines        : 67                                               *
*   History      :                                                 *
*   Printed      : ---                                              *
*                                                                  *
*********************************************************************)
{ To do:
  0. Set Project|Options|Directories/Conditionals|Conditional defines
     USE_BDE or USE_IB or USE_NCOCI (for use BDE, Interbase Express or Oracle NCOCI respectively)
  To compile standalone CGI .EXE script:
    1.MANUALLY type "program" clause.
    2.Choose Project|Option and set "MKCGI" condition define.
    3.Rebuild project (choose Project|Build)
    I'm not sure: change TWebModule to TDataModule in ebookcgi
  To compile NSAPI/ISAPI dll:
    1.MANUALLY type "library" clause.
    2.Choose Project|Option and clear "MKCGI" condition define.
    3.Rebuild project (choose Project|Build)

  To debug an dll, choose Run|Parameters and set your app's run par..s:
  Microsoft IIS server:
    Host Application: c:\winnt\system32\inetsrv\inetinfo.exe
    Run Parameters:   -e w3svc
  Personal Web Server:
    Host Application: C:\Program Files\WEBSVR\SYSTEM\Inetsw95.exe
    Run Parameters:   -w3svc
  Netscape webs:
  see "Debugging ISAPI and NSAPI applications" in Delphi help (too many steps)
  TestISAPI.dpr - simple utility calls ISAPI/NSAPI DLL (source included)
    Host Application: C:\Source\ISAPITest\testisapi.exe
    Run Parameters:
    Choose DLL file name
}
(*##*)

{%ToDo 'Is2sql.todo'}

uses
  Sysutils, Windows, ISAPI2,
  ISAPIApp,
  webbroker,
  fis2sql in 'fis2sql.pas' {WebModule1: TWebModule};

{$R *.RES}

{$IFDEF MKCGI}
{$APPTYPE CONSOLE}  // CGI application
{$ELSE}
function Is2sqlGetExtensionVersion(var Ver: THSE_VERSION_INFO): BOOL; stdcall;
var
  Title: String;
begin
  Title:= 'is2sql database gateway';
  try
    Ver.dwExtensionVersion := MakeLong(HSE_VERSION_MINOR, HSE_VERSION_MAJOR);
    StrLCopy(Ver.lpszExtensionDesc, PChar(Title), HSE_MAX_EXT_DLL_NAME_LEN);
    Result:= BOOL(1); // This is so that the Apache web server will know what "True" really is
  except
    Result:= False;
  end;
end;

exports
  Is2sqlGetExtensionVersion name 'GetExtensionVersion',
  // GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;
{$ENDIF}

begin
  Application.Initialize;
  Application.CreateForm(TWebModule1, WebModule1);
  Application.Run;
end.
