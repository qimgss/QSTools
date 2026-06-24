pub mod bootimg;
pub mod cpio;
pub mod compress;
pub mod error;

pub use bootimg::BootImage;
pub use compress::CompressionType;
pub use error::QSLibError;

pub fn unpack<P: AsRef<std::path::Path>>(
    input: P,
    output_dir: P,
) -> Result<(), QSLibError> {
    let img = BootImage::parse(input)?;
    img.extract_all(output_dir)
}

pub fn repack<P: AsRef<std::path::Path>>(
    source_dir: P,
    original_img: P,
    output: P,
) -> Result<(), QSLibError> {
    let mut img = BootImage::load_from_dir(source_dir)?;

    let original_data = std::fs::read(&original_img)?;
    img.total_size = original_data.len();

    img.repack(output)
}