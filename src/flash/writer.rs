use std::fs;
use std::io;
use std::process::Command;
use thiserror::Error;
use anyhow::{Result, Context};

#[derive(Error, Debug)]
pub enum FlashError {
    #[error("Failed to open file: {0}")]
    FileOpenError(#[from] io::Error),
    #[error("Permission denied: root access required")]
    PermissionDenied,
    #[error("Flash failed: {0}")]
    FlashFailed(String),
}

pub struct ImageFlasher;

impl ImageFlasher {
    pub fn new() -> Self {
        ImageFlasher
    }
    
    /// Check if running as root
    fn is_root(&self) -> bool {
        let output = Command::new("id")
            .arg("-u")
            .output();
        
        match output {
            Ok(cmd_output) if cmd_output.status.success() => {
                let output_str = String::from_utf8_lossy(&cmd_output.stdout);
                let trimmed = output_str.trim();
                trimmed == "0"
            }
            _ => {
                // Fallback: check if we can access root-only files
                let test_path = "/dev/block/by-name";
                fs::metadata(test_path).is_ok()
            }
        }
    }
    
    /// Flash an image to a block device
    pub fn flash_image(&self, image_path: &str, device_path: &str) -> Result<()> {
        // Check if we have root permissions
        if !self.is_root() {
            return Err(FlashError::PermissionDenied.into());
        }
        
        // Check if source file exists
        if !std::path::Path::new(image_path).exists() {
            return Err(anyhow::anyhow!("Image file not found: {}", image_path));
        }
        
        // Check if target device exists
        if !std::path::Path::new(device_path).exists() {
            return Err(anyhow::anyhow!("Device not found: {}", device_path));
        }
        
        println!("Flashing {} to {}...", image_path, device_path);
        
        // Use dd command to flash the image
        let status = Command::new("dd")
            .arg("if")
            .arg(image_path)
            .arg("of")
            .arg(device_path)
            .arg("bs=4096")
            .arg("conv=notrunc")
            .arg("oflag=sync")
            .status()
            .context("Failed to execute dd command. Make sure dd is available.")?;
        
        if status.success() {
            // Force sync to ensure data is written
            let _ = Command::new("sync").status();
            Ok(())
        } else {
            Err(FlashError::FlashFailed(format!("dd command failed with exit code: {:?}", status.code())).into())
        }
    }
    
    /// Alternative method using direct file operations (requires root)
    pub fn flash_image_direct(&self, image_path: &str, device_path: &str) -> Result<()> {
        use std::fs::OpenOptions;
        use std::io::Read;
        use std::io::Write;
        
        // Check if we have root permissions
        if !self.is_root() {
            return Err(FlashError::PermissionDenied.into());
        }
        
        // Read the image file
        let mut source_file = OpenOptions::new()
            .read(true)
            .open(image_path)
            .with_context(|| format!("Failed to open image file: {}", image_path))?;
        
        let mut target_file = OpenOptions::new()
            .write(true)
            .open(device_path)
            .with_context(|| format!("Failed to open device: {}", device_path))?;
        
        let mut buffer = vec![0; 64 * 1024]; // 64KB buffer
        
        println!("Flashing {} to {} (direct method)...", image_path, device_path);
        
        loop {
            let bytes_read = source_file.read(&mut buffer)?;
            if bytes_read == 0 {
                break;
            }
            
            target_file.write_all(&buffer[..bytes_read])?;
        }
        
        target_file.sync_all()?;
        
        // Force sync
        let _ = Command::new("sync").status();
        
        Ok(())
    }
}
