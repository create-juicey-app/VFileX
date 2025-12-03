//! VTF (Valve Texture Format) decoder
//!

mod decoder;
mod formats;
mod header;

pub use decoder::{DecodedFrame, VtfBuilder, VtfDecoder, VtfImage};
pub use formats::ImageFormat;
pub use header::{VtfFlags, VtfFormat, VtfHeader, VtfVersion};

use thiserror::Error;

// Errors that can occur during VTF operations
#[derive(Error, Debug)]
pub enum VtfError {
    #[error("Failed to read file: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Invalid VTF signature")]
    InvalidSignature,

    #[error("Unsupported VTF version: {0}.{1}")]
    UnsupportedVersion(u32, u32),

    #[error("Unsupported image format: {0:?}")]
    UnsupportedFormat(ImageFormat),

    #[error("Invalid data: {0}")]
    InvalidData(String),

    #[error("Decompression error: {0}")]
    DecompressionError(String),

    #[error("Invalid mipmap level: {0}")]
    InvalidMipmap(u32),

    #[error("Invalid frame index: {0}")]
    InvalidFrame(u16),
}

// Result type for VTF operations
pub type VtfResult<T> = Result<T, VtfError>;
