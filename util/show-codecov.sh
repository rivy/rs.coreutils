#!/bin/sh

# spell-checker:ignore (abbrevs/acronyms) gcno llvm
# spell-checker:ignore (jargon) toolchain
# spell-checker:ignore (rust) Ccodegen Cinline Coverflow RUSTC RUSTFLAGS RUSTUP
# spell-checker:ignore (shell) OSID esac
# spell-checker:ignore (utils) grcov readlink sccache uutils

BIN=uutils

FEATURES_OPTION="--features unix"

cd "$(dirname -- $(readlink -fm -- "$0"/..))"
echo "[ \"$PWD\" ]"

cargo clean

export CARGO_INCREMENTAL=0
export RUSTC_WRAPPER=""     ## NOTE: RUSTC_WRAPPER=='sccache' breaks code coverage calculations (uu_*.gcno files are not created during build)
export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Cinline-threshold=0 -Clink-dead-code -Coverflow-checks=off -Zno-landing-pads"
export RUSTUP_TOOLCHAIN=nightly
cargo build ${FEATURES_OPTION}
cargo test --no-run ${FEATURES_OPTION}
cargo test --quiet ${FEATURES_OPTION}

COVERAGE_REPORT_DIR="target/debug/coverage-nix"
rm -r "${COVERAGE_REPORT_DIR}" 2>/dev/null

GRCOV_IGNORE_OPTION="--ignore build.rs --ignore \"/cargo/*\" --ignore \"/rustc/*\" --ignore \"${HOME}/.cargo/*\" --ignore \"${PWD}/rustc/*\""
grcov . --output-type html --output-file "${COVERAGE_REPORT_DIR}" --llvm --branch ${GRCOV_IGNORE_OPTION}
if [ $? -ne 0 ]; then exit 1 ; fi

case ";$OSID_tags;" in
    *";wsl;"* ) powershell.exe -c "${COVERAGE_REPORT_DIR}"/index.html ;;
    * ) xdg-open --version >/dev/null 2>&1 && xdg-open "${COVERAGE_REPORT_DIR}"/index.html || echo "report available at '\"${COVERAGE_REPORT_DIR}\"/index.html'" ;;
esac ;
