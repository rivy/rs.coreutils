//  * This file is part of the uutils coreutils package.
//  *
//  * (c) Alex Lyon <arcterus@mail.com>
//  *
//  * For the full copyright and license information, please view the LICENSE
//  * file that was distributed with this source code.

#[macro_use]
extern crate uucore;

use std::thread;
use std::time::Duration;

use clap::{crate_version, App, Arg};

static ABOUT: &str = "Pause for NUMBER seconds.";
static LONG_HELP: &str = "Pause for NUMBER seconds.  SUFFIX may be 's' for seconds (the default),
'm' for minutes, 'h' for hours or 'd' for days.  Unlike most implementations
that require NUMBER be an integer, here NUMBER may be an arbitrary floating
point number.  Given two or more arguments, pause for the amount of time
specified by the sum of their values.";

mod options {
    pub const NUMBER: &str = "NUMBER";
}

fn usage() -> String {
    format!(
        "{0} {1}[SUFFIX]... \n    {0} OPTION",
        executable!(),
        options::NUMBER
    )
}

pub fn uumain(args: impl uucore::Args) -> i32 {
    let usage = usage();

    let matches = uu_app().usage(&usage[..]).get_matches_from(args);

    if let Some(values) = matches.values_of(options::NUMBER) {
        let numbers = values.collect();
        sleep(numbers);
    }

    0
}

pub fn uu_app() -> App<'static, 'static> {
    App::new(util_name!())
        .version(crate_version!())
        .about(ABOUT)
        .after_help(LONG_HELP)
        .arg(
            Arg::with_name(options::NUMBER)
                .long(options::NUMBER)
                .help("pause for NUMBER seconds")
                .value_name(options::NUMBER)
                .index(1)
                .multiple(true)
                .required(true),
        )
}

fn sleep(args: Vec<&str>) {
    let sleep_dur =
        args.iter().fold(
            Duration::new(0, 0),
            |result, arg| match uucore::parse_time::from_str(&arg[..]) {
                Ok(m) => m + result,
                Err(f) => crash!(1, "{}", f),
            },
        );

    thread::sleep(sleep_dur);
}
