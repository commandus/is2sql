program etxtcoll;

uses
  Forms,
  formedit in 'formedit.pas' {Form1},
  rename in 'rename.pas' {DlgRename},
  About in 'About.pas' {AboutBox},
  FileMsk in 'FileMsk.pas' {DlgMaskFile},
  dlgRelace in 'dlgRelace.pas' {DlgReplaceWord};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Редактор коллекций текстов';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDlgRename, DlgRename);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TDlgMaskFile, DlgMaskFile);
  Application.CreateForm(TDlgReplaceWord, DlgReplaceWord);
  Application.Run;
end.
