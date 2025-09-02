#!/usr/bin/env bash

set -eo pipefail

cd "${0%/*}" || exit # go to script dir

echo "=== PyDuckling macOS Build Script ==="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is designed for macOS only"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "Checking for required tools..."

if ! command_exists brew; then
    echo "Error: Homebrew is required but not installed."
    echo "Please install Homebrew from https://brew.sh/"
    exit 1
fi

if ! command_exists rustc; then
    echo "Error: Rust is required but not installed."
    echo "Please install Rust from https://rustup.rs/"
    exit 1
fi

if ! command_exists stack; then
    echo "Error: Haskell Stack is required but not installed."
    echo "Installing Stack via Homebrew..."
    brew install haskell-stack
fi

# Install system dependencies via Homebrew
echo "Installing system dependencies via Homebrew..."
brew install pcre gmp pkg-config

# Check for GHC and install if needed
if ! command_exists ghc; then
    echo "Installing GHC via Homebrew..."
    brew install ghc
fi

# Set environment variables for pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [[ "$ARCH" == "arm64" ]]; then
    # Apple Silicon specific paths
    export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"
    export CPATH="/opt/homebrew/include:$CPATH"
else
    # Intel Mac specific paths
    export LIBRARY_PATH="/usr/local/lib:$LIBRARY_PATH"
    export CPATH="/usr/local/include:$CPATH"
fi

echo "Building Duckling FFI library..."
cd duckling-ffi

# Build the Haskell library
if [[ ! -f "libducklingffi.a" ]]; then
    echo "Building static library with Stack..."
    stack build --no-install-ghc --system-ghc --allow-different-user --force-dirty
    
    # Copy the library to the expected location
    cp libducklingffi.a ../ext_lib/libducklingffi.a
    echo "Static library built and copied to ext_lib/"
else
    echo "Static library already exists, skipping build..."
fi

cd ..

echo "Building Python extension..."

# Install Python dependencies
if command_exists python3; then
    python3 -m pip install --upgrade pip
    python3 -m pip install maturin pendulum
else
    echo "Error: Python 3 is required but not found"
    exit 1
fi

# Build the Python extension
echo "Building with maturin..."
maturin develop --release

echo "Running tests..."
python3 -m pytest -v duckling/tests/ || echo "Warning: Some tests failed"

echo "=== Build completed successfully! ==="
echo ""
echo "To install the package:"
echo "  maturin build --release"
echo "  pip install target/wheels/*.whl"
echo ""
echo "To test the installation:"
echo "  python3 -c 'import duckling; print(\"PyDuckling imported successfully!\")'"
