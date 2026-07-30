@echo off
setlocal enabledelayedexpansion
title Smart Security System Launcher
cd /d "%~dp0"

echo ============================================
echo   Smart Security System - Launcher
echo ============================================
echo.

REM --- 1. Check Python 3.11 is installed via the py launcher ---
py -3.11 --version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python 3.11 was not found.
    echo This project requires Python 3.11 specifically ^(mediapipe/tensorflow
    echo do not yet support newer Python versions^).
    echo Install it from https://www.python.org/downloads/release/python-3119/
    pause
    exit /b 1
)

REM --- 2. Create virtual environment if it doesn't exist ---
if not exist "venv\Scripts\activate.bat" (
    echo [1/5] Creating virtual environment with Python 3.11...
    py -3.11 -m venv venv
) else (
    echo [1/5] Virtual environment already exists, skipping creation.
)

REM --- 3. Activate virtual environment ---
echo [2/5] Activating virtual environment...
call venv\Scripts\activate.bat

REM --- 4. Install dependencies (only if marker file missing) ---
if not exist "venv\installed.flag" (
    echo [3/5] Installing dependencies from requirements.txt...
    echo       This may take several minutes on first run...
    pip install --upgrade pip >nul
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Dependency installation failed. See errors above.
        pause
        exit /b 1
    )
    echo done> venv\installed.flag
) else (
    echo [3/5] Dependencies already installed, skipping.
)

REM --- 5. Initialize ChromaDB collection if missing ---
if not exist "backend\db\chromadb_data" (
    echo [4/5] Initializing ChromaDB collection...
    python backend\db\create_chroma_db.py
) else (
    echo [4/5] ChromaDB already initialized, skipping.
)

REM --- 6. Warn if .env / GROQ key missing ---
if not exist ".env" (
    echo.
    echo [NOTE] No .env file found - the chatbot feature will not work
    echo        until you create a .env file with GROQ_API_KEY=your_key_here
    echo.
)

REM --- 7. Start the server in a new window, then open the browser ---
echo [5/5] Starting server on http://localhost:8000 ...
start "Smart Security System - Server" cmd /k "call venv\Scripts\activate.bat && uvicorn main:app --host 0.0.0.0 --port 8000"

REM Give the server a few seconds to boot before opening the browser
timeout /t 5 /nobreak >nul
start "" "http://localhost:8000/dashboard"

echo.
echo Server is running in a separate window titled "Smart Security System - Server".
echo Close that window (or press Ctrl+C in it) to stop the server.
echo This launcher window can be closed safely.
echo.
pause
