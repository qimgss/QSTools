use flate2::{read::GzDecoder, write::GzEncoder};
use flate2::Compression;
use lzzzz::lz4;
use xz2::read::XzDecoder;
use xz2::write::XzEncoder;
use std::io::{Read, Write};

use crate::error::QSLibError;

/// ✅ 统一的压缩类型枚举
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CompressionType {
    None,
    Gzip,
    Lz4,
    Xz,
    Bzip2,
}

/// 检测压缩格式
pub fn detect_compression(data: &[u8]) -> CompressionType {
    if data.len() < 4 {
        return CompressionType::None;
    }
    
    match &data[0..4] {
        [0x1f, 0x8b, _, _] => CompressionType::Gzip,
        [0xfd, 0x37, 0x7a, 0x58] => CompressionType::Xz,
        [0x42, 0x5a, 0x68, _] => CompressionType::Bzip2,
        _ if data.len() > 4 && data[0] == 0x04 && data[1] == 0x22 => CompressionType::Lz4,
        _ => CompressionType::None,
    }
}

/// 自动解压并返回解压后的数据和原始压缩格式
pub fn detect_and_decompress(data: &[u8]) -> Result<(Vec<u8>, CompressionType), QSLibError> {
    let comp_type = detect_compression(data);
    let decompressed = match comp_type {
        CompressionType::None => data.to_vec(),
        CompressionType::Gzip => decompress_gzip(data)?,
        CompressionType::Lz4 => decompress_lz4(data)?,
        CompressionType::Xz => decompress_xz(data)?,
        CompressionType::Bzip2 => decompress_bzip2(data)?,
    };
    Ok((decompressed, comp_type))
}

/// 使用指定格式压缩
pub fn compress_with_type(data: &[u8], comp_type: CompressionType) -> Result<Vec<u8>, QSLibError> {
    match comp_type {
        CompressionType::None => Ok(data.to_vec()),
        CompressionType::Gzip => compress_gzip(data),
        CompressionType::Lz4 => compress_lz4(data),
        CompressionType::Xz => compress_xz(data),
        CompressionType::Bzip2 => compress_bzip2(data),
    }
}

pub fn decompress_gzip(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut d = GzDecoder::new(data);
    let mut out = Vec::new();
    d.read_to_end(&mut out)?;
    Ok(out)
}

pub fn decompress_lz4(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut out = Vec::new();
    lz4::decompress(data, &mut out)?;
    Ok(out)
}

pub fn decompress_xz(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut d = XzDecoder::new(data);
    let mut out = Vec::new();
    d.read_to_end(&mut out)?;
    Ok(out)
}

pub fn decompress_bzip2(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    use bzip2::read::BzDecoder;
    let mut d = BzDecoder::new(data);
    let mut out = Vec::new();
    d.read_to_end(&mut out)?;
    Ok(out)
}

pub fn compress_gzip(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut e = GzEncoder::new(Vec::new(), Compression::default());
    e.write_all(data)?;
    Ok(e.finish()?)
}

pub fn compress_lz4(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut out = Vec::new();
    lz4::compress(data, &mut out, lz4::ACC_LEVEL_DEFAULT)?;
    Ok(out)
}

pub fn compress_xz(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    let mut e = XzEncoder::new(Vec::new(), 6);
    e.write_all(data)?;
    Ok(e.finish()?)
}

pub fn compress_bzip2(data: &[u8]) -> Result<Vec<u8>, QSLibError> {
    use bzip2::write::BzEncoder;
    use bzip2::Compression as BzCompression;
    let mut e = BzEncoder::new(Vec::new(), BzCompression::default());
    e.write_all(data)?;
    Ok(e.finish()?)
}