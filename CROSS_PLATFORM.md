# Cross-Platform Build Guide

This document explains how to build PyDuckling on different platforms and the various configuration options available.

## Supported Platforms

- **Linux** (x86_64) - Full support with Docker-based builds
- **macOS** (Intel and Apple Silicon) - Native support with Homebrew
- **Windows** - Not yet supported (contributions welcome)

## Build Methods

### Linux (Recommended)

#### Docker Build (Easiest)
```bash
./build.sh
```
This uses the existing Docker-based build system that handles all dependencies automatically.

#### Native Build
```bash
# Install system dependencies
sudo apt-get install build-essential libpcre3-dev libgmp-dev pkg-config

# Install Rust and Haskell Stack
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
curl -sSL https://get.haskellstack.org/ | sh

# Build the project
cd duckling-ffi
stack build
cp libducklingffi.a ../ext_lib/
cd ..
maturin develop
```

### macOS

#### Homebrew Build (Recommended)
```bash
./build-macos.sh
```

#### Manual Build
```bash
# Install dependencies via Homebrew
brew install pcre gmp pkg-config haskell-stack ghc rust

# Build the project
cd duckling-ffi
stack build --system-ghc
cp libducklingffi.a ../ext_lib/
cd ..
maturin develop
```

## Feature Flags

PyDuckling supports different feature configurations to reduce system dependencies:

### Default Features
- `system-pcre`: Uses system-installed PCRE library (default)

### Alternative Features
- `rust-regex`: Uses Rust's regex crate instead of system PCRE

#### Building with Rust Regex
```bash
# Build with Rust regex instead of system PCRE
maturin develop --features rust-regex --no-default-features

# Or for release builds
maturin build --release --features rust-regex --no-default-features
```

## Dependency Management

### System Dependencies

#### Required on All Platforms
- **GMP** (GNU Multiple Precision Arithmetic Library)
  - Linux: `libgmp-dev` or `gmp-devel`
  - macOS: `brew install gmp`
  - Used for arbitrary precision arithmetic in Haskell

#### Optional (Feature-Dependent)
- **PCRE** (Perl Compatible Regular Expressions)
  - Linux: `libpcre3-dev` or `pcre-devel`
  - macOS: `brew install pcre`
  - Only required with `system-pcre` feature (default)

#### Build Tools
- **Rust** toolchain (cargo, rustc)
- **Haskell** toolchain (ghc, stack)
- **pkg-config** for library detection
- **maturin** for Python packaging

### Python Dependencies
- **pendulum** - Date/time handling (runtime dependency)
- **pytest** - Testing framework (development)

## Platform-Specific Notes

### macOS
- **Apple Silicon (M1/M2)**: Libraries installed via Homebrew go to `/opt/homebrew/`
- **Intel Macs**: Libraries installed via Homebrew go to `/usr/local/`
- The build system automatically detects the architecture and sets appropriate paths

### Linux
- **glibc vs musl**: The Docker build creates wheels for both glibc and musl-based systems
- **Static linking**: The Haskell library is statically linked to reduce runtime dependencies

## Troubleshooting

### Common Issues

#### Library Not Found Errors
```bash
# Check if libraries are installed
pkg-config --exists libpcre && echo "PCRE found" || echo "PCRE missing"
pkg-config --exists gmp && echo "GMP found" || echo "GMP missing"

# Check library paths
pkg-config --libs libpcre
pkg-config --libs gmp
```

#### macOS Specific
```bash
# If libraries aren't found, check Homebrew paths
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# For Apple Silicon, also set library paths
export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"
export CPATH="/opt/homebrew/include:$CPATH"
```

#### Haskell Stack Issues
```bash
# Clear Stack cache if builds fail
stack clean
rm -rf .stack-work

# Use system GHC instead of Stack's
stack build --system-ghc
```

### Performance Considerations

- **System PCRE vs Rust Regex**: System PCRE may be faster for complex patterns, but Rust regex is more portable
- **Static vs Dynamic Linking**: Static linking increases binary size but reduces runtime dependencies
- **Build Time**: First build takes longer due to Haskell compilation; subsequent builds are cached

## Contributing

When adding support for new platforms:

1. Update `build.rs` with platform-specific library detection
2. Add platform-specific build scripts (like `build-macos.sh`)
3. Update GitHub Actions workflow in `.github/workflows/cross-platform-build.yml`
4. Test with both feature configurations (`system-pcre` and `rust-regex`)
5. Update this documentation

## Future Improvements

- **Windows Support**: Add Windows build configuration
- **Pure Rust Backend**: Gradually replace Haskell components with Rust
- **Conda Packages**: Create conda-forge recipes for easier dependency management
- **ARM Linux**: Add support for ARM-based Linux systems
