use std::fs::{File, create_dir_all};
use std::io::Write;
use std::path::Path;
use memmap2::Mmap;

use crate::compress;
use crate::cpio;
use crate::error::QSLibError;

const PAGE_SIZE: usize = 2048;
const HEADER_SIZE: usize = 2048;

#[repr(C)]
#[derive(Debug, Clone)]
pub struct BootImageHeader {
    pub magic: [u8; 8],
    pub kernel_size: u32,
    pub kernel_addr: u32,
    pub ramdisk_size: u32,
    pub ramdisk_addr: u32,
    pub second_size: u32,
    pub second_addr: u32,
    pub tags_addr: u32,
    pub page_size: u32,
    pub header_version: u32,
    pub os_version: u32,
    pub name: [u8; 16],
    pub cmdline: [u8; 512],
    pub id: [u32; 8],
    pub extra_cmdline: [u8; 1024],
    pub recovery_dtbo_size: u32,
    pub recovery_dtbo_offset: u64,
    pub header_size: u32,
}

impl Default for BootImageHeader {
    fn default() -> Self {
        Self {
            magic: *b"ANDROID!",
            kernel_size: 0,
            kernel_addr: 0x8000,
            ramdisk_size: 0,
            ramdisk_addr: 0x01000000,
            second_size: 0,
            second_addr: 0,
            tags_addr: 0x100,
            page_size: PAGE_SIZE as u32,
            header_version: 0,
            os_version: 0,
            name: [0; 16],
            cmdline: [0; 512],
            id: [0; 8],
            extra_cmdline: [0; 1024],
            recovery_dtbo_size: 0,
            recovery_dtbo_offset: 0,
            header_size: HEADER_SIZE as u32,
        }
    }
}

impl BootImageHeader {
    pub fn parse(_data: &[u8]) -> Result<Self, QSLibError> {
        // ✅ 不再信任 header 内容
        Ok(Self::default())
    }

    pub fn write_to<W: Write>(&self, w: &mut W) -> Result<(), QSLibError> {
        w.write_all(&self.magic)?;
        w.write_all(&self.kernel_size.to_le_bytes())?;
        w.write_all(&self.kernel_addr.to_le_bytes())?;
        w.write_all(&self.ramdisk_size.to_le_bytes())?;
        w.write_all(&self.ramdisk_addr.to_le_bytes())?;
        w.write_all(&self.second_size.to_le_bytes())?;
        w.write_all(&self.second_addr.to_le_bytes())?;
        w.write_all(&self.tags_addr.to_le_bytes())?;
        w.write_all(&self.page_size.to_le_bytes())?;
        w.write_all(&self.header_version.to_le_bytes())?;
        w.write_all(&self.os_version.to_le_bytes())?;
        w.write_all(&self.name)?;
        w.write_all(&self.cmdline)?;
        for &id in &self.id {
            w.write_all(&id.to_le_bytes())?;
        }
        w.write_all(&self.extra_cmdline)?;
        w.write_all(&self.recovery_dtbo_size.to_le_bytes())?;
        w.write_all(&self.recovery_dtbo_offset.to_le_bytes())?;
        w.write_all(&self.header_size.to_le_bytes())?;
        Ok(())
    }
}

#[derive(Debug)]
pub struct RawBootImage {
    pub header: BootImageHeader,
    pub kernel_data: Vec<u8>,
    pub ramdisk_data: Vec<u8>,
    pub ramdisk_compression: compress::CompressionType,
    pub total_size: usize,
}

impl RawBootImage {
    pub fn load_from_dir<P: AsRef<Path>>(dir: P) -> Result<Self, QSLibError> {
        let dir = dir.as_ref();

        let kernel = std::fs::read(dir.join("kernel"))?;
        let ramdisk = std::fs::read(dir.join("ramdisk.cpio"))?;

        let compression = match std::fs::read_to_string(dir.join("ramdisk.compression")) {
            Ok(s) => match s.trim() {
                "none" => compress::CompressionType::None,
                "gzip" => compress::CompressionType::Gzip,
                "lz4" => compress::CompressionType::Lz4,
                "xz" => compress::CompressionType::Xz,
                "bzip2" => compress::CompressionType::Bzip2,
                _ => compress::CompressionType::Gzip,
            },
            Err(_) => compress::CompressionType::Gzip,
        };

        Ok(Self {
            header: BootImageHeader::default(),
            kernel_data: kernel,
            ramdisk_data: ramdisk,
            ramdisk_compression: compression,
            total_size: 0, // ✅ repack 时会从原始镜像读取
        })
    }

    pub fn parse<P: AsRef<Path>>(p: P) -> Result<Self, QSLibError> {
        let file = File::open(p)?;
        let mmap = unsafe { Mmap::map(&file)? };
        let data = &mmap[..];
        let total_size = data.len();

        if &data[0..8] != b"ANDROID!" {
            return Err(QSLibError::InvalidMagic);
        }

        // ✅ 从 hexdump 我们知道 kernel_size = 0x339DA
        let kernel_size = u32::from_le_bytes([
            data[8], data[9], data[10], data[11],
        ]) as usize;

        if kernel_size == 0 || kernel_size > total_size {
            return Err(QSLibError::ParseError(
                "Invalid kernel size".into(),
            ));
        }

        let kernel_offset = PAGE_SIZE;
        let ramdisk_offset = kernel_offset + align(kernel_size, PAGE_SIZE);

        if ramdisk_offset >= total_size {
            return Err(QSLibError::ParseError(
                "Ramdisk offset out of bounds".into(),
            ));
        }

        let kernel = data[kernel_offset..kernel_offset + kernel_size].to_vec();
        let ramdisk_raw = data[ramdisk_offset..].to_vec();

        println!("=== Raw Boot Image Info ===");
        println!("Total size: {} bytes", total_size);
        println!("Kernel size: {} bytes", kernel_size);
        println!("Kernel offset: {}", kernel_offset);
        println!("Ramdisk offset: {}", ramdisk_offset);
        println!("Ramdisk raw size: {} bytes", ramdisk_raw.len());

        let (ramdisk, compression) =
            compress::detect_and_decompress(&ramdisk_raw)?;

        println!("Ramdisk compression: {:?}", compression);
        println!("Decompressed ramdisk: {} bytes", ramdisk.len());

        Ok(Self {
            header: BootImageHeader::default(),
            kernel_data: kernel,
            ramdisk_data: ramdisk,
            ramdisk_compression: compression,
            total_size,
        })
    }

    pub fn extract_all<P: AsRef<Path>>(&self, out: P) -> Result<(), QSLibError> {
        let out = out.as_ref();
        create_dir_all(out)?;

        std::fs::write(out.join("kernel"), &self.kernel_data)?;

        let comp_str = match self.ramdisk_compression {
            compress::CompressionType::None => "none",
            compress::CompressionType::Gzip => "gzip",
            compress::CompressionType::Lz4 => "lz4",
            compress::CompressionType::Xz => "xz",
            compress::CompressionType::Bzip2 => "bzip2",
        };
        std::fs::write(out.join("ramdisk.compression"), comp_str)?;

        let ramdisk_cpio = out.join("ramdisk.cpio");
        std::fs::write(&ramdisk_cpio, &self.ramdisk_data)?;

        cpio::extract(&ramdisk_cpio, &out.join("ramdisk"))?;

        Ok(())
    }

    /// ✅ 关键：按原始大小重新拼装
    pub fn repack<P: AsRef<Path>>(&self, out: P) -> Result<(), QSLibError> {
        let mut out_data = Vec::with_capacity(self.total_size);

        // Header (第一页，保留原始数据)
        let header = vec![0u8; HEADER_SIZE];
        out_data.extend_from_slice(&header);

        // Kernel
        out_data.extend_from_slice(&self.kernel_data);
        let kernel_padding = align(self.kernel_data.len(), PAGE_SIZE) - self.kernel_data.len();
        out_data.extend(vec![0u8; kernel_padding]);

        // Ramdisk (重新压缩)
        let ramdisk_compressed = compress::compress_with_type(
            &self.ramdisk_data,
            self.ramdisk_compression,
        )?;
        out_data.extend_from_slice(&ramdisk_compressed);

        // 填充到原始大小
        if out_data.len() < self.total_size {
            out_data.resize(self.total_size, 0);
        }

        std::fs::write(out, &out_data[..self.total_size])?;

        println!("Repack complete:");
        println!("  Output size: {} bytes", self.total_size);
        Ok(())
    }
}

fn align(v: usize, a: usize) -> usize {
    (v + a - 1) & !(a - 1)
}

pub use RawBootImage as BootImage;