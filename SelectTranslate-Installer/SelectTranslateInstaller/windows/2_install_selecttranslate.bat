@echo off
setlocal EnableDelayedExpansion

title SelectTranslate Installer - Step 2

if "%1"=="" (
    cmd /k "%~f0" run
    exit /b
)

echo.
echo  ====================================================
echo   SelectTranslate - Installer (Step 2 of 2)
echo  ====================================================
echo.

set "PYTHON_CMD="

if exist "%~dp0python_path.txt" (
    set /p PYTHON_CMD=<"%~dp0python_path.txt"
    if exist "!PYTHON_CMD!" (
        echo  Using saved Python path: !PYTHON_CMD!
        goto :found_python
    )
)

if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
) else if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
) else if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
) else if exist "C:\Program Files\Python312\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python312\python.exe"
) else if exist "C:\Program Files\Python311\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python311\python.exe"
) else if exist "C:\Program Files\Python310\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python310\python.exe"
) else if exist "C:\Python312\python.exe" (
    set "PYTHON_CMD=C:\Python312\python.exe"
) else if exist "C:\Python311\python.exe" (
    set "PYTHON_CMD=C:\Python311\python.exe"
) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe"
)

:found_python
if "%PYTHON_CMD%"=="" (
    echo  [ERROR] Python not found!
    echo.
    echo  Please run "1_install_python.bat" first.
    echo.
    pause
    exit /b 1
)

"%PYTHON_CMD%" --version >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Python found but not working: %PYTHON_CMD%
    echo.
    echo  Please run "1_install_python.bat" first.
    echo.
    pause
    exit /b 1
)

echo  Found Python: %PYTHON_CMD%
"%PYTHON_CMD%" --version
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Please run as Administrator!
    echo.
    echo  Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"

if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo  Script folder: %SCRIPT_DIR%
echo  Checking for: %SCRIPT_DIR%\native_host.py

if exist "%SCRIPT_DIR%\native_host.py" (
    echo  [OK] Found native_host.py
    set "SCRIPT_DIR=%SCRIPT_DIR%\"
    goto :files_ok
)

if exist "%~dp0native_host.py" (
    echo  [OK] Found native_host.py (alt check)
    set "SCRIPT_DIR=%~dp0"
    goto :files_ok
)

if exist "native_host.py" (
    echo  [OK] Found in current directory
    set "SCRIPT_DIR=%CD%\"
    goto :files_ok
)

echo.
echo  [ERROR] native_host.py not found!
echo.
echo  Script location: %~dp0
echo  Current directory: %CD%
echo.
echo  Files in script folder:
dir /b "%~dp0" 2>nul
echo.
echo  Please make sure native_host.py is in the same folder as this script.
echo.
pause
exit /b 1

:files_ok
set "INSTALL_DIR=%ProgramFiles%\SelectTranslate"
set "MANIFEST_NAME=com.selecttranslate.host.json"
set "REG_KEY=HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.selecttranslate.host"
set "CHROME_EXTENSIONS_DIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions"
set "EDGE_EXTENSIONS_DIR=%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Extensions"
set "SCRIPT_DIR=%~dp0"

REM ============================================================
REM CHANGE THIS URL to your GitHub repository page (not ZIP!)
REM ============================================================
set "GITHUB_URL=https://github.com/Serious014i/select-translate"

echo.
echo  ====================================================
echo   EXTENSION INSTALLATION
echo  ====================================================
echo.
echo  The extension needs to be installed manually:
echo.
echo  Option 1: Load from GitHub (Recommended)
echo   1. Go to: %GITHUB_URL%
echo   2. Click "Code" then "Download ZIP"
echo   3. Extract the ZIP file
echo   4. Open Chrome and go to: chrome://extensions/
echo   5. Enable "Developer mode" (top right)
echo   6. Click "Load unpacked"
echo   7. Select the extracted extension folder
echo.
echo  Opening GitHub page now...
start "" "%GITHUB_URL%"
echo.
echo  ====================================================
echo   After installing the extension, press any key
echo  ====================================================
echo.
pause

echo.
echo  [STEP 2/5] Detecting extension ID...

set "EXTENSION_ID="
for /d %%D in ("%CHROME_EXTENSIONS_DIR%\*") do (
    if exist "%%D\*\manifest.json" (
        findstr /i /c:"SelectTranslate" "%%D\*\manifest.json" >nul 2>&1
        if !errorLevel! equ 0 (
            for %%F in ("%%D") do set "EXTENSION_ID=%%~nxF"
        )
    )
)

if "%EXTENSION_ID%"=="" (
    for /d %%D in ("%EDGE_EXTENSIONS_DIR%\*") do (
        if exist "%%D\*\manifest.json" (
            findstr /i /c:"SelectTranslate" "%%D\*\manifest.json" >nul 2>&1
            if !errorLevel! equ 0 (
                for %%F in ("%%D") do set "EXTENSION_ID=%%~nxF"
            )
        )
    )
)

if "%EXTENSION_ID%"=="" (
    echo.
    echo  [!] Could not auto-detect extension ID.
    echo.
    echo  Please find it manually:
    echo   1. Open Chrome and go to: chrome://extensions/
    echo   2. Enable "Developer mode" if not already
    echo   3. Find "SelectTranslate" and copy the ID
    echo      (looks like: abcdefghijklmnopqrstuvwxyz)
    echo.
    set /p EXTENSION_ID="  Enter Extension ID: "
)

if "%EXTENSION_ID%"=="" (
    echo  [ERROR] No extension ID provided. Exiting.
    pause
    exit /b 1
)

echo  Found Extension ID: %EXTENSION_ID%

echo.
echo  [STEP 3/5] Verifying pynput...

"%PYTHON_CMD%" -c "import pynput" >nul 2>&1
if %errorLevel% neq 0 (
    echo  pynput not found, installing...
    "%PYTHON_CMD%" -m pip install pynput
) else (
    echo  pynput: OK
)

echo.
echo  [STEP 4/5] Installing native host...

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo  Copying native_host.py...
echo  From: %~dp0native_host.py
echo  To: %INSTALL_DIR%\native_host.py

copy /Y "%~dp0native_host.py" "%INSTALL_DIR%\native_host.py" >nul 2>&1
if not exist "%INSTALL_DIR%\native_host.py" (
    echo  [ERROR] Failed to copy native_host.py!
    echo.
    echo  Trying alternative method...
    xcopy /Y "%~dp0native_host.py" "%INSTALL_DIR%\" >nul 2>&1
)

if not exist "%INSTALL_DIR%\native_host.py" (
    echo  [ERROR] Still failed to copy!
    echo  Please manually copy native_host.py to:
    echo  %INSTALL_DIR%\
    pause
    exit /b 1
)
echo  Copied successfully!

echo  Creating launcher...
echo @echo off> "%INSTALL_DIR%\run_host.bat"
echo "%PYTHON_CMD%" "%INSTALL_DIR%\native_host.py" %%*>> "%INSTALL_DIR%\run_host.bat"

echo  Creating manifest...
set "LAUNCHER_PATH=%INSTALL_DIR:\=\\%\\run_host.bat"
echo {> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   "name": "com.selecttranslate.host",>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   "description": "SelectTranslate Native Messaging Host",>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   "path": "%LAUNCHER_PATH%",>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   "type": "stdio",>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   "allowed_origins": [>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo     "chrome-extension://%EXTENSION_ID%/">> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo   ]>> "%INSTALL_DIR%\%MANIFEST_NAME%"
echo }>> "%INSTALL_DIR%\%MANIFEST_NAME%"

echo  Registering with Chrome...
reg add "%REG_KEY%" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%" /f >nul

reg add "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%INSTALL_DIR%\%MANIFEST_NAME%" /f >nul 2>&1

echo.
echo  [STEP 5/5] Verifying installation...
echo.

echo  Testing Python...
"%PYTHON_CMD%" -c "print('  Python: OK')" 2>nul
if %errorLevel% neq 0 (
    echo  [ERROR] Python test failed!
    pause
    exit /b 1
)

echo  Testing pynput...
"%PYTHON_CMD%" -c "import pynput; print('  pynput: OK')" 2>nul
if %errorLevel% neq 0 (
    echo  [WARNING] pynput not working, reinstalling...
    "%PYTHON_CMD%" -m pip install --force-reinstall pynput
)

echo  Testing native host...
"%PYTHON_CMD%" "%INSTALL_DIR%\native_host.py" --test 2>nul
if %errorLevel% neq 0 (
    echo  [INFO] Native host ready (will start when Chrome connects)
)

echo.
echo  Checking installed files:
if exist "%INSTALL_DIR%\native_host.py" (echo   [OK] native_host.py) else (echo   [MISSING] native_host.py)
if exist "%INSTALL_DIR%\run_host.bat" (echo   [OK] run_host.bat) else (echo   [MISSING] run_host.bat)
if exist "%INSTALL_DIR%\%MANIFEST_NAME%" (echo   [OK] %MANIFEST_NAME%) else (echo   [MISSING] %MANIFEST_NAME%)

reg query "%REG_KEY%" >nul 2>&1
if %errorLevel% equ 0 (echo   [OK] Chrome registry entry) else (echo   [MISSING] Chrome registry entry)

echo.
echo  ====================================================
echo   Installation Complete!
echo  ====================================================
echo.
echo  Extension ID: %EXTENSION_ID%
echo  Python: %PYTHON_CMD%
echo  Installed to: %INSTALL_DIR%
echo.
echo  ====================================================
echo.
echo  NEXT STEPS:
echo   1. RESTART CHROME COMPLETELY (close all windows)
echo   2. Click the SelectTranslate icon
echo   3. Click Play button to start
echo   4. Select text in any app to test
echo.
echo  TO TEST MANUALLY:
echo   Open Command Prompt and run:
echo   "%PYTHON_CMD%" "%INSTALL_DIR%\native_host.py"
echo.
echo  ====================================================
echo.
pause
exit /b 0
