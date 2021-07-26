unit uSettingsWindow;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Ani, FMX.Layouts,
  FMX.Objects, FMX.Gestures, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus,
  FMX.GIFImage, FMX.Windows.TrayIcon, AnimatedWallpaper, FMX.ListBox,
  System.IOUtils, FMX.Platform.Win, Winapi.Windows, Winapi.ShellAPI;

type
  TSettingsWindow = class(TForm)
    grpSettings: TGroupBox;
    btnSelectGif: TButton;
    lblGif: TLabel;
    cbbWrapMode: TComboBox;
    grpButtons: TGroupBox;
    btnSetWallpaper: TButton;
    btnReset: TButton;
    btnClose: TButton;
    vrtscrlbx: TVertScrollBox;
    lblWrapMode: TLabel;
    stylbk: TStyleBook;
    mm: TMainMenu;
    miAbout: TMenuItem;
    procedure btnSelectGifClick(Sender: TObject);
    procedure cbbWrapModeChange(Sender: TObject);
    procedure btnSetWallpaperClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure OpenSettings(Sender: TObject);
    procedure ExitApplication(Sender: TObject);
    procedure PlayGif(Sender: TObject);
    procedure PauseGif(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;

var
  SettingsWindow: TSettingsWindow;
  TrayIcon: TTrayIcon;

implementation

{$R *.fmx}

procedure TSettingsWindow.btnCloseClick(Sender: TObject);
begin
  Hide;
  ShowWindow(ApplicationHWND, SW_HIDE);
end;

procedure TSettingsWindow.btnResetClick(Sender: TObject);
begin
  TAnimatedWallpaper.ResetWallpaper;
end;

procedure TSettingsWindow.btnSelectGifClick(Sender: TObject);
var
  dlg: TOpenDialog;
begin
  dlg := TOpenDialog.Create(Self);
  try
    dlg.Filter := 'GIF Image|*.gif';
    if dlg.Execute then
    begin
      lblGif.Text := dlg.FileName;
      if TFile.Exists(dlg.FileName) and TAnimatedWallpaper.Activated then
      begin
        TAnimatedWallpaper.SetGif(dlg.FileName);
      end;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TSettingsWindow.btnSetWallpaperClick(Sender: TObject);
begin
  if TFile.Exists(lblGif.Text) then
  begin
    TAnimatedWallpaper.SetWallpaper(lblGif.Text, TImageWrapMode(cbbWrapMode.ItemIndex));
  end;
end;

procedure TSettingsWindow.cbbWrapModeChange(Sender: TObject);
begin
  TAnimatedWallpaper.SetWrapMode(TImageWrapMode(cbbWrapMode.ItemIndex));
end;

procedure TSettingsWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // when the user closes the window from the taskbar
  // hide the window instead of quitting the application
  Action := TCloseAction.caNone;
  btnCloseClick(Sender);
end;

procedure TSettingsWindow.FormShow(Sender: TObject);
begin
  if not Assigned(TrayIcon) then
  begin
    Hide;
    TrayIcon := TTrayIcon.Create(Self);
    TrayIcon.SetOnDoubleClick(OpenSettings);
    TrayIcon.AddMenuAction('Settings', OpenSettings);
    TrayIcon.AddMenuAction('Exit', ExitApplication);
    TrayIcon.Show('WinAnimatedWallpaper');
  end;
end;

procedure TSettingsWindow.miAboutClick(Sender: TObject);
begin
  MessageBox(0, 'Developed by AkyrosXD'#13#10'Icon by DefaultO'#13#10'Version: 1.0.0.1', 'About', MB_ICONINFORMATION);
end;

procedure TSettingsWindow.OpenSettings(Sender: TObject);
begin
  if not Visible then
  begin
    Show;
    ShowWindow(ApplicationHWND, SW_SHOW);
  end;
  SetForegroundWindow(WindowHandleToPlatform(Handle).Wnd);
end;

procedure TSettingsWindow.ExitApplication(Sender: TObject);
begin
  if Assigned(TrayIcon) then
  begin
    TrayIcon.Destroy;
  end;
  TAnimatedWallpaper.ResetWallpaper;
  Application.Terminate;
end;

procedure TSettingsWindow.PlayGif(Sender: TObject);
begin
  TAnimatedWallpaper.Play;
end;

procedure TSettingsWindow.PauseGif(Sender: TObject);
begin
  TAnimatedWallpaper.Pause;
end;

end.

