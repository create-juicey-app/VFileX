//! VPK Archive Support for VFileX
//!
//! This module provides functionality to read VTF/VMT files from Valve's VPK archives,
//! enabling support for built-in textures from games like HL2, TF2, Portal, etc.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::RwLock;

use once_cell::sync::Lazy;
use vpk::VPK;

/// Global VPK manager instance
pub static VPK_MANAGER: Lazy<VpkManager> = Lazy::new(VpkManager::new);

/// Logging helper - prints to stderr for debugging
macro_rules! vpk_log {
    ($($arg:tt)*) => {
        eprintln!("[VPK] {}", format!($($arg)*));
    };
}

/// Error type for VPK operations
#[derive(Debug)]
pub enum VpkError {
    NotFound(String),
    IoError(std::io::Error),
    VpkError(String),
}

impl std::fmt::Display for VpkError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            VpkError::NotFound(path) => write!(f, "File not found in VPK: {}", path),
            VpkError::IoError(e) => write!(f, "IO error: {}", e),
            VpkError::VpkError(e) => write!(f, "VPK error: {}", e),
        }
    }
}

impl std::error::Error for VpkError {}

impl From<std::io::Error> for VpkError {
    fn from(e: std::io::Error) -> Self {
        VpkError::IoError(e)
    }
}

/// Cached VPK archive with precomputed lookup index
struct CachedVpk {
    /// The VPK archive handle
    vpk: VPK,
    /// Normalized path index (lowercase paths -> original paths)
    path_index: HashMap<String, String>,
}

/// Manager for VPK archives
/// Handles loading, caching, and file extraction from VPK archives
pub struct VpkManager {
    /// Cached VPK archives by game directory path
    archives: RwLock<HashMap<PathBuf, Vec<CachedVpk>>>,
    /// File data cache (cache_key -> data)
    file_cache: RwLock<HashMap<String, Vec<u8>>>,
    /// Maximum file cache size in bytes (default 256MB)
    max_cache_size: usize,
    /// Current cache size
    cache_size: RwLock<usize>,
}

impl VpkManager {
    /// Create a new VPK manager
    pub fn new() -> Self {
        vpk_log!("Initializing VPK manager (max cache: 256MB)");
        Self {
            archives: RwLock::new(HashMap::new()),
            file_cache: RwLock::new(HashMap::new()),
            max_cache_size: 256 * 1024 * 1024, // 256MB
            cache_size: RwLock::new(0),
        }
    }

    /// Load all VPK archives for a game directory
    /// 
    /// # Arguments
    /// * `game_dir` - Path to the game directory (e.g., "Half-Life 2/hl2")
    pub fn load_game_vpks(&self, game_dir: &Path) -> Result<usize, VpkError> {
        vpk_log!("Loading VPKs from: {}", game_dir.display());
        
        // Check if already loaded
        {
            let archives = self.archives.read().unwrap();
            if archives.contains_key(game_dir) {
                let count = archives.get(game_dir).map(|v| v.len()).unwrap_or(0);
                vpk_log!("  Already loaded {} VPK(s) for this directory (cached)", count);
                return Ok(count);
            }
        }

        let mut loaded_vpks: Vec<CachedVpk> = Vec::new();

        // Find all *_dir.vpk files in the game directory
        vpk_log!("  Scanning for *_dir.vpk files...");
        if let Ok(entries) = std::fs::read_dir(game_dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if let Some(filename) = path.file_name().and_then(|s| s.to_str()) {
                    // We're looking for *_dir.vpk files (the directory/index files)
                    if filename.ends_with("_dir.vpk") {
                        vpk_log!("  Found VPK: {}", filename);
                        match self.load_single_vpk(&path) {
                            Ok(cached) => {
                                vpk_log!("    ✓ Loaded {} files from {}", cached.path_index.len(), filename);
                                loaded_vpks.push(cached);
                            }
                            Err(e) => {
                                vpk_log!("    ✗ Failed to load {}: {}", filename, e);
                            }
                        }
                    }
                }
            }
        } else {
            vpk_log!("  ✗ Could not read directory: {}", game_dir.display());
        }

        let count = loaded_vpks.len();
        let total_files: usize = loaded_vpks.iter().map(|v| v.path_index.len()).sum();
        vpk_log!("  Loaded {} VPK archive(s) with {} total files", count, total_files);
        
        // Store in cache
        {
            let mut archives = self.archives.write().unwrap();
            archives.insert(game_dir.to_path_buf(), loaded_vpks);
        }

        // Debug: print sample paths (only if VPK_DEBUG env is set)
        if std::env::var("VPK_DEBUG").is_ok() {
            self.debug_print_sample_paths(game_dir);
        }

        Ok(count)
    }

    /// Load a single VPK archive
    fn load_single_vpk(&self, vpk_path: &Path) -> Result<CachedVpk, VpkError> {
        let vpk = vpk::from_path(vpk_path)
            .map_err(|e| VpkError::VpkError(format!("{}", e)))?;

        // Build a normalized path index for case-insensitive lookups
        let mut path_index = HashMap::new();
        
        for original_path in vpk.tree.keys() {
            let normalized = original_path.to_lowercase().replace('\\', "/");
            path_index.insert(normalized, original_path.clone());
        }

        Ok(CachedVpk {
            vpk,
            path_index,
        })
    }

    /// Read a file from VPK archives for a given game directory
    /// 
    /// # Arguments
    /// * `game_dir` - The game directory path
    /// * `file_path` - The relative file path within the VPK (e.g., "materials/brick/brickfloor001a.vtf")
    pub fn read_file(&self, game_dir: &Path, file_path: &str) -> Result<Vec<u8>, VpkError> {
        // Normalize the path
        let normalized_path = file_path.to_lowercase().replace('\\', "/");
        vpk_log!("Reading file: {} (normalized: {})", file_path, normalized_path);
        
        // Check file cache first
        let cache_key = format!("{}:{}", game_dir.display(), normalized_path);
        {
            let cache = self.file_cache.read().unwrap();
            if let Some(data) = cache.get(&cache_key) {
                vpk_log!("  ✓ Cache HIT - {} bytes from memory cache", data.len());
                return Ok(data.clone());
            }
        }
        vpk_log!("  Cache MISS - searching VPK archives...");

        // Load VPKs for this game directory if not already loaded
        self.load_game_vpks(game_dir)?;

        // Search through all VPKs for this game
        let archives = self.archives.read().unwrap();
        
        if let Some(vpks) = archives.get(game_dir) {
            vpk_log!("  Searching {} VPK archive(s) for: '{}'", vpks.len(), normalized_path);
            for (idx, cached_vpk) in vpks.iter().enumerate() {
                // Look up the normalized path in our index
                if let Some(original_path) = cached_vpk.path_index.get(&normalized_path) {
                    vpk_log!("  ✓ Found in VPK #{}: {}", idx, original_path);
                    // Get the entry from the VPK tree
                    if let Some(entry) = cached_vpk.vpk.tree.get(original_path) {
                        // Read the file data using the entry's get() method
                        match entry.get() {
                            Ok(data) => {
                                let data_vec = data.to_vec();
                                vpk_log!("  ✓ Extracted {} bytes", data_vec.len());
                                // Cache the result
                                self.cache_file(&cache_key, &data_vec);
                                return Ok(data_vec);
                            }
                            Err(e) => {
                                vpk_log!("  ✗ Failed to read from VPK: {}", e);
                                return Err(VpkError::IoError(e));
                            }
                        }
                    }
                }
            }
        } else {
            vpk_log!("  ✗ No VPKs found for this game directory!");
        }

        vpk_log!("  ✗ File not found in any VPK archive");
        Err(VpkError::NotFound(file_path.to_string()))
    }

    /// Check if a file exists in any VPK for the given game directory
    pub fn file_exists(&self, game_dir: &Path, file_path: &str) -> bool {
        let normalized_path = file_path.to_lowercase().replace('\\', "/");
        
        // Load VPKs if not loaded
        let _ = self.load_game_vpks(game_dir);
        
        let archives = self.archives.read().unwrap();
        if let Some(vpks) = archives.get(game_dir) {
            for cached_vpk in vpks {
                if cached_vpk.path_index.contains_key(&normalized_path) {
                    return true;
                }
            }
        }
        
        false
    }

    /// List all files matching a pattern in VPKs for a game directory
    pub fn list_files(&self, game_dir: &Path, extension: Option<&str>) -> Vec<String> {
        let _ = self.load_game_vpks(game_dir);
        
        let mut files = Vec::new();
        let archives = self.archives.read().unwrap();
        
        if let Some(vpks) = archives.get(game_dir) {
            for cached_vpk in vpks {
                for original_path in cached_vpk.vpk.tree.keys() {
                    if let Some(ext) = extension {
                        let lower = original_path.to_lowercase();
                        if lower.ends_with(&format!(".{}", ext.to_lowercase())) {
                            files.push(original_path.clone());
                        }
                    } else {
                        files.push(original_path.clone());
                    }
                }
            }
        }
        
        files.sort();
        files.dedup();
        files
    }

    /// Debug: Print sample paths from loaded VPKs to understand path format
    pub fn debug_print_sample_paths(&self, game_dir: &Path) {
        vpk_log!("=== DEBUG: Sample VPK paths ===");
        let archives = self.archives.read().unwrap();
        
        if let Some(vpks) = archives.get(game_dir) {
            for (vpk_idx, cached_vpk) in vpks.iter().enumerate() {
                vpk_log!("VPK #{}: {} entries", vpk_idx, cached_vpk.path_index.len());
                
                // Print first 10 paths containing "vtf" 
                let mut vtf_count = 0;
                for (normalized, original) in &cached_vpk.path_index {
                    if normalized.ends_with(".vtf") {
                        vpk_log!("  VTF Path: '{}' -> '{}'", normalized, original);
                        vtf_count += 1;
                        if vtf_count >= 10 {
                            break;
                        }
                    }
                }
                
                // Print first 10 paths containing "brick"
                let mut brick_count = 0;
                for (normalized, original) in &cached_vpk.path_index {
                    if normalized.contains("brick") {
                        vpk_log!("  Brick Path: '{}' -> '{}'", normalized, original);
                        brick_count += 1;
                        if brick_count >= 10 {
                            break;
                        }
                    }
                }
                
                // If no vtf/brick, print first 10 paths anyway
                if vtf_count == 0 && brick_count == 0 {
                    vpk_log!("  (no vtf/brick paths, showing first 10 of any type):");
                    for (i, (normalized, original)) in cached_vpk.path_index.iter().enumerate() {
                        if i >= 10 { break; }
                        vpk_log!("  Path: '{}' -> '{}'", normalized, original);
                    }
                }
            }
        } else {
            vpk_log!("No VPKs loaded for: {}", game_dir.display());
        }
        vpk_log!("=== END DEBUG ===");
    }

    /// Get all loaded game directories
    pub fn loaded_games(&self) -> Vec<PathBuf> {
        let archives = self.archives.read().unwrap();
        archives.keys().cloned().collect()
    }

    /// Clear VPK cache for a specific game
    pub fn clear_game_cache(&self, game_dir: &Path) {
        let mut archives = self.archives.write().unwrap();
        archives.remove(game_dir);
        
        // Also clear file cache entries for this game
        let prefix = format!("{}:", game_dir.display());
        let mut file_cache = self.file_cache.write().unwrap();
        let mut cache_size = self.cache_size.write().unwrap();
        
        let keys_to_remove: Vec<_> = file_cache.keys()
            .filter(|k| k.starts_with(&prefix))
            .cloned()
            .collect();
        
        for key in keys_to_remove {
            if let Some(data) = file_cache.remove(&key) {
                *cache_size = cache_size.saturating_sub(data.len());
            }
        }
    }

    /// Clear all caches
    pub fn clear_all_caches(&self) {
        let mut archives = self.archives.write().unwrap();
        archives.clear();
        
        let mut file_cache = self.file_cache.write().unwrap();
        file_cache.clear();
        
        let mut cache_size = self.cache_size.write().unwrap();
        *cache_size = 0;
    }

    /// Cache a file's data
    fn cache_file(&self, key: &str, data: &[u8]) {
        let mut file_cache = self.file_cache.write().unwrap();
        let mut cache_size = self.cache_size.write().unwrap();
        
        // Check if we need to evict entries
        while *cache_size + data.len() > self.max_cache_size && !file_cache.is_empty() {
            // Simple eviction: remove first entry (not LRU, but simple)
            if let Some(key) = file_cache.keys().next().cloned() {
                if let Some(removed) = file_cache.remove(&key) {
                    *cache_size = cache_size.saturating_sub(removed.len());
                }
            }
        }
        
        *cache_size += data.len();
        file_cache.insert(key.to_string(), data.to_vec());
    }
}

impl Default for VpkManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Helper function to find VPK files in a game directory
pub fn find_vpk_files(game_dir: &Path) -> Vec<PathBuf> {
    let mut vpk_files = Vec::new();
    
    if let Ok(entries) = std::fs::read_dir(game_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                if name.ends_with("_dir.vpk") {
                    vpk_files.push(path);
                }
            }
        }
    }
    
    vpk_files
}

/// Get the number of VPK archives found in a game directory
pub fn count_vpk_archives(game_dir: &Path) -> usize {
    find_vpk_files(game_dir).len()
}

/// Quick test function to verify VPK loading works
pub fn test_vpk_loading(game_dir: &Path, test_path: &str) -> Result<usize, String> {
    vpk_log!("=== TEST: Verifying VPK loading ===");
    vpk_log!("Game dir: {}", game_dir.display());
    vpk_log!("Test path: {}", test_path);
    
    // Load VPKs
    if let Err(e) = VPK_MANAGER.load_game_vpks(game_dir) {
        return Err(format!("Failed to load VPKs: {}", e));
    }
    
    // Try reading the file
    match VPK_MANAGER.read_file(game_dir, test_path) {
        Ok(data) => {
            vpk_log!("=== TEST SUCCESS: Read {} bytes ===", data.len());
            Ok(data.len())
        }
        Err(e) => {
            vpk_log!("=== TEST FAILED: {} ===", e);
            Err(format!("Failed to read: {}", e))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vpk_manager_creation() {
        let manager = VpkManager::new();
        assert!(manager.loaded_games().is_empty());
    }
}
