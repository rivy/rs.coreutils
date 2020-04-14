extern crate cpp_build;

#[cfg(not(target_os = "windows"))]
use cpp_build::Config;

#[cfg(not(target_os = "windows"))]
fn main() {
    Config::new().pic(true).build("src/libstdbuf.rs");
}

#[cfg(target_os = "windows")]
fn main() {
    panic!("target_os = \"windows\" is NOT SUPPORTED");
}
