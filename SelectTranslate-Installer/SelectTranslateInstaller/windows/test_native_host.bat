@echo off
setlocal

echo.
echo  ====================================================
echo   SelectTranslate - Test Native Host
echo  ====================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  ====================================================
    echo   [ERROR] Please run as Administrator!
    echo  ====================================================
    echo.
    echo  Mouse hooks require administrator privileges.
    echo.
    echo  Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo  ====================================================
echo   SelectTranslate - Test Native Host
echo  ====================================================
echo.
echo  This will test if the native host is working properly.
echo  Select some text in another window while this is running.
echo.
echo  Press Ctrl+C to stop.
echo.
echo  ====================================================
echo.

set "NATIVE_HOST="

if exist "C:\Program Files\SelectTranslate\native_host.py" set "NATIVE_HOST=C:\Program Files\SelectTranslate\native_host.py"

if "%NATIVE_HOST%"=="" if exist "%~dp0native_host.py" set "NATIVE_HOST=%~dp0native_host.py"

if "%NATIVE_HOST%"=="" if exist "native_host.py" set "NATIVE_HOST=native_host.py"

if "%NATIVE_HOST%"=="" (
    echo  [ERROR] native_host.py not found!
    echo.
    echo  Please run the installer first.
    echo.
    pause
    exit /b 1
)

echo  Found native_host.py at: %NATIVE_HOST%
echo.

set "PYTHON_CMD="

if exist "C:\Program Files\Python312\python.exe" set "PYTHON_CMD=C:\Program Files\Python312\python.exe"
if "%PYTHON_CMD%"=="" if exist "C:\Program Files\Python311\python.exe" set "PYTHON_CMD=C:\Program Files\Python311\python.exe"
if "%PYTHON_CMD%"=="" if exist "C:\Python312\python.exe" set "PYTHON_CMD=C:\Python312\python.exe"
if "%PYTHON_CMD%"=="" if exist "C:\Python311\python.exe" set "PYTHON_CMD=C:\Python311\python.exe"

if "%PYTHON_CMD%"=="" if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if "%PYTHON_CMD%"=="" if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" set "PYTHON_CMD=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if "%PYTHON_CMD%"=="" if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe" set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
if "%PYTHON_CMD%"=="" if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe" set "PYTHON_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe"

if "%PYTHON_CMD%"=="" if exist "%~dp0python_path.txt" set /p PYTHON_CMD=<"%~dp0python_path.txt"

if "%PYTHON_CMD%"=="" (
    echo  [ERROR] Python not found!
    echo.
    echo  Please run 1_install_python.bat first.
    echo.
    pause
    exit /b 1
)

echo  Using Python: %PYTHON_CMD%
echo.

echo  Testing Python and dependencies:
echo.

"%PYTHON_CMD%" -c "import sys; print('  Python version:', sys.version.split()[0])"
"%PYTHON_CMD%" -c "import pynput; print('  pynput: OK')"
if %errorLevel% neq 0 (
    echo  pynput: NOT INSTALLED
    echo.
    echo  Installing pynput...
    "%PYTHON_CMD%" -m pip install pynput
    echo.
)

echo.
echo  ====================================================
echo  Starting native host in test mode...
echo  ====================================================
echo.
echo  Now select some text in any application (Notepad, Word, etc.)
echo  You should see "[Selection] your text here" messages below.
echo.
echo  If you don't see any messages, the mouse hook may not be working.
echo.
echo  Press Ctrl+C to stop.
echo  ====================================================
echo.

"%PYTHON_CMD%" "%NATIVE_HOST%"

echo.
echo  ====================================================
echo  Native host stopped.
echo  ====================================================
pause
