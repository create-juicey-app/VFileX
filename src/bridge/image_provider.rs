//! Texture Image Provider for QML
//!
//! Todo: idk

use cxx_qt::CxxQtType;
use std::collections::HashMap;
use std::path::PathBuf;
use std::pin::Pin;
use std::sync::{Arc, Mutex};

use crate::vtf::{DecodedFrame, VtfDecoder, VtfImage};

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

        // Construct the full path
        // VMT paths are relative to the materials folder and don't include extension
        let mut full_path = PathBuf::from(&materials_root_str);
        full_path.push(&texture_path_str);
        full_path.set_extension("vtf");

        // Try loading
        if full_path.exists() {
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

            if alt_path.exists() {
                let path = QString::from(alt_path.to_string_lossy().as_ref());
                return self.load_texture(&path);
            }
        }

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
        let thumbnail_path = temp_dir.join(format!("supervtf_thumb_{}.png", cache_key));

        // Return cached thumbnail if it exists (fast path - no I/O except stat)
        if thumbnail_path.exists() {
            return QString::from(format!("file://{}", thumbnail_path.to_string_lossy()).as_str());
        }

        // Try to find and load the texture
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

        if !full_path.exists() {
            return QString::default();
        }

        // Load the VTF and generate thumbnail
        match VtfDecoder::load_file(full_path.to_string_lossy().as_ref()) {
            Ok(vtf) => {
                // Use a small mipmap for fast thumbnail generation
                // Higher mipmap number = smaller image = faster decode
                // Use about halfway through the mipmap chain for small but recognizable thumbnails
                let mipmap_level = if vtf.header.mipmap_count <= 2 {
                    0
                } else {
                    // Use about halfway - gives ~64x64 or ~128x128 for most textures
                    vtf.header.mipmap_count / 2
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

        if let Some(ref decoded) = self.current_decoded {
            // Create temp file path with frame/mipmap in name for cache invalidation
            let frame = self.current_frame;
            let mipmap = self.current_mipmap;
            let temp_dir = std::env::temp_dir();
            let preview_path = temp_dir.join(format!("supervtf_preview_{}_{}.png", frame, mipmap));

            // Save the decoded frame to the temp file
            match decoded.save(preview_path.to_str().unwrap_or("")) {
                Ok(_) => {
                    self.as_mut().rust_mut().preview_path = Some(preview_path.clone());
                    // Return just the path - QML Image will handle it
                    QString::from(preview_path.to_str().unwrap_or(""))
                }
                Err(e) => {
                    let msg = QString::from(format!("Failed to save preview: {}", e).as_str());
                    self.as_mut().set_error_message(msg);
                    QString::default()
                }
            }
        } else {
            QString::default()
        }
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
