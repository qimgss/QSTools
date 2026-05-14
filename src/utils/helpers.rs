// Utility functions for the extratool

pub fn get_api_level() -> anyhow::Result<i32> {
    use std::process::Command;
    use anyhow::Context;
    
    let output = Command::new("getprop")
        .arg("ro.build.version.sdk")
        .output()
        .context("Failed to execute getprop command")?;
    
    if output.status.success() {
        let api_str = String::from_utf8_lossy(&output.stdout)
            .trim()
            .to_string();
        
        api_str.parse::<i32>()
            .with_context(|| format!("Failed to parse API level: {}", api_str))
    } else {
        Ok(0)  // Unknown
    }
}

pub fn has_ab_partitions() -> bool {
    use std::process::Command;
    
    let result = Command::new("getprop")
        .arg("ro.build.ab_update")
        .output();
    
    match result {
        Ok(output) if output.status.success() => {
            let value = String::from_utf8_lossy(&output.stdout)
                .trim()
                .to_lowercase();
            value == "true" || value == "1"
        }
        _ => false,
    }
}
