//! VTF file header structures
//! Yes i have created my own VTF parser because i am FUCKING insane
use super::{VtfError, VtfResult};
use byteorder::{LittleEndian, ReadBytesExt};
use std::io::{Cursor, Read};

// VTF file signature "VTF\0" - Valve's autograph

pub const VTF_SIGNATURE: [u8; 4] = [0x56, 0x54, 0x46, 0x00];

// VTF file version (we stopped at 7.5 because counting is hard)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct VtfVersion {
    pub major: u32,
    pub minor: u32,
}

impl VtfVersion {
    pub fn new(major: u32, minor: u32) -> Self {
        Self { major, minor }
    }

    // Check if this version is supported
    pub fn is_supported(&self) -> bool {
        self.major == 7 && self.minor <= 5
    }
}

impl std::fmt::Display for VtfVersion {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}.{}", self.major, self.minor)
    }
}

bitflags::bitflags! {
    // VTF image flags
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct VtfFlags: u32 {
        const POINTSAMPLE = 0x00000001;
        const TRILINEAR = 0x00000002;
        const CLAMPS = 0x00000004;
        const CLAMPT = 0x00000008;
        const ANISOTROPIC = 0x00000010;
        const HINT_DXT5 = 0x00000020;
        const PWL_CORRECTED = 0x00000040;
        const NORMAL = 0x00000080;
        const NOMIP = 0x00000100;
        const NOLOD = 0x00000200;
        const ALL_MIPS = 0x00000400;
        const PROCEDURAL = 0x00000800;
        const ONEBITALPHA = 0x00001000;
        const EIGHTBITALPHA = 0x00002000;
        const ENVMAP = 0x00004000;
        const RENDERTARGET = 0x00008000;
        const DEPTHRENDERTARGET = 0x00010000;
        const NODEBUGOVERRIDE = 0x00020000;
        const SINGLECOPY = 0x00040000;
        const PRE_SRGB = 0x00080000;
        const UNUSED0 = 0x00100000;
        const UNUSED1 = 0x00200000;
        const UNUSED2 = 0x00400000;
        const NODEPTHBUFFER = 0x00800000;
        const UNUSED3 = 0x01000000;
        const CLAMPU = 0x02000000;
        const VERTEXTEXTURE = 0x04000000;
        const SSBUMP = 0x08000000;
        const UNUSED4 = 0x10000000;
        const BORDER = 0x20000000;
        const UNUSED5 = 0x40000000;
        const UNUSED6 = 0x80000000;
    }
}

// VTF format enumeration
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(i32)]
pub enum VtfFormat {
    None = -1,
    Rgba8888 = 0,
    Abgr8888 = 1,
    Rgb888 = 2,
    Bgr888 = 3,
    Rgb565 = 4,
    I8 = 5,
    Ia88 = 6,
    P8 = 7,
    A8 = 8,
    Rgb888BlueScreen = 9,
    Bgr888BlueScreen = 10,
    Argb8888 = 11,
    Bgra8888 = 12,
    Dxt1 = 13,
    Dxt3 = 14,
    Dxt5 = 15,
    Bgrx8888 = 16,
    Bgr565 = 17,
    Bgrx5551 = 18,
    Bgra4444 = 19,
    Dxt1OneBitAlpha = 20,
    Bgra5551 = 21,
    Uv88 = 22,
    Uvwq8888 = 23,
    Rgba16161616F = 24,
    Rgba16161616 = 25,
    Uvlx8888 = 26,
}

impl TryFrom<i32> for VtfFormat {
    type Error = VtfError;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        match value {
            -1 => Ok(VtfFormat::None),
            0 => Ok(VtfFormat::Rgba8888),
            1 => Ok(VtfFormat::Abgr8888),
            2 => Ok(VtfFormat::Rgb888),
            3 => Ok(VtfFormat::Bgr888),
            4 => Ok(VtfFormat::Rgb565),
            5 => Ok(VtfFormat::I8),
            6 => Ok(VtfFormat::Ia88),
            7 => Ok(VtfFormat::P8),
            8 => Ok(VtfFormat::A8),
            9 => Ok(VtfFormat::Rgb888BlueScreen),
            10 => Ok(VtfFormat::Bgr888BlueScreen),
            11 => Ok(VtfFormat::Argb8888),
            12 => Ok(VtfFormat::Bgra8888),
            13 => Ok(VtfFormat::Dxt1),
            14 => Ok(VtfFormat::Dxt3),
            15 => Ok(VtfFormat::Dxt5),
            16 => Ok(VtfFormat::Bgrx8888),
            17 => Ok(VtfFormat::Bgr565),
            18 => Ok(VtfFormat::Bgrx5551),
            19 => Ok(VtfFormat::Bgra4444),
            20 => Ok(VtfFormat::Dxt1OneBitAlpha),
            21 => Ok(VtfFormat::Bgra5551),
            22 => Ok(VtfFormat::Uv88),
            23 => Ok(VtfFormat::Uvwq8888),
            24 => Ok(VtfFormat::Rgba16161616F),
            25 => Ok(VtfFormat::Rgba16161616),
            26 => Ok(VtfFormat::Uvlx8888),
            _ => Err(VtfError::InvalidData(format!("Unknown format: {}", value))),
        }
    }
}

impl VtfFormat {
    // Get the bits per pixel for this format
    pub fn bits_per_pixel(&self) -> u32 {
        match self {
            VtfFormat::None => 0,
            VtfFormat::Rgba8888
            | VtfFormat::Abgr8888
            | VtfFormat::Argb8888
            | VtfFormat::Bgra8888
            | VtfFormat::Bgrx8888
            | VtfFormat::Uvwq8888
            | VtfFormat::Uvlx8888 => 32,
            VtfFormat::Rgb888
            | VtfFormat::Bgr888
            | VtfFormat::Rgb888BlueScreen
            | VtfFormat::Bgr888BlueScreen => 24,
            VtfFormat::Rgb565
            | VtfFormat::Bgr565
            | VtfFormat::Ia88
            | VtfFormat::Bgrx5551
            | VtfFormat::Bgra4444
            | VtfFormat::Bgra5551
            | VtfFormat::Uv88 => 16,
            VtfFormat::I8 | VtfFormat::P8 | VtfFormat::A8 => 8,
            VtfFormat::Dxt1 | VtfFormat::Dxt1OneBitAlpha => 4,
            VtfFormat::Dxt3 | VtfFormat::Dxt5 => 8,
            VtfFormat::Rgba16161616F | VtfFormat::Rgba16161616 => 64,
        }
    }

    // check if this is a compressed format
    pub fn is_compressed(&self) -> bool {
        matches!(
            self,
            VtfFormat::Dxt1 | VtfFormat::Dxt3 | VtfFormat::Dxt5 | VtfFormat::Dxt1OneBitAlpha
        )
    }

    // get the block size for compressed formats
    pub fn block_size(&self) -> Option<u32> {
        match self {
            VtfFormat::Dxt1 | VtfFormat::Dxt1OneBitAlpha => Some(8),
            VtfFormat::Dxt3 | VtfFormat::Dxt5 => Some(16),
            _ => None,
        }
    }

    // calculate the size of image data in bytes
    pub fn compute_image_size(&self, width: u32, height: u32) -> u32 {
        if self.is_compressed() {
            let block_width = (width + 3) / 4;
            let block_height = (height + 3) / 4;
            block_width * block_height * self.block_size().unwrap_or(8)
        } else {
            width * height * self.bits_per_pixel() / 8
        }
    }
}

// VTF file header
#[derive(Debug, Clone)]
pub struct VtfHeader {
    // File version
    pub version: VtfVersion,
    // Header size in bytes
    pub header_size: u32,
    // Image width
    pub width: u16,
    // Image height
    pub height: u16,
    // Image flags
    pub flags: VtfFlags,
    // Number of frames (for animated textures)
    pub frames: u16,
    // First frame index
    pub first_frame: u16,
    // Reflectivity vector (for HDR)
    pub reflectivity: [f32; 3],
    // Bump map scale
    pub bumpmap_scale: f32,
    // High-resolution image format
    pub high_res_format: VtfFormat,
    // Number of mipmap levels
    pub mipmap_count: u8,
    // Low-resolution image format
    pub low_res_format: VtfFormat,
    // Low-resolution image width
    pub low_res_width: u8,
    // Low-resolution image height
    pub low_res_height: u8,
    // Depth (for volume textures)
    pub depth: u16,
    // Number of resources (version 7.3+)
    pub resource_count: u32,
}

impl VtfHeader {
    // read VTF header from a byte buffer
    pub fn read(data: &[u8]) -> VtfResult<Self> {
        let mut cursor = Cursor::new(data);

        // read and verify signature
        let mut signature = [0u8; 4];
        cursor.read_exact(&mut signature)?;
        if signature != VTF_SIGNATURE {
            return Err(VtfError::InvalidSignature);
        }

        // read version
        let major = cursor.read_u32::<LittleEndian>()?;
        let minor = cursor.read_u32::<LittleEndian>()?;
        let version = VtfVersion::new(major, minor);

        if !version.is_supported() {
            return Err(VtfError::UnsupportedVersion(major, minor));
        }

        // read header size
        let header_size = cursor.read_u32::<LittleEndian>()?;

        // read image dimensions
        let width = cursor.read_u16::<LittleEndian>()?;
        let height = cursor.read_u16::<LittleEndian>()?;

        // read flags
        let flags = VtfFlags::from_bits_truncate(cursor.read_u32::<LittleEndian>()?);

        // read frame info
        let frames = cursor.read_u16::<LittleEndian>()?;
        let first_frame = cursor.read_u16::<LittleEndian>()?;

        // skip padding (4 bytes)
        cursor.read_u32::<LittleEndian>()?;

        // read reflectivity
        let reflectivity = [
            cursor.read_f32::<LittleEndian>()?,
            cursor.read_f32::<LittleEndian>()?,
            cursor.read_f32::<LittleEndian>()?,
        ];

        // skip padding (4 bytes)
        cursor.read_u32::<LittleEndian>()?;

        // read bumpmap scale
        let bumpmap_scale = cursor.read_f32::<LittleEndian>()?;

        // read formats
        let high_res_format = VtfFormat::try_from(cursor.read_i32::<LittleEndian>()?)?;
        let mipmap_count = cursor.read_u8()?;
        let low_res_format = VtfFormat::try_from(cursor.read_i32::<LittleEndian>()? as i32)
            .unwrap_or(VtfFormat::Dxt1);
        let low_res_width = cursor.read_u8()?;
        let low_res_height = cursor.read_u8()?;

        // read depth (version 7.2+)
        let depth = if version.minor >= 2 {
            cursor.read_u16::<LittleEndian>()?
        } else {
            1
        };

        // read resource count (version 7.3+)
        let resource_count = if version.minor >= 3 {
            // skip padding (3 bytes)
            let mut pad = [0u8; 3];
            cursor.read_exact(&mut pad)?;
            cursor.read_u32::<LittleEndian>()?
        } else {
            0
        };

        Ok(Self {
            version,
            header_size,
            width,
            height,
            flags,
            frames,
            first_frame,
            reflectivity,
            bumpmap_scale,
            high_res_format,
            mipmap_count,
            low_res_format,
            low_res_width,
            low_res_height,
            depth,
            resource_count,
        })
    }

    // calculate the size of a specific mipmap level
    pub fn mipmap_size(&self, level: u8) -> (u32, u32) {
        let divisor = 1u32 << level;
        let width = (self.width as u32 / divisor).max(1);
        let height = (self.height as u32 / divisor).max(1);
        (width, height)
    }

    // calculate the data size for a specific mipmap level
    pub fn mipmap_data_size(&self, level: u8) -> u32 {
        let (width, height) = self.mipmap_size(level);
        self.high_res_format.compute_image_size(width, height)
    }

    // calculate the offset to a specific mipmap level
    pub fn mipmap_offset(&self, level: u8, frame: u16) -> u32 {
        let mut offset = self.header_size;

        // add thumbnail size
        offset += self
            .low_res_format
            .compute_image_size(self.low_res_width as u32, self.low_res_height as u32);

        // add all previous mipmap levels for all frames
        // VTF stores mipmaps from smallest to largest
        for mip in (level + 1..self.mipmap_count).rev() {
            let size = self.mipmap_data_size(mip);
            offset += size * self.frames as u32 * self.depth as u32;
        }

        // add previous frames at this mipmap level
        offset += self.mipmap_data_size(level) * frame as u32 * self.depth as u32;

        offset
    }

    // get the total size of all image data
    pub fn total_data_size(&self) -> u32 {
        let mut size = self
            .low_res_format
            .compute_image_size(self.low_res_width as u32, self.low_res_height as u32);

        for level in 0..self.mipmap_count {
            size += self.mipmap_data_size(level) * self.frames as u32 * self.depth as u32;
        }

        size
    }

    // check if this texture has alpha
    pub fn has_alpha(&self) -> bool {
        self.flags.contains(VtfFlags::ONEBITALPHA)
            || self.flags.contains(VtfFlags::EIGHTBITALPHA)
            || matches!(
                self.high_res_format,
                VtfFormat::Rgba8888
                    | VtfFormat::Abgr8888
                    | VtfFormat::Argb8888
                    | VtfFormat::Bgra8888
                    | VtfFormat::Dxt3
                    | VtfFormat::Dxt5
                    | VtfFormat::Dxt1OneBitAlpha
                    | VtfFormat::Bgra4444
                    | VtfFormat::Bgra5551
                    | VtfFormat::A8
                    | VtfFormat::Ia88
            )
    }

    // check if this is an animated texture
    pub fn is_animated(&self) -> bool {
        self.frames > 1
    }

    // check if this is a volume texture
    pub fn is_volume(&self) -> bool {
        self.depth > 1
    }

    // check if this is an environment map
    pub fn is_envmap(&self) -> bool {
        self.flags.contains(VtfFlags::ENVMAP)
    }

    // check if this is a normal map
    pub fn is_normal_map(&self) -> bool {
        self.flags.contains(VtfFlags::NORMAL)
    }
}
