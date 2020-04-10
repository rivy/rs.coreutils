@setLocal
@echo off

@rem ::# spell-checker:ignore (abbrevs/acronyms) gcno
@rem ::# spell-checker:ignore (CMD) COMSPEC ERRORLEVEL
@rem ::# spell-checker:ignore (jargon) toolchain
@rem ::# spell-checker:ignore (rust) RUSTC RUSTFLAGS RUSTUP Ccodegen Cinline Coverflow
@rem ::# spell-checker:ignore (utils) uutils sccache grcov

set BIN=uutils

set "FEATURES_OPTION=--features windows"

cd "%~dp0.."
echo [ "%CD%" ]

cargo clean

set CARGO_INCREMENTAL=0
set "RUSTC_WRAPPER="    &@REM ## NOTE: RUSTC_WRAPPER=='sccache' breaks code coverage calculations (uu_*.gcno files are not created during build)
set "RUSTFLAGS=-Zprofile -Ccodegen-units=1 -Cinline-threshold=0 -Clink-dead-code -Coverflow-checks=off -Zno-landing-pads"
set RUSTUP_TOOLCHAIN=nightly-x86_64-pc-windows-gnu
cargo build %FEATURES_OPTION%
cargo test --no-run %FEATURES_OPTION%
cargo test --quiet %FEATURES_OPTION%

set COVERAGE_REPORT_DIR=target\debug\coverage-win
rm -r "%COVERAGE_REPORT_DIR%" 2>NUL

set GRCOV_IGNORE_OPTION=--ignore build.rs --ignore "/*" --ignore "[A-Z][a-z]:/*"
grcov . --output-type html --output-file "%COVERAGE_REPORT_DIR%" --branch %GRCOV_IGNORE_OPTION%
if ERRORLEVEL 1 goto _undefined_ 2>NUL || @for %%G in ("%COMSPEC%") do @title %%nG & @"%COMSPEC%" /d/c exit %ERRORLEVEL%

start "" "%COVERAGE_REPORT_DIR%"\index.html
