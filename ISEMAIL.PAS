unit isemail;
(*##*)
(*******************************************************************
*                                                                 *
*   I  S  E  M  A  I  L     IS2SQL email routines                  *
*                                                                 *
*   Copyright (c) 1999, А. Иванов                                  *
*   вспомогательные функции                                       *
*   Part of IS2SQL                                                 *
*                                                                 *
*   for more information see readme.txt                            *
*                                                                 *
*   Conditional defines:                                           *
*                                                                 *
*   Last Revision: Jan 18 1999                                     *
*   Last fix     : Jan 18 1999                                    *
*   Lines        :                                                 *
*   History      :                                                *
*   Printed      : ---                                             *
*                                                                 *
********************************************************************)
(*##*)


interface
uses
  Classes, SysUtils, NMSMTP, dbtables, httpApp, htmlprod,
{$IFDEF VER140}
    HTTPProd,
{$ENDIF}
  util1, isutil1;

{ отправляет сообщение через ANMSMTP. В ATags задаются все параметры:
  host, port, userid   -  идентифицирует smtp сервер
  from, to, subj - идентифицирует получателя
  form|body, mime - определяет тип mime (Plain, Html, Sgml, Enriched, Tabbed)
  timeout, ok, fail
  значения полей извлекаются парсером AHTMLTagEvent
}
function SendEMail(AHost, APort, AUserid, ATimeOut, AFrom, AFromName, AMimeTypeKind, ASubj,
  ABody, AEMail: String; ANMSMTP: TNMSMTP; AHTMLTagEvent: THTMLTagEvent;
  ADefaultPath, ADefaultOkResponse, ADefaultFailResponse: String): String;

function CheckMailHeader(ACharset: String; ATransferEncoding: String; AHeader: TStrings): Boolean;

implementation

const
  DEFSMTPTIMEOUT = 0;

function CheckMailHeader(ACharset: String; ATransferEncoding: String; AHeader: TStrings): Boolean;
var
  ind, i, p0, p1, p2: Integer;
  S: String;
begin
  Result:= True;
  if ACharset = #32 then begin
    { пробел- оставить как есть }
    Exit;
  end else begin
    ind:= -1;
    S:= 'Content-Type: ';
    for i:= 0 to AHeader.Count - 1 do begin
      if Pos('Content-Type', AHeader[i]) = 1 then begin
        ind:= i;
        S:= AHeader[i];
        Break;
      end;
    end;

    p0:= Pos('charset', S);
    p1:= PosFrom(p0+1, '=', S);
    p2:= PosFrom(p1+1, ';', S);
    if p2 = 0
    then p2:= Length(S)+1;
    if (p0 > 0) then begin
      Delete(S, p0, p2-p0);
    end else begin
      S:= '';
      p0:=1;
    end;
    Insert('charset=' + ACharset, S, p0);
    if ind > 0
    then AHeader[ind]:= S
    else AHeader.Add(S);
  end;
end;

{
procedure PgProdEMailHTMLTag(Sender: TObject; Tag: TTag; const TagString: string;
  TagParams: TStrings; var ReplaceText: string);
begin
end;
}
{ parse e-mail form }
function ParseEmailForm(AHTMLTagEvent: THTMLTagEvent; const AEmailForm: String): String;
var
  PgProdEmail: TEPageProducer;
begin
  PgProdEmail:= TEPageProducer.Create(Nil);
  PgProdEmail.HTMLDoc:= AEmailForm;
  PgProdEmail.OnHTMLTag:= AHtmlTagEvent;
  Result:= PgProdEmail.Content;
  PgProdEmail.Free;
end;

function SendEMail(AHost, APort, AUserid, ATimeOut, AFrom, AFromName,
  AMimeTypeKind, ASubj, ABody, AEMail: String;
  ANMSMTP: TNMSMTP; AHTMLTagEvent: THTMLTagEvent;
  ADefaultPath, ADefaultOkResponse, ADefaultFailResponse: String): String;
begin
  Result:= ADefaultOkResponse;
  try
  // if ANMSMTP.FConnected then
    ANMSMTP.Disconnect;
  except
  end;
  { установить соединение с smtp сервером }
  ANMSMTP.Host:= AHost;
  ANMSMTP.Port:= StrToIntDef(APort, 25);
  ANMSMTP.Userid:= AUserid;
  { тип mime по первым буквам Plain, Html, Sgml, Enriched, Tabbed }
  ANMSMTP.SubType:= mtPlain;
  if Length(AMimeTypeKind) > 0 then begin
    case Upcase(AMimeTypeKind[1]) of
    'H': ANMSMTP.SubType:= mtHTML;
    'S': ANMSMTP.SubType:= mtSGML;
    'E': ANMSMTP.SubType:= mtEnriched;
    'T': ANMSMTP.SubType:= mtTabSeperated;
    end;
  end;
  ANMSMTP.TimeOut:= StrToIntDef(ATimeout, DEFSMTPTIMEOUT);

  try
    ANMSMTP.Connect;
  except
    on E: Exception do begin
      { вернуть сообщение о сбое }
      Result:= ADefaultFailResponse;
      { если нет предопредленного ответа, вернуть описание ошибки }
      if Result = '' then begin
        Result:= 'Mail box connection fails: ' + E.Message +
        ' mail server:' + ANMSMTP.Host +
        ' mail port:' + IntToStr(ANMSMTP.Port) +
        ' mail userid:' + ANMSMTP.Userid +
        ' mime:' + AMimeTypeKind;
      end;
      Exit;
    end;
  end;

  ANMSMTP.ClearParameters;

  with ANMSMTP.PostMessage do begin
    FromAddress:= AFrom;
    if AFromName = ''
    then FromName:= 'Ensen''s e-mailer'
    else FromName:= AFromName;
    Subject:= ASubj;
    ToAddress.Clear;
    ToAddress.Add(AEMail);
    ToCarbonCopy.Clear;
    Attachments.Clear;
    LocalProgram:= 'Useful utilities. Ensen''s e-mail gateway';
    if ABody = '' then begin
      { не отправлять пустые сообщения }
      ANMSMTP.Disconnect;
      Exit;
    end;
    Attachments.Clear;
  end;

  { parse e-mail form }
  ANMSMTP.PostMessage.Body.Text:= ParseEmailForm(AHtmlTagEvent, ABody);
  try
    ANMSMTP.SendMail;
  except
    on E: Exception do begin
      { вернуть сообщение о сбое }
      Result:= ADefaultFailResponse;
      { если нет предопределенного ответа, вернуть описание ошибки }
      if Result = '' then begin
        Result:= 'Mail delivery error: ' + E.Message +
        ' mail server:' + ANMSMTP.Host +
        ' fromname:' + ANMSMTP.PostMessage.FromName +
        ' from:' + ANMSMTP.PostMessage.FromAddress +
        ' to:' + ANMSMTP.PostMessage.ToAddress.Text +
        ' timeout: ' + IntToStr(ANMSMTP.TimeOut);
      end;
      Exit;
    end;
  end;
  ANMSMTP.Disconnect;
end;

end.
