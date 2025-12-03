//! VTF decoder - i forgot textures are upside down

use super::formats::convert_to_rgba;
use super::header::{VtfFormat, VtfHeader};
use super::{VtfError, VtfResult};
use std::fs;
use std::path::Path;

// A decoded image frame (the bytes are just vibing in memory)
#[derive(Debug, Clone)]
pub struct DecodedFrame {
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
    // 0 = highest res, higher = squintier
    pub mipmap_level: u8,
    pub frame: u16,
}

impl DecodedFrame {
    pub fn to_image(&self) -> image::DynamicImage {
        let img = image::RgbaImage::from_raw(self.width, self.height, self.data.clone())
            .expect("The pixels have betrayed us");
        image::DynamicImage::ImageRgba8(img)
    }

    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), image::ImageError> {
        self.to_image().save(path)
    }
}

// A loaded VTF texture (Gabe Newell's gift to humanity)
#[derive(Debug, Clone)]
pub struct VtfImage {
    pub header: VtfHeader,
    raw_data: Vec<u8>,
    pub file_path: Option<String>,
}

impl VtfImage {
    pub fn width(&self) -> u32 {
        self.header.width as u32
    }

    pub fn height(&self) -> u32 {
        self.header.height as u32
    }

    pub fn frame_count(&self) -> u16 {
        self.header.frames
    }

    pub fn mipmap_count(&self) -> u8 {
        self.header.mipmap_count
    }

    pub fn has_alpha(&self) -> bool {
        self.header.has_alpha()
    }

    pub fn is_animated(&self) -> bool {
        self.header.is_animated()
    }

    pub fn format(&self) -> VtfFormat {
        self.header.high_res_format
    }

    // Decode the thumbnail (basically a texture for ants)
    pub fn decode_thumbnail(&self) -> VtfResult<DecodedFrame> {
        let width = self.header.low_res_width as u32;
        let height = self.header.low_res_height as u32;

        if width == 0 || height == 0 {
            return Err(VtfError::InvalidData("No thumbnail present".into()));
        }

        let data_size = self.header.low_res_format.compute_image_size(width, height) as usize;
        let data_start = self.header.header_size as usize;
        let data_end = data_start + data_size;

        if data_end > self.raw_data.len() {
            return Err(VtfError::InvalidData("Thumbnail data out of bounds".into()));
        }

        let raw_data = &self.raw_data[data_start..data_end];
        let rgba_data = convert_to_rgba(raw_data, self.header.low_res_format, width, height)?;

        Ok(DecodedFrame {
            data: rgba_data,
            width,
            height,
            mipmap_level: 255, // Special value for thumbnail
            frame: 0,
        })
    }

    // Decode a specific mipmap level and frame (mipmap 7 is just one sad pixel)
    pub fn decode(&self, mipmap_level: u8, frame: u16) -> VtfResult<DecodedFrame> {
        if mipmap_level >= self.header.mipmap_count {
            return Err(VtfError::InvalidMipmap(mipmap_level as u32));
        }

        if frame >= self.header.frames {
            return Err(VtfError::InvalidFrame(frame));
        }

        let (width, height) = self.header.mipmap_size(mipmap_level);
        let data_size = self
            .header
            .high_res_format
            .compute_image_size(width, height) as usize;
        let data_offset = self.calculate_data_offset(mipmap_level, frame);
        let data_end = data_offset + data_size;

        if data_end > self.raw_data.len() {
            return Err(VtfError::InvalidData(format!(
                "Image data out of bounds: offset {} + size {} > file size {}",
                data_offset,
                data_size,
                self.raw_data.len()
            )));
        }

        let raw_data = &self.raw_data[data_offset..data_end];
        let rgba_data = convert_to_rgba(raw_data, self.header.high_res_format, width, height)?;

        Ok(DecodedFrame {
            data: rgba_data,
            width,
            height,
            mipmap_level,
            frame,
        })
    }

    pub fn decode_main(&self) -> VtfResult<DecodedFrame> {
        self.decode(0, self.header.first_frame)
    }

    pub fn decode_all_frames(&self, mipmap_level: u8) -> VtfResult<Vec<DecodedFrame>> {
        let mut frames = Vec::with_capacity(self.header.frames as usize);
        for frame in 0..self.header.frames {
            frames.push(self.decode(mipmap_level, frame)?);
        }
        Ok(frames)
    }

    // WARNING: Here be pointer arithmetic dragons
    fn calculate_data_offset(&self, mipmap_level: u8, frame: u16) -> usize {
        let mut offset = self.header.header_size as usize;

        // Add thumbnail size
        offset += self.header.low_res_format.compute_image_size(
            self.header.low_res_width as u32,
            self.header.low_res_height as u32,
        ) as usize;

        // VTF stores mipmaps from smallest to largest
        // Add all smaller mipmaps (all frames)
        for mip in ((mipmap_level + 1)..self.header.mipmap_count).rev() {
            let size = self.header.mipmap_data_size(mip) as usize;
            offset += size * self.header.frames as usize * self.header.depth as usize;
        }

        // Add previous frames at this mipmap level
        offset += self.header.mipmap_data_size(mipmap_level) as usize
            * frame as usize
            * self.header.depth as usize;

        offset
    }

    pub fn raw_data(&self) -> &[u8] {
        &self.raw_data
    }
}

// VTF file decoder (it decodes things... shocking, I know)
pub struct VtfDecoder;

impl VtfDecoder {
    pub fn load_file<P: AsRef<Path>>(path: P) -> VtfResult<VtfImage> {
        let data = fs::read(path.as_ref())?;
        let mut image = Self::load_from_memory(&data)?;
        image.file_path = Some(path.as_ref().to_string_lossy().to_string());
        Ok(image)
    }

    pub fn load_from_memory(data: &[u8]) -> VtfResult<VtfImage> {
        if data.len() < 16 {
            return Err(VtfError::InvalidData("File too small".into()));
        }

        let header = VtfHeader::read(data)?;

        let expected_size = header.header_size + header.total_data_size();
        if (data.len() as u32) < expected_size {
            // Valve moment™, some VTFs are truncated but we just roll with it
        }

        Ok(VtfImage {
            header,
            raw_data: data.to_vec(),
            file_path: None,
        })
    }

    // Sniff a VTF without commitment issues
    pub fn probe<P: AsRef<Path>>(path: P) -> VtfResult<VtfHeader> {
        let mut file = fs::File::open(path)?;
        let mut header_data = vec![0u8; 80]; // Max header size for version 7.5
        std::io::Read::read(&mut file, &mut header_data)?;
        VtfHeader::read(&header_data)
    }
}

// Builder for creating VTF files (because Valve won't release their tools for Linux)
pub struct VtfBuilder {
    width: u32,
    height: u32,
    format: VtfFormat,
    generate_mipmaps: bool,
    is_normal_map: bool,
    rgba_data: Vec<u8>,
}

impl VtfBuilder {
    pub fn new(width: u32, height: u32, rgba_data: Vec<u8>) -> Self {
        Self {
            width,
            height,
            format: VtfFormat::Dxt5,
            generate_mipmaps: true,
            is_normal_map: false,
            rgba_data,
        }
    }

    pub fn from_image_file<P: AsRef<Path>>(path: P) -> VtfResult<Self> {
        let img = image::open(path)
            .map_err(|e| VtfError::InvalidData(format!("Failed to load image: {}", e)))?;

        let rgba = img.to_rgba8();
        let (width, height) = rgba.dimensions();

        Ok(Self::new(width, height, rgba.into_raw()))
    }

    pub fn format(mut self, format: VtfFormat) -> Self {
        self.format = format;
        self
    }

    pub fn mipmaps(mut self, generate: bool) -> Self {
        self.generate_mipmaps = generate;
        self
    }

    pub fn normal_map(mut self, is_normal: bool) -> Self {
        self.is_normal_map = is_normal;
        self
    }

    fn calculate_mipmap_count(width: u32, height: u32) -> u8 {
        let max_dim = width.max(height);
        (max_dim as f32).log2().floor() as u8 + 1
    }

    // Assembles bytes
    // I don't know what valve was smoking when they designed this format
    // But that must be some strong shit
    pub fn build(self) -> VtfResult<Vec<u8>> {
        // DXT compression is left because i don't care

        let mipmap_count = if self.generate_mipmaps {
            Self::calculate_mipmap_count(self.width, self.height)
        } else {
            1
        };

        // BGRA because Microsoft said so in 1995 and we're still paying for it
        let format = VtfFormat::Bgra8888;
        let header_size: u32 = 64;
        let mut output = Vec::new();

        output.extend_from_slice(b"VTF\0"); // The sacred runes
        output.extend_from_slice(&7u32.to_le_bytes());
        output.extend_from_slice(&2u32.to_le_bytes());
        output.extend_from_slice(&header_size.to_le_bytes());
        output.extend_from_slice(&(self.width as u16).to_le_bytes());
        output.extend_from_slice(&(self.height as u16).to_le_bytes());

        let mut flags: u32 = 0;
        if self.is_normal_map {
            flags |= 0x00000080;
        }
        flags |= 0x00002000;
        // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        output.extend_from_slice(&flags.to_le_bytes());
        output.extend_from_slice(&1u16.to_le_bytes());
        output.extend_from_slice(&0u16.to_le_bytes());
        output.extend_from_slice(&0u32.to_le_bytes());
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&0u32.to_le_bytes());
        output.extend_from_slice(&1.0f32.to_le_bytes());
        output.extend_from_slice(&(format as i32).to_le_bytes());
        output.push(mipmap_count);
        output.extend_from_slice(&(VtfFormat::Dxt1 as i32).to_le_bytes());
        let low_res_width = (self.width / 16).max(1) as u8;
        let low_res_height = (self.height / 16).max(1) as u8;
        output.push(low_res_width);
        output.push(low_res_height);
        output.extend_from_slice(&1u16.to_le_bytes());

        while output.len() < header_size as usize {
            output.push(0);
        }

        // The world's saddest thumbnail
        let thumb_size =
            VtfFormat::Dxt1.compute_image_size(low_res_width as u32, low_res_height as u32);
        output.extend(vec![0u8; thumb_size as usize]);

        // Mipmap time! (smallest to largest)
        for mip in (0..mipmap_count).rev() {
            let mip_width = (self.width >> mip).max(1);
            let mip_height = (self.height >> mip).max(1);

            let mip_data = if mip == 0 {
                // RGBA -> BGRA 
                let mut bgra = self.rgba_data.clone();
                for i in (0..bgra.len()).step_by(4) {
                    bgra.swap(i, i + 2);
                }
                bgra
            } else {
                let img =
                    image::RgbaImage::from_raw(self.width, self.height, self.rgba_data.clone())
                        .ok_or(VtfError::InvalidData("Invalid image data".into()))?;

                let resized = image::imageops::resize(
                    &img,
                    mip_width,
                    mip_height,
                    image::imageops::FilterType::Lanczos3,
                );

                let mut bgra = resized.into_raw();
                for i in (0..bgra.len()).step_by(4) {
                    bgra.swap(i, i + 2);
                }
                bgra
            };

            output.extend(mip_data);
        }

        Ok(output)
    }

    pub fn save<P: AsRef<Path>>(self, path: P) -> VtfResult<()> {
        let data = self.build()?;
        fs::write(path, data)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mipmap_count() {
        assert_eq!(VtfBuilder::calculate_mipmap_count(256, 256), 9);
        assert_eq!(VtfBuilder::calculate_mipmap_count(512, 512), 10);
        assert_eq!(VtfBuilder::calculate_mipmap_count(1024, 1024), 11);
        assert_eq!(VtfBuilder::calculate_mipmap_count(64, 128), 8);
    }
}
