@echo off
setlocal enabledelayedexpansion

echo ======================================================================
echo       FreshFlow ERP — Unified Windows Project Runner
echo ======================================================================

set "ROOT_DIR=%~dp0"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "FRONTEND_DIR=%ROOT_DIR%\frontend"
set "VENV_DIR=%ROOT_DIR%\venv"
set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"
set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"

:: 1. Verify Python
echo [1/5] Verifying Python runtime...
set "PYTHON_CMD="
where python >nul 2>&1 && set "PYTHON_CMD=python"
if not defined PYTHON_CMD (
    where py >nul 2>&1 && set "PYTHON_CMD=py"
)

if not defined PYTHON_CMD (
    echo Error: Python >= 3.11 is required. Please install Python from https://www.python.org/
    exit /b 1
)

:: 2. Verify Node
echo [2/5] Verifying Node.js runtime...
where node >nul 2>&1 || (
    echo Error: Node.js is required. Please install from https://nodejs.org/
    exit /b 1
)

:: 3. Setup venv
echo [3/5] Setting up backend Python virtual environment...
if not exist "%VENV_PYTHON%" (
    echo Creating fresh virtual environment at %VENV_DIR%...
    %PYTHON_CMD% -m venv "%VENV_DIR%"
)

"%VENV_PYTHON%" -c "import django, rest_framework, rest_framework_simplejwt, corsheaders" >nul 2>&1 || (
    echo Installing backend dependencies...
    "%VENV_PIP%" install --upgrade pip
    "%VENV_PIP%" install -r "%BACKEND_DIR%\requirements.txt"
)

if not exist "%BACKEND_DIR%\.env" (
    if exist "%BACKEND_DIR%\.env.example" (
        copy "%BACKEND_DIR%\.env.example" "%BACKEND_DIR%\.env" >nul
    )
)

echo Applying backend database migrations...
"%VENV_PYTHON%" "%BACKEND_DIR%\manage.py" migrate --noinput

echo Ensuring demo accounts and inventory are seeded...
"%VENV_PYTHON%" "%BACKEND_DIR%\manage.py" seed_employees

if not exist "%BACKEND_DIR%\media\profile_pictures" (
    mkdir "%BACKEND_DIR%\media\profile_pictures" 2>nul
)

:: 4. Frontend Setup
echo [4/5] Preparing frontend dependencies and environment...
if not exist "%FRONTEND_DIR%\.env" (
    if not exist "%FRONTEND_DIR%\.env.local" (
        echo NEXT_PUBLIC_API_URL=http://localhost:8005/api> "%FRONTEND_DIR%\.env.local"
    )
)

if not exist "%FRONTEND_DIR%\node_modules" (
    echo Running npm install...
    call npm.cmd --prefix "%FRONTEND_DIR%" install
)

:: 5. Launch Services
echo [5/5] Launching FreshFlow ERP services...
echo Local Access:
echo   - Frontend:     http://localhost:3000
echo   - Backend API:  http://localhost:8005/api
echo   - Admin Panel:  http://localhost:8005/admin
echo ----------------------------------------------------------------------

start "FreshFlow Backend (Django)" /d "%BACKEND_DIR%" "%VENV_PYTHON%" manage.py runserver 0.0.0.0:8005
start "FreshFlow Frontend (Next.js)" /d "%FRONTEND_DIR%" npm.cmd run dev -- -H 0.0.0.0

echo FreshFlow ERP services are running!
