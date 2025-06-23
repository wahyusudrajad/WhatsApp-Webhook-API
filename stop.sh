#!/bin/bash

# WhatsApp Webhook API - Stop Script
# Usage: ./stop.sh

echo "🛑 Stopping WhatsApp Webhook API..."

# Function to stop process by PID file
stop_service() {
    local service_name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "🔴 Stopping $service_name (PID: $pid)..."
            kill "$pid"
            
            # Wait for process to stop
            local count=0
            while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  Force killing $service_name..."
                kill -9 "$pid" 2>/dev/null
            fi
            
            echo "✅ $service_name stopped"
        else
            echo "⚠️  $service_name was not running"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  No PID file found for $service_name"
    fi
}

# Stop services
stop_service "Flask backend" ".flask.pid"
stop_service "WhatsApp service" ".whatsapp.pid"

# Kill any remaining processes on ports 3000 and 5000
echo "🧹 Cleaning up remaining processes..."

# Kill processes on port 3000
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔴 Killing remaining processes on port 3000..."
    kill $(lsof -ti:3000) 2>/dev/null || true
fi

# Kill processes on port 5000
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔴 Killing remaining processes on port 5000..."
    kill $(lsof -ti:5000) 2>/dev/null || true
fi

echo ""
echo "✅ All services stopped successfully!"
echo "📝 To start again, run: ./start.sh"

