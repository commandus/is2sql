unit rename;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDlgRename = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    LOldFile: TLabel;
    ENewFile: TEdit;
    Label2: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgRename: TDlgRename;

implementation

{$R *.DFM}

end.
