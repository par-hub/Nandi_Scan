@echo off
title Setup Cattle AI Server Environment
color 0B
echo.
echo ================================================================
echo               CATTLE AI SERVER - ENVIRONMENT SETUP
echo ================================================================
echo.

cd /d "%~dp0"

echo 🔧 Setting up Python virtual environment for Cattle AI Server...
echo.

REM Check if Python is available
echo 🐍 Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found! Please install Python 3.8+ first.
    echo    Visit: https://python.org/downloads/
    pause
    exit /b 1
)

python --version
echo.

REM Check if virtual environment already exists
if exist "venv" (
    echo 📁 Virtual environment already exists.
    echo    Do you want to recreate it? This will delete the existing environment.
    set /p recreate="Recreate environment? (y/N): "
    if /i "!recreate!"=="y" (
        echo 🗑️  Removing existing virtual environment...
        rmdir /s /q venv
    ) else (
        echo ✅ Using existing virtual environment.
        goto :activate_and_install
    )
)

REM Create virtual environment
echo 📦 Creating virtual environment...
python -m venv venv
if %errorlevel% neq 0 (
    echo ❌ Failed to create virtual environment!
    echo    Make sure you have the 'venv' module available.
    pause
    exit /b 1
)

echo ✅ Virtual environment created successfully.
echo.

:activate_and_install
echo 🔌 Activating virtual environment...
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ Failed to activate virtual environment!
    pause
    exit /b 1
)

echo ✅ Virtual environment activated.
echo.

echo 📥 Upgrading pip...
python -m pip install --upgrade pip
echo.

REM Check if requirements.txt exists
if not exist "requirements.txt" (
    echo ❌ requirements.txt not found!
    echo    Creating a basic requirements file...
    echo # Cattle AI Server Requirements > requirements.txt
    echo torch^>=2.0.0 >> requirements.txt
    echo torchvision^>=0.15.0 >> requirements.txt
    echo fastapi^>=0.100.0 >> requirements.txt
    echo uvicorn[standard]^>=0.23.0 >> requirements.txt
    echo Pillow^>=10.0.0 >> requirements.txt
    echo requests^>=2.31.0 >> requirements.txt
    echo python-multipart^>=0.0.6 >> requirements.txt
    echo ✅ Created basic requirements.txt
)

echo 📦 Installing dependencies from requirements.txt...
echo    This may take several minutes, especially for PyTorch...
echo.

REM Install requirements with better output
python -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  Some dependencies may have failed to install.
    echo    This might be due to:
    echo    - Network connectivity issues
    echo    - Missing system dependencies
    echo    - Incompatible Python version
    echo.
    echo    You can try installing manually:
    echo    1. Activate the environment: venv\Scripts\activate.bat
    echo    2. Install PyTorch: pip install torch torchvision
    echo    3. Install other deps: pip install fastapi uvicorn pillow requests
    echo.
) else (
    echo.
    echo ✅ All dependencies installed successfully!
    echo.
)

echo 🧪 Testing imports...
python -c "import torch; print('✅ PyTorch:', torch.__version__)" 2>nul || echo "❌ PyTorch import failed"
python -c "import PIL; print('✅ PIL (Pillow):', PIL.__version__)" 2>nul || echo "❌ PIL import failed"
python -c "import fastapi; print('✅ FastAPI:', fastapi.__version__)" 2>nul || echo "❌ FastAPI import failed"
python -c "import uvicorn; print('✅ Uvicorn:', uvicorn.__version__)" 2>nul || echo "❌ Uvicorn import failed"
echo.

echo ================================================================
echo                         SETUP COMPLETE!
echo ================================================================
echo.
echo 📁 Virtual environment location: %~dp0venv
echo.
echo 🚀 To start the server in the future, use one of these methods:
echo.
echo   Method 1: Use the updated START_CATTLE_SERVER.bat (recommended)
echo   Method 2: Manual activation
echo     1. cd /d "%~dp0"
echo     2. venv\Scripts\activate.bat
echo     3. python simple_ai_server.py
echo.
echo 💡 The environment is now ready with all dependencies!
echo.
pause