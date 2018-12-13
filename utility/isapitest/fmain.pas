unit fmain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, ClipBrd,
  util1, utilisapi, filecoll;

type
  TForm1 = class(TForm)
    PageControlQuery: TPageControl;
    TSQueryParam: TTabSheet;
    PanelDLL: TPanel;
    CBDll: TComboBox;
    CBPathInfo: TComboBox;
    CBMethod: TComboBox;
    PageControlAnswer: TPageControl;
    TSResultHTML: TTabSheet;
    MemoResult: TMemo;
    TSFileEditor: TTabSheet;
    MemoFileEdit: TMemo;
    PanelFileEditor: TPanel;
    BSaveFile: TButton;
    MPar: TMemo;
    PanelQuery: TPanel;
    CBColl: TComboBox;
    BStoreNew: TButton;
    BRename: TButton;
    BGo: TButton;
    BCall: TButton;
    BVersion: TButton;
    TSServerVars: TTabSheet;
    MemoServerVars: TMemo;
    Splitter1: TSplitter;
    procedure BCallClick(Sender: TObject);
    procedure BVersionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MResultChange(Sender: TObject);
    procedure BGoClick(Sender: TObject);
    procedure BStoreNewClick(Sender: TObject);
    procedure BRenameClick(Sender: TObject);
    procedure PageControlAnswerChanging(Sender: TObject;
      var AllowChange: Boolean);
    procedure BEditSaveClick(Sender: TObject);
    procedure CBCollKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CBDllKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PageControlQueryChanging(Sender: TObject;
      var AllowChange: Boolean);
  private
    { Private declarations }
    FOldParName,
    FEditFN: String;
    FFileColl: TFileColl;
    procedure RebuildCB;
    procedure CalcCONTENT_LENGTHVar;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.CalcCONTENT_LENGTHVar;
begin
  MemoServerVars.Lines.Values['CONTENT_LENGTH']:=
    IntToStr(Length(CreateParameterList(MPar.Lines)));
end;

procedure TForm1.RebuildCB;
var
  i: Integer;
begin
  CBColl.Items.Clear;
  for i:= 0 to FFileColl.FFilePtr.Count - 1
  do CBColl.Items.Add(FFileColl.FFilePtr.Names[i]);
end;

procedure TForm1.BCallClick(Sender: TObject);
begin
  CalcCONTENT_LENGTHVar;
  MemoResult.Text:= UtilISAPI.CallISAPI(CBDll.Text, CBMethod.Text, CBPathInfo.Text,
    MPar.Lines, MemoServerVars.Lines);
end;

procedure TForm1.BVersionClick(Sender: TObject);
begin
  MemoResult.Text:= GetVersionISAPI(CBDll.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FOldParName:= '';
  FEditFN:= '';
  FFileColl:= TFileColl.Create;
  FFileColl.CollectionFile:= 'parlist.txt';
  RebuildCB;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FFileColl.StoreChanges;
  FFileColl.Free;
end;

procedure TForm1.MResultChange(Sender: TObject);
begin
  if FFileColl.FFilePtr.IndexOf(CBColl.Text) > 0
  then FFileColl.Content[CBColl.Text]:= MPar.Text;
end;

procedure TForm1.BGoClick(Sender: TObject);
begin
  if FOldParName <> ''
  then FFileColl.Content[FOldParName]:= MPar.Text;
  FOldParName:= CBColl.Text;
  MPar.Text:= FFileColl.Content[CBColl.Text];
end;

procedure TForm1.BStoreNewClick(Sender: TObject);
begin
  FFileColl.NewFile(CBColl.Text, MemoResult.Text);
  RebuildCB;
end;

procedure TForm1.BRenameClick(Sender: TObject);
begin
  FFileColl.RenameFile(FOldParName, CBColl.Text);
  RebuildCB;
end;

procedure TForm1.PageControlAnswerChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  BSaveFile.Enabled:= False;
  try
    FEditFN:= ClipBoard.AsText;
    FEditFN:= Copy(FEditFN, Pos('=', FEditFN)+1, 255);
    if FileExists(FEditFN) then begin
      MemoFileEdit.Text:= util1.LoadString(FEditFN);
    end;
    BSaveFile.Enabled:= True;
  except
  end;
end;

procedure TForm1.BEditSaveClick(Sender: TObject);
begin
  if FileExists(FEditFN) then begin
    util1.StoreString(FEditFN, MemoFileEdit.Text);
  end;
end;

procedure TForm1.CBCollKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
  VK_RETURN: begin BGoClick(Self); Key:= 0; end;
  end;
end;

procedure TForm1.CBDllKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
  VK_RETURN: begin BCallClick(Self); Key:= 0; end;
  end;
end;


procedure TForm1.PageControlQueryChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  CalcCONTENT_LENGTHVar;
end;

end.
