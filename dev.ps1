# First time setup
if (-not (Test-Path "backend\venv")) {
    Write-Host "Setting up backend..."
    Set-Location backend
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    Copy-Item .env.example .env -ErrorAction SilentlyContinue
    Set-Location ..
}

if (-not (Test-Path "frontend\node_modules")) {
    Write-Host "Setting up frontend..."
    Set-Location frontend
    npm install
    Copy-Item .env.example .env -ErrorAction SilentlyContinue
    Set-Location ..
}

# Start backend
Write-Host "Starting backend..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; .\venv\Scripts\Activate.ps1; python -m uvicorn src.main:app --reload --port 8000"

Start-Sleep -Seconds 2

# Start frontend
Write-Host "Starting frontend..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

Write-Host ""
Write-Host "✓ Frontend: http://localhost:5173"
Write-Host "✓ Backend:  http://localhost:8000"
Write-Host ""
Write-Host "Close the windows to stop servers"
