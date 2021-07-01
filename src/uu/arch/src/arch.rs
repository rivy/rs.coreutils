// This file is part of the uutils coreutils package.
//
// (c) Smigle00 <smigle00@gmail.com>
// (c) Jian Zeng <anonymousknight96 AT gmail.com>
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.

#[macro_use]
extern crate uucore;

use platform_info::*;

use clap::{crate_version, App};
use uucore::error::{FromIo, UResult};

static ABOUT: &str = "Display machine architecture";
static SUMMARY: &str = "Determine architecture name for current machine.";

#[uucore_procs::gen_uumain]
pub fn uumain(args: impl uucore::Args) -> UResult<()> {
    uu_app().get_matches_from(args);

    let uts = PlatformInfo::new().map_err_context(|| "cannot get system name".to_string())?;
    println!("{}", uts.machine().trim());
    Ok(())
}

pub fn uu_app() -> App<'static, 'static> {
    App::new(util_name!())
        .version(crate_version!())
        .about(ABOUT)
        .after_help(SUMMARY)
}
