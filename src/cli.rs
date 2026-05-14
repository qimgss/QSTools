use clap::{Arg, ArgAction, Command};

pub fn get_matches() -> clap::ArgMatches {
    Command::new("extratool")
        .name("extratool")
        .about("Android block device operation utility")
        .author("Your Name <your.email@example.com>")
        .version("0.1.0")
        .subcommand_required(false)
        .arg_required_else_help(false)
        .subcommand(
            Command::new("search")
                .short_flag('s')
                .about("Search for a block device by name")
                .arg(
                    Arg::new("partition")
                        .help("Partition name to search for (e.g., boot, system, vendor)")
                        .required(true)
                )
        )
        .subcommand(
            Command::new("flash")
                .short_flag('f')
                .about("Flash an image to a partition")
                .arg(
                    Arg::new("image")
                        .help("Path to the image file")
                        .required(true)
                )
                .arg(
                    Arg::new("partition")
                        .help("Target partition name")
                        .required(true)
                )
        )
        .arg(
            Arg::new("help")
                .short('h')
                .long("help")
                .help("Show help information")
                .action(ArgAction::Help)
        )
        .get_matches()
}

pub fn print_help() {
    println!("extratool - Android Block Device Utility");
    println!();
    println!("Usage:");
    println!("  extratool -s <partition>    Search for a partition and show its device path");
    println!("  extratool -f <image> <partition>  Flash image to partition");
    println!("  extratool -h, --help        Show this help message");
    println!();
    println!("Examples:");
    println!("  extratool -s boot           Find boot partition device path");
    println!("  extratool -f boot.img boot  Flash boot.img to boot partition");
    println!();
    println!("The tool automatically detects the current slot suffix (getprop ro.boot.slot_suffix)");
}
