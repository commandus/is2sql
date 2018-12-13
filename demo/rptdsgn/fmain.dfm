object FormMain: TFormMain
  Left = 264
  Top = 111
  Width = 430
  Height = 480
  Caption = 'FormMain'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object PanelBanner: TPanel
    Left = 0
    Top = 25
    Width = 422
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
  end
  object CoolBar1: TCoolBar
    Left = 0
    Top = 0
    Width = 422
    Height = 25
    AutoSize = True
    Bands = <
      item
        Control = ToolBar1
        ImageIndex = -1
        MinHeight = 21
        Width = 169
      end
      item
        Break = False
        Control = CBDll
        ImageIndex = -1
        MinHeight = 21
        Width = 247
      end>
    object ToolBar1: TToolBar
      Left = 9
      Top = 0
      Width = 156
      Height = 21
      AutoSize = True
      ButtonHeight = 21
      ButtonWidth = 49
      EdgeBorders = []
      Flat = True
      ShowCaptions = True
      TabOrder = 0
      object TBFile: TToolButton
        Left = 0
        Top = 0
        AutoSize = True
        Caption = '&File'
        DropdownMenu = pmFile
        Grouped = True
        ImageIndex = 0
      end
      object TBOptions: TToolButton
        Left = 27
        Top = 0
        Caption = '&Options'
        DropdownMenu = pmOptions
        Grouped = True
        ImageIndex = 1
      end
    end
    object CBDll: TComboBox
      Left = 180
      Top = 0
      Width = 234
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      OnChange = CBDllChange
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 600000
    OnTimer = Timer1Timer
    Left = 376
    Top = 32
  end
  object pmFile: TPopupMenu
    Left = 88
    Top = 41
    object pmFileD1: TMenuItem
      Caption = '-'
    end
    object pmFileExit: TMenuItem
      Caption = 'E&xit'
      ShortCut = 32856
      OnClick = pmFileExitClick
    end
  end
  object pmOptions: TPopupMenu
    Left = 120
    Top = 41
    object pmOptionsLibraryFolder: TMenuItem
      Caption = 'Library &folder: '
      OnClick = pmOptionsLibraryFolderClick
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 312
    Top = 33
  end
  object SaveDialog1: TSaveDialog
    Left = 344
    Top = 33
  end
end
