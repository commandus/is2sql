library fmtiso2709;
(*******************************************************************
*                                                                 *
*   f  m  t  i  s  o  2  7  0  9                                   *
*   formatting DLL for marc records stored in database's table    *
*   Copyright (c) 2000, A.Ivanov. All rights reserved.             *
*   Part of is2sql.dll, demo DLL                                  *
*     function bytemplate(AData, Aspecifier: PChar; ABuf: PChar;   *
*     ABufLen: Integer): Boolean; stdcall;                        *
*   <#f name=.. fmt=external dll=fmtiso2709 func=bytemplate        *
*     specifier=FILENAME>                                         *
*   filename= path of template file, example:                      *
*      c:\bibliography_template.htm or template_in_dll_folder or  *
*      /templ_alias/file.txt (web server alias or /Virtual Roots   *
*      template file contain tags like <~XXXx[|...%s...]>, e.g.   *
*      Title:   <~245a>                                            *
*      Authors: <~100> or <~100ac-g>                              *
*      <~090| delimiter text instead semicolon >                   *
*   Created:       Jun 08 2000                                    *
*   Last Revision: Jun 29 2000                                     *
*   Last fix     :        2000                                    *
*   Files: bib01.htm template file                                 *
*   Lines        :                                                *
*   History      :                                                 *
*   Printed      : ---                                            *
*                                                                  *
*                                                                 *
********************************************************************)
(*##*)
{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }
{$R *.RES}
uses
  SysUtils, Classes, Registry, Windows,
  Marc, util1;

const
  LNVERSION = '1.0';
  RGPATH = 'Software\ensen\is2sql\'+ LNVERSION;
  RGW2SVCALIAS = '\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\Virtual Roots';

var
  SaveExit: Pointer;
  SLAlias: TStringList;
  DllPath: String;

procedure ValidateW3SvcColon(AVirtualRoots: TStringList);
var
  i, L: Integer;
  S: String;
begin
  for i:= 0 to AVirtualRoots.Count - 1 do begin
    repeat
      S:= AVirtualRoots.Names[i];
      L:= Length(S);
      if (L < 0) or (not(S[L] in [#32, ',']))
      then Break;
      S:= AVirtualRoots[i];
      Delete(S, L, 1);
      AVirtualRoots[i]:= S;
    until False;
  end;
end;

function bytemplate(AData, Aspecifier: PChar; ABuf: PChar; ABufLen: Integer): Boolean; stdcall;
var
  S: String;
  HtmlForm: String;
begin
  HtmlForm:= util1.File2String(util1.ConcatAliasPath(SLAlias, DllPath, ASpecifier));
  Bib2HTML(AData^, HtmlForm, S);
  StrPLCopy(ABuf, S, ABufLen);
  Result:= True;
end;

procedure LibExit;
begin
  SLAlias.Free;
  ExitProc:= SaveExit;  // restore exit procedure chain
end;

procedure Init;
var
  FN: array[0..MAX_PATH - 1] of Char;
begin
  SaveExit:= ExitProc;  // save exit procedure chain
  ExitProc:= @LibExit;  // install LibExit exit procedure
  SetString(DllPath, FN, GetModuleFileName(hInstance, FN, SizeOf(FN)));
  DllPath:= ExtractFilePath(DllPath);

  SLAlias:= TStringList.Create;
  util1.AddEntireKey(RGPATH+'\Virtual Roots', SLAlias);
  util1.AddEntireKey(RGW2SVCALIAS, SLAlias);
  ValidateW3SvcColon(SLAlias);
end;

exports
  bytemplate index 1 name 'bytemplate';

begin
  Init;
end.
