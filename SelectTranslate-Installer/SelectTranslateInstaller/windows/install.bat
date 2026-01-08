@echo off
setlocal enabledelayedexpansion

echo.
echo ====================================================
echo   SelectTranslate - Complete Installer
echo ====================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run as Administrator!
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [Step 1/3] Checking Python installation...
echo.

set "PYTHON_CMD="

where python >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%i in ('python -c "import sys; print(sys.executable)" 2^>nul') do (
        echo %%i | findstr /i /v "WindowsApps" >nul
        if !errorlevel! equ 0 (
            set "PYTHON_CMD=python"
            goto :check_python_version
        )
    )
)

where python3 >nul 2>&1
if %errorLevel% equ 0 (
    set "PYTHON_CMD=python3"
    goto :check_python_version
)

where py >nul 2>&1
if %errorLevel% equ 0 (
    set "PYTHON_CMD=py -3"
    goto :check_python_version
)

for %%V in (313 312 311 310 39 38) do (
    if exist "C:\Python%%V\python.exe" (
        set "PYTHON_CMD=C:\Python%%V\python.exe"
        goto :check_python_version
    )
    if exist "%LOCALAPPDATA%\Programs\Python\Python%%V\python.exe" (
        set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python%%V\python.exe"
        goto :check_python_version
    )
    if exist "C:\Program Files\Python%%V\python.exe" (
        set "PYTHON_CMD=C:\Program Files\Python%%V\python.exe"
        goto :check_python_version
    )
)

goto :install_python

:check_python_version
for /f "tokens=2" %%v in ('%PYTHON_CMD% --version 2^>^&1') do set "PY_VERSION=%%v"
for /f "tokens=1,2 delims=." %%a in ("%PY_VERSION%") do (
    set "PY_MAJOR=%%a"
    set "PY_MINOR=%%b"
)

if "%PY_MAJOR%"=="3" (
    if %PY_MINOR% GEQ 8 (
        echo Found Python %PY_VERSION%
        goto :python_ok
    )
)

echo Found Python %PY_VERSION% but need 3.8 or higher.
goto :install_python

:install_python
echo Python 3.8+ not found. Installing Python 3.12...
echo.

set "PYTHON_URL=https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
set "PYTHON_INSTALLER=%TEMP%\python-installer.exe"

echo Downloading Python installer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'}"

if not exist "%PYTHON_INSTALLER%" (
    echo.
    echo ERROR: Failed to download Python installer.
    echo Please install Python manually from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

echo Installing Python (this may take a minute)...
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

timeout /t 5 /nobreak >nul

del "%PYTHON_INSTALLER%" 2>nul

set "PYTHON_CMD=py -3"

%PYTHON_CMD% --version >nul 2>&1
if %errorLevel% neq 0 (
    set "PYTHON_CMD=python"
    %PYTHON_CMD% --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo.
        echo ERROR: Python installation may have failed.
        echo Please install Python manually from https://www.python.org/downloads/
        echo.
        pause
        exit /b 1
    )
)

echo Python installed successfully!

:python_ok
echo.
for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo Using: %%v

for /f "tokens=*" %%p in ('%PYTHON_CMD% -c "import sys; print(sys.executable)"') do set "PYTHON_EXE=%%p"
echo Path: %PYTHON_EXE%
echo.

echo [Step 2/3] Installing Python dependencies...
echo.

%PYTHON_CMD% -m pip install --upgrade pip --quiet 2>nul
%PYTHON_CMD% -m pip install pynput --quiet --break-system-packages 2>nul
if %errorLevel% neq 0 (
    %PYTHON_CMD% -m pip install pynput --quiet 2>nul
)

%PYTHON_CMD% -c "from pynput import mouse; print('pynput: OK')" 2>nul
if %errorLevel% neq 0 (
    echo WARNING: pynput installation may have issues.
    echo The extension will still work for web pages.
    echo.
)

echo Dependencies installed.
echo.

echo [Step 3/3] Installing SelectTranslate native host...
echo.

set "INSTALL_DIR=C:\Program Files\SelectTranslate"
set "SCRIPT_DIR=%~dp0"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /Y "%SCRIPT_DIR%native_host.py" "%INSTALL_DIR%\native_host.py" >nul
if %errorLevel% neq 0 (
    echo ERROR: Failed to copy native_host.py
    pause
    exit /b 1
)

echo @echo off> "%INSTALL_DIR%\run_host.bat"
echo "%PYTHON_EXE%" "%INSTALL_DIR%\native_host.py" %%*>> "%INSTALL_DIR%\run_host.bat"

set "MANIFEST_CHROME=%INSTALL_DIR%\com.selecttranslate.host.json"
echo {> "%MANIFEST_CHROME%"
echo   "name": "com.selecttranslate.host",>> "%MANIFEST_CHROME%"
echo   "description": "SelectTranslate Native Host",>> "%MANIFEST_CHROME%"
echo   "path": "%INSTALL_DIR:\=\\%\\run_host.bat",>> "%MANIFEST_CHROME%"
echo   "type": "stdio",>> "%MANIFEST_CHROME%"
echo   "allowed_origins": [>> "%MANIFEST_CHROME%"
echo     "chrome-extension://*/",>> "%MANIFEST_CHROME%"
echo     "chrome-extension://*/*">> "%MANIFEST_CHROME%"
echo   ]>> "%MANIFEST_CHROME%"
echo }>> "%MANIFEST_CHROME%"

set "MANIFEST_EDGE=%INSTALL_DIR%\com.selecttranslate.host.edge.json"
echo {> "%MANIFEST_EDGE%"
echo   "name": "com.selecttranslate.host",>> "%MANIFEST_EDGE%"
echo   "description": "SelectTranslate Native Host",>> "%MANIFEST_EDGE%"
echo   "path": "%INSTALL_DIR:\=\\%\\run_host.bat",>> "%MANIFEST_EDGE%"
echo   "type": "stdio",>> "%MANIFEST_EDGE%"
echo   "allowed_origins": [>> "%MANIFEST_EDGE%"
echo     "chrome-extension://*/",>> "%MANIFEST_EDGE%"
echo     "chrome-extension://*/*">> "%MANIFEST_EDGE%"
echo   ]>> "%MANIFEST_EDGE%"
echo }>> "%MANIFEST_EDGE%"

reg add "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_CHROME%" /f >nul 2>&1

reg add "HKCU\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_CHROME%" /f >nul 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_EDGE%" /f >nul 2>&1

reg add "HKCU\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_EDGE%" /f >nul 2>&1

reg add "HKLM\SOFTWARE\WOW6432Node\Google\Chrome\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_CHROME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge\NativeMessagingHosts\com.selecttranslate.host" /ve /t REG_SZ /d "%MANIFEST_EDGE%" /f >nul 2>&1

echo.
echo ====================================================
echo   Installation Complete!
echo ====================================================
echo.
echo Installed to: %INSTALL_DIR%
echo Python: %PYTHON_CMD%
echo.
echo NEXT STEPS:
echo 1. Install the Chrome extension (load unpacked)
echo 2. Restart Chrome/Edge completely
echo 3. Click the extension icon and press Play to start
echo.
echo The extension starts PAUSED by default.
echo Click the Play button to enable translation.
echo.
pause
