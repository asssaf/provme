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

# Ensure Gleam compiler is installed
GLEAM_CACHE_DIR="$HOME/host-cache/gleam"
GLEAM_CACHE_PATH="$GLEAM_CACHE_DIR/gleam"

if [ ! -f "$GLEAM_CACHE_PATH" ]; then
    echo "Gleam binary not found in host cache ($GLEAM_CACHE_PATH). Downloading..."
    mkdir -p "$GLEAM_CACHE_DIR"
    curl -L -o gleam.tar.gz https://github.com/gleam-lang/gleam/releases/download/v1.17.0/gleam-v1.17.0-x86_64-unknown-linux-musl.tar.gz
    tar xf gleam.tar.gz
    chmod +x gleam
    mv gleam "$GLEAM_CACHE_PATH"
    rm -f gleam.tar.gz
else
    echo "Gleam compiler binary found in host cache."
fi

# Link cached binary to /usr/local/bin if not already in PATH
if ! command -v gleam &> /dev/null; then
    echo "Creating symlink to /usr/local/bin/gleam..."
    sudo ln -sf "$GLEAM_CACHE_PATH" /usr/local/bin/gleam
fi

# Ensure esbuild is installed
ESBUILD_CACHE_DIR="$HOME/host-cache/esbuild"
ESBUILD_CACHE_PATH="$ESBUILD_CACHE_DIR/esbuild"

if [ ! -f "$ESBUILD_CACHE_PATH" ]; then
    echo "esbuild binary not found in host cache ($ESBUILD_CACHE_PATH). Downloading..."
    mkdir -p "$ESBUILD_CACHE_DIR"
    curl -fsSL https://esbuild.github.io/dl/v0.20.1 | sh
    chmod +x esbuild
    mv esbuild "$ESBUILD_CACHE_PATH"
else
    echo "esbuild binary found in host cache."
fi

# Link cached binary to /usr/local/bin if not already in PATH
if ! command -v esbuild &> /dev/null; then
    echo "Creating symlink to /usr/local/bin/esbuild..."
    sudo ln -sf "$ESBUILD_CACHE_PATH" /usr/local/bin/esbuild
fi



echo "--------------------------------------------------------"
echo "Development environment setup complete!"
echo "To use the environment, activate the virtual environment:"
echo "  source .venv/bin/activate"
echo "--------------------------------------------------------"

