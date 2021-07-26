unit AnimatedWallpaper;

{
  Author: AkyrosXD
  GitHub: https://github.com/AkyrosXD
  Platform: Windows
}

interface

uses
  FMX.Forms, FMX.GIFImage, FMX.Objects, FMX.Types, System.UITypes,
  FMX.Platform.Win, FMX.Graphics, Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes;

type
  TAnimatedWallpaper = class
  private
    class var
      wpGif: TGIFImage;
      wpWindow: TForm;
      hWndWorkerW: HWND;
      oldWindowProc: Pointer;
      pOnReset: TNotifyEvent;
      s_uTaskbarRestart: UINT;
      bgThread: THandle;
      bPlaying: Boolean;
    class procedure CreateWallpaperWindow(AFileName: string; AWrapMode: TImageWrapMode);
    class function GetWallpaperWindowHandle(): HWND; inline;
  public
    class function Activated: Boolean;
    class procedure SetWrapMode(AWrapMode: TImageWrapMode);
    class procedure SetGif(AFileName: string);
    class procedure SetWallpaper(AFileName: string; AWrapMode: TImageWrapMode);
    class procedure SetOnWallpaperReset(ACallback: TNotifyEvent);
    class procedure Pause;
    class procedure Play;
    class procedure ResetWallpaper;
  end;

implementation

const
  WM_PAUSE = WM_USER + 123;
  WM_PLAY = WM_USER + 456;

function EnumWindowsCallback(AWndParent: HWND; AParam: LPARAM): BOOL; stdcall;
begin
  if FindWindowEx(AWndParent, 0, 'SHELLDLL_DefView', nil) <> 0 then
  begin
    TAnimatedWallpaper.hWndWorkerW := FindWindowEx(0, AWndParent, 'WorkerW', nil);
  end;
  Result := True;
end;

function WndProcCallback(hWindow: HWND; uMsg: UINT; wpParam: WPARAM; lpParam: LPARAM): LRESULT; stdcall;
begin
  // resize the wallpaper window
  // when the resolution of the screen changes
  if (uMsg = WM_DISPLAYCHANGE) and Assigned(TAnimatedWallpaper.wpWindow) then
  begin
    TAnimatedWallpaper.wpWindow.Width := Screen.Width;
    TAnimatedWallpaper.wpWindow.Height := Screen.Height;
  end;
  if uMsg = TAnimatedWallpaper.s_uTaskbarRestart then
  begin
    TAnimatedWallpaper.ResetWallpaper;
  end;
  if hWindow = ApplicationHWND then
  begin
    if uMsg = WM_PAUSE then
    begin
      TAnimatedWallpaper.Pause;
    end;
    if uMsg = WM_PLAY then
    begin
      TAnimatedWallpaper.Play;
    end;
  end;
  Result := CallWindowProc(TAnimatedWallpaper.oldWindowProc, hWindow, uMsg, wpParam, lpParam);
end;

class procedure TAnimatedWallpaper.CreateWallpaperWindow(AFileName: string; AWrapMode: TImageWrapMode);
begin
  wpWindow := TForm.CreateNew(nil);
  wpWindow.BorderStyle := TFmxFormBorderStyle.None;
  wpWindow.FullScreen := True;
  wpWindow.Fill := TBrush.Create(TBrushKind.Solid, 0);
  wpGif := TGIFImage.Create(wpWindow);
  wpGif.Parent := wpWindow;
  wpGif.Align := TAlignLayout.Client;
  wpGif.WrapMode := AWrapMode;
  wpGif.LoadFromFile(AFileName);
end;

class function TAnimatedWallpaper.GetWallpaperWindowHandle: HWND;
begin
  // http://docwiki.embarcadero.com/Libraries/Sydney/en/FMX.Platform.Win.WindowHandleToPlatform
  Result := WindowHandleToPlatform(wpWindow.Handle).Wnd;
end;

class function TAnimatedWallpaper.Activated: Boolean;
begin
  Result := Assigned(wpGif);
end;

class procedure TAnimatedWallpaper.SetWrapMode(AWrapMode: TImageWrapMode);
begin
  if Assigned(wpGif) then
    wpGif.WrapMode := AWrapMode;
end;

class procedure TAnimatedWallpaper.SetGif(AFileName: string);
begin
  if Assigned(wpGif) then
  begin
    wpGif.LoadFromFile(AFileName);
    if bPlaying then
      wpGif.Play;
  end;
end;

// in this thread, we check if the current working window
// is maximized. if yes, pause the wallpaper or keep playing
// if the window is not maximized.
//
// the proper way is to check if ANY window is maximized but
// this has many false-positives.
// UPDATE 26/07/2021: I found a solution!!! A huge thank you to the person who wrote the code below:
// https://gist.github.com/blewert/b6e7b11c565cf82e7d700c609f22d023
function BackgroundThread: DWORD; stdcall;
var
  winp: WINDOWPLACEMENT;
  currentWindow: HWND;
  appWindow: HWND;
  bKeepPlaying: Boolean;
begin
  appWindow := ApplicationHWND;
  while Assigned(TAnimatedWallpaper.wpGif) do
  begin
    bKeepPlaying := True;
    currentWindow := GetTopWindow(GetDesktopWindow);
    repeat
      currentWindow := GetWindow(currentWindow, GW_HWNDNEXT);
      if IsWindowVisible(currentWindow) and GetWindowPlacement(currentWindow, @winp) and (winp.showCmd = SW_SHOWMAXIMIZED) then
      begin
        bKeepPlaying := False;
        Break;
      end;
    until not Boolean(currentWindow);
    if bKeepPlaying then
    begin
      SendMessage(appWindow, WM_PLAY, 0, 0);
    end
    else
    begin
      SendMessage(appWindow, WM_PAUSE, 0, 0);
    end;
    Sleep(200);
  end;
  TAnimatedWallpaper.bgThread := 0;
  Result := 0
end;

class procedure TAnimatedWallpaper.SetWallpaper(AFileName: string; AWrapMode: TImageWrapMode);
var
  progman: HWND;
  lpThreadId: DWORD;
begin
  if s_uTaskbarRestart = 0 then
  begin
    s_uTaskbarRestart := RegisterWindowMessage('TaskbarCreated');
  end;
  if not Assigned(wpWindow) then
  begin
    TAnimatedWallpaper.CreateWallpaperWindow(AFileName, AWrapMode);
  end;
  bPlaying := False;
  progman := FindWindow('Progman', nil);
  SendMessageTimeout(progman, $052C, 0, 0, SMTO_NORMAL, 1000, nil);
  EnumWindows(@EnumWindowsCallback, 0);
  if hWndWorkerW <> 0 then
  begin
    wpWindow.Show;
    if not Assigned(oldWindowProc) then
    begin
      oldWindowProc := Pointer(GetWindowLongPtr(ApplicationHWND, GWL_WNDPROC));
    end;
    SetWindowLongPtr(ApplicationHWND, GWL_WNDPROC, NativeInt(@WndProcCallback));
    SetParent(GetWallpaperWindowHandle, hWndWorkerW);
    wpWindow.WindowState := TWindowState.wsMaximized;
    wpGif.Play;
    bPlaying := True;
    if bgThread = 0 then
    begin
      bgThread := CreateThread(nil, 0, @BackgroundThread, nil, 0, lpThreadId);
    end;
  end;
end;

class procedure TAnimatedWallpaper.SetOnWallpaperReset(ACallback: TNotifyEvent);
begin
  pOnReset := ACallback;
end;

class procedure TAnimatedWallpaper.Pause;
begin
  if Assigned(wpGif) and bPlaying then
  begin
    wpGif.Stop;
    bPlaying := False;
  end;
end;

class procedure TAnimatedWallpaper.Play;
begin
  if Assigned(wpGif) and (not bPlaying) then
  begin
    wpGif.Play;
    bPlaying := True;
  end;
end;

class procedure TAnimatedWallpaper.ResetWallpaper;
begin
  if Assigned(wpGif) then
  begin
    wpGif.Free;
    wpGif := nil;
  end;
  if Assigned(wpWindow) then
  begin
    wpWindow.Close;
    wpWindow.Free;
    wpWindow := nil;
  end;
  if hWndWorkerW = 0 then
  begin
    EnumWindows(@EnumWindowsCallback, 0);
  end;
  if hWndWorkerW <> 0 then
  begin
    SetParent(hWndWorkerW, 0);
    if Assigned(pOnReset) then
    begin
      pOnReset(nil);
    end;
  end;
end;

end.

