unit dlgRelace;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDlgReplaceWord = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Label1: TLabel;
    Label2: TLabel;
    ESearchWord: TEdit;
    EReplaceWord: TEdit;
    CheckBox1: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgReplaceWord: TDlgReplaceWord;

implementation

{$R *.DFM}

end.
