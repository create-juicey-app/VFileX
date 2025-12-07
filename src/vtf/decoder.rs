//! VTF decoder

use super::formats::convert_to_rgba;
use super::header::{VtfFormat, VtfHeader};
use super::{VtfError, VtfResult};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone)]
pub struct DecodedFrame {
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
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
            // Some VTFs are truncated but still loadable
        }

        Ok(VtfImage {
            header,
            raw_data: data.to_vec(),
            file_path: None,
        })
    }

    pub fn probe<P: AsRef<Path>>(path: P) -> VtfResult<VtfHeader> {
        let mut file = fs::File::open(path)?;
        let mut header_data = vec![0u8; 80];
        std::io::Read::read(&mut file, &mut header_data)?;
        VtfHeader::read(&header_data)
    }
}

pub struct VtfBuilder {
    width: u32,
    height: u32,
    format: VtfFormat,
    generate_mipmaps: bool,
    is_normal_map: bool,
    clamp_s: bool,
    clamp_t: bool,
    no_lod: bool,
    // Support multiple frames for animated textures. Each entry is RGBA8 bytes for a single frame.
    frames: Vec<Vec<u8>>,
}

impl VtfBuilder {
    pub fn new(width: u32, height: u32, rgba_data: Vec<u8>) -> Self {
        Self {
            width,
            height,
            format: VtfFormat::Dxt5,
            generate_mipmaps: true,
            is_normal_map: false,
            clamp_s: false,
            clamp_t: false,
            no_lod: false,
            frames: vec![rgba_data],
        }
    }

    pub fn from_image_file<P: AsRef<Path>>(path: P) -> VtfResult<Self> {
        let path_ref = path.as_ref();
        // Try to detect animated GIFs first
        if let Some(ext) = path_ref.extension().and_then(|e| e.to_str()) {
            if ext.eq_ignore_ascii_case("gif") {
                // Decode GIF frames using image crate's GIF decoder
                use image::codecs::gif::GifDecoder;
                use image::AnimationDecoder;

                let file = std::fs::File::open(path_ref)
                    .map_err(|e| VtfError::InvalidData(format!("Failed to open file: {}", e)))?;
                let buf_reader = std::io::BufReader::new(file);
                let decoder = GifDecoder::new(buf_reader)
                    .map_err(|e| VtfError::InvalidData(format!("Failed to decode GIF: {}", e)))?;

                let frames_iter = decoder.into_frames();
                let frames_collected = frames_iter
                    .collect_frames()
                    .map_err(|e| VtfError::InvalidData(format!("Failed to collect GIF frames: {}", e)))?;

                if frames_collected.is_empty() {
                    return Err(VtfError::InvalidData("No frames in GIF".into()));
                }

                // Use first frame as reference size
                let (width, height) = (
                    frames_collected[0].buffer().width(),
                    frames_collected[0].buffer().height(),
                );

                // Convert each frame to RGBA8 raw and ensure consistent dimensions
                let mut frames_data: Vec<Vec<u8>> = Vec::new();
                for frame in frames_collected {
                    let buf = frame.buffer();
                    // Convert frame buffer into RGBA8 Vec<u8>
                    let rgba_buf = buf.clone().to_owned();
                    if rgba_buf.width() != width || rgba_buf.height() != height {
                        return Err(VtfError::InvalidData(
                            "GIF frames have different sizes, unsupported".into(),
                        ));
                    }
                    frames_data.push(rgba_buf.into_raw());
                }

                return Ok(Self {
                    width,
                    height,
                    format: VtfFormat::Dxt5,
                    generate_mipmaps: true,
                    is_normal_map: false,
                    clamp_s: false,
                    clamp_t: false,
                    no_lod: false,
                    frames: frames_data,
                });
            }
        }

        // Fallback: single-frame image
        let img = image::open(path)
            .map_err(|e| VtfError::InvalidData(format!("Failed to load image: {}", e)))?;

        let rgba = img.to_rgba8();
        let (width, height) = rgba.dimensions();

        Ok(Self::new(width, height, rgba.into_raw()))
    }

    /// Create a VTF builder from a set of RGBA frames. Each frame is a raw RGBA8 byte vector.
    pub fn from_frames(width: u32, height: u32, frames: Vec<Vec<u8>>) -> VtfResult<Self> {
        if frames.is_empty() {
            return Err(VtfError::InvalidData("No frames provided".into()));
        }

        // Ensure all frames have correct length
        let expected_len = (width * height * 4) as usize;
        for frame in &frames {
            if frame.len() != expected_len {
                return Err(VtfError::InvalidData("Frame size mismatch".into()));
            }
        }

        Ok(Self {
            width,
            height,
            format: VtfFormat::Dxt5,
            generate_mipmaps: true,
            is_normal_map: false,
            clamp_s: false,
            clamp_t: false,
            no_lod: false,
            frames,
        })
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

    pub fn clamp(mut self, clamp: bool) -> Self {
        self.clamp_s = clamp;
        self.clamp_t = clamp;
        self
    }

    pub fn no_lod(mut self, no_lod: bool) -> Self {
        self.no_lod = no_lod;
        self
    }

    fn calculate_mipmap_count(width: u32, height: u32) -> u8 {
        let max_dim = width.max(height);
        (max_dim as f32).log2().floor() as u8 + 1
    }

    pub fn build(self) -> VtfResult<Vec<u8>> {
        let mipmap_count = if self.generate_mipmaps {
            Self::calculate_mipmap_count(self.width, self.height)
        } else {
            1
        };

        let format = VtfFormat::Bgra8888;
        let header_size: u32 = 80;
        let mut output = Vec::new();

        output.extend_from_slice(b"VTF\0");
        output.extend_from_slice(&7u32.to_le_bytes());
        output.extend_from_slice(&2u32.to_le_bytes());
        output.extend_from_slice(&header_size.to_le_bytes());
        output.extend_from_slice(&(self.width as u16).to_le_bytes());
        output.extend_from_slice(&(self.height as u16).to_le_bytes());

    let mut flags: u32 = 0;
        if self.is_normal_map {
            flags |= 0x00000080; // TEXTUREFLAGS_NORMAL
        }
        if self.clamp_s {
            flags |= 0x00000004; // TEXTUREFLAGS_CLAMPS
        }
        if self.clamp_t {
            flags |= 0x00000008; // TEXTUREFLAGS_CLAMPT
        }
        if self.no_lod {
            flags |= 0x00000200; // TEXTUREFLAGS_NOLOD
        }
        flags |= 0x00002000;
        output.extend_from_slice(&flags.to_le_bytes());
    // Number of frames for animated textures
    let frame_count_u16: u16 = self.frames.len() as u16;
    output.extend_from_slice(&frame_count_u16.to_le_bytes());
        output.extend_from_slice(&0u16.to_le_bytes());
        output.extend_from_slice(&[0u8; 4]);
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&0.5f32.to_le_bytes());
        output.extend_from_slice(&[0u8; 4]);
        output.extend_from_slice(&1.0f32.to_le_bytes());
        output.extend_from_slice(&(format as i32).to_le_bytes());
        output.push(mipmap_count);
        output.extend_from_slice(&(VtfFormat::Dxt1 as i32).to_le_bytes());
        output.push(4);
        output.push(4);
        output.extend_from_slice(&1u16.to_le_bytes());
        output.extend_from_slice(&[0u8; 3]);
        output.extend_from_slice(&0u32.to_le_bytes());

        while output.len() < header_size as usize {
            output.push(0);
        }

        let avg_color = self.calculate_average_color();
        let thumb_data = self.create_dxt1_solid_block(avg_color);
        output.extend_from_slice(&thumb_data);

        // For each mipmap level (smallest-to-largest), write image data for all frames.
        for mip in (0..mipmap_count).rev() {
            let mip_width = (self.width >> mip).max(1);
            let mip_height = (self.height >> mip).max(1);

            for frame in &self.frames {
                let mip_data = if mip == 0 {
                    let mut bgra = frame.clone();
                    for i in (0..bgra.len()).step_by(4) {
                        if i + 2 < bgra.len() {
                            bgra.swap(i, i + 2);
                        }
                    }
                    bgra
                } else {
                    let img = image::RgbaImage::from_raw(self.width, self.height, frame.clone())
                        .ok_or(VtfError::InvalidData("Invalid image data".into()))?;

                    let resized = image::imageops::resize(
                        &img,
                        mip_width,
                        mip_height,
                        image::imageops::FilterType::Lanczos3,
                    );

                    let mut bgra = resized.into_raw();
                    for i in (0..bgra.len()).step_by(4) {
                        if i + 2 < bgra.len() {
                            bgra.swap(i, i + 2);
                        }
                    }
                    bgra
                };

                output.extend(mip_data);
            }
        }

        Ok(output)
    }

    fn calculate_average_color(&self) -> [u8; 4] {
        let pixel_count = (self.width * self.height) as usize;
        // Use first frame existence as validation
        if pixel_count == 0 || self.frames.is_empty() || self.frames[0].len() < 4 {
            return [128, 128, 128, 255];
        }

        let mut r_sum: u64 = 0;
        let mut g_sum: u64 = 0;
        let mut b_sum: u64 = 0;
        let mut a_sum: u64 = 0;
        let mut count: u64 = 0;

        for frame in &self.frames {
            for i in (0..frame.len()).step_by(4) {
                if i + 3 < frame.len() {
                    r_sum += frame[i] as u64;
                    g_sum += frame[i + 1] as u64;
                    b_sum += frame[i + 2] as u64;
                    a_sum += frame[i + 3] as u64;
                    count += 1;
                }
            }
        }

        if count == 0 {
            return [128, 128, 128, 255];
        }

        [
            (r_sum / count) as u8,
            (g_sum / count) as u8,
            (b_sum / count) as u8,
            (a_sum / count) as u8,
        ]
    }

    fn create_dxt1_solid_block(&self, color: [u8; 4]) -> [u8; 8] {
        let r5 = (color[0] as u16 >> 3) & 0x1F;
        let g6 = (color[1] as u16 >> 2) & 0x3F;
        let b5 = (color[2] as u16 >> 3) & 0x1F;
        let rgb565 = (r5 << 11) | (g6 << 5) | b5;

        let mut block = [0u8; 8];
        block[0..2].copy_from_slice(&rgb565.to_le_bytes());
        block[2..4].copy_from_slice(&rgb565.to_le_bytes());
        block[4] = 0;
        block[5] = 0;
        block[6] = 0;
        block[7] = 0;

        block
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

    #[test]
    fn test_build_animated_vtf() {
        // Create two simple 4x4 frames: red and green
        let width = 4;
        let height = 4;
        let mut frame_red: Vec<u8> = Vec::new();
        let mut frame_green: Vec<u8> = Vec::new();
        for _ in 0..(width * height) {
            frame_red.push(255); // R
            frame_red.push(0); // G
            frame_red.push(0); // B
            frame_red.push(255); // A

            frame_green.push(0);
            frame_green.push(255);
            frame_green.push(0);
            frame_green.push(255);
        }

        let frames = vec![frame_red, frame_green];
        let builder = VtfBuilder::from_frames(width, height, frames).unwrap();
        let data = builder.build().unwrap();

        // Parse back to ensure it was written as an animated texture
        let vtf = VtfDecoder::load_from_memory(&data).unwrap();
        assert_eq!(vtf.header.frames, 2);
        assert!(vtf.header.mipmap_count >= 1);
    }
}
