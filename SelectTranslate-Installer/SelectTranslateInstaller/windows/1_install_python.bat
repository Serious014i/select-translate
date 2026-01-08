@echo off
setlocal EnableDelayedExpansion

title Python Installer for SelectTranslate

echo.
echo  ====================================================
echo   Step 1: Installing Python
echo  ====================================================
echo.

set "PYTHON_CMD="

if exist "C:\Program Files\Python312\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python312\python.exe"
    goto :found
)
if exist "C:\Program Files\Python311\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python311\python.exe"
    goto :found
)
if exist "C:\Program Files\Python310\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python310\python.exe"
    goto :found
)
if exist "C:\Python312\python.exe" (
    set "PYTHON_CMD=C:\Python312\python.exe"
    goto :found
)
if exist "C:\Python311\python.exe" (
    set "PYTHON_CMD=C:\Python311\python.exe"
    goto :found
)
if exist "C:\Python310\python.exe" (
    set "PYTHON_CMD=C:\Python310\python.exe"
    goto :found
)
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto :found
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :found
)
if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    goto :found
)
if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
    goto :found
)
if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe" (
    set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe"
    goto :found
)

echo  Python not found. Will download and install Python 3.12...
echo.
goto :install_python

:found
echo  Found Python at: %PYTHON_CMD%
"%PYTHON_CMD%" --version
goto :install_pynput

:install_python
echo  Downloading Python 3.12...
echo.

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Write-Host '  Downloading... (about 25MB)'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe' -OutFile '%TEMP%\python_installer.exe'; Write-Host '  Download complete!'}"

if not exist "%TEMP%\python_installer.exe" (
    echo.
    echo  [ERROR] Download failed!
    echo.
    echo  Please download Python manually:
    echo   1. Go to https://www.python.org/downloads/
    echo   2. Click "Download Python 3.12"
    echo   3. Run the installer
    echo   4. IMPORTANT: Check "Add Python to PATH" at the bottom!
    echo   5. Click "Install Now"
    echo   6. After installation, run this script again
    echo.
    start "" "https://www.python.org/downloads/"
    pause
    exit /b 1
)

echo.
echo  ====================================================
echo   Python Installer will now open.
echo  ====================================================
echo.
echo   IMPORTANT: Check the box "Add python.exe to PATH"
echo              at the BOTTOM of the installer window!
echo.
echo   Then click "Install Now"
echo.
echo  ====================================================
echo.
pause

start /wait "" "%TEMP%\python_installer.exe"

del "%TEMP%\python_installer.exe" 2>nul

set "PYTHON_CMD="
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
) else if exist "C:\Program Files\Python312\python.exe" (
    set "PYTHON_CMD=C:\Program Files\Python312\python.exe"
) else if exist "C:\Python312\python.exe" (
    set "PYTHON_CMD=C:\Python312\python.exe"
) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
)

if "%PYTHON_CMD%"=="" (
    echo.
    echo  [ERROR] Python installation not detected.
    echo.
    echo  Please make sure you:
    echo   1. Checked "Add python.exe to PATH"
    echo   2. Clicked "Install Now"
    echo   3. Let the installation complete
    echo.
    echo  Try running this script again.
    echo.
    pause
    exit /b 1
)

:install_pynput
echo.
echo  ====================================================
echo   Step 2: Installing pynput
echo  ====================================================
echo.

echo  Python location: %PYTHON_CMD%
echo.

"%PYTHON_CMD%" --version >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Python found but not working!
    echo  Path: %PYTHON_CMD%
    pause
    exit /b 1
)

echo  Upgrading pip...
"%PYTHON_CMD%" -m pip install --upgrade pip 2>nul

echo  Installing pynput...
"%PYTHON_CMD%" -m pip install pynput

echo.
echo  Verifying installation...
"%PYTHON_CMD%" -c "import pynput; print('  pynput: OK')"

if %errorLevel% equ 0 (
    echo.
    echo  ====================================================
    echo   SUCCESS! Python and pynput are installed.
    echo  ====================================================
    echo.
    echo  Python: %PYTHON_CMD%
    echo.
    echo  NOW RUN: 2_install_selecttranslate.bat (as Administrator)
    echo.
) else (
    echo.
    echo  [WARNING] pynput may not have installed correctly.
    echo  Try running 2_install_selecttranslate.bat anyway.
    echo.
)

echo %PYTHON_CMD%> "%~dp0python_path.txt"
echo  (Saved Python path to python_path.txt)

pause
