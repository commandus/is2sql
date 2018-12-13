object Form1: TForm1
  Left = 265
  Top = 222
  Width = 337
  Height = 196
  Caption = 'Act as'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 24
    Width = 51
    Height = 13
    Caption = '&User name'
  end
  object Label2: TLabel
    Left = 24
    Top = 56
    Width = 46
    Height = 13
    Caption = '&Password'
  end
  object Label3: TLabel
    Left = 24
    Top = 88
    Width = 52
    Height = 13
    Caption = '&Application'
  end
  object Label4: TLabel
    Left = 24
    Top = 120
    Width = 53
    Height = 13
    Caption = '&Parameters'
  end
  object Button1: TButton
    Left = 80
    Top = 136
    Width = 75
    Height = 25
    Caption = '&Start'
    TabOrder = 0
    OnClick = Button1Click
  end
  object CheckBox1: TCheckBox
    Left = 224
    Top = 24
    Width = 97
    Height = 17
    Caption = '&Show dialog'
    TabOrder = 1
  end
  object EUser: TEdit
    Left = 80
    Top = 16
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'IUSR_ENSEN'
  end
  object EPassword: TEdit
    Left = 80
    Top = 48
    Width = 121
    Height = 21
    PasswordChar = '*'
    TabOrder = 3
  end
  object CBApp: TComboBox
    Left = 80
    Top = 80
    Width = 193
    Height = 21
    ItemHeight = 13
    TabOrder = 4
  end
  object ComboBox1: TComboBox
    Left = 80
    Top = 112
    Width = 193
    Height = 21
    ItemHeight = 13
    TabOrder = 5
  end
end
