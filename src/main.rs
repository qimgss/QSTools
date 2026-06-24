use std::env;
use std::path::Path;
use qslib::{unpack, repack};

fn usage() {
    eprintln!("Usage:");
    eprintln!("  {} unpack <boot.img> <output_dir>", env::args().next().unwrap());
    eprintln!("  {} repack <source_dir> <original.img> <output.img>", env::args().next().unwrap());
    std::process::exit(1);
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        usage();
    }

    match args[1].as_str() {
        "unpack" => {
            if args.len() != 4 {
                usage();
            }
            unpack(Path::new(&args[2]), Path::new(&args[3]))?;
            println!("Unpack complete.");
        }
        "repack" => {
            if args.len() != 5 {
                usage();
            }
            repack(
                Path::new(&args[2]),
                Path::new(&args[3]),
                Path::new(&args[4]),
            )?;
            println!("Repack complete.");
        }
        _ => usage(),
    }

    Ok(())
}