unit formedit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  filecoll, StdCtrls, Menus,
  FileMsk,
  ShellAPI,
  filectrl;

const
  HELPURL = 'http://ensen.8m.com';

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    MainMenu1: TMainMenu;
    PopupMenu1: TPopupMenu;
    MFile: TMenuItem;
    MFileNewCollection: TMenuItem;
    MFileOpen: TMenuItem;
    MFileSave: TMenuItem;
    MFileExit: TMenuItem;

    MEdit: TMenuItem;
    MEditNewWindow: TMenuItem;
    MEditExtractFile: TMenuItem;
    MEditExtactAll: TMenuItem;

    MAct: TMenuItem;
    MActNew: TMenuItem;
    MActAdd: TMenuItem;
    MActDeleteMask: TMenuItem;
    MActSaveChanges: TMenuItem;
    MActRename: TMenuItem;

    MHelp: TMenuItem;
    MHelpAbout: TMenuItem;

    MD1: TMenuItem;
    MD2: TMenuItem;
    MD3: TMenuItem;

    popRenameFile: TMenuItem;
    popSaveChanges: TMenuItem;
    popDeleteFile: TMenuItem;
    popAddFile: TMenuItem;
    popNewFile: TMenuItem;
    popD1: TMenuItem;

    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    GroupBox1: TGroupBox;
    ComboBox1: TComboBox;
    LCollectionCount: TLabel;
    MD4: TMenuItem;
    mActAddDir: TMenuItem;
    MD5: TMenuItem;
    MD6: TMenuItem;
    MFileHelp: TMenuItem;
    N1: TMenuItem;
    MActReplaceWordsAll: TMenuItem;
    procedure ComboBox1Click(Sender: TObject);
    procedure MFileExitClick(Sender: TObject);
    procedure MFileSaveClick(Sender: TObject);
    procedure MFileOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MActDeleteClick(Sender: TObject);
    procedure MActAddClick(Sender: TObject);
    procedure MActSaveChangesClick(Sender: TObject);
    procedure MActRenameClick(Sender: TObject);
    procedure MActNewClick(Sender: TObject);
    procedure MEditNewWindowClick(Sender: TObject);
    procedure MEditExtractFileClick(Sender: TObject);
    procedure MEditExtactAllClick(Sender: TObject);
    procedure MHelpAboutClick(Sender: TObject);
    procedure MFileNewCollectionClick(Sender: TObject);
    procedure mActAddDirClick(Sender: TObject);
    procedure MFileHelpClick(Sender: TObject);
    procedure MActDeleteMaskClick(Sender: TObject);
    procedure MActReplaceWordsAllClick(Sender: TObject);
  private
    { Private declarations }
    FNewFileCount: Integer;
    FFileName: String;
    procedure EnableAll;
    procedure DisableAll;
  public
    { Public declarations }
    FileColl: TFileColl;
    EntireFolderName: String;
    procedure FillUpComboBox;
  end;

var
  Form1: TForm1;

implementation

uses
  util1, rename, About, dlgRelace;

{$R *.DFM}

procedure TForm1.ComboBox1Click(Sender: TObject);
begin
  if Memo1.Modified then begin
    if MessageDlg('Внести изменения в "' + FFIleName + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
      MActSaveChangesClick(Self);
    end;
  end;
  FFileName:= ComboBox1.Text;
  Memo1.Lines.Text:= FileColl.Content[FFileName];
  Memo1.Modified:= False;
end;

procedure TForm1.MFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MFileSaveClick(Sender: TObject);
begin
  FileColl.StoreChanges;
end;

procedure TForm1.FillUpComboBox;
var
  i: Integer;
begin
  Combobox1.Items.Clear;
  for i:= 0 to FileColl.FFilePtr.Count - 1 do begin
    Combobox1.Items.Add(FileColl.FFilePtr.Names[i]);
  end;
  LCollectionCount.Caption:= 'Файлов: ' + IntToStr(Combobox1.Items.Count);
end;

procedure TForm1.MFileOpenClick(Sender: TObject);
begin
  with OpenDialog1 do begin
    Options:= Options - [ofAllowMultiSelect];
    if Execute then begin
      FileColl.CollectionFile:= ExpandFileName(ExtractFileName(Filename));
      EnableAll;
      Form1.Caption:= 'Stupid text collection '+ FileColl.CollectionFile;
    end;
  end;
  FillUpComboBox;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FileColl:= TFileColl.Create;
  FNewFileCount:= 1;
  DisableAll;
end;

procedure TForm1.MActDeleteClick(Sender: TObject);
begin
  FileColl.DeleteFile(FFileName);
  FFileName:= '';
  FillUpComboBox;
  Memo1.Clear;
  Memo1.Modified:= False;
end;

procedure TForm1.MActAddClick(Sender: TObject);
var
  S: String;
  i: Integer;
begin
  with OpenDialog1 do begin
    Caption:= 'Add file(s) to collection ';
    Options:= Options + [ofAllowMultiSelect];
    if Execute then begin
      for i:= 0 to Files.Count - 1 do begin
        S:= ExtractFileName(Files[i]);
        FileColl.AddFile(S);
        Combobox1.Items.Add(S);
      end;
    end;
    Options:= Options - [ofAllowMultiSelect];
  end;
  FillUpComboBox;
end;

procedure TForm1.MActSaveChangesClick(Sender: TObject);
begin
  FileColl.Content[FFileName]:= Memo1.Lines.Text;
  Memo1.Modified:= False;
end;

procedure TForm1.MActRenameClick(Sender: TObject);
begin
  with DlgRename do begin
    ENewFile.Text:= FFileName;
    LOldFile.Caption:= FFileName;
    if ShowModal = mrOk then begin
      FileColl.RenameFile(ComboBox1.Text, ENewFile.Text);
      FFileName:= ENewFile.Text;
      FillUpComboBox;
    end;
  end;
end;

procedure TForm1.MActNewClick(Sender: TObject);
begin
  FileColl.NewFile('', Memo1.Text);
  Memo1.Modified:= True;
  FillUpComboBox;
end;

procedure TForm1.MEditNewWindowClick(Sender: TObject);
var
  S: String;
  FN: array[0..255] of Char;
begin
  SetString(S, FN, GetModuleFileName(hInstance, FN, SizeOf(FN)));
  WinExec(FN, SW_SHOWDEFAULT);
end;

procedure TForm1.MEditExtractFileClick(Sender: TObject);
begin
  if FFileName = ''
  then Exit;
  with SaveDialog1 do begin
    // Options:= Options;
    FileName:= FFileName;
    if Execute then begin
      util1.StoreString(FileName, FileColl.Content[FFileName]);
    end;
  end;
end;

{ simple check extension }
function FileNameInMask(FMask, Fn: String): Boolean;
begin
  Fmask:= ExtractFileExt(FMask);
  Result:= (FMask = '.*') or (AnsiCompareText(Copy(Fn, Length(Fn) - Length(FMask) + 1, 255), FMask) = 0);
end;

procedure TForm1.MEditExtactAllClick(Sender: TObject);
var
  i, p: Integer;
  Fn: String;
  Dir: string;
  FMask: String;
begin
  Dir:= GetCurrentDir;
  if SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt], 0) then begin
   { let the user select a file mask }
    with DlgMaskFile do begin
      if ShowModal <> mrOk
      then Exit;
      FMask:= CBFileMask.Text;
      p:= Pos(#32, FMask);
      if p > 0
      then FMask:= Copy(FMask, 1, p-1);
    end;
    { process }
    for i:= 0 to FileColl.FFilePtr.Count - 1 do begin
      Fn:= FileColl.FFilePtr.Names[i];
      if not FileNameInMask(FMask, Fn)
      then Continue;
      if Pos('\', Fn) > 0 then begin
        { returns True if it successfully creates all necessary directories }
        if not filectrl.ForceDirectories(ConcatPath(Dir, ExtractFilePath(Fn))) then begin
          if MessageDlg('Ошибки, прекратить?',
            mtConfirmation, [mbYes, mbNo], 0) = mrYes
          then Break;
        end;
        util1.StoreString(ConcatPath(Dir, Fn), FileColl.Content[FN]);
      end else begin
        util1.StoreString(ConcatPath(Dir, Fn), FileColl.Content[FN]);
      end;
    end;
  end;
end;

procedure TForm1.EnableAll;
begin
  MFileSave.Enabled:= True;
  MEdit.Enabled:= True;
  MAct.Enabled:= True;
  Memo1.Enabled:= True;
end;

procedure TForm1.DisableAll;
begin
  MFileSave.Enabled:= False;
  MEdit.Enabled:= False;
  MAct.Enabled:= False;
  Memo1.Enabled:= False;
end;

procedure TForm1.MHelpAboutClick(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TForm1.MFileNewCollectionClick(Sender: TObject);
begin
  { new collection file }
  FileColl.CollectionFile:= ExpandFileName('NewColl' + IntToHex(FNewFileCount, 4) + '.txt');
  Form1.Caption:= 'New stupid text collection ' + FileColl.CollectionFile;
  Inc(FNewFileCount);
  EnableAll;
  FillUpComboBox;
end;

function DoAdd2Collection(Fn: String): Boolean;
var
  FNInColl: String; { relative file name in collection }
begin
  with Form1 do begin
    if FileExists(Fn) then begin
      FNInColl:= DiffPath(EntireFolderName, Fn);
      if (Length(FNInColl) > 0) and (FNInColl[1]='\')
      then Delete(FNInColl, 1, 1);
      FileColl.AddFile(FNInColl);
      Combobox1.Items.Add(FNInColl);
    end;  
  end;
  Result:= True;
end;

procedure TForm1.mActAddDirClick(Sender: TObject);
var
  p: Integer;
  FMask, Dir: string;
  { add entire catalog }
begin
  Dir:= GetCurrentDir;
  { let the user select a file mask }
  with DlgMaskFile do begin
    if ShowModal <> mrOk
    then Exit;
    FMask:= CBFileMask.Text;
    p:= Pos(#32, FMask);
    if p > 0
    then FMask:= Copy(FMask, 1, p-1);
  end;
  { let the user enter a directory name }
  if SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt], 0) then begin
    EntireFolderName:= Dir;
    SetCurrentDir(Dir);
    Walk_Tree(FMask, Dir, faAnyFile, True, DoAdd2Collection);
  end;
  FillUpComboBox;
end;

procedure TForm1.MFileHelpClick(Sender: TObject);
begin
  { }
  if ShellAPI.ShellExecute(Application.Handle, 'open',
    HELPURL, '', '', SW_SHOWNORMAL) <=32 then begin
  end;
end;

procedure TForm1.MActDeleteMaskClick(Sender: TObject);
var
  i, p: Integer;
  Fn: String;
  FMask: String;
begin
 { let the user select a file mask }
  with DlgMaskFile do begin
    if ShowModal <> mrOk
    then Exit;
    FMask:= CBFileMask.Text;
    p:= Pos(#32, FMask);
    if p > 0
    then FMask:= Copy(FMask, 1, p-1);
  end;
  { process }
  i:= 0;
  while i < FileColl.FFilePtr.Count do begin
    Fn:= FileColl.FFilePtr.Names[i];
    if FileNameInMask(FMask, Fn) then begin
      Inc(i);
      Continue;
    end;
    FileColl.DeleteFile(Fn);
  end;
  FillUpComboBox;
end;

function ReplaceWord(ASrch, ARplc, ASrc: String): String;
const
  ABC = ['0'..'9', 'A'..'Z', 'a'..'z'];
  DELIMITERS = [#0..#255] - ABC;
var
  i, L: Integer;
  token: String;
begin
  Result:= '';
  token:= '';
  L:= Length(ASrc);
  for i:= 1 to L do begin
    if (ASrc[i] in DELIMITERS) or (i = L) then begin
      if AnsiCompareText(Token, ASrch) = 0
      then Result:= Result + ARplc
      else Result:= Result + Token;
      Token:= '';
      Result:= Result + ASrc[i];
    end else begin
      token:= token + ASrc[i];
    end;
  end;
end;

{ replace all word occurancies }
procedure TForm1.MActReplaceWordsAllClick(Sender: TObject);
var
  i, p: Integer;
  Fn: String;
  FMask: String;
  Srch, Rplc: String;
begin
 { let the user select a file mask }
  with DlgMaskFile do begin
    if ShowModal <> mrOk
    then Exit;
    FMask:= CBFileMask.Text;
    p:= Pos(#32, FMask);
    if p > 0
    then FMask:= Copy(FMask, 1, p-1);
  end;
  with DlgReplaceWord do begin
    if ShowModal <> mrOk
    then Exit;
    Srch:= ESearchWord.Text;
    Rplc:= EReplaceWord.Text;
  end;
  { process }
  for i:= 0 to FileColl.FFilePtr.Count - 1 do begin
    Fn:= FileColl.FFilePtr.Names[i];
    if not FileNameInMask(FMask, Fn)
    then Continue;
    FileColl.Content[Fn]:= ReplaceWord(Srch, Rplc, FileColl.Content[Fn]);
  end;
  Memo1.Lines.Text:= FileColl.Content[FFileName];
end;

end.
