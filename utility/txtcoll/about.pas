unit About;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls,
  ShellApi;

type
  TAboutBox = class(TForm)
    OKButton: TButton;
    LMailto: TLabel;
    Copyright: TLabel;
    Version: TLabel;
    ProductName: TLabel;
    ProgramIcon: TImage;
    LHttp: TLabel;
    procedure LMailtoMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure LHttpMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure LMailtoClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.DFM}

procedure TAboutBox.LMailtoMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  (Sender as TLabel).Font.Style:= [fsBold, fsUnderline];
  Lhttp.Font.Style:= [fsUnderline];
end;

procedure TAboutBox.LHttpMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  (Sender as TLabel).Font.Style:= [fsBold, fsUnderline];
  LMailto.Font.Style:= [fsUnderline];
end;

procedure TAboutBox.LMailtoClick(Sender: TObject);
begin
  if ShellAPI.ShellExecute(Application.Handle, 'open',
    PChar((Sender as TLabel).Caption), '', '', SW_SHOWNORMAL) <=32 then begin
  end;
end;

procedure TAboutBox.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  LMailto.Font.Style:= [fsUnderline];
  LHttp.Font.Style:= [fsUnderline];
end;

end.
 
