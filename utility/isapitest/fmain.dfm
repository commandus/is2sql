object Form1: TForm1
  Left = 232
  Top = 85
  Width = 431
  Height = 433
  Caption = 'Test ISAPI/NSAPI'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 193
    Width = 423
    Height = 4
    Cursor = crVSplit
    Align = alTop
  end
  object PageControlQuery: TPageControl
    Left = 0
    Top = 25
    Width = 423
    Height = 168
    ActivePage = TSQueryParam
    Align = alTop
    TabIndex = 0
    TabOrder = 1
    OnChanging = PageControlQueryChanging
    object TSQueryParam: TTabSheet
      Caption = '&Query'
      object MPar: TMemo
        Left = 0
        Top = 25
        Width = 415
        Height = 115
        Align = alClient
        Lines.Strings = (
          'dbs=equiz'
          'user=cli'
          'key=look'
          'form=c:\src\delphi\isapitest\isapitest.htm')
        TabOrder = 0
      end
      object PanelQuery: TPanel
        Left = 0
        Top = 0
        Width = 415
        Height = 25
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object CBColl: TComboBox
          Left = 0
          Top = 0
          Width = 129
          Height = 21
          Hint = 'List parameter list'
          ItemHeight = 13
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnKeyDown = CBCollKeyDown
        end
        object BStoreNew: TButton
          Left = 153
          Top = 0
          Width = 50
          Height = 20
          Hint = 'Store with new name'
          Caption = '&New'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = BStoreNewClick
        end
        object BRename: TButton
          Left = 204
          Top = 0
          Width = 50
          Height = 20
          Hint = 'Rename'
          Caption = '&Rename'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          OnClick = BRenameClick
        end
        object BGo: TButton
          Left = 132
          Top = 0
          Width = 20
          Height = 20
          Hint = 'Go'
          Caption = '>>'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = BGoClick
        end
      end
    end
    object TSServerVars: TTabSheet
      Caption = 'Server &Variables'
      ImageIndex = 1
      object MemoServerVars: TMemo
        Left = 0
        Top = 0
        Width = 415
        Height = 140
        Align = alClient
        Lines.Strings = (
          'SERVER_PROTOCOL=HTTP/1.1'
          'URL=/scripts/is2sql.dll'
          
            'HTTP_ACCEPT=image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,' +
            ' */*'
          'HTTP_HOST=ensen'
          'HTTP_REFERER=http://ensen/quiz/'
          
            'HTTP_USER_AGENT=Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; D' +
            'igExt)'
          'CONTENT_TYPE=application/x-www-form-urlencoded'
          'CONTENT_LENGTH='
          'REMOTE_ADDR=62.76.127.26'
          'REMOTE_HOST=62.76.127.26'
          'SCRIPT_NAME=/scripts/is2sql.dll'
          'SERVER_PORT=80'
          'HTTP_CONNECTION=Keep-Alive'
          'HTTP_CACHE_CONTROL='
          'HTTP_DATE='
          'HTTP_FROM='
          'HTTP_IF_MODIFIED_SINCE='
          'HTTP_CONTENT_ENCODING='
          'HTTP_CONTENT_VERSION='
          'HTTP_DERIVED_FROM='
          'HTTP_EXPIRES='
          'HTTP_TITLE='
          'HTTP_COOKIE='
          'HTTP_AUTHORIZATION=')
        TabOrder = 0
      end
    end
  end
  object PanelDLL: TPanel
    Left = 0
    Top = 0
    Width = 423
    Height = 25
    Align = alTop
    TabOrder = 0
    object CBDll: TComboBox
      Left = 0
      Top = 0
      Width = 169
      Height = 21
      ItemHeight = 13
      TabOrder = 0
      Text = 'c:\src\is2sql\is2sql.dll'
      OnKeyDown = CBDllKeyDown
      Items.Strings = (
        'c:\inetpub\scripts\is2sql.dll'
        'c:\inetpub\scripts\ib\is2sql.dll'
        'is2sql.dll')
    end
    object CBPathInfo: TComboBox
      Left = 170
      Top = 0
      Width = 89
      Height = 21
      ItemHeight = 13
      TabOrder = 1
      Text = '/info'
      OnKeyDown = CBDllKeyDown
      Items.Strings = (
        '/show'
        '/info'
        '/r'
        '/setup')
    end
    object CBMethod: TComboBox
      Left = 260
      Top = 0
      Width = 53
      Height = 21
      Hint = 'Method'
      ItemHeight = 13
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      Text = 'GET'
      OnKeyDown = CBDllKeyDown
      Items.Strings = (
        'GET'
        'POST')
    end
    object BCall: TButton
      Left = 312
      Top = 1
      Width = 35
      Height = 19
      Caption = 'Call'
      TabOrder = 3
      OnClick = BCallClick
    end
    object BVersion: TButton
      Left = 348
      Top = 1
      Width = 35
      Height = 19
      Caption = 'Ver'
      TabOrder = 4
      OnClick = BVersionClick
    end
  end
  object PageControlAnswer: TPageControl
    Left = 0
    Top = 197
    Width = 423
    Height = 209
    ActivePage = TSResultHTML
    Align = alClient
    TabIndex = 0
    TabOrder = 2
    OnChanging = PageControlAnswerChanging
    object TSResultHTML: TTabSheet
      Caption = '&Result'
      object MemoResult: TMemo
        Left = 0
        Top = 0
        Width = 415
        Height = 181
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
        OnChange = MResultChange
      end
    end
    object TSFileEditor: TTabSheet
      Caption = '&Editor'
      ImageIndex = 1
      object MemoFileEdit: TMemo
        Left = 0
        Top = 25
        Width = 416
        Height = 156
        Align = alClient
        TabOrder = 0
        OnChange = MResultChange
      end
      object PanelFileEditor: TPanel
        Left = 0
        Top = 0
        Width = 416
        Height = 25
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object BSaveFile: TButton
          Left = 0
          Top = 0
          Width = 75
          Height = 25
          Caption = '&Save'
          TabOrder = 0
          OnClick = BEditSaveClick
        end
      end
    end
  end
end
