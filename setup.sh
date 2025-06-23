#!/bin/bash

# WhatsApp Webhook API - Setup Script
# Usage: ./setup.sh

echo "🔧 Setting up WhatsApp Webhook API..."

# Check system requirements
echo "🔍 Checking system requirements..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "✅ Python $PYTHON_VERSION found"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js $NODE_VERSION found"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo "✅ npm $NPM_VERSION found"

# Create virtual environment if not exists
if [ ! -d "venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Python dependencies installed"

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install
echo "✅ Node.js dependencies installed"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p src/database
mkdir -p logs
mkdir -p backups

# Set permissions for scripts
echo "🔐 Setting script permissions..."
chmod +x start.sh
chmod +x stop.sh

# Create .env template
if [ ! -f ".env" ]; then
    echo "📝 Creating .env template..."
    cat > .env << EOF
# WhatsApp Webhook API Configuration
FLASK_SECRET_KEY=your-super-secret-key-here
API_KEY=your-api-key-here
WHATSAPP_SERVICE_URL=http://localhost:3000
DATABASE_URL=sqlite:///src/database/app.db
FLASK_ENV=development
NODE_ENV=development
EOF
    echo "✅ .env template created"
else
    echo "✅ .env file already exists"
fi

# Create .gitignore
if [ ! -f ".gitignore" ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# WhatsApp session data
auth_info_baileys/

# Environment variables
.env

# Logs
logs/
*.log

# Database
*.db
*.sqlite

# Backups
backups/

# Process IDs
*.pid

# OS
.DS_Store
Thumbs.db
EOF
    echo "✅ .gitignore created"
else
    echo "✅ .gitignore already exists"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Review and update .env file with your configuration"
echo "   2. Run: ./start.sh"
echo "   3. Open http://localhost:5000 in your browser"
echo "   4. Scan QR code with WhatsApp"
echo ""
echo "📚 Documentation:"
echo "   - README.md: Complete documentation"
echo "   - QUICKSTART.md: Quick start guide"
echo ""
echo "🚀 Ready to start? Run: ./start.sh"

