#!/bin/bash
# Build script for PC Tweaks executable (Linux/Mac)

echo "Building PC Tweaks executable..."
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python is not installed or not in PATH"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "Installing dependencies..."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi

echo ""
echo "Building executable with PyInstaller..."
pyinstaller PC_Tweaks.spec
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build executable"
    exit 1
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo ""
echo "Executable location: dist/PC_Tweaks"
echo "========================================"
echo ""
