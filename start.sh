#!/bin/bash

# WhatsApp Webhook API - Start Script
# Usage: ./start.sh

echo "🚀 Starting WhatsApp Webhook API..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run setup first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if dependencies are installed
if ! pip show flask > /dev/null 2>&1; then
    echo "📦 Installing Python dependencies..."
    pip install -r requirements.txt
fi

if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Function to check if port is available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ Port $1 is already in use"
        echo "   Kill process with: kill \$(lsof -ti:$1)"
        return 1
    fi
    return 0
}

# Check ports
echo "🔍 Checking ports..."
check_port 3000 || exit 1
check_port 5000 || exit 1

echo "✅ Ports are available"

# Start WhatsApp service in background
echo "🟢 Starting WhatsApp service on port 3000..."
node whatsapp-service.js &
WHATSAPP_PID=$!

# Wait for WhatsApp service to start
sleep 3

# Check if WhatsApp service is running
if ! kill -0 $WHATSAPP_PID 2>/dev/null; then
    echo "❌ Failed to start WhatsApp service"
    exit 1
fi

echo "✅ WhatsApp service started (PID: $WHATSAPP_PID)"

# Start Flask backend
echo "🟢 Starting Flask backend on port 5000..."
python src/main.py &
FLASK_PID=$!

# Wait for Flask to start
sleep 3

# Check if Flask is running
if ! kill -0 $FLASK_PID 2>/dev/null; then
    echo "❌ Failed to start Flask backend"
    kill $WHATSAPP_PID 2>/dev/null
    exit 1
fi

echo "✅ Flask backend started (PID: $FLASK_PID)"

# Save PIDs for stop script
echo $WHATSAPP_PID > .whatsapp.pid
echo $FLASK_PID > .flask.pid

echo ""
echo "🎉 WhatsApp Webhook API is running!"
echo ""
echo "📱 Web Interface: http://localhost:5000"
echo "🔗 API Base URL: http://localhost:5000/api/whatsapp"
echo ""
echo "📋 Next steps:"
echo "   1. Open http://localhost:5000 in your browser"
echo "   2. Click 'Refresh Status' to generate QR code"
echo "   3. Scan QR code with WhatsApp on your phone"
echo "   4. Start sending messages via API!"
echo ""
echo "🛑 To stop services, run: ./stop.sh"
echo ""

# Keep script running and monitor processes
trap 'echo ""; echo "🛑 Stopping services..."; kill $WHATSAPP_PID $FLASK_PID 2>/dev/null; rm -f .whatsapp.pid .flask.pid; exit 0' INT

echo "📊 Monitoring services... (Press Ctrl+C to stop)"
while true; do
    if ! kill -0 $WHATSAPP_PID 2>/dev/null; then
        echo "❌ WhatsApp service stopped unexpectedly"
        kill $FLASK_PID 2>/dev/null
        rm -f .whatsapp.pid .flask.pid
        exit 1
    fi
    
    if ! kill -0 $FLASK_PID 2>/dev/null; then
        echo "❌ Flask backend stopped unexpectedly"
        kill $WHATSAPP_PID 2>/dev/null
        rm -f .whatsapp.pid .flask.pid
        exit 1
    fi
    
    sleep 5
done

