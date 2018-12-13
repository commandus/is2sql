unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    EUser: TEdit;
    EPassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    CBApp: TComboBox;
    Label3: TLabel;
    ComboBox1: TComboBox;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FToken: THandle;
    function LogonApp: Boolean;
    function ExecuteApp: Integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

function TForm1.LogonApp: Boolean;
var
  UserName, Domain, Password: String;
  LogonType,
  LogonProvider: Cardinal;
begin
  UserName:= EUser.Text;
  Domain:= '';
  Password:= EPassword.Text;
  LogonType:= LOGON32_LOGON_INTERACTIVE;
  LogonProvider:= 0;
  Result:= LogonUser(PChar(UserName), PChar(Domain), PChar(Password),
    LogonType, LogonProvider, FToken) <> 0;
end;

function TForm1.ExecuteApp: Integer;
begin
  LogonApp;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ExecuteApp;
end;

end.
