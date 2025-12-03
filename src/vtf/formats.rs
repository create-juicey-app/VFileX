//! VTF image format handling (a.k.a. the fuck)
// spent a dozen hours on this
// thank you thank you thank you thank you thank you

use super::header::VtfFormat;
use super::{VtfError, VtfResult};

// Supported image formats for conversion
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageFormat {
    Rgba8,
    Rgb8,
    Grayscale,
    GrayscaleAlpha,
}

impl ImageFormat {
    pub fn channels(&self) -> u32 {
        match self {
            ImageFormat::Rgba8 => 4,
            ImageFormat::Rgb8 => 3,
            ImageFormat::Grayscale => 1,
            ImageFormat::GrayscaleAlpha => 2,
        }
    }

    pub fn bytes_per_pixel(&self) -> u32 {
        self.channels()
    }
}

// convert raw VTF image data to RGBA8
pub fn convert_to_rgba(
    data: &[u8],
    format: VtfFormat,
    width: u32,
    height: u32,
) -> VtfResult<Vec<u8>> {
    let pixel_count = (width * height) as usize;
    let mut output = vec![0u8; pixel_count * 4];

    match format {
        VtfFormat::Rgba8888 => {
            output.copy_from_slice(&data[..pixel_count * 4]);
        }

        VtfFormat::Abgr8888 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 4 + 3]; // R from A
                output[i * 4 + 1] = data[i * 4 + 2]; // G from B
                output[i * 4 + 2] = data[i * 4 + 1]; // B from G
                output[i * 4 + 3] = data[i * 4]; // A from R position
            }
        }

        VtfFormat::Argb8888 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 4 + 1]; // R
                output[i * 4 + 1] = data[i * 4 + 2]; // G
                output[i * 4 + 2] = data[i * 4 + 3]; // B
                output[i * 4 + 3] = data[i * 4]; // A
            }
        }

        VtfFormat::Bgra8888 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 4 + 2]; // R from B
                output[i * 4 + 1] = data[i * 4 + 1]; // G
                output[i * 4 + 2] = data[i * 4]; // B from R position
                output[i * 4 + 3] = data[i * 4 + 3]; // A
            }
        }

        VtfFormat::Bgrx8888 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 4 + 2]; // R from B
                output[i * 4 + 1] = data[i * 4 + 1]; // G
                output[i * 4 + 2] = data[i * 4]; // B from R position
                output[i * 4 + 3] = 255; // A = opaque
            }
        }

        VtfFormat::Rgb888 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 3];
                output[i * 4 + 1] = data[i * 3 + 1];
                output[i * 4 + 2] = data[i * 3 + 2];
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Bgr888 | VtfFormat::Bgr888BlueScreen => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 3 + 2]; // R from B
                output[i * 4 + 1] = data[i * 3 + 1]; // G
                output[i * 4 + 2] = data[i * 3]; // B from R position
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Rgb888BlueScreen => {
            for i in 0..pixel_count {
                let r = data[i * 3];
                let g = data[i * 3 + 1];
                let b = data[i * 3 + 2];
                output[i * 4] = r;
                output[i * 4 + 1] = g;
                output[i * 4 + 2] = b;
                // Blue screen: if pure blue, make transparent
                output[i * 4 + 3] = if r == 0 && g == 0 && b == 255 { 0 } else { 255 };
            }
        }

        VtfFormat::Rgb565 => {
            for i in 0..pixel_count {
                let pixel = u16::from_le_bytes([data[i * 2], data[i * 2 + 1]]);
                output[i * 4] = (((pixel >> 11) & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 1] = (((pixel >> 5) & 0x3F) as u32 * 255 / 63) as u8;
                output[i * 4 + 2] = ((pixel & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Bgr565 => {
            for i in 0..pixel_count {
                let pixel = u16::from_le_bytes([data[i * 2], data[i * 2 + 1]]);
                output[i * 4 + 2] = (((pixel >> 11) & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 1] = (((pixel >> 5) & 0x3F) as u32 * 255 / 63) as u8;
                output[i * 4] = ((pixel & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Bgra4444 => {
            for i in 0..pixel_count {
                let pixel = u16::from_le_bytes([data[i * 2], data[i * 2 + 1]]);
                output[i * 4 + 2] = (((pixel >> 12) & 0xF) as u32 * 17) as u8;
                output[i * 4 + 1] = (((pixel >> 8) & 0xF) as u32 * 17) as u8;
                output[i * 4] = (((pixel >> 4) & 0xF) as u32 * 17) as u8;
                output[i * 4 + 3] = ((pixel & 0xF) as u32 * 17) as u8;
            }
        }
        // fuck me sideways
        // thank god copy pasting code saved my life
        VtfFormat::Bgra5551 | VtfFormat::Bgrx5551 => {
            for i in 0..pixel_count {
                let pixel = u16::from_le_bytes([data[i * 2], data[i * 2 + 1]]);
                output[i * 4 + 2] = (((pixel >> 10) & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 1] = (((pixel >> 5) & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4] = ((pixel & 0x1F) as u32 * 255 / 31) as u8;
                output[i * 4 + 3] = if format == VtfFormat::Bgrx5551 {
                    255
                } else if pixel & 0x8000 != 0 {
                    255
                } else {
                    0
                };
            }
        }

        VtfFormat::I8 => {
            for i in 0..pixel_count {
                let intensity = data[i];
                output[i * 4] = intensity;
                output[i * 4 + 1] = intensity;
                output[i * 4 + 2] = intensity;
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Ia88 => {
            for i in 0..pixel_count {
                let intensity = data[i * 2];
                let alpha = data[i * 2 + 1];
                output[i * 4] = intensity;
                output[i * 4 + 1] = intensity;
                output[i * 4 + 2] = intensity;
                output[i * 4 + 3] = alpha;
            }
        }

        VtfFormat::A8 => {
            for i in 0..pixel_count {
                output[i * 4] = 255;
                output[i * 4 + 1] = 255;
                output[i * 4 + 2] = 255;
                output[i * 4 + 3] = data[i];
            }
        }

        VtfFormat::Uv88 => {
            for i in 0..pixel_count {
                output[i * 4] = data[i * 2]; // U -> R
                output[i * 4 + 1] = data[i * 2 + 1]; // V -> G
                output[i * 4 + 2] = 128; // B = neutral
                output[i * 4 + 3] = 255;
            }
        }

        VtfFormat::Uvwq8888 | VtfFormat::Uvlx8888 => {
            output.copy_from_slice(&data[..pixel_count * 4]);
        }

        VtfFormat::Dxt1 | VtfFormat::Dxt1OneBitAlpha => {
            decode_dxt1(
                data,
                width,
                height,
                &mut output,
                format == VtfFormat::Dxt1OneBitAlpha,
            )?;
        }

        VtfFormat::Dxt3 => {
            decode_dxt3(data, width, height, &mut output)?;
        }

        VtfFormat::Dxt5 => {
            decode_dxt5(data, width, height, &mut output)?;
        }

        VtfFormat::Rgba16161616F => {
            // Convert 16-bit float to 8-bit
            for i in 0..pixel_count {
                for c in 0..4 {
                    let bytes = [data[i * 8 + c * 2], data[i * 8 + c * 2 + 1]];
                    let f16 = half_to_float(u16::from_le_bytes(bytes));
                    output[i * 4 + c] = (f16.clamp(0.0, 1.0) * 255.0) as u8;
                }
            }
        }

        VtfFormat::Rgba16161616 => {
            for i in 0..pixel_count {
                for c in 0..4 {
                    let bytes = [data[i * 8 + c * 2], data[i * 8 + c * 2 + 1]];
                    let value = u16::from_le_bytes(bytes);
                    output[i * 4 + c] = (value >> 8) as u8;
                }
            }
        }

        VtfFormat::None | VtfFormat::P8 => {
            return Err(VtfError::UnsupportedFormat(super::ImageFormat::Rgba8));
        }
    }

    Ok(output)
}

// Decode DXT1 compressed data
fn decode_dxt1(
    data: &[u8],
    width: u32,
    height: u32,
    output: &mut [u8],
    has_alpha: bool,
) -> VtfResult<()> {
    let block_width = (width + 3) / 4;
    let block_height = (height + 3) / 4;

    for by in 0..block_height {
        for bx in 0..block_width {
            let block_index = (by * block_width + bx) as usize;
            let block_data = &data[block_index * 8..(block_index + 1) * 8];

            // Read color endpoints
            let c0 = u16::from_le_bytes([block_data[0], block_data[1]]);
            let c1 = u16::from_le_bytes([block_data[2], block_data[3]]);

            // Decode colors
            let color0 = decode_565(c0);
            let color1 = decode_565(c1);

            // Generate color palette
            let colors = if c0 > c1 || !has_alpha {
                [
                    color0,
                    color1,
                    interpolate_color(&color0, &color1, 1, 3),
                    interpolate_color(&color0, &color1, 2, 3),
                ]
            } else {
                [
                    color0,
                    color1,
                    interpolate_color(&color0, &color1, 1, 2),
                    [0, 0, 0, 0], // Transparent
                ]
            };

            // Read color indices
            let indices =
                u32::from_le_bytes([block_data[4], block_data[5], block_data[6], block_data[7]]);

            // Decode them pixels
            for py in 0..4 {
                for px in 0..4 {
                    let x = bx * 4 + px;
                    let y = by * 4 + py;

                    if x < width && y < height {
                        let pixel_index = py * 4 + px;
                        let color_index = ((indices >> (pixel_index * 2)) & 0x3) as usize;
                        let color = &colors[color_index];

                        let output_index = ((y * width + x) * 4) as usize;
                        output[output_index] = color[0];
                        output[output_index + 1] = color[1];
                        output[output_index + 2] = color[2];
                        output[output_index + 3] = color[3];
                    }
                }
            }
        }
    }

    Ok(())
}

// Decode DXT3 compressed data
fn decode_dxt3(data: &[u8], width: u32, height: u32, output: &mut [u8]) -> VtfResult<()> {
    let block_width = (width + 3) / 4;
    let block_height = (height + 3) / 4;

    for by in 0..block_height {
        for bx in 0..block_width {
            let block_index = (by * block_width + bx) as usize;
            let block_data = &data[block_index * 16..(block_index + 1) * 16];

            // Read explicit alpha values (first 8 bytes)
            let alpha_data = &block_data[0..8];

            // Read color data (last 8 bytes)
            let color_data = &block_data[8..16];

            let c0 = u16::from_le_bytes([color_data[0], color_data[1]]);
            let c1 = u16::from_le_bytes([color_data[2], color_data[3]]);

            let color0 = decode_565(c0);
            let color1 = decode_565(c1);

            let colors = [
                color0,
                color1,
                interpolate_color(&color0, &color1, 1, 3),
                interpolate_color(&color0, &color1, 2, 3),
            ];

            let indices =
                u32::from_le_bytes([color_data[4], color_data[5], color_data[6], color_data[7]]);

            for py in 0..4 {
                for px in 0..4 {
                    let x = bx * 4 + px;
                    let y = by * 4 + py;

                    if x < width && y < height {
                        let pixel_index = py * 4 + px;
                        let color_index = ((indices >> (pixel_index * 2)) & 0x3) as usize;
                        let color = &colors[color_index];

                        // kill em all
                        let alpha_byte_index = (pixel_index / 2) as usize;
                        let alpha_nibble = if pixel_index % 2 == 0 {
                            alpha_data[alpha_byte_index] & 0x0F
                        } else {
                            alpha_data[alpha_byte_index] >> 4
                        };
                        let alpha = alpha_nibble * 17; // Scale 0-15 to 0-255

                        let output_index = ((y * width + x) * 4) as usize;
                        output[output_index] = color[0];
                        output[output_index + 1] = color[1];
                        output[output_index + 2] = color[2];
                        output[output_index + 3] = alpha;
                    }
                }
            }
        }
    }

    Ok(())
}

// Decode DXT5 compressed data
fn decode_dxt5(data: &[u8], width: u32, height: u32, output: &mut [u8]) -> VtfResult<()> {
    let block_width = (width + 3) / 4;
    let block_height = (height + 3) / 4;

    for by in 0..block_height {
        for bx in 0..block_width {
            let block_index = (by * block_width + bx) as usize;
            let block_data = &data[block_index * 16..(block_index + 1) * 16];

            // Read alpha endpoints
            let a0 = block_data[0];
            let a1 = block_data[1];

            // Generate alpha palette
            let alphas = if a0 > a1 {
                [
                    a0,
                    a1,
                    ((6 * a0 as u32 + 1 * a1 as u32) / 7) as u8,
                    ((5 * a0 as u32 + 2 * a1 as u32) / 7) as u8,
                    ((4 * a0 as u32 + 3 * a1 as u32) / 7) as u8,
                    ((3 * a0 as u32 + 4 * a1 as u32) / 7) as u8,
                    ((2 * a0 as u32 + 5 * a1 as u32) / 7) as u8,
                    ((1 * a0 as u32 + 6 * a1 as u32) / 7) as u8,
                ]
            } else {
                [
                    a0,
                    a1,
                    ((4 * a0 as u32 + 1 * a1 as u32) / 5) as u8,
                    ((3 * a0 as u32 + 2 * a1 as u32) / 5) as u8,
                    ((2 * a0 as u32 + 3 * a1 as u32) / 5) as u8,
                    ((1 * a0 as u32 + 4 * a1 as u32) / 5) as u8,
                    0,
                    255,
                ]
            };

            // Read alpha indices (6 bytes = 48 bits for 16 pixels at 3 bits each)
            let alpha_bits: u64 = (block_data[2] as u64)
                | ((block_data[3] as u64) << 8)
                | ((block_data[4] as u64) << 16)
                | ((block_data[5] as u64) << 24)
                | ((block_data[6] as u64) << 32)
                | ((block_data[7] as u64) << 40);

            // Read color data
            let color_data = &block_data[8..16];
            let c0 = u16::from_le_bytes([color_data[0], color_data[1]]);
            let c1 = u16::from_le_bytes([color_data[2], color_data[3]]);

            let color0 = decode_565(c0);
            let color1 = decode_565(c1);

            let colors = [
                color0,
                color1,
                interpolate_color(&color0, &color1, 1, 3),
                interpolate_color(&color0, &color1, 2, 3),
            ];

            let color_indices =
                u32::from_le_bytes([color_data[4], color_data[5], color_data[6], color_data[7]]);

            for py in 0..4 {
                for px in 0..4 {
                    let x = bx * 4 + px;
                    let y = by * 4 + py;

                    if x < width && y < height {
                        let pixel_index = py * 4 + px;
                        let color_index = ((color_indices >> (pixel_index * 2)) & 0x3) as usize;
                        let alpha_index = ((alpha_bits >> (pixel_index * 3)) & 0x7) as usize;

                        let color = &colors[color_index];
                        let alpha = alphas[alpha_index];

                        let output_index = ((y * width + x) * 4) as usize;
                        output[output_index] = color[0];
                        output[output_index + 1] = color[1];
                        output[output_index + 2] = color[2];
                        output[output_index + 3] = alpha;
                    }
                }
            }
        }
    }

    Ok(())
}

// Decode RGB565 color
fn decode_565(color: u16) -> [u8; 4] {
    let r = ((color >> 11) & 0x1F) as u32;
    let g = ((color >> 5) & 0x3F) as u32;
    let b = (color & 0x1F) as u32;

    [
        (r * 255 / 31) as u8,
        (g * 255 / 63) as u8,
        (b * 255 / 31) as u8,
        255,
    ]
}

// Interpolate between two colors
fn interpolate_color(c0: &[u8; 4], c1: &[u8; 4], num: u32, denom: u32) -> [u8; 4] {
    [
        ((c0[0] as u32 * (denom - num) + c1[0] as u32 * num) / denom) as u8,
        ((c0[1] as u32 * (denom - num) + c1[1] as u32 * num) / denom) as u8,
        ((c0[2] as u32 * (denom - num) + c1[2] as u32 * num) / denom) as u8,
        255,
    ]
}

// Convert half-precision float to single-precision float
fn half_to_float(h: u16) -> f32 {
    let sign = (h >> 15) & 0x1;
    let exponent = (h >> 10) & 0x1F;
    let mantissa = h & 0x3FF;

    if exponent == 0 {
        if mantissa == 0 {
            return if sign == 0 { 0.0 } else { -0.0 };
        }
        // Denormalized number
        let m = mantissa as f32 / 1024.0;
        let f = m * 2.0f32.powi(-14);
        return if sign == 0 { f } else { -f };
    } else if exponent == 31 {
        if mantissa == 0 {
            return if sign == 0 {
                f32::INFINITY
            } else {
                f32::NEG_INFINITY
            };
        }
        return f32::NAN;
    }

    let m = 1.0 + mantissa as f32 / 1024.0;
    let f = m * 2.0f32.powi(exponent as i32 - 15);
    if sign == 0 {
        f
    } else {
        -f
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decode_565() {
        let white = decode_565(0xFFFF);
        assert_eq!(white[0], 255);
        assert_eq!(white[1], 255);
        assert_eq!(white[2], 255);

        let black = decode_565(0x0000);
        assert_eq!(black[0], 0);
        assert_eq!(black[1], 0);
        assert_eq!(black[2], 0);
    }

    #[test]
    fn test_half_to_float() {
        assert!((half_to_float(0x3C00) - 1.0).abs() < 0.001); // 1.0
        assert!((half_to_float(0x0000) - 0.0).abs() < 0.001); // 0.0
        assert!((half_to_float(0x4000) - 2.0).abs() < 0.001); // 2.0
    }
}
