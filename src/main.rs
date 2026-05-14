use anyhow::Result;

mod cli;
mod flash;
mod device;
mod utils;

fn main() -> Result<()> {
    let matches = cli::get_matches();
    
    match matches.subcommand() {
        Some(("search", sub_m)) => {
            let partition_name = sub_m.get_one::<String>("partition").unwrap();
            let finder = device::BlockDeviceFinder::new();
            let slot_suffix = finder.get_slot_suffix()?;
            let device_path = finder.find_partition(partition_name, &slot_suffix)?;
            println!("{}", device_path);
            Ok(())
        }
        Some(("flash", sub_m)) => {
            let image_path = sub_m.get_one::<String>("image").unwrap();
            let partition_name = sub_m.get_one::<String>("partition").unwrap();
            
            let finder = device::BlockDeviceFinder::new();
            let slot_suffix = finder.get_slot_suffix()?;
            let target_device = finder.find_partition(partition_name, &slot_suffix)?;
            
            let flasher = flash::ImageFlasher::new();
            flasher.flash_image(image_path, &target_device)?;
            println!("Successfully flashed {} to {}", image_path, target_device);
            Ok(())
        }
        _ => {
            cli::print_help();
            Ok(())
        }
    }
}
