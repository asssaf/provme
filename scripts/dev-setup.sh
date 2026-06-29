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

# Ensure Elm compiler is installed
ELM_CACHE_DIR="$HOME/host-cache/elm"
ELM_CACHE_PATH="$ELM_CACHE_DIR/elm"

if [ ! -f "$ELM_CACHE_PATH" ]; then
    echo "Elm binary not found in host cache ($ELM_CACHE_PATH). Downloading..."
    mkdir -p "$ELM_CACHE_DIR"
    curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
    gunzip elm.gz
    chmod +x elm
    mv elm "$ELM_CACHE_PATH"
else
    echo "Elm compiler binary found in host cache."
fi

# Link cached binary to /usr/local/bin if not already in PATH
if ! command -v elm &> /dev/null; then
    echo "Creating symlink to /usr/local/bin/elm..."
    sudo ln -sf "$ELM_CACHE_PATH" /usr/local/bin/elm
fi

# Install elm-test-rs for frontend unit testing
if ! command -v elm-test-rs &> /dev/null; then
    echo "Installing elm-test-rs..."
    if command -v npm &> /dev/null; then
        sudo npm install -g elm-test-rs
    else
        echo "Warning: npm not found. Skipping elm-test-rs installation."
    fi
else
    echo "elm-test-rs already exists."
fi


echo "--------------------------------------------------------"
echo "Development environment setup complete!"
echo "To use the environment, activate the virtual environment:"
echo "  source .venv/bin/activate"
echo "--------------------------------------------------------"

