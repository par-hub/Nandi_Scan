@echo off
echo Starting Cattle Breed Classification FastAPI Server...
echo.
echo Prerequisites:
echo - Python with PyTorch, FastAPI, and dependencies installed
echo - Model file at models/stable_cattle_model.pth
echo.

cd /d "%~dp0Deploy"

if not exist "models\stable_cattle_model.pth" (
    echo Error: Model file not found at models/stable_cattle_model.pth
    echo Please ensure the model file is in the correct location.
    pause
    exit /b 1
)

echo Starting server on http://127.0.0.1:8000
echo.
echo API Endpoints:
echo - Health Check: http://127.0.0.1:8000/health
echo - Prediction: http://127.0.0.1:8000/predict
echo - API Docs: http://127.0.0.1:8000/docs
echo.

python app.py

if %ERRORLEVEL% neq 0 (
    echo.
    echo Error starting server. Common issues:
    echo 1. Python not installed or not in PATH
    echo 2. Missing dependencies - run: pip install torch torchvision fastapi uvicorn pillow
    echo 3. Model file missing or corrupted
    echo 4. Port 8000 already in use
    echo.
    pause
)