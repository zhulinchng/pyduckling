use std::env;
use std::path::Path;

fn main() {
    let dir_path = env::current_dir().unwrap();
    let path = dir_path.to_str().unwrap();
    
    // Link the static duckling FFI library (built with -dynamic-too for PIC compatibility)
    println!("cargo:rustc-link-lib=static=ducklingffi");
    println!("cargo:rustc-link-search=native={}/ext_lib/", path);

    // For Haskell runtime, we'll rely on dynamic linking at runtime
    // This is simpler and more reliable than trying to link statically
    println!("cargo:warning=Haskell runtime will be linked dynamically at runtime");
    println!("cargo:warning=Ensure Haskell runtime libraries are available in LD_LIBRARY_PATH");
    
    // Cross-platform library detection
    detect_and_link_libraries();
}

fn detect_and_link_libraries() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_else(|_| "unknown".to_string());
    
    match target_os.as_str() {
        "macos" => link_macos_libraries(),
        "linux" => link_linux_libraries(),
        _ => {
            println!("cargo:warning=Unsupported target OS: {}", target_os);
            // Fallback to Linux-style linking
            link_linux_libraries();
        }
    }
}

fn link_macos_libraries() {
    // Always link GMP for arbitrary precision arithmetic
    println!("cargo:rustc-link-lib=dylib=gmp");

    // Only link PCRE if using system-pcre feature
    if cfg!(feature = "system-pcre") {
        println!("cargo:rustc-link-lib=dylib=pcre");
    }

    // Add common macOS library search paths
    let homebrew_paths = [
        "/opt/homebrew/lib",  // Apple Silicon Homebrew
        "/usr/local/lib",     // Intel Homebrew
        "/opt/local/lib",     // MacPorts
    ];

    for path in &homebrew_paths {
        if Path::new(path).exists() {
            println!("cargo:rustc-link-search=native={}", path);
        }
    }

    // Add Haskell-specific paths for macOS
    let hs_macos_paths = [
        "/opt/homebrew/lib/ghc-9.4.8",
        "/usr/local/lib/ghc-9.4.8",
        "/opt/homebrew/lib/ghc-9.4",
        "/usr/local/lib/ghc-9.4",
        "/opt/homebrew/lib/ghc-9",
        "/usr/local/lib/ghc-9",
    ];

    for path in &hs_macos_paths {
        if Path::new(path).exists() {
            println!("cargo:rustc-link-search=native={}", path);
        }
    }

    // Try to use pkg-config for better library detection
    if cfg!(feature = "system-pcre") {
        if let Ok(pcre_lib) = pkg_config::probe_library("libpcre") {
            for path in pcre_lib.link_paths {
                println!("cargo:rustc-link-search=native={}", path.display());
            }
        }
    }

    if let Ok(gmp_lib) = pkg_config::probe_library("gmp") {
        for path in gmp_lib.link_paths {
            println!("cargo:rustc-link-search=native={}", path.display());
        }
    }
}

fn link_linux_libraries() {
    // Always link GMP for arbitrary precision arithmetic
    println!("cargo:rustc-link-lib=dylib=gmp");
    
    // Only link PCRE if using system-pcre feature
    if cfg!(feature = "system-pcre") {
        println!("cargo:rustc-link-lib=dylib=pcre");
    }
    
    // Try to use pkg-config for better library detection on Linux too
    if cfg!(feature = "system-pcre") {
        if let Ok(pcre_lib) = pkg_config::probe_library("libpcre") {
            for path in pcre_lib.link_paths {
                println!("cargo:rustc-link-search=native={}", path.display());
            }
        }
    }
    
    if let Ok(gmp_lib) = pkg_config::probe_library("gmp") {
        for path in gmp_lib.link_paths {
            println!("cargo:rustc-link-search=native={}", path.display());
        }
    }
}
