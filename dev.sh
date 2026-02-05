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
