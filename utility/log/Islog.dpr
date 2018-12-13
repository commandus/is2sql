library islog;
(*##*)
(*******************************************************************
*                                                                 *
*   I  S  L  O  G           part of IS2SQL project                 *
*                                                                 *
*   Copyright (c) 1999, Андрей Иванов                              *
*   DLL для ведения журнала is2sql.dll                            *
*   Part of is2sql                                                 *
*                                                                 *
*   for more information see readme.txt                            *
*                                                                 *
*   Conditional defines:                                           *
*                                                                 *
*   Last Revision: Feb 22 1999                                     *
*   Last fix     : Feb 22 1999                                    *
*   Lines        :                                                 *
*   History      :                                                *
*   Printed      : ---                                             *
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

uses
  SysUtils, Classes, Windows,
  util1, isutil1, logmeter;

const
  MAX_PATH = 128;

var
  logfn: String[255] = '';
  SaveExit: Pointer;

function logstartfunc(ALogStart: TLogStart): Boolean; stdcall;
var
  S: String;
  FN: array[0..MAX_PATH - 1] of Char;
  F: TFileStream;
begin
  Result:= False;
  if util1.IsAbsolutePath(S) then begin
    logfn:= ALogStart.FN
  end else begin
    SetString(S, FN, GetModuleFileName(hInstance, FN, SizeOf(FN)));
    logfn:= ConcatPath(ExtractFilePath(S), ALogStart.FN, '\');
  end;
  if not FileExists(logfn) then begin
    try
      F:= TFileStream.Create(logfn, fmCreate);
      { remoteIP t0 dt len empno lst }
      S:= 'ip'#9#9'Date'#9#9'Time'#9#9#9'Duration'#9'Bytes'#9'emp no'#9'Host'#9'db'#9'user'#9'key'#9'form'#9'family'#9'Description'#13#10;
      F.Write(S[1], Length(S));
      F.Free;
    except
      Exit;
    end;
  end;
  Result:= True;
end;

{   remoteIP: String[4*4];имя журнала (файла журнала)
    t0,               начало по времени
    dt: TDateTime;    продолжительность
    len: Integer;     длина ответа, отправляемого клиенту
    empno: Integer;   номер сотрудника
    lst: String[128]; хост,алиас,имя,парольБД,форма,семейство,действие }
function logfunc(ALogP: TLogStruc): Boolean; stdcall;
var
  S: String;
  F: TFileStream;

  { put field delimiter}
  procedure Dlmt;
  begin
    S:= #9;
    F.Write(S[1], Length(S));
  end;

begin
  Result:= False;
  with ALogP do begin
    {}
    try
      F:= TFileStream.Create(logfn, fmOpenWrite + fmShareDenyNone);
    except
      Exit;
    end;
    try
      F.Seek(0, soFromEnd);
      S:= remoteIP;
      F.Write(S[1], Length(S));
      Dlmt;
      S:= DateTimeToStr(t0);
      F.Write(S[1], Length(S));
      Dlmt;
      S:= TimeToStr(dt);
      F.Write(S[1], Length(S));
      Dlmt;
      S:= IntToStr(len);
      F.Write(S[1], Length(S));
      Dlmt;
      F.Write(lst[1], Length(lst));
      S:= #13#10;
      F.Write(S[1], Length(S));
      {
      logevt.Text:= DateTimeToStr(t0);
      }
    finally
      F.Free;
    end;
  end;
  Result:= True;
end;

procedure LibExit;
begin
  // restore exit procedure chain
  ExitProc := SaveExit;
end;

exports
  logfunc index 1 name 'logfunc',
  logstartfunc index 2 name 'logstartfunc';

begin
  {..}
  // save exit procedure chain & install LibExit exit procedure
  // SaveExit:= ExitProc;
  // ExitProc:= @LibExit;
end.
