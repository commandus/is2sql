unit FileMsk;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDlgMaskFile = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    CBFileMask: TComboBox;
    Memo1: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgMaskFile: TDlgMaskFile;

implementation

{$R *.DFM}

end.
