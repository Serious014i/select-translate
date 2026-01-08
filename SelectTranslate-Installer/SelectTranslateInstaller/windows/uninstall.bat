@echo off
setlocal

echo.
echo  ====================================================
echo   SelectTranslate - Uninstaller
echo  ====================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Please run as Administrator!
    pause
    exit /b 1
)

set "INSTALL_DIR=%ProgramFiles%\SelectTranslate"

echo  Removing SelectTranslate...
echo.

echo  Removing Chrome registration...
reg delete "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.selecttranslate.host" /f >nul 2>&1

echo  Removing Edge registration...
reg delete "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.selecttranslate.host" /f >nul 2>&1

echo  Removing files...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"

echo.
echo  ====================================================
echo   Uninstallation Complete!
echo  ====================================================
echo.
echo  Note: The Chrome extension must be removed separately
echo  from chrome://extensions/
echo.
pause
