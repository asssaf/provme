#!/bin/bash
set -e

echo "Starting development environment setup for Python..."

# Ensure Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3 and venv..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip
else
    echo "Python 3 already exists."
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment .venv..."
    python3 -m venv .venv
else
    echo "Virtual environment .venv already exists."
fi

# Upgrade pip and install dependencies
echo "Upgrading pip and installing dependencies..."
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo "--------------------------------------------------------"
echo "Development environment setup complete!"
echo "To use the environment, activate the virtual environment:"
echo "  source .venv/bin/activate"
echo "--------------------------------------------------------"
