//! Application controller for VFileX (the brains of the operation, such as they are)

use std::path::PathBuf;
use std::pin::Pin;

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;

        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;

        include!("cxx-qt-lib/qurl.h");
        type QUrl = cxx_qt_lib::QUrl;
    }

    // Application settings
    #[derive(Default, Clone)]
    pub struct AppSettings {
        // Root path for game materials
        pub materials_root: QString,
        // Recent files list
        pub recent_files: QStringList,
        // Theme (dark/light)
        pub theme: QString,
        // Auto-save enabled
        pub auto_save: bool,
        // Preview background color
        pub preview_background: QString,
    }

    unsafe extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, app_name)]
        #[qproperty(QString, app_version)]
        #[qproperty(QString, materials_root)]
        #[qproperty(QStringList, recent_files)]
        #[qproperty(QString, theme)]
        #[qproperty(bool, auto_save)]
        #[qproperty(bool, is_first_run)]
        #[qproperty(QString, selected_game)]
        type VFileXApp = super::VFileXAppRust;
    }

    unsafe extern "RustQt" {
        // Initialize the application
        #[qinvokable]
        fn initialize(self: Pin<&mut VFileXApp>);

        // Set the materials root directory
        #[qinvokable]
        fn set_materials_root_path(self: Pin<&mut VFileXApp>, path: &QString);

        // Add a file to recent files
        #[qinvokable]
        fn add_recent_file(self: Pin<&mut VFileXApp>, path: &QString);

        // Clear recent files
        #[qinvokable]
        fn clear_recent_files(self: Pin<&mut VFileXApp>);

        // Get file dialog filter for VMT files
        #[qinvokable]
        fn get_vmt_filter(self: &VFileXApp) -> QString;

        // Get file dialog filter for VTF files
        #[qinvokable]
        fn get_vtf_filter(self: &VFileXApp) -> QString;

        // Get file dialog filter for image files
        #[qinvokable]
        fn get_image_filter(self: &VFileXApp) -> QString;

        // Browse for materials directory
        #[qinvokable]
        fn browse_materials_directory(self: &VFileXApp) -> QString;

        // Get default materials root path
        #[qinvokable]
        fn get_default_materials_root(self: &VFileXApp) -> QString;

        // Convert an image file to VTF
        #[qinvokable]
        fn convert_to_vtf(self: &VFileXApp, source: &QString, dest: &QString) -> bool;

        // Export a VTF to an image format
        #[qinvokable]
        fn export_vtf_to_image(self: &VFileXApp, source: &QString, dest: &QString) -> bool;

        // Open a path in the system file browser
        #[qinvokable]
        fn reveal_in_explorer(self: &VFileXApp, path: &QString);

        // Save application settings
        #[qinvokable]
        fn save_settings(self: &VFileXApp);

        // Load application settings
        #[qinvokable]
        fn load_settings(self: Pin<&mut VFileXApp>);

        // Set theme
        #[qinvokable]
        fn set_app_theme(self: Pin<&mut VFileXApp>, theme: &QString);

        // Get supported shader list
        #[qinvokable]
        fn get_supported_shaders(self: &VFileXApp) -> QStringList;

        // Detect game installation paths
        #[qinvokable]
        fn detect_game_paths(self: &VFileXApp) -> QStringList;

        // Get list of detected games (returns "GameName|path" pairs)
        #[qinvokable]
        fn get_detected_games(self: &VFileXApp) -> QStringList;

        // Set the selected game by name
        #[qinvokable]
        fn select_game(self: Pin<&mut VFileXApp>, game_name: &QString);

        // Mark first run as complete
        #[qinvokable]
        fn complete_first_run(self: Pin<&mut VFileXApp>);

        // Get VPK archive count for the current game
        #[qinvokable]
        fn get_vpk_count(self: &VFileXApp) -> i32;

        // Load VPK archives for the current game (returns count of loaded archives)
        #[qinvokable]
        fn load_game_vpks(self: &VFileXApp) -> i32;

        // Start async VPK loading for a game (non-blocking)
        #[qinvokable]
        fn start_async_vpk_load(self: Pin<&mut VFileXApp>, game_path: &QString);

        // List materials available in VPK archives (returns paths like "brick/brickfloor001a")
        #[qinvokable]
        fn list_vpk_materials(self: &VFileXApp, filter: &QString) -> QStringList;

        // Check if a texture exists (on disk or in VPK)
        #[qinvokable]
        fn texture_exists(self: &VFileXApp, texture_path: &QString) -> bool;

        // Get autocomplete suggestions for a texture path
        // Returns a list of suggestions that start with the given prefix
        #[qinvokable]
        fn get_texture_completions(self: &VFileXApp, prefix: &QString, max_results: i32) -> QStringList;

        // Get the "ghost" completion for a texture path (single best match)
        // Returns the remaining text to complete the path, or empty if no match
        #[qinvokable]
        fn get_texture_ghost(self: &VFileXApp, prefix: &QString) -> QString;

        // Test VPK loading with a known HL2 texture
        // Returns: "OK: <bytes>" on success, "ERR: <message>" on failure
        #[qinvokable]
        fn test_vpk_texture(self: &VFileXApp, texture_path: &QString) -> QString;

        // Get list of custom textures (loose .vtf files on disk, not in VPK)
        // Returns a list of texture paths relative to materials folder
        #[qinvokable]
        fn get_custom_textures(self: &VFileXApp, max_results: i32) -> QStringList;
    }

    // Signals
    unsafe extern "RustQt" {
        // Emitted when settings change
        #[qsignal]
        fn settings_changed(self: Pin<&mut VFileXApp>);

        // Emitted on status message
        #[qsignal]
        fn status_message(self: Pin<&mut VFileXApp>, message: QString);

        // Emitted when VPK loading starts
        #[qsignal]
        fn vpk_loading_started(self: Pin<&mut VFileXApp>);

        // Emitted when VPK loading completes
        #[qsignal]
        fn vpk_loading_finished(self: Pin<&mut VFileXApp>, count: i32);

        // Emitted during VPK loading progress
        #[qsignal]
        fn vpk_loading_progress(self: Pin<&mut VFileXApp>, message: QString);
    }
}

use crate::schema::ShaderRegistry;
use crate::vpk_archive::{count_vpk_archives, VPK_MANAGER};
use crate::vtf::{VtfBuilder, VtfDecoder};
use qobject::*;

const APP_NAME: &str = "VFileX";
const APP_VERSION: &str = env!("CARGO_PKG_VERSION");
const MAX_RECENT_FILES: usize = 10;

// Rust implementation
pub struct VFileXAppRust {
    shader_registry: ShaderRegistry,
    settings_path: PathBuf,

    // Q_PROPERTY backing fields
    app_name: QString,
    app_version: QString,
    materials_root: QString,
    recent_files: QStringList,
    theme: QString,
    auto_save: bool,
    is_first_run: bool,
    selected_game: QString,
}

impl Default for VFileXAppRust {
    fn default() -> Self {
        let settings_path = dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("VFileX")
            .join("settings.toml");

        // First run if settings file doesn't exist
        let is_first_run = !settings_path.exists();

        Self {
            shader_registry: ShaderRegistry::with_builtin_shaders(),
            settings_path,
            app_name: QString::from(APP_NAME),
            app_version: QString::from(APP_VERSION),
            materials_root: QString::default(),
            recent_files: QStringList::default(),
            theme: QString::from("dark"),
            auto_save: false,
            is_first_run,
            selected_game: QString::default(),
        }
    }
}

impl qobject::VFileXApp {
    // Start the engines
    fn initialize(mut self: Pin<&mut Self>) {
        // Load settings
        self.as_mut().load_settings();

        // Don't auto-detect on first run - let the welcome dialog handle it
        if !self.is_first_run && self.materials_root.is_empty() {
            let paths = self.detect_game_paths();
            let qlist_paths: cxx_qt_lib::QList<cxx_qt_lib::QString> = (&paths).into();
            if qlist_paths.len() > 0 {
                // Use first detected path
                if let Some(first) = qlist_paths.get(0) {
                    self.as_mut().set_materials_root(first.clone());
                }
            }
        }

        self.as_mut()
            .status_message(QString::from("VFileX initialized"));
    }

    // Set the materials root directory
    fn set_materials_root_path(mut self: Pin<&mut Self>, path: &QString) {
        self.as_mut().set_materials_root(path.clone());
        self.as_mut().settings_changed();
    }

    // Add a file to recent files
    fn add_recent_file(mut self: Pin<&mut Self>, path: &QString) {
        let path_str = path.to_string();

        // Get current list and rebuild
        let mut files: Vec<String> = Vec::new();
        files.push(path_str.clone());

        // Limit size
        files.truncate(MAX_RECENT_FILES);

        // Rebuild QStringList
        let strings: Vec<cxx_qt_lib::QString> =
            files.iter().map(|f| QString::from(f.as_str())).collect();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = strings.into();
        let new_list = QStringList::from(&qlist);

        self.as_mut().set_recent_files(new_list);
    }

    // Clear recent files
    fn clear_recent_files(mut self: Pin<&mut Self>) {
        self.as_mut().set_recent_files(QStringList::default());
    }

    // Get file dialog filter for VMT files
    fn get_vmt_filter(&self) -> QString {
        QString::from("Valve Material Files (*.vmt);;All Files (*)")
    }

    // Get file dialog filter for VTF files
    fn get_vtf_filter(&self) -> QString {
        QString::from("Valve Texture Files (*.vtf);;All Files (*)")
    }

    // Get file dialog filter for image files
    fn get_image_filter(&self) -> QString {
        QString::from("Image Files (*.png *.jpg *.jpeg *.tga *.bmp);;PNG Files (*.png);;JPEG Files (*.jpg *.jpeg);;TGA Files (*.tga);;All Files (*)")
    }

    // Browse for materials directory
    fn browse_materials_directory(&self) -> QString {
        // This would typically open a directory picker
        // The actual implementation depends on Qt file dialog integration
        QString::default()
    }

    // Get default materials root path
    fn get_default_materials_root(&self) -> QString {
        // Use dynamic Steam library detection
        let steam_paths = get_steam_library_paths();

        for path in steam_paths {
            if path.exists() {
                return QString::from(path.to_string_lossy().as_ref());
            }
        }

        QString::default()
    }

    // Convert an image file to VTF
    fn convert_to_vtf(&self, source: &QString, dest: &QString) -> bool {
        let source_str = source.to_string();
        let dest_str = dest.to_string();

        match VtfBuilder::from_image_file(&source_str) {
            Ok(builder) => builder.save(&dest_str).is_ok(),
            Err(_) => false,
        }
    }

    // Export a VTF to an image format
    fn export_vtf_to_image(&self, source: &QString, dest: &QString) -> bool {
        let source_str = source.to_string();
        let dest_str = dest.to_string();

        match VtfDecoder::load_file(&source_str) {
            Ok(vtf) => match vtf.decode_main() {
                Ok(frame) => frame.save(&dest_str).is_ok(),
                Err(_) => false,
            },
            Err(_) => false,
        }
    }

    // Open a path in the system file browser
    fn reveal_in_explorer(&self, path: &QString) {
        let path_str = path.to_string();

        #[cfg(target_os = "windows")]
        {
            let _ = std::process::Command::new("explorer")
                .arg("/select,")
                .arg(&path_str)
                .spawn();
        }

        #[cfg(target_os = "macos")]
        {
            let _ = std::process::Command::new("open")
                .arg("-R")
                .arg(&path_str)
                .spawn();
        }

        #[cfg(target_os = "linux")]
        {
            // Try different file managers
            let parent = std::path::Path::new(&path_str)
                .parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or(path_str);

            let _ = std::process::Command::new("xdg-open").arg(&parent).spawn();
        }
    }

    // Save application settings
    fn save_settings(&self) {
        // Create settings directory if needed
        if let Some(parent) = self.settings_path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        // ough
        let settings = format!(
            r#"# VFileX Settings
materials_root = "{}"
selected_game = "{}"
theme = "{}"
auto_save = {}
"#,
            self.materials_root
                .to_string()
                .replace('\\', "\\\\")
                .replace('"', "\\\""),
            self.selected_game
                .to_string()
                .replace('\\', "\\\\")
                .replace('"', "\\\""),
            self.theme.to_string(),
            self.auto_save,
        );

        let _ = std::fs::write(&self.settings_path, settings);
    }

    // Load application settings
    fn load_settings(mut self: Pin<&mut Self>) {
        if let Ok(content) = std::fs::read_to_string(&self.settings_path) {
            // Settings file exists, not first run
            self.as_mut().set_is_first_run(false);
            
            // Simple TOML parsing for our known keys
            for line in content.lines() {
                let line = line.trim();
                if line.starts_with("materials_root") {
                    if let Some(value) = extract_toml_string(line) {
                        self.as_mut()
                            .set_materials_root(QString::from(value.as_str()));
                    }
                } else if line.starts_with("selected_game") {
                    if let Some(value) = extract_toml_string(line) {
                        self.as_mut()
                            .set_selected_game(QString::from(value.as_str()));
                    }
                } else if line.starts_with("theme") {
                    if let Some(value) = extract_toml_string(line) {
                        self.as_mut().set_theme(QString::from(value.as_str()));
                    }
                } else if line.starts_with("auto_save") {
                    if let Some(value) = extract_toml_bool(line) {
                        self.as_mut().set_auto_save(value);
                    }
                }
            }
        }
    }

    // dark theme :3
    fn set_app_theme(mut self: Pin<&mut Self>, theme: &QString) {
        self.as_mut().set_theme(theme.clone());
        self.as_mut().settings_changed();
    }

    // Get supported shader list
    fn get_supported_shaders(&self) -> QStringList {
        let names: Vec<cxx_qt_lib::QString> = self
            .shader_registry
            .shader_names()
            .into_iter()
            .map(|name| QString::from(name))
            .collect();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = names.into();
        QStringList::from(&qlist)
    }

    // outdated
    fn detect_game_paths(&self) -> QStringList {
        let mut path_strings: Vec<cxx_qt_lib::QString> = Vec::new();

        // Honestly, i had no other ideas how to detect installed games from steam
        // so here's a very naive implementation that just checks common paths
        // for known games and adds their material directories
        // i mean it works sooooooooooooooooooooooooooooooooo
        let games = [
            "Half-Life 2/hl2/materials",
            "Counter-Strike Global Offensive/csgo/materials",
            "Counter-Strike Source/cstrike/materials",
            "Team Fortress 2/tf/materials",
            "Portal/portal/materials",
            "Portal 2/portal2/materials",
            "Left 4 Dead 2/left4dead2/materials",
            "GarrysMod/garrysmod/materials",
        ];

        // Use the dynamic Steam library detection
        let steam_paths = get_steam_library_paths();

        for steam_path in steam_paths {
            if steam_path.exists() {
                for game in &games {
                    let game_path = steam_path.join(game);
                    if game_path.exists() {
                        path_strings.push(QString::from(game_path.to_string_lossy().as_ref()));
                    }
                }
            }
        }

        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = path_strings.into();
        QStringList::from(&qlist)
    }

    // Get detected games with names (returns "GameName|path|iconPath" triplets)
    fn get_detected_games(&self) -> QStringList {
        use std::collections::HashSet;
        let mut found_games: HashSet<String> = HashSet::new();
        let mut game_strings: Vec<cxx_qt_lib::QString> = Vec::new();

        // Game name -> (game folder to check exists, path to materials or game folder, resource folder)
        // For games using VPK archives, we point to the game folder itself since materials aren't extracted
        let games = [
            // Games with materials folders
            ("Portal 2", "Portal 2/portal2", "Portal 2/portal2/materials", "Portal 2/portal2/resource"),
            ("Left 4 Dead 2", "Left 4 Dead 2/left4dead2", "Left 4 Dead 2/left4dead2/materials", "Left 4 Dead 2/left4dead2/resource"),
            ("Counter-Strike 2", "Counter-Strike Global Offensive/game/csgo", "Counter-Strike Global Offensive/game/csgo/materials", "Counter-Strike Global Offensive/game/csgo/resource"),
            ("Black Mesa", "Black Mesa/bms", "Black Mesa/bms/materials", "Black Mesa/bms/resource"),
            
            // Games with VPK-only content (materials folder might not exist, check game folder)
            ("Half-Life 2", "Half-Life 2/hl2", "Half-Life 2/hl2", "Half-Life 2/hl2/resource"),
            ("Half-Life 2: Episode One", "Half-Life 2/episodic", "Half-Life 2/episodic", "Half-Life 2/episodic/resource"),
            ("Half-Life 2: Episode Two", "Half-Life 2/ep2", "Half-Life 2/ep2", "Half-Life 2/ep2/resource"),
            ("Portal", "Portal/portal", "Portal/portal", "Portal/portal/resource"),
            ("Team Fortress 2", "Team Fortress 2/tf", "Team Fortress 2/tf", "Team Fortress 2/tf/resource"),
            ("Counter-Strike: Source", "Counter-Strike Source/cstrike", "Counter-Strike Source/cstrike", "Counter-Strike Source/cstrike/resource"),
            ("CS:GO (Legacy)", "Counter-Strike Global Offensive/csgo", "Counter-Strike Global Offensive/csgo", "Counter-Strike Global Offensive/csgo/resource"),
            ("Day of Defeat: Source", "Day of Defeat Source/dod", "Day of Defeat Source/dod", "Day of Defeat Source/dod/resource"),
            ("Half-Life: Source", "Half-Life 2/hl1", "Half-Life 2/hl1", "Half-Life 2/hl1/resource"),
            ("Alien Swarm", "Alien Swarm/swarm", "Alien Swarm/swarm", "Alien Swarm/swarm/resource"),
            
            // Garry's Mod - folder name is "GarrysMod" not "Garry's Mod"
            ("Garry's Mod", "GarrysMod/garrysmod", "GarrysMod/garrysmod", "GarrysMod/garrysmod/resource"),
        ];

        // Get all Steam library paths dynamically
        let steam_paths = get_steam_library_paths();

        for steam_path in steam_paths {
            if steam_path.exists() {
                for (name, rel_check, rel_materials, rel_resource) in &games {
                    // Skip if we already found this game
                    if found_games.contains(*name) {
                        continue;
                    }
                    
                    // Check if the game folder exists
                    let check_path = steam_path.join(rel_check);
                    if check_path.exists() {
                        // Mark as found to avoid duplicates
                        found_games.insert(name.to_string());
                        
                        // Use materials path for the entry
                        let materials_path = steam_path.join(rel_materials);
                        
                        // Try to find game icon
                        let resource_path = steam_path.join(rel_resource);
                        let icon_path = find_game_icon(&resource_path);
                        
                        // Format: "Game Name|/full/path/to/materials|/path/to/icon"
                        let entry = format!(
                            "{}|{}|{}", 
                            name, 
                            materials_path.to_string_lossy(),
                            icon_path.unwrap_or_default()
                        );
                        game_strings.push(QString::from(entry.as_str()));
                    }
                }
            }
        }

        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = game_strings.into();
        QStringList::from(&qlist)
    }

    // Select a game and set its materials path
    fn select_game(mut self: Pin<&mut Self>, game_name: &QString) {
        let games = self.get_detected_games();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = (&games).into();
        
        let game_name_str = game_name.to_string();
        
        for i in 0..qlist.len() {
            if let Some(entry) = qlist.get(i) {
                let entry_str = entry.to_string();
                // Format is "name|path|icon" - split into parts
                let parts: Vec<&str> = entry_str.split('|').collect();
                if parts.len() >= 2 && parts[0] == game_name_str {
                    // parts[1] is the materials path
                    let game_path = QString::from(parts[1]);
                    self.as_mut().set_materials_root(game_path.clone());
                    self.as_mut().set_selected_game(game_name.clone());
                    self.as_mut().save_settings();
                    self.as_mut().settings_changed();
                    
                    // Start async VPK loading (signals will be emitted)
                    self.as_mut().start_async_vpk_load(&game_path);
                    return;
                }
            }
        }
    }

    // Mark first run as complete
    fn complete_first_run(mut self: Pin<&mut Self>) {
        self.as_mut().set_is_first_run(false);
        self.as_mut().save_settings();
    }

    // Get VPK archive count for the current game
    fn get_vpk_count(&self) -> i32 {
        let materials_root = self.materials_root.to_string();
        if materials_root.is_empty() {
            return 0;
        }
        count_vpk_archives(std::path::Path::new(&materials_root)) as i32
    }

    // Load VPK archives for the current game
    fn load_game_vpks(&self) -> i32 {
        let materials_root = self.materials_root.to_string();
        if materials_root.is_empty() {
            return 0;
        }
        VPK_MANAGER.load_game_vpks(std::path::Path::new(&materials_root))
            .unwrap_or(0) as i32
    }

    // Start async VPK loading (non-blocking)
    fn start_async_vpk_load(mut self: Pin<&mut Self>, game_path: &QString) {
        let game_path_str = game_path.to_string();
        if game_path_str.is_empty() {
            return;
        }
        
        // Emit loading started signal
        self.as_mut().vpk_loading_started();
        
        // Check if already loaded in cache (fast path)
        {
            let path = std::path::Path::new(&game_path_str);
            if VPK_MANAGER.is_loaded(path) {
                let count = VPK_MANAGER.get_archive_count(path) as i32;
                self.as_mut().vpk_loading_finished(count);
                return;
            }
        }
        
        // For now, just load synchronously but emit progress
        // TODO: In a real async implementation, this would spawn a thread
        // and use Qt's queued connections to emit signals from the thread
        self.as_mut().vpk_loading_progress(QString::from("Loading VPK archives..."));
        
        let count = VPK_MANAGER.load_game_vpks(std::path::Path::new(&game_path_str))
            .unwrap_or(0) as i32;
        
        self.as_mut().vpk_loading_finished(count);
    }

    // List materials available in VPK archives
    fn list_vpk_materials(&self, filter: &QString) -> QStringList {
        let materials_root = self.materials_root.to_string();
        if materials_root.is_empty() {
            return QStringList::default();
        }
        
        let filter_str = filter.to_string().to_lowercase();
        let game_path = std::path::Path::new(&materials_root);
        
        // Get all .vmt files from VPK (materials)
        let files = VPK_MANAGER.list_files(game_path, Some("vmt"));
        
        // Filter and format the results
        let filtered: Vec<cxx_qt_lib::QString> = files
            .into_iter()
            .filter(|f| {
                let lower = f.to_lowercase();
                // Filter by extension and optional search term
                lower.starts_with("materials/") && 
                    (filter_str.is_empty() || lower.contains(&filter_str))
            })
            .map(|f| {
                // Strip "materials/" prefix and ".vmt" suffix for cleaner display
                let clean = f
                    .trim_start_matches("materials/")
                    .trim_end_matches(".vmt");
                QString::from(clean)
            })
            .take(1000) // Limit results to avoid UI freeze
            .collect();
        
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = filtered.into();
        QStringList::from(&qlist)
    }

    // Check if a texture exists (on disk or in VPK)
    fn texture_exists(&self, texture_path: &QString) -> bool {
        let texture_path_str = texture_path.to_string();
        let materials_root = self.materials_root.to_string();
        
        if texture_path_str.is_empty() || materials_root.is_empty() {
            return false;
        }
        
        // Try disk first
        let mut full_path = PathBuf::from(&materials_root);
        full_path.push(&texture_path_str);
        full_path.set_extension("vtf");
        
        if full_path.exists() {
            return true;
        }
        
        // Try with materials/ prefix
        if !texture_path_str.starts_with("materials/") {
            let mut alt_path = PathBuf::from(&materials_root);
            alt_path.push("materials");
            alt_path.push(&texture_path_str);
            alt_path.set_extension("vtf");
            
            if alt_path.exists() {
                return true;
            }
        }
        
        // Check VPK archives
        let vpk_path = if texture_path_str.starts_with("materials/") {
            format!("{}.vtf", texture_path_str.replace('\\', "/"))
        } else {
            format!("materials/{}.vtf", texture_path_str.replace('\\', "/"))
        };
        
        VPK_MANAGER.file_exists(std::path::Path::new(&materials_root), &vpk_path)
    }

    // Get autocomplete suggestions for a texture path
    fn get_texture_completions(&self, prefix: &QString, max_results: i32) -> QStringList {
        let prefix_str = prefix.to_string().to_lowercase();
        let materials_root = self.materials_root.to_string();
        
        if materials_root.is_empty() {
            return QStringList::default();
        }
        
        // Handle unlimited (-1) or convert to usize
        let limit = if max_results < 0 { usize::MAX } else { max_results as usize };
        
        let mut completions: Vec<String> = Vec::new();
        let game_path = std::path::Path::new(&materials_root);
        
        // Search both disk and VPK for matching textures
        // First, search disk (materials folder)
        let disk_materials = PathBuf::from(&materials_root).join("materials");
        if disk_materials.exists() && !prefix_str.is_empty() {
            self.collect_disk_completions(&disk_materials, &prefix_str, &mut completions, limit);
        }
        
        // Also check if materials_root itself is a materials folder
        let direct_search = PathBuf::from(&materials_root);
        if direct_search.exists() && !direct_search.ends_with("materials") && !prefix_str.is_empty() {
            self.collect_disk_completions(&direct_search, &prefix_str, &mut completions, limit);
        }
        
        // Search VPK archives
        let vpk_files = VPK_MANAGER.list_files(game_path, Some("vtf"));
        for file in vpk_files {
            if completions.len() >= limit {
                break;
            }
            
            // Strip "materials/" prefix and ".vtf" suffix for cleaner paths
            let clean_path = file
                .to_lowercase()
                .trim_start_matches("materials/")
                .trim_end_matches(".vtf")
                .to_string();
            
            // Include if prefix is empty (browsing all) or if it matches the prefix
            let matches = prefix_str.is_empty() || clean_path.starts_with(&prefix_str);
            if matches && !completions.contains(&clean_path) {
                completions.push(clean_path);
            }
        }
        
        // Sort for consistent ordering
        completions.sort();
        if limit < usize::MAX {
            completions.truncate(limit);
        }
        
        // Convert to QStringList
        let strings: Vec<cxx_qt_lib::QString> = completions
            .iter()
            .map(|s| QString::from(s.as_str()))
            .collect();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = strings.into();
        QStringList::from(&qlist)
    }

    // Get the "ghost" completion - the remaining text for the best match
    fn get_texture_ghost(&self, prefix: &QString) -> QString {
        let prefix_str = prefix.to_string();
        let prefix_lower = prefix_str.to_lowercase();
        
        if prefix_str.is_empty() {
            return QString::default();
        }
        
        let materials_root = self.materials_root.to_string();
        if materials_root.is_empty() {
            return QString::default();
        }
        
        let game_path = std::path::Path::new(&materials_root);
        
        // Find the first matching path
        // Check VPK first (usually has more content)
        let vpk_files = VPK_MANAGER.list_files(game_path, Some("vtf"));
        
        for file in &vpk_files {
            let clean_path = file
                .trim_start_matches("materials/")
                .trim_end_matches(".vtf");
            
            let clean_lower = clean_path.to_lowercase();
            
            if clean_lower.starts_with(&prefix_lower) {
                // Return the remaining portion (preserving original case)
                let ghost = &clean_path[prefix_str.len()..];
                return QString::from(ghost);
            }
        }
        
        // Check disk as fallback
        let disk_materials = PathBuf::from(&materials_root).join("materials");
        if disk_materials.exists() {
            if let Some(ghost) = self.find_disk_ghost(&disk_materials, &prefix_str) {
                return QString::from(ghost.as_str());
            }
        }
        
        QString::default()
    }

    // Test VPK loading with a specific texture path
    fn test_vpk_texture(&self, texture_path: &QString) -> QString {
        let path_str = texture_path.to_string();
        let materials_root = self.materials_root.to_string();
        
        if materials_root.is_empty() {
            return QString::from("ERR: No materials root set");
        }
        
        // Normalize the path
        let normalized = path_str.replace('\\', "/");
        let with_ext = if normalized.to_lowercase().ends_with(".vtf") {
            normalized
        } else {
            format!("{}.vtf", normalized)
        };
        
        let vpk_path = if with_ext.starts_with("materials/") {
            with_ext
        } else {
            format!("materials/{}", with_ext)
        };
        
        eprintln!("[TEST] Testing VPK texture: {}", vpk_path);
        eprintln!("[TEST] Materials root: {}", materials_root);
        
        let game_path = std::path::Path::new(&materials_root);
        
        match VPK_MANAGER.read_file(game_path, &vpk_path) {
            Ok(data) => {
                let result = format!("OK: Read {} bytes, VTF magic: {:02x}{:02x}{:02x}{:02x}",
                    data.len(),
                    data.get(0).unwrap_or(&0),
                    data.get(1).unwrap_or(&0),
                    data.get(2).unwrap_or(&0),
                    data.get(3).unwrap_or(&0));
                eprintln!("[TEST] {}", result);
                QString::from(result.as_str())
            }
            Err(e) => {
                let result = format!("ERR: {}", e);
                eprintln!("[TEST] {}", result);
                QString::from(result.as_str())
            }
        }
    }

    // Get list of custom textures (loose .vtf files on disk, not in VPK)
    fn get_custom_textures(&self, max_results: i32) -> QStringList {
        let materials_root = self.materials_root.to_string();
        
        if materials_root.is_empty() {
            return QStringList::default();
        }
        
        // Handle unlimited (-1) or convert to usize
        let limit = if max_results < 0 { usize::MAX } else { max_results as usize };
        
        let mut custom_textures: Vec<String> = Vec::new();
        
        // Check materials folder under game directory
        let disk_materials = PathBuf::from(&materials_root).join("materials");
        if disk_materials.exists() {
            self.collect_all_disk_textures(&disk_materials, &disk_materials, &mut custom_textures, limit);
        }
        
        // Also check if materials_root itself contains textures directly
        let direct_path = PathBuf::from(&materials_root);
        if direct_path.exists() && !direct_path.ends_with("materials") {
            // Check for a nested materials folder structure
            self.collect_all_disk_textures(&direct_path, &direct_path, &mut custom_textures, limit);
        }
        
        // Sort for consistent ordering
        custom_textures.sort();
        if limit < usize::MAX {
            custom_textures.truncate(limit);
        }
        
        // Convert to QStringList
        let strings: Vec<cxx_qt_lib::QString> = custom_textures
            .iter()
            .map(|s| QString::from(s.as_str()))
            .collect();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = strings.into();
        QStringList::from(&qlist)
    }
}

impl VFileXAppRust {
    // Helper: Collect ALL texture files from disk (for browsing, no prefix filter)
    fn collect_all_disk_textures(&self, dir: &PathBuf, base: &PathBuf, results: &mut Vec<String>, max: usize) {
        if results.len() >= max {
            return;
        }
        
        if let Ok(entries) = std::fs::read_dir(dir) {
            for entry in entries.flatten() {
                if results.len() >= max {
                    break;
                }
                
                let path = entry.path();
                
                if path.is_dir() {
                    // Recurse into subdirectories
                    self.collect_all_disk_textures(&path, base, results, max);
                } else if let Some(ext) = path.extension() {
                    if ext == "vtf" {
                        // Get relative path from base
                        if let Ok(rel_path) = path.strip_prefix(base) {
                            let rel_str = rel_path.to_string_lossy().replace('\\', "/");
                            let clean = rel_str.trim_end_matches(".vtf").to_string();
                            
                            if !results.contains(&clean) {
                                results.push(clean);
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper: Collect texture completions from disk
    fn collect_disk_completions(&self, base_path: &PathBuf, prefix: &str, completions: &mut Vec<String>, max: usize) {
        // Walk the materials directory looking for .vtf files
        if let Ok(walker) = walkdir(base_path, prefix, max - completions.len()) {
            for entry in walker {
                if completions.len() >= max {
                    break;
                }
                completions.push(entry);
            }
        }
    }
    
    // Helper: Find ghost text from disk
    fn find_disk_ghost(&self, base_path: &PathBuf, prefix: &str) -> Option<String> {
        let prefix_lower = prefix.to_lowercase();
        
        // Simple recursive search for first match
        if let Ok(entries) = std::fs::read_dir(base_path) {
            for entry in entries.flatten() {
                let path = entry.path();
                
                if path.is_dir() {
                    // Build partial path and check if it could match
                    if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                        let name_lower = name.to_lowercase();
                        
                        // If this directory name starts with our prefix, dive in
                        if prefix_lower.starts_with(&name_lower) || name_lower.starts_with(&prefix_lower) {
                            if let Some(ghost) = self.find_disk_ghost(&path, prefix) {
                                return Some(ghost);
                            }
                        }
                    }
                } else if let Some(ext) = path.extension() {
                    if ext == "vtf" {
                        // Get relative path from materials root
                        if let Some(rel_path) = path.strip_prefix(base_path).ok() {
                            let rel_str = rel_path.to_string_lossy();
                            let clean = rel_str.trim_end_matches(".vtf");
                            let clean_lower = clean.to_lowercase();
                            
                            if clean_lower.starts_with(&prefix_lower) {
                                return Some(clean[prefix.len()..].to_string());
                            }
                        }
                    }
                }
            }
        }
        
        None
    }
}

// Simple directory walker that collects texture paths matching a prefix
fn walkdir(base: &PathBuf, prefix: &str, max: usize) -> Result<Vec<String>, std::io::Error> {
    let mut results = Vec::new();
    let prefix_lower = prefix.to_lowercase();
    
    fn walk_recursive(dir: &PathBuf, base: &PathBuf, prefix: &str, results: &mut Vec<String>, max: usize) -> std::io::Result<()> {
        if results.len() >= max {
            return Ok(());
        }
        
        for entry in std::fs::read_dir(dir)? {
            if results.len() >= max {
                break;
            }
            
            let entry = entry?;
            let path = entry.path();
            
            if path.is_dir() {
                walk_recursive(&path, base, prefix, results, max)?;
            } else if let Some(ext) = path.extension() {
                if ext == "vtf" {
                    if let Some(rel_path) = path.strip_prefix(base).ok() {
                        let rel_str = rel_path.to_string_lossy().replace('\\', "/");
                        let clean = rel_str.trim_end_matches(".vtf").to_string();
                        
                        if clean.to_lowercase().starts_with(prefix) {
                            results.push(clean);
                        }
                    }
                }
            }
        }
        
        Ok(())
    }
    
    walk_recursive(base, base, &prefix_lower, &mut results, max)?;
    Ok(results)
}

// Find a game icon in the resource folder
fn find_game_icon(resource_path: &PathBuf) -> Option<String> {
    if !resource_path.exists() {
        return None;
    }
    
    // Common icon filenames used by Source games
    // Im trying my best here okay
    let icon_names = [
        "game.ico",
        "game_icon.ico",
        "icon.ico",
        "game.png",
        "game_icon.png",
        "icon.png",
        // BMP as last resort (Qt may not decode some formats)
        "game-icon.bmp",
        "game_icon.bmp",
        "icon.bmp",
    ];
    
    for icon_name in &icon_names {
        let icon_path = resource_path.join(icon_name);
        if icon_path.exists() {
            return Some(path_to_file_url(&icon_path));
        }
    }
    
    // Also check parent directory (some games have it there, lookin at u black mesa)
    if let Some(parent) = resource_path.parent() {
        for icon_name in &icon_names {
            let icon_path = parent.join(icon_name);
            if icon_path.exists() {
                return Some(path_to_file_url(&icon_path));
            }
        }
    }
    
    None
}

/// Convert a local file path to a proper file:// URL
/// On Windows: C:\path\to\file -> file:///C:/path/to/file
/// On Unix: /path/to/file -> file:///path/to/file
fn path_to_file_url(path: &std::path::Path) -> String {
    let path_str = path.to_string_lossy();
    
    #[cfg(target_os = "windows")]
    {
        // Windows paths need file:/// with forward slashes
        let normalized = path_str.replace('\\', "/");
        format!("file:///{}", normalized)
    }
    
    #[cfg(not(target_os = "windows"))]
    {
        // Unix paths already start with /, so file:// + /path = file:///path
        format!("file://{}", path_str)
    }
}

// Get all Steam library paths (works on Windows and Linux)
fn get_steam_library_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    
    // On Windows, try to read Steam install path from registry
    #[cfg(target_os = "windows")]
    {
        use winreg::enums::*;
        use winreg::RegKey;
        
        // Try to find Steam install path from registry
        if let Ok(hklm) = RegKey::predef(HKEY_LOCAL_MACHINE)
            .open_subkey("SOFTWARE\\WOW6432Node\\Valve\\Steam")
            .or_else(|_| RegKey::predef(HKEY_LOCAL_MACHINE).open_subkey("SOFTWARE\\Valve\\Steam"))
        {
            if let Ok(install_path) = hklm.get_value::<String, _>("InstallPath") {
                let steam_path = PathBuf::from(&install_path);
                if steam_path.exists() {
                    // Add main Steam library
                    let common_path = steam_path.join("steamapps").join("common");
                    if common_path.exists() {
                        paths.push(common_path);
                    }
                    
                    // Parse libraryfolders.vdf to find additional library paths
                    let vdf_path = steam_path.join("steamapps").join("libraryfolders.vdf");
                    if let Some(mut lib_paths) = parse_library_folders_vdf(&vdf_path) {
                        paths.append(&mut lib_paths);
                    }
                }
            }
        }
        
        // Also try current user registry
        if let Ok(hkcu) = RegKey::predef(HKEY_CURRENT_USER)
            .open_subkey("SOFTWARE\\Valve\\Steam")
        {
            if let Ok(steam_path_str) = hkcu.get_value::<String, _>("SteamPath") {
                let steam_path = PathBuf::from(&steam_path_str);
                let common_path = steam_path.join("steamapps").join("common");
                if common_path.exists() && !paths.contains(&common_path) {
                    paths.push(common_path.clone());
                    
                    // Parse libraryfolders.vdf
                    let vdf_path = steam_path.join("steamapps").join("libraryfolders.vdf");
                    if let Some(lib_paths) = parse_library_folders_vdf(&vdf_path) {
                        for p in lib_paths {
                            if !paths.contains(&p) {
                                paths.push(p);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // On Linux, check common Steam paths
    #[cfg(not(target_os = "windows"))]
    {
        let linux_steam_paths = [
            dirs::home_dir().map(|h| h.join(".steam/steam")),
            dirs::home_dir().map(|h| h.join(".local/share/Steam")),
            dirs::home_dir().map(|h| h.join("snap/steam/common/.steam/steam")), // Snap Steam
            dirs::home_dir().map(|h| h.join(".var/app/com.valvesoftware.Steam/.steam/steam")), // Flatpak Steam
        ];
        
        for steam_path in linux_steam_paths.into_iter().flatten() {
            if steam_path.exists() {
                let common_path = steam_path.join("steamapps/common");
                if common_path.exists() && !paths.contains(&common_path) {
                    paths.push(common_path);
                }
                
                // Parse libraryfolders.vdf
                let vdf_path = steam_path.join("steamapps/libraryfolders.vdf");
                if let Some(lib_paths) = parse_library_folders_vdf(&vdf_path) {
                    for p in lib_paths {
                        if !paths.contains(&p) {
                            paths.push(p);
                        }
                    }
                }
            }
        }
    }
    
    // Fallback: check common hardcoded paths if nothing was found
    #[cfg(target_os = "windows")]
    if paths.is_empty() {
        let fallback_paths = [
            PathBuf::from("C:\\Program Files (x86)\\Steam\\steamapps\\common"),
            PathBuf::from("C:\\Program Files\\Steam\\steamapps\\common"),
            PathBuf::from("D:\\Steam\\steamapps\\common"),
            PathBuf::from("D:\\SteamLibrary\\steamapps\\common"),
            PathBuf::from("E:\\Steam\\steamapps\\common"),
            PathBuf::from("E:\\SteamLibrary\\steamapps\\common"),
            PathBuf::from("F:\\Steam\\steamapps\\common"),
            PathBuf::from("F:\\SteamLibrary\\steamapps\\common"),
        ];
        
        for p in fallback_paths {
            if p.exists() && !paths.contains(&p) {
                paths.push(p);
            }
        }
    }
    
    paths
}

// Parse Steam's libraryfolders.vdf to get additional library paths
fn parse_library_folders_vdf(vdf_path: &PathBuf) -> Option<Vec<PathBuf>> {
    let content = std::fs::read_to_string(vdf_path).ok()?;
    let mut paths = Vec::new();
    
    // Simple VDF parsing - look for "path" keys
    // VDF format is like:
    // "libraryfolders"
    // {
    //     "0"
    //     {
    //         "path"    "C:\\Program Files (x86)\\Steam"
    //         ...
    //     }
    //     "1"
    //     {
    //         "path"    "D:\\SteamLibrary"
    //         ...
    //     }
    // }
    
    for line in content.lines() {
        let trimmed = line.trim();
        
        // Look for "path" entries
        if trimmed.starts_with("\"path\"") {
            // Extract the path value
            let parts: Vec<&str> = trimmed.splitn(2, "\"path\"").collect();
            if parts.len() == 2 {
                let value_part = parts[1].trim();
                // Remove surrounding quotes and unescape
                if let Some(path_str) = value_part.strip_prefix('"') {
                    if let Some(path_str) = path_str.strip_suffix('"') {
                        // Unescape backslashes
                        let clean_path = path_str.replace("\\\\", "\\");
                        let lib_path = PathBuf::from(&clean_path);
                        let common_path = lib_path.join("steamapps").join("common");
                        if common_path.exists() {
                            paths.push(common_path);
                        }
                    }
                }
            }
        }
    }
    
    if paths.is_empty() {
        None
    } else {
        Some(paths)
    }
}

// Extract a string value from a TOML line
fn extract_toml_string(line: &str) -> Option<String> {
    let parts: Vec<&str> = line.splitn(2, '=').collect();
    if parts.len() == 2 {
        let value = parts[1].trim().trim_matches('"');
        Some(value.replace("\\\\", "\\").replace("\\\"", "\""))
    } else {
        None
    }
}

// Extract a bool value from a TOML line
fn extract_toml_bool(line: &str) -> Option<bool> {
    let parts: Vec<&str> = line.splitn(2, '=').collect();
    if parts.len() == 2 {
        let value = parts[1].trim();
        Some(value == "true")
    } else {
        None
    }
}
