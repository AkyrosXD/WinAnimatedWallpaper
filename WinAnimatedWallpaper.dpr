program WinAnimatedWallpaper;

uses
  FMX.Forms,
  uSettingsWindow in 'uSettingsWindow.pas' {SettingsWindow},
  AnimatedWallpaper in 'AnimatedWallpaper.pas',
  FMX.Windows.TrayIcon in 'FMX.Windows.TrayIcon.pas',
  Winapi.Windows,
  FMX.Platform.Win;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSettingsWindow, SettingsWindow);
  ShowWindow(ApplicationHWND, SW_HIDE);
  Application.Run;
end.
