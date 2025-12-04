//! Texture Image Provider for QML
//!
//! Todo: idk

use cxx_qt::CxxQtType;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::pin::Pin;
use std::sync::{Arc, Mutex};

use crate::vpk_archive::VPK_MANAGER;
use crate::vtf::{DecodedFrame, VtfDecoder, VtfImage};

/// Logging helper for texture operations
macro_rules! tex_log {
    ($($arg:tt)*) => {
        eprintln!("[Texture] {}", format!($($arg)*));
    };
}

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;

        include!("cxx-qt-lib/qurl.h");
        type QUrl = cxx_qt_lib::QUrl;

        include!("cxx-qt-lib/qbytearray.h");
        type QByteArray = cxx_qt_lib::QByteArray;
    }

    unsafe extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, current_texture)]
        #[qproperty(i32, texture_width)]
        #[qproperty(i32, texture_height)]
        #[qproperty(i32, frame_count)]
        #[qproperty(i32, current_frame)]
        #[qproperty(i32, mipmap_count)]
        #[qproperty(i32, current_mipmap)]
        #[qproperty(bool, has_alpha)]
        #[qproperty(bool, is_animated)]
        #[qproperty(QString, format_name)]
        #[qproperty(QString, error_message)]
        #[qproperty(bool, is_loaded)]
        type TextureProvider = super::TextureProviderRust;
    }

    unsafe extern "RustQt" {
        // Load a VTF texture from file path
        #[qinvokable]
        fn load_texture(self: Pin<&mut TextureProvider>, path: &QString) -> bool;

        // Load a VTF texture from a material's base texture path
        #[qinvokable]
        fn load_from_material_path(
            self: Pin<&mut TextureProvider>,
            texture_path: &QString,
            materials_root: &QString,
        ) -> bool;

        // Get a thumbnail preview path for any texture (doesn't affect main provider state)
        // Returns file:// URL to a cached PNG thumbnail, or empty string on failure
        #[qinvokable]
        fn get_thumbnail_for_texture(
            self: &TextureProvider,
            texture_path: &QString,
            materials_root: &QString,
        ) -> QString;

        // Get the raw RGBA data as a byte array for the current frame
        #[qinvokable]
        fn get_rgba_data(self: &TextureProvider) -> QByteArray;

        // Get RGBA data for a specific mipmap level
        #[qinvokable]
        fn get_mipmap_data(self: Pin<&mut TextureProvider>, level: i32) -> QByteArray;

        // Set the current frame (for animated textures)
        #[qinvokable]
        fn set_frame(self: Pin<&mut TextureProvider>, frame: i32);

        // Set the current mipmap level
        #[qinvokable]
        fn set_mipmap(self: Pin<&mut TextureProvider>, level: i32);

        // Save the current frame as an image file
        #[qinvokable]
        fn save_as_image(self: &TextureProvider, path: &QString) -> bool;

        // Clear the loaded texture
        #[qinvokable]
        fn clear(self: Pin<&mut TextureProvider>);

        // Get texture info as formatted string
        #[qinvokable]
        fn get_texture_info(self: &TextureProvider) -> QString;

        // Get a temporary file path with the current frame saved as PNG
        // Returns empty string if no texture is loaded
        #[qinvokable]
        fn get_preview_path(self: Pin<&mut TextureProvider>) -> QString;
    }

    // Signals
    unsafe extern "RustQt" {
        // Emitted when a texture is loaded
        #[qsignal]
        fn texture_loaded(self: Pin<&mut TextureProvider>);

        // Emitted when the frame changes
        #[qsignal]
        fn frame_changed(self: Pin<&mut TextureProvider>);

        // Emitted when the mipmap level changes  
        #[qsignal]
        fn mipmap_changed(self: Pin<&mut TextureProvider>);

        // Emitted when an error occurs
        #[qsignal]
        fn error_occurred(self: Pin<&mut TextureProvider>, message: QString);
    }
}

use qobject::*;

// Rust implementation of the texture provider
pub struct TextureProviderRust {
    // Loaded VTF image
    vtf_image: Option<VtfImage>,
    // Current decoded frame
    current_decoded: Option<DecodedFrame>,
    // Cached preview path
    preview_path: Option<PathBuf>,

    // Q_PROPERTY backing fields
    current_texture: QString,
    texture_width: i32,
    texture_height: i32,
    frame_count: i32,
    current_frame: i32,
    mipmap_count: i32,
    current_mipmap: i32,
    has_alpha: bool,
    is_animated: bool,
    format_name: QString,
    error_message: QString,
    is_loaded: bool,
}

impl Default for TextureProviderRust {
    fn default() -> Self {
        Self {
            vtf_image: None,
            current_decoded: None,
            preview_path: None,
            current_texture: QString::default(),
            texture_width: 0,
            texture_height: 0,
            frame_count: 0,
            current_frame: 0,
            mipmap_count: 0,
            current_mipmap: 0,
            has_alpha: false,
            is_animated: false,
            format_name: QString::default(),
            error_message: QString::default(),
            is_loaded: false,
        }
    }
}

impl qobject::TextureProvider {
    // Load a VTF texture from file path
    fn load_texture(mut self: Pin<&mut Self>, path: &QString) -> bool {
        let path_str = path.to_string();

        match VtfDecoder::load_file(&path_str) {
            Ok(vtf) => {
                self.as_mut().update_from_vtf(&vtf);
                self.as_mut().set_current_texture(path.clone());
                self.as_mut().rust_mut().vtf_image = Some(vtf);

                // Decode the first frame
                self.as_mut().decode_current_frame();

                self.as_mut().texture_loaded();
                true
            }
            Err(e) => {
                tex_log!("✗ Failed to load: {}", e);
                let msg = QString::from(format!("Failed to load texture: {}", e).as_str());
                self.as_mut().set_error_message(msg.clone());
                self.as_mut().error_occurred(msg);
                false
            }
        }
    }

    // Load a VTF texture from a material's base texture path
    fn load_from_material_path(
        mut self: Pin<&mut Self>,
        texture_path: &QString,
        materials_root: &QString,
    ) -> bool {
        let texture_path_str = texture_path.to_string();
        let materials_root_str = materials_root.to_string();
        
        tex_log!("Loading texture: {}", texture_path_str);
        tex_log!("  Materials root: {}", materials_root_str);

        // Construct the full path
        // VMT paths are relative to the materials folder and don't include extension
        let mut full_path = PathBuf::from(&materials_root_str);
        full_path.push(&texture_path_str);
        full_path.set_extension("vtf");

        // Try loading from disk first
        tex_log!("  Trying disk: {}", full_path.display());
        if full_path.exists() {
            tex_log!("  ✓ Found on disk!");
            let path = QString::from(full_path.to_string_lossy().as_ref());
            return self.load_texture(&path);
        }

        // Try with "materials/" prefix if not already there
        if !texture_path_str.starts_with("materials/")
            && !texture_path_str.starts_with("materials\\")
        {
            let mut alt_path = PathBuf::from(&materials_root_str);
            alt_path.push("materials");
            alt_path.push(&texture_path_str);
            alt_path.set_extension("vtf");

            tex_log!("  Trying disk (alt): {}", alt_path.display());
            if alt_path.exists() {
                tex_log!("  ✓ Found on disk (alt path)!");
                let path = QString::from(alt_path.to_string_lossy().as_ref());
                return self.load_texture(&path);
            }
        }

        // Try loading from VPK archives
        tex_log!("  Not on disk, trying VPK archives...");
        // Build the VPK path (usually "materials/path/texture.vtf")
        // First ensure the path has correct format - add .vtf only if not already present
        let texture_normalized = texture_path_str.replace('\\', "/");
        let texture_with_ext = if texture_normalized.to_lowercase().ends_with(".vtf") {
            texture_normalized
        } else {
            format!("{}.vtf", texture_normalized)
        };
        
        let vpk_path = if texture_with_ext.starts_with("materials/") {
            texture_with_ext
        } else {
            format!("materials/{}", texture_with_ext)
        };

        tex_log!("  VPK path: {}", vpk_path);

        // Try to load from VPK
        let game_dir = Path::new(&materials_root_str);
        if let Ok(data) = VPK_MANAGER.read_file(game_dir, &vpk_path) {
            tex_log!("  ✓ Found in VPK! ({} bytes)", data.len());
            // Load VTF from memory
            match VtfDecoder::load_from_memory(&data) {
                Ok(vtf) => {
                    tex_log!("  ✓ Decoded VTF: {}x{} {:?}", vtf.width(), vtf.height(), vtf.format());
                    self.as_mut().update_from_vtf(&vtf);
                    self.as_mut().set_current_texture(QString::from(format!("vpk:{}", vpk_path).as_str()));
                    self.as_mut().rust_mut().vtf_image = Some(vtf);
                    self.as_mut().decode_current_frame();
                    self.as_mut().texture_loaded();
                    return true;
                }
                Err(e) => {
                    tex_log!("  ✗ Failed to decode VTF from VPK: {}", e);
                    let msg = QString::from(format!("Failed to decode VPK texture: {}", e).as_str());
                    self.as_mut().set_error_message(msg.clone());
                    self.as_mut().error_occurred(msg);
                    return false;
                }
            }
        }

        tex_log!("  ✗ Texture not found anywhere!");
        let msg = QString::from(format!("Texture not found: {}", texture_path_str).as_str());
        self.as_mut().set_error_message(msg.clone());
        self.as_mut().error_occurred(msg);
        false
    }

    // Get a thumbnail preview path for any texture (doesn't affect main provider state)
    fn get_thumbnail_for_texture(
        &self,
        texture_path: &QString,
        materials_root: &QString,
    ) -> QString {
        let texture_path_str = texture_path.to_string();
        let materials_root_str = materials_root.to_string();

        // Skip empty paths
        if texture_path_str.is_empty() || materials_root_str.is_empty() {
            return QString::default();
        }

        // Generate a cache key from the texture path
        let cache_key: String = texture_path_str
            .chars()
            .map(|c| if c.is_alphanumeric() { c } else { '_' })
            .collect();
        
        let temp_dir = std::env::temp_dir();
        let thumbnail_path = temp_dir.join(format!("VFileX_thumb_{}.png", cache_key));

        // Return cached thumbnail if it exists (fast path - no I/O except stat)
        if thumbnail_path.exists() {
            return QString::from(format!("file://{}", thumbnail_path.to_string_lossy()).as_str());
        }

        // Try to find and load the texture from disk first
        let mut full_path = PathBuf::from(&materials_root_str);
        full_path.push(&texture_path_str);
        full_path.set_extension("vtf");

        // Try alternate path if not found
        if !full_path.exists() {
            if !texture_path_str.starts_with("materials/")
                && !texture_path_str.starts_with("materials\\")
            {
                let mut alt_path = PathBuf::from(&materials_root_str);
                alt_path.push("materials");
                alt_path.push(&texture_path_str);
                alt_path.set_extension("vtf");
                if alt_path.exists() {
                    full_path = alt_path;
                }
            }
        }

        // Try loading from disk
        if full_path.exists() {
            return self.generate_thumbnail_from_file(&full_path, &thumbnail_path);
        }

        // Try loading from VPK archives
        // First ensure the path has correct format - add .vtf only if not already present
        let texture_normalized = texture_path_str.replace('\\', "/");
        let texture_with_ext = if texture_normalized.to_lowercase().ends_with(".vtf") {
            texture_normalized
        } else {
            format!("{}.vtf", texture_normalized)
        };
        
        let vpk_path = if texture_with_ext.starts_with("materials/") {
            texture_with_ext
        } else {
            format!("materials/{}", texture_with_ext)
        };

        let game_dir = Path::new(&materials_root_str);
        if let Ok(data) = VPK_MANAGER.read_file(game_dir, &vpk_path) {
            return self.generate_thumbnail_from_data(&data, &thumbnail_path);
        }

        QString::default()
    }

    // Helper: Generate thumbnail from a file path
    fn generate_thumbnail_from_file(&self, vtf_path: &Path, thumbnail_path: &Path) -> QString {
        match VtfDecoder::load_file(vtf_path.to_string_lossy().as_ref()) {
            Ok(vtf) => self.generate_thumbnail_from_vtf(&vtf, thumbnail_path),
            Err(_) => QString::default(),
        }
    }

    // Helper: Generate thumbnail from VTF data bytes
    fn generate_thumbnail_from_data(&self, data: &[u8], thumbnail_path: &Path) -> QString {
        match VtfDecoder::load_from_memory(data) {
            Ok(vtf) => self.generate_thumbnail_from_vtf(&vtf, thumbnail_path),
            Err(_) => QString::default(),
        }
    }

    // Helper: Generate thumbnail from loaded VTF
    fn generate_thumbnail_from_vtf(&self, vtf: &VtfImage, thumbnail_path: &Path) -> QString {
        // Use a mipmap about 1/4 of the way through the chain for good quality thumbnails
        // Lower mipmap number = larger image = better quality but slower decode
        // For small mipmap chains, stay at 0 (full resolution).
        let mipmap_level = if vtf.header.mipmap_count <= 3 {
            0u8
        } else {
            // Use 1/4 of the way through for higher quality (e.g., mipmap 1-2 for most textures)
            // This gives ~256x256 or ~512x512 thumbnails for 1024x1024 textures
            (vtf.header.mipmap_count / 4).max(1).min(vtf.header.mipmap_count.saturating_sub(1))
        };
        
        match vtf.decode(mipmap_level, 0) {
            Ok(decoded) => {
                if decoded.save(thumbnail_path.to_str().unwrap_or("")).is_ok() {
                    QString::from(format!("file://{}", thumbnail_path.to_string_lossy()).as_str())
                } else {
                    QString::default()
                }
            }
            Err(_) => QString::default(),
        }
    }

    // Get the raw RGBA data as a byte array
    fn get_rgba_data(&self) -> QByteArray {
        self.current_decoded
            .as_ref()
            .map(|frame| {
                let mut arr = QByteArray::default();
                for byte in &frame.data {
                    arr.append(*byte);
                }
                arr
            })
            .unwrap_or_default()
    }

    // Get RGBA data for a specific mipmap level
    fn get_mipmap_data(mut self: Pin<&mut Self>, level: i32) -> QByteArray {
        if level < 0 || level >= self.mipmap_count {
            return QByteArray::default();
        }

        if level as i32 != self.current_mipmap {
            self.as_mut().set_current_mipmap(level);
            self.as_mut().decode_current_frame();
            self.as_mut().mipmap_changed();
        }

        self.get_rgba_data()
    }

    // Set the current frame
    fn set_frame(mut self: Pin<&mut Self>, frame: i32) {
        if frame < 0 || frame >= self.frame_count {
            return;
        }

        self.as_mut().set_current_frame(frame);
        self.as_mut().decode_current_frame();
        self.as_mut().frame_changed();
    }

    // Set the current mipmap level
    fn set_mipmap(mut self: Pin<&mut Self>, level: i32) {
        if level < 0 || level >= self.mipmap_count {
            return;
        }

        self.as_mut().set_current_mipmap(level);
        self.as_mut().decode_current_frame();
        self.as_mut().mipmap_changed();
    }

    // Save the current frame as an image file
    fn save_as_image(&self, path: &QString) -> bool {
        self.current_decoded
            .as_ref()
            .map(|frame| frame.save(&path.to_string()).is_ok())
            .unwrap_or(false)
    }

    // Clear the loaded texture
    fn clear(mut self: Pin<&mut Self>) {
        self.as_mut().rust_mut().vtf_image = None;
        self.as_mut().rust_mut().current_decoded = None;
        self.as_mut().set_current_texture(QString::default());
        self.as_mut().set_texture_width(0);
        self.as_mut().set_texture_height(0);
        self.as_mut().set_frame_count(0);
        self.as_mut().set_current_frame(0);
        self.as_mut().set_mipmap_count(0);
        self.as_mut().set_current_mipmap(0);
        self.as_mut().set_has_alpha(false);
        self.as_mut().set_is_animated(false);
        self.as_mut().set_format_name(QString::default());
        self.as_mut().set_error_message(QString::default());
        self.as_mut().set_is_loaded(false);
    }

    // Get texture info as formatted string
    fn get_texture_info(&self) -> QString {
        if let Some(ref vtf) = self.vtf_image {
            let info = format!(
                "Size: {}x{}\nFormat: {:?}\nMipmaps: {}\nFrames: {}\nVersion: {}\nHas Alpha: {}",
                vtf.header.width,
                vtf.header.height,
                vtf.header.high_res_format,
                vtf.header.mipmap_count,
                vtf.header.frames,
                vtf.header.version,
                vtf.has_alpha()
            );
            QString::from(info.as_str())
        } else {
            QString::from("No texture loaded")
        }
    }

    // Update properties from a VTF image
    fn update_from_vtf(mut self: Pin<&mut Self>, vtf: &VtfImage) {
        self.as_mut().set_texture_width(vtf.header.width as i32);
        self.as_mut().set_texture_height(vtf.header.height as i32);
        self.as_mut().set_frame_count(vtf.header.frames as i32);
        self.as_mut()
            .set_current_frame(vtf.header.first_frame as i32);
        self.as_mut()
            .set_mipmap_count(vtf.header.mipmap_count as i32);
        self.as_mut().set_current_mipmap(0);
        self.as_mut().set_has_alpha(vtf.has_alpha());
        self.as_mut().set_is_animated(vtf.is_animated());
        self.as_mut().set_format_name(QString::from(
            format!("{:?}", vtf.header.high_res_format).as_str(),
        ));
        self.as_mut().set_is_loaded(true);
        self.as_mut().set_error_message(QString::default());
    }

    // Decode the current frame
    fn decode_current_frame(mut self: Pin<&mut Self>) {
        let frame = self.current_frame as u16;
        let mipmap = self.current_mipmap as u8;

        if let Some(ref vtf) = self.vtf_image {
            match vtf.decode(mipmap, frame) {
                Ok(decoded) => {
                    // Update dimensions for current mipmap
                    self.as_mut().set_texture_width(decoded.width as i32);
                    self.as_mut().set_texture_height(decoded.height as i32);
                    self.as_mut().rust_mut().current_decoded = Some(decoded);
                }
                Err(e) => {
                    let msg = QString::from(format!("Failed to decode frame: {}", e).as_str());
                    self.as_mut().set_error_message(msg.clone());
                    self.as_mut().error_occurred(msg);
                }
            }
        }
    }

    // Get a temporary file path with the current frame saved as PNG
    fn get_preview_path(mut self: Pin<&mut Self>) -> QString {
        // Make sure we have a decoded frame
        if self.current_decoded.is_none() && self.vtf_image.is_some() {
            self.as_mut().decode_current_frame();
        }

        if self.current_decoded.is_none() {
            return QString::default();
        }

        // At this point we have a decoded frame
        let decoded = self.current_decoded.as_ref().unwrap();
            // Create temp file path with frame/mipmap in name for cache invalidation
            let frame = self.current_frame;
            // Use a slightly higher (smaller) mipmap for previews when possible.
            // Keep provider state untouched: decode & save from the desired mipmap
            // Use 1/4 of the way for good quality previews
            let mipmap: i32 = if self.current_mipmap == 0 {
                // If we have > 3 mipmaps, use mipmap 1 for preview (still high quality)
                let mut prefer = 0i32;
                if let Some(ref vtf) = self.vtf_image {
                    if vtf.header.mipmap_count > 3 { prefer = 1; }
                }
                prefer
            } else { self.current_mipmap };
            let temp_dir = std::env::temp_dir();
            let preview_path = temp_dir.join(format!("VFileX_preview_{}_{}.png", frame, mipmap));

                // If the decoded frame matches our desired mipmap, save that; otherwise decode new one
                if decoded.mipmap_level as i32 == mipmap as i32 {
                    match decoded.save(preview_path.to_str().unwrap_or("")) {
                        Ok(_) => {
                            self.as_mut().rust_mut().preview_path = Some(preview_path.clone());
                            // Return just the path - QML Image will handle it
                            return QString::from(preview_path.to_str().unwrap_or(""));
                        }
                        Err(e) => {
                            let msg = QString::from(format!("Failed to save preview: {}", e).as_str());
                            self.as_mut().set_error_message(msg);
                            return QString::default();
                        }
                    }
                }

                // Otherwise decode the requested mipmap for preview (without mutating provider state)
                if let Some(ref vtf) = self.vtf_image {
            match vtf.decode(mipmap as u8, frame as u16) {
                        Ok(decoded_preview) => {
                            match decoded_preview.save(preview_path.to_str().unwrap_or("")) {
                                Ok(_) => {
                                    self.as_mut().rust_mut().preview_path = Some(preview_path.clone());
                                    return QString::from(preview_path.to_str().unwrap_or(""));
                                }
                                Err(e) => {
                                    let msg = QString::from(format!("Failed to save preview: {}", e).as_str());
                                    self.as_mut().set_error_message(msg);
                                    return QString::default();
                                }
                            }
                        }
                        Err(e) => {
                            let msg = QString::from(format!("Failed to decode preview mipmap: {}", e).as_str());
                            self.as_mut().set_error_message(msg);
                            return QString::default();
                        }
                    }
                }
        QString::default()
    }
}

// Global texture cache for sharing textures across QML
pub struct TextureCache {
    cache: Mutex<HashMap<String, Arc<VtfImage>>>,
    max_size: usize,
}

impl TextureCache {
    pub fn new(max_size: usize) -> Self {
        Self {
            cache: Mutex::new(HashMap::new()),
            max_size,
        }
    }

    // Get or load a texture
    pub fn get_or_load(&self, path: &str) -> Result<Arc<VtfImage>, crate::vtf::VtfError> {
        let mut cache = self.cache.lock().unwrap();

        if let Some(vtf) = cache.get(path) {
            return Ok(Arc::clone(vtf));
        }

        // Load the texture
        let vtf = VtfDecoder::load_file(path)?;
        let vtf = Arc::new(vtf);

        // Add to cache (simple LRU: just clear if full)
        if cache.len() >= self.max_size {
            cache.clear();
        }

        cache.insert(path.to_string(), Arc::clone(&vtf));
        Ok(vtf)
    }

    // Clear the cache
    pub fn clear(&self) {
        self.cache.lock().unwrap().clear();
    }
}

impl Default for TextureCache {
    fn default() -> Self {
        Self::new(50)
    }
}
