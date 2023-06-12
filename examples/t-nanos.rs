use std::time::{SystemTime, UNIX_EPOCH};

fn main() {
    let current_time = SystemTime::now();
    let duration = current_time
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards");

    let nanoseconds = duration.as_secs() * 1_000_000_000 + u64::from(duration.subsec_nanos());

    println!("Nanoseconds since Linux epoch: {}", nanoseconds);
    println!("Nanoseconds MAX: {}", std::i64::MAX);
}
