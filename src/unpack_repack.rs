use magiskboot_rs::{unpack, repack};
use std::path::Path;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let boot_img = Path::new("boot.img");
    let extracted = Path::new("extracted");
    let repacked = Path::new("repacked.img");
    
    println!("Unpacking boot image...");
    unpack(boot_img, extracted)?;
    
    println!("Repacking boot image...");
    repack(extracted, boot_img, repacked)?;
    
    println!("Done!");
    Ok(())
}