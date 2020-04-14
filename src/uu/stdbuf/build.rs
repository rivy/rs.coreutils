extern crate cargo_metadata;

use std::env;
use std::fs;
use std::path::Path;

#[path = "../../common/mkmain.rs"]
mod mkmain;

#[cfg(not(any(target_os = "macos", target_os = "ios", target_os = "windows")))]
mod platform {
    pub const DYLIB_EXT: &str = ".so";
}

#[cfg(any(target_os = "macos", target_os = "ios"))]
mod platform {
    pub const DYLIB_EXT: &str = ".dylib";
}

#[cfg(target_os = "windows")]
mod platform {
    pub const DYLIB_EXT: &str = ".dll";
}

fn main() {
    mkmain::main();

    let mut cargo_metadata_cmd = cargo_metadata::MetadataCommand::new();
    let metadata = cargo_metadata_cmd.exec().unwrap();

    let profile = env::var("PROFILE").expect("Could not determine profile");

    let out_dir = env::var("OUT_DIR").unwrap();

    let libstdbuf = format!(
        "{}/{}/deps/liblibstdbuf{}",
        metadata.target_directory.to_str().unwrap(),
        profile,
        platform::DYLIB_EXT
    );

    fs::copy(libstdbuf, Path::new(&out_dir).join("libstdbuf.so")).unwrap();
}
