# ==============================================================================
# FreshFlow ERP — Unified Windows PowerShell Project Runner
# ==============================================================================

$ErrorActionPreference = "Stop"
$ROOT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKEND_DIR = Join-Path $ROOT_DIR "backend"
$FRONTEND_DIR = Join-Path $ROOT_DIR "frontend"
$VENV_DIR = Join-Path $ROOT_DIR "venv"
$VENV_PYTHON = Join-Path $VENV_DIR "Scripts\python.exe"
$VENV_PIP = Join-Path $VENV_DIR "Scripts\pip.exe"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "      FreshFlow ERP — Unified Windows PowerShell Project Runner       " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ─── 1. Check Python ──────────────────────────────────────────────────────────
Write-Host "[1/5] Verifying Python runtime..." -ForegroundColor Blue
$PYTHON_CMD = $null
foreach ($cmd in @("python", "py", "python3")) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) {
        $check = & $cmd -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $PYTHON_CMD = $cmd
            break
        }
    }
}

if (-not $PYTHON_CMD) {
    Write-Host "Error: Python >= 3.11 is required. Please install Python from https://www.python.org/downloads/." -ForegroundColor Red
    exit 1
}

$pyVersion = & $PYTHON_CMD --version
Write-Host "✓ Using Python: $pyVersion ($PYTHON_CMD)" -ForegroundColor Green

# ─── 2. Check Node.js & npm ───────────────────────────────────────────────────
Write-Host "[2/5] Verifying Node.js runtime..." -ForegroundColor Blue
$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "Error: Node.js (>= 18.18 / 20 LTS) is required. Install from https://nodejs.org/" -ForegroundColor Red
    exit 1
}
$nodeVer = & node -v
Write-Host "✓ Using Node.js: $nodeVer" -ForegroundColor Green

# ─── 3. Backend Virtualenv & Dependencies ─────────────────────────────────────
Write-Host "[3/5] Setting up backend Python virtual environment..." -ForegroundColor Blue
if (-not (Test-Path $VENV_PYTHON)) {
    Write-Host "Creating fresh virtualenv at $VENV_DIR..." -ForegroundColor Yellow
    & $PYTHON_CMD -m venv $VENV_DIR
}

Write-Host "✓ Virtual environment ready: $VENV_DIR" -ForegroundColor Green

$reqInstalled = & $VENV_PYTHON -c "import django, rest_framework, rest_framework_simplejwt, corsheaders" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing backend dependencies from requirements.txt..." -ForegroundColor Yellow
    & $VENV_PIP install --upgrade pip
    & $VENV_PIP install -r (Join-Path $BACKEND_DIR "requirements.txt")
}

# Ensure backend .env exists
$backendEnv = Join-Path $BACKEND_DIR ".env"
if (-not (Test-Path $backendEnv)) {
    $backendEnvExample = Join-Path $BACKEND_DIR ".env.example"
    if (Test-Path $backendEnvExample) {
        Copy-Item $backendEnvExample $backendEnv
    } else {
        @"
SECRET_KEY=django-insecure-freshflow-$(New-Guid)
DEBUG=True
ALLOWED_HOSTS=*
CORS_ALLOWED_ORIGINS=http://localhost:3000
USE_TURSO=False
"@ | Out-File -FilePath $backendEnv -Encoding utf8
    }
}

Write-Host "Applying backend database migrations..." -ForegroundColor Blue
& $VENV_PYTHON (Join-Path $BACKEND_DIR "manage.py") migrate --noinput

Write-Host "Ensuring demo accounts and inventory are seeded..." -ForegroundColor Blue
& $VENV_PYTHON (Join-Path $BACKEND_DIR "manage.py") seed_employees

# Ensure media directory exists
$mediaDir = Join-Path $BACKEND_DIR "media\profile_pictures"
if (-not (Test-Path $mediaDir)) {
    New-Item -ItemType Directory -Path $mediaDir -Force | Out-Null
}

# ─── 4. Frontend Setup & Dependencies ─────────────────────────────────────────
Write-Host "[4/5] Preparing frontend dependencies and environment..." -ForegroundColor Blue
$frontendEnv = Join-Path $FRONTEND_DIR ".env"
$frontendEnvLocal = Join-Path $FRONTEND_DIR ".env.local"
if ((-not (Test-Path $frontendEnv)) -and (-not (Test-Path $frontendEnvLocal))) {
    "NEXT_PUBLIC_API_URL=http://localhost:8005/api" | Out-File -FilePath $frontendEnvLocal -Encoding utf8
}

$frontendModules = Join-Path $FRONTEND_DIR "node_modules"
if (-not (Test-Path $frontendModules)) {
    Write-Host "frontend/node_modules not found. Running npm install..." -ForegroundColor Yellow
    npm.cmd --prefix $FRONTEND_DIR install
}

# ─── 5. Launch Services Concurrently ─────────────────────────────────────────
Write-Host "[5/5] Launching FreshFlow ERP services..." -ForegroundColor Blue
Write-Host "✓ Local Access:" -ForegroundColor Green
Write-Host "  - Frontend:     http://localhost:3000" -ForegroundColor Cyan
Write-Host "  - Backend API:  http://localhost:8005/api" -ForegroundColor Cyan
Write-Host "  - Admin Panel:  http://localhost:8005/admin" -ForegroundColor Cyan
Write-Host "Press [CTRL+C] at any time to stop services." -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan

$backendProcess = Start-Process -FilePath $VENV_PYTHON -ArgumentList (Join-Path $BACKEND_DIR "manage.py"), "runserver", "0.0.0.0:8005" -PassThru
$frontendProcess = Start-Process -FilePath "npm.cmd" -ArgumentList "--prefix", "`"$FRONTEND_DIR`"", "run", "dev", "--", "-H", "0.0.0.0" -PassThru

try {
    Wait-Process -Id $backendProcess.Id, $frontendProcess.Id
} finally {
    Write-Host "`nStopping FreshFlow services..." -ForegroundColor Yellow
    if ($backendProcess -and -not $backendProcess.HasExited) {
        Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($frontendProcess -and -not $frontendProcess.HasExited) {
        Stop-Process -Id $frontendProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "All FreshFlow services stopped cleanly." -ForegroundColor Green
}
