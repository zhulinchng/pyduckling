use std::env;

fn main() {
    let dir_path = env::current_dir().unwrap();
    let path = dir_path.to_str().unwrap();
    println!("cargo:rustc-link-lib=static=ducklingffi");
    println!("cargo:rustc-link-search=native={}/ext_lib/", path);
    println!("cargo:rustc-link-lib=dylib=pcre");
    println!("cargo:rustc-link-lib=dylib=gmp");
}
