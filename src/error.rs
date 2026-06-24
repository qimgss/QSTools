use thiserror::Error;

#[derive(Error, Debug)]
pub enum QSLibError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid magic number")]
    InvalidMagic,

    #[error("Parse error: {0}")]
    ParseError(String),

    #[error("Compression error: {0}")]
    CompressionError(String),
}

impl From<flate2::DecompressError> for QSLibError {
    fn from(err: flate2::DecompressError) -> Self {
        QSLibError::CompressionError(err.to_string())
    }
}

impl From<lzzzz::Error> for QSLibError {
    fn from(err: lzzzz::Error) -> Self {
        QSLibError::CompressionError(err.to_string())
    }
}

impl From<std::string::FromUtf8Error> for QSLibError {
    fn from(err: std::string::FromUtf8Error) -> Self {
        QSLibError::ParseError(err.to_string())
    }
}