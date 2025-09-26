@echo off
title Cattle AI Server
color 0A
echo.
echo ================================================================
echo                   CATTLE AI PREDICTION SERVER
echo ================================================================
echo.

REM Get current IP address
echo 🔍 Detecting network configuration...
echo.
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    set "current_ip=%%i"
    goto :found_ip
)
:found_ip
set current_ip=%current_ip: =%

echo 📡 Network Information:
ipconfig | findstr /i "IPv4"
echo.

echo Starting the AI server for cattle breed prediction...
echo This server will run continuously to serve your mobile app.
echo.
echo 🌐 Server will be accessible at:
if defined current_ip (
    echo   • Your computer IP: http://%current_ip%:8001
) else (
    echo   • Your computer IP: http://[IP_NOT_DETECTED]:8001
)
echo   • Localhost: http://localhost:8001
echo   • Local: http://127.0.0.1:8001
echo.
echo 💡 To connect from your mobile device:
echo   Use the IP address shown above in your app settings
echo.
echo To stop the server: Close this window or press Ctrl+C
echo.
echo ================================================================
echo.

cd /d "%~dp0"

REM Check for Python installation
echo 🐍 Checking Python installation...
echo.

REM Check if virtual environment exists
if exist "cattle_env\Scripts\activate.bat" (
    echo ✅ Found existing virtual environment
    goto :use_venv
) else (
    echo 📦 Setting up virtual environment for the first time...
    echo    This will only happen once and may take a few minutes...
    echo.
)

REM Try different Python commands to create venv
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Found Python: 
    python --version
    goto :setup_venv
)

python3 --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Found Python3: 
    python3 --version
    set PYTHON_CMD=python3
    goto :setup_venv
)

py --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Found Python (py launcher): 
    py --version
    set PYTHON_CMD=py
    goto :setup_venv
)

REM Python not found
echo ❌ Python was not found on this system!
echo.
echo � To fix this issue, you have several options:
echo.
echo   1. Install Python from python.org:
echo      • Go to https://python.org/downloads/
echo      • Download Python 3.8 or newer
echo      • During installation, check "Add Python to PATH"
echo.
echo   2. If Python is already installed:
echo      • Open Command Prompt as Administrator
echo      • Run: setx PATH "%%PATH%%;C:\Python39" (adjust path as needed)
echo      • Restart this batch file
echo.
echo   3. Use Microsoft Store Python (if available):
echo      • Search "Python" in Microsoft Store
echo      • Install Python 3.x
echo.
echo   4. Check if Python is in a different location:
echo      • Try running: where python
echo      • Add that location to your PATH environment variable
echo.
echo Press any key to open Python download page...
pause >nul
start https://python.org/downloads/
goto :end

:setup_venv
if not defined PYTHON_CMD set PYTHON_CMD=python

echo 🏗️ Creating virtual environment...
%PYTHON_CMD% -m venv cattle_env
if %errorlevel% neq 0 (
    echo ❌ Failed to create virtual environment
    echo    Make sure you have Python 3.6 or newer installed
    goto :end
)

echo 📥 Installing dependencies...
call cattle_env\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ⚠️  Some dependencies failed to install, but continuing...
)
echo ✅ Virtual environment setup complete!
echo.

:use_venv
echo 🔄 Activating virtual environment...
call cattle_env\Scripts\activate.bat

echo 🚀 Starting Cattle AI Server...
echo.
echo 📦 Checking required files...
if not exist "simple_ai_server.py" (
    echo ❌ Error: simple_ai_server.py not found!
    echo    Make sure you're running this from the Deploy folder.
    goto :end
)
if not exist "requirements.txt" (
    echo ⚠️  Warning: requirements.txt not found!
    echo    Dependencies might not be installed properly.
) else (
    echo ✅ Found requirements.txt
)
echo.
python simple_ai_server.py
goto :end

goto :end

:end

echo.
echo Server has stopped.
echo.
pause