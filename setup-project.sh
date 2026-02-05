#!/bin/bash

echo "Creating Trading Backtest System with TypeScript..."

# Backend structure
mkdir -p backend/src/{data/indicators,strategy,position_generator,analysis,api/routes,models,utils}
mkdir -p backend/tests/{test_data,test_strategy,test_position_generator,test_analysis}

# Frontend structure
mkdir -p frontend/{public,src/{components/{common,data,strategy,backtest,analysis},pages,services,store,utils,types}}

# Shared and docs
mkdir -p shared
mkdir -p docker
mkdir -p docs

# Create backend __init__.py files
touch backend/src/__init__.py
touch backend/src/data/__init__.py
touch backend/src/data/indicators/__init__.py
touch backend/src/strategy/__init__.py
touch backend/src/position_generator/__init__.py
touch backend/src/analysis/__init__.py
touch backend/src/api/__init__.py
touch backend/src/api/routes/__init__.py
touch backend/src/models/__init__.py
touch backend/src/utils/__init__.py
touch backend/tests/__init__.py

# Create backend Python files
touch backend/src/main.py
touch backend/src/data/{warehouse.py,filters.py,transformations.py}
touch backend/src/data/indicators/{volume.py,trend.py,momentum.py,volatility.py}
touch backend/src/strategy/{base.py,parser.py,validator.py}
touch backend/src/position_generator/{generator.py,execution.py,costs.py,trade_logger.py}
touch backend/src/analysis/{metrics.py,monte_carlo.py,variance.py}
touch backend/src/api/routes/{data.py,strategy.py,backtest.py,analysis.py}
touch backend/src/api/middleware.py
touch backend/src/models/{data.py,strategy.py,position.py,analysis.py}
touch backend/src/utils/{config.py,helpers.py}

# Create frontend TypeScript files
touch frontend/public/index.html
touch frontend/src/{App.tsx,main.tsx,vite-env.d.ts}
touch frontend/src/types/index.ts
touch frontend/src/components/common/{Button.tsx,Input.tsx,Dropdown.tsx}
touch frontend/src/components/data/{DataSelector.tsx,DataFilter.tsx}
touch frontend/src/components/strategy/{StrategyBuilder.tsx,IndicatorSelector.tsx,IndicatorSearch.tsx,IndicatorConfig.tsx}
touch frontend/src/components/backtest/{BacktestRunner.tsx,ExecutionSettings.tsx,CostSettings.tsx}
touch frontend/src/components/analysis/{MetricsDisplay.tsx,EquityCurve.tsx,TradeLog.tsx,DrawdownChart.tsx}
touch frontend/src/pages/{Home.tsx,StrategyPage.tsx,BacktestPage.tsx,ResultsPage.tsx}
touch frontend/src/services/{api.ts,dataService.ts,strategyService.ts,backtestService.ts}
touch frontend/src/store/{index.ts,dataSlice.ts,strategySlice.ts,backtestSlice.ts}
touch frontend/src/utils/{constants.ts,helpers.ts}

# Create shared files
touch shared/indicator_definitions.json

# Create docker files
touch docker/{Dockerfile.backend,Dockerfile.frontend,docker-compose.yml}

# Create documentation
touch docs/{API.md,ARCHITECTURE.md,INDICATORS.md}

# Create root files
touch {.gitignore,README.md}

# ============================================
# CREATE BACKEND FILES WITH CONTENT
# ============================================

# backend/requirements.txt
cat > backend/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0
pandas==2.2.0
numpy==1.26.2
python-dotenv==1.0.0
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.1
python-multipart==0.0.6
aiofiles==23.2.1
EOF

# backend/.env.example
cat > backend/.env.example << 'EOF'
# Database
DATABASE_URL=sqlite:///./backtest.db

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=True

# CORS
CORS_ORIGINS=http://localhost:5173,http://localhost:3000

# Data Sources
ALPHA_VANTAGE_API_KEY=your_key_here
POLYGON_API_KEY=your_key_here

# Security
SECRET_KEY=your-secret-key-change-in-production
EOF

# backend/src/main.py
cat > backend/src/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(
    title="Trading Backtest API",
    description="API for backtesting trading strategies",
    version="1.0.0"
)

# CORS
origins = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Trading Backtest API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("API_PORT", 8000)),
        reload=os.getenv("DEBUG", "True") == "True"
    )
EOF

# ============================================
# CREATE FRONTEND FILES WITH CONTENT
# ============================================

# frontend/package.json
cat > frontend/package.json << 'EOF'
{
  "name": "trading-backtest-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.2",
    "recharts": "^2.10.3",
    "zustand": "^4.4.7"
  },
  "devDependencies": {
    "@types/react": "^18.2.42",
    "@types/react-dom": "^18.2.17",
    "@typescript-eslint/eslint-plugin": "^6.14.0",
    "@typescript-eslint/parser": "^6.14.0",
    "@vitejs/plugin-react": "^4.2.1",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "typescript": "^5.3.3",
    "vite": "^5.0.5"
  }
}
EOF

# frontend/tsconfig.json
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    /* Path aliases */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# frontend/tsconfig.node.json
cat > frontend/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

# frontend/vite.config.ts
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      }
    }
  }
})
EOF

# frontend/.env.example
cat > frontend/.env.example << 'EOF'
VITE_API_URL=http://localhost:8000
VITE_API_TIMEOUT=30000
EOF

# frontend/public/index.html
cat > frontend/public/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Trading Backtest System</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# frontend/src/vite-env.d.ts
cat > frontend/src/vite-env.d.ts << 'EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_API_TIMEOUT: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
EOF

# frontend/src/main.tsx
cat > frontend/src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# frontend/src/App.tsx
cat > frontend/src/App.tsx << 'EOF'
import { useState } from 'react'

function App() {
  const [count, setCount] = useState<number>(0)

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Trading Backtest System</h1>
      <p>Backend and Frontend are connected!</p>
      <button 
        onClick={() => setCount((count) => count + 1)}
        style={{ 
          padding: '0.5rem 1rem', 
          fontSize: '1rem',
          cursor: 'pointer'
        }}
      >
        Count: {count}
      </button>
    </div>
  )
}

export default App
EOF

# frontend/src/types/index.ts
cat > frontend/src/types/index.ts << 'EOF'
// Data types
export interface OHLCVData {
  timestamp: string
  open: number
  high: number
  low: number
  close: number
  volume: number
}

export interface Strategy {
  id: string
  name: string
  description?: string
  indicators: Indicator[]
  conditions: Condition[]
}

export interface Indicator {
  id: string
  name: string
  type: string
  parameters: Record<string, any>
}

export interface Condition {
  id: string
  indicator: string
  operator: 'gt' | 'lt' | 'eq' | 'gte' | 'lte'
  value: number
}

export interface Position {
  id: string
  timestamp: string
  type: 'long' | 'short'
  entry_price: number
  exit_price?: number
  quantity: number
  pnl?: number
}

export interface BacktestResult {
  total_return: number
  sharpe_ratio: number
  max_drawdown: number
  win_rate: number
  positions: Position[]
}
EOF

# frontend/src/services/api.ts
cat > frontend/src/services/api.ts << 'EOF'
import axios, { AxiosInstance } from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api: AxiosInstance = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

export default api
EOF

# ============================================
# CREATE .GITIGNORE
# ============================================

cat > .gitignore << 'EOF'
# Virtual environments
backend/venv/
backend/env/

# Node modules
frontend/node_modules/

# Environment files
backend/.env
frontend/.env
.env

# Python cache
__pycache__/
*.pyc

# OS files
.DS_Store
Thumbs.db

# Logs
*.log

# Database
*.db
*.sqlite

# Build
frontend/dist/
frontend/build/

# IDE
.vscode/
.idea/
*.swp
EOF

# ============================================
# CREATE README
# ============================================

cat > README.md << 'EOF'
# Trading Backtest System

A full-stack backtesting platform with Python backend and React TypeScript frontend.

## Prerequisites

- Python 3.9-3.11 (NOT 3.14)
- Node.js 16+

## Getting Started

### Linux/Mac
```bash
chmod +x dev.sh
./dev.sh
```

### Windows
```powershell
.\dev.ps1
```

## Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

## Stopping the Servers

- **Linux/Mac**: Press `Ctrl+C` in the terminal
- **Windows**: Close the PowerShell windows

## Tech Stack

- **Backend**: Python, FastAPI, Pandas
- **Frontend**: React, TypeScript, Vite, Zustand
- **Charts**: Recharts
EOF

# ============================================
# CREATE DEV.SH
# ============================================

cat > dev.sh << 'EOF'
#!/bin/bash

# First time setup
if [ ! -d "backend/venv" ]; then
    echo "Setting up backend..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    cp .env.example .env 2>/dev/null || true
    cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "Setting up frontend..."
    cd frontend
    npm install
    cp .env.example .env 2>/dev/null || true
    cd ..
fi

# Cleanup function
cleanup() {
    echo "Shutting down..."
    kill $(jobs -p) 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
python -m uvicorn src.main:app --reload --port 8000 &
cd ..

sleep 2

echo "Starting frontend..."
cd frontend
npm run dev &
cd ..

echo ""
echo "✓ Frontend: http://localhost:5173"
echo "✓ Backend:  http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop"

wait
EOF

chmod +x dev.sh

# ============================================
# CREATE DEV.PS1 (Windows)
# ============================================

cat > dev.ps1 << 'EOF'
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
EOF

echo ""
echo "✅ Project structure created successfully!"
echo ""
echo "Next steps:"
echo "1. chmod +x dev.sh"
echo "2. ./dev.sh"
echo ""
echo "Note: Make sure you're using Python 3.9-3.11 (NOT 3.14)"
EOF

chmod +x setup-project.sh