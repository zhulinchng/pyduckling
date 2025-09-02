#!/usr/bin/env python3
"""
Cross-platform test script for PyDuckling
Tests basic functionality across different platforms and build configurations.
"""

import sys
import platform
import subprocess
from pathlib import Path

def run_command(cmd, description):
    """Run a command and return success status"""
    print(f"\n🔧 {description}")
    print(f"Command: {cmd}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=300)
        if result.returncode == 0:
            print(f"✅ Success: {description}")
            if result.stdout.strip():
                print(f"Output: {result.stdout.strip()}")
            return True
        else:
            print(f"❌ Failed: {description}")
            print(f"Error: {result.stderr.strip()}")
            return False
    except subprocess.TimeoutExpired:
        print(f"⏰ Timeout: {description}")
        return False
    except Exception as e:
        print(f"💥 Exception: {description} - {e}")
        return False

def test_system_info():
    """Display system information"""
    print("🖥️  System Information")
    print(f"Platform: {platform.platform()}")
    print(f"Architecture: {platform.machine()}")
    print(f"Python: {sys.version}")
    print(f"Working Directory: {Path.cwd()}")

def test_dependencies():
    """Test if required dependencies are available"""
    print("\n📦 Testing Dependencies")
    
    dependencies = [
        ("rust --version", "Rust compiler"),
        ("cargo --version", "Cargo package manager"),
        ("python3 --version", "Python 3"),
        ("pkg-config --version", "pkg-config"),
    ]
    
    # Platform-specific dependencies
    if platform.system() == "Darwin":  # macOS
        dependencies.extend([
            ("brew --version", "Homebrew"),
            ("stack --version", "Haskell Stack"),
            ("ghc --version", "GHC Haskell compiler"),
        ])
    elif platform.system() == "Linux":
        dependencies.extend([
            ("stack --version", "Haskell Stack"),
            ("ghc --version", "GHC Haskell compiler"),
        ])
    
    results = []
    for cmd, desc in dependencies:
        results.append(run_command(cmd, f"Check {desc}"))
    
    return all(results)

def test_library_detection():
    """Test if required libraries can be found"""
    print("\n📚 Testing Library Detection")
    
    libraries = [
        ("pkg-config --exists gmp", "GMP library"),
        ("pkg-config --exists libpcre", "PCRE library"),
    ]
    
    results = []
    for cmd, desc in libraries:
        results.append(run_command(cmd, f"Detect {desc}"))
    
    return all(results)

def test_build_configurations():
    """Test different build configurations"""
    print("\n🔨 Testing Build Configurations")
    
    # Test with default features (system-pcre)
    print("\n--- Testing with system PCRE (default) ---")
    success_default = run_command(
        "maturin develop --release", 
        "Build with system PCRE"
    )
    
    # Test basic import
    if success_default:
        success_import = run_command(
            "python3 -c 'import duckling; print(\"✅ Import successful\")'",
            "Test import with system PCRE"
        )
    else:
        success_import = False
    
    # Test with rust-regex feature
    print("\n--- Testing with Rust regex ---")
    success_rust = run_command(
        "maturin develop --release --features rust-regex --no-default-features",
        "Build with Rust regex"
    )
    
    if success_rust:
        success_import_rust = run_command(
            "python3 -c 'import duckling; print(\"✅ Import successful with Rust regex\")'",
            "Test import with Rust regex"
        )
    else:
        success_import_rust = False
    
    return success_default and success_import and success_rust and success_import_rust

def test_basic_functionality():
    """Test basic PyDuckling functionality"""
    print("\n🧪 Testing Basic Functionality")
    
    test_code = '''
import duckling
try:
    # Test basic parsing
    from duckling import parse_lang, default_locale_lang, parse_locale, parse_dimensions, parse, Context
    import pendulum
    
    # Simple test without time zones for cross-platform compatibility
    lang_en = parse_lang("EN")
    default_locale = default_locale_lang(lang_en)
    locale = parse_locale("EN_US", default_locale)
    
    # Create a simple context (without timezone for simplicity)
    context = Context(None, locale)
    
    # Test number parsing
    dimensions = parse_dimensions(["number"])
    result = parse("forty two", context, dimensions, False)
    
    if result and len(result) > 0:
        print("✅ Basic parsing test passed")
        print(f"Parsed 'forty two' as: {result[0]}")
    else:
        print("❌ Basic parsing test failed")
        exit(1)
        
except Exception as e:
    print(f"❌ Functionality test failed: {e}")
    exit(1)
'''
    
    return run_command(
        f"python3 -c \"{test_code}\"",
        "Basic functionality test"
    )

def main():
    """Main test function"""
    print("🚀 PyDuckling Cross-Platform Test Suite")
    print("=" * 50)
    
    test_system_info()
    
    # Run tests
    tests = [
        ("Dependencies", test_dependencies),
        ("Library Detection", test_library_detection),
        ("Build Configurations", test_build_configurations),
        ("Basic Functionality", test_basic_functionality),
    ]
    
    results = {}
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"💥 Test {test_name} crashed: {e}")
            results[test_name] = False
    
    # Summary
    print(f"\n{'='*20} SUMMARY {'='*20}")
    all_passed = True
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{test_name}: {status}")
        if not passed:
            all_passed = False
    
    if all_passed:
        print("\n🎉 All tests passed! Cross-platform build is working correctly.")
        return 0
    else:
        print("\n💥 Some tests failed. Please check the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
