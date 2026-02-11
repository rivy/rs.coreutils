@setLocal

@rem ::# spell-checker:ignore (CMD) ERRORLEVEL
@rem ::# spell-checker:ignore (utils) cksum coreutils dircolors hashsum mkdir mktemp printenv printf readlink realpath relpath rmdir shuf tsort unexpand
@rem ::# spell-checker:ignore (jq) deps startswith

@set "ME=%~0"
@set "ME_dir=%~dp0."
@set "ME_parent_dir=%~dp0.\.."

@rem refs: <https://forge.rust-lang.org/release/platform-support.html> , <https://docs.rs/platforms/0.2.1/platforms/platform/tier1/index.html>

@rem :: default (v0.6.0 "Tier 1" cross-platform) utility list (`show-utils.BAT --no-default-features --features feat_Tier1`)
@set "default_utils=arch b2sum base32 base64 basename basenc cat cksum comm cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor false fmt fold head hostname join link ln ls md5sum mkdir mktemp more mv nl nproc numfmt od paste pr printenv printf ptx pwd readlink realpath rm rmdir seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort split sum sync tac tail tee test touch tr true truncate tsort uname unexpand uniq unlink vdir wc whoami yes"

@set "project_dir=%ME_parent_dir%"
@cd "%project_dir%"

@:: `jq` available?
@set "JQ="
@set "ERRORLEVEL="
@call jq --version 1>NUL 2>&1
@if NOT ERRORLEVEL 1 @( set "JQ=jq" )

@if NOT DEFINED JQ @(
    @echo WARN: missing `jq` ^(install with `scoop install jq`^)^; falling back to default ^(only fully cross-platform^) util list 1>&2
    @echo %default_utils%
    @goto :eof & @:: exit ~ avoids execution of `jq` within else parens which can cause BAT/CMD parsing errors of the jq script
)

@rem :: "cargo 1.93.0 (083ac5135 2025-12-15)"-compatible metadata parsing
@rem :: ... expect { ..., "resolve": { "nodes": [ { "id": "path+file:///C:/Users/Roy/AARK/Projects/rust/coreutils#0.0.27", "deps": [ { "name": "base32", "pkg": "path+file:///.../path/to/base32#uu_base@0.0.27" }, ... ] }, ... ] } }
@rem :: NOTE: expectation of prior cargo version? { ..., "resolve": { "nodes": [ { "id": "coreutils 0.1.0 (path+file:///C:/path/to/coreutils)", "name": "coreutils", "deps": [ { "name": "uu_base32", "pkg": "uu_base32 0.1.0 (path+file:///C:/path/to/uu_base32)" }, ... ] }, ... ] } }
@call cargo metadata --format-version 1 %* | call jq -Mr "[.resolve.nodes[] | {id, name, deps: [.deps[] | { name, pkg }]}] | .[] | select(.id|test(\"\\bcoreutils(#\\d+([.]\\d+)*)?\\z\")) | [.deps[] | select(.pkg|test(\"\\buu_.*(@\\d+([.]\\d+)*)?\\z\"))] | [.[].pkg | match(\"\\buu_\\w+\") | .string | sub(\"^uu_\"; \"\")] | sort | join(\" \")"
