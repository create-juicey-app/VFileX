//! Application controller for SuperVTF (the brains of the operation, such as they are)

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
        type SuperVtfApp = super::SuperVtfAppRust;
    }

    unsafe extern "RustQt" {
        // Initialize the application
        #[qinvokable]
        fn initialize(self: Pin<&mut SuperVtfApp>);

        // Set the materials root directory
        #[qinvokable]
        fn set_materials_root_path(self: Pin<&mut SuperVtfApp>, path: &QString);

        // Add a file to recent files
        #[qinvokable]
        fn add_recent_file(self: Pin<&mut SuperVtfApp>, path: &QString);

        // Clear recent files
        #[qinvokable]
        fn clear_recent_files(self: Pin<&mut SuperVtfApp>);

        // Get file dialog filter for VMT files
        #[qinvokable]
        fn get_vmt_filter(self: &SuperVtfApp) -> QString;

        // Get file dialog filter for VTF files
        #[qinvokable]
        fn get_vtf_filter(self: &SuperVtfApp) -> QString;

        // Get file dialog filter for image files
        #[qinvokable]
        fn get_image_filter(self: &SuperVtfApp) -> QString;

        // Browse for materials directory
        #[qinvokable]
        fn browse_materials_directory(self: &SuperVtfApp) -> QString;

        // Get default materials root path
        #[qinvokable]
        fn get_default_materials_root(self: &SuperVtfApp) -> QString;

        // Convert an image file to VTF
        #[qinvokable]
        fn convert_to_vtf(self: &SuperVtfApp, source: &QString, dest: &QString) -> bool;

        // Export a VTF to an image format
        #[qinvokable]
        fn export_vtf_to_image(self: &SuperVtfApp, source: &QString, dest: &QString) -> bool;

        // Open a path in the system file browser
        #[qinvokable]
        fn reveal_in_explorer(self: &SuperVtfApp, path: &QString);

        // Save application settings
        #[qinvokable]
        fn save_settings(self: &SuperVtfApp);

        // Load application settings
        #[qinvokable]
        fn load_settings(self: Pin<&mut SuperVtfApp>);

        // Set theme
        #[qinvokable]
        fn set_app_theme(self: Pin<&mut SuperVtfApp>, theme: &QString);

        // Get supported shader list
        #[qinvokable]
        fn get_supported_shaders(self: &SuperVtfApp) -> QStringList;

        // Detect game installation paths
        #[qinvokable]
        fn detect_game_paths(self: &SuperVtfApp) -> QStringList;

        // Get list of detected games (returns "GameName|path" pairs)
        #[qinvokable]
        fn get_detected_games(self: &SuperVtfApp) -> QStringList;

        // Set the selected game by name
        #[qinvokable]
        fn select_game(self: Pin<&mut SuperVtfApp>, game_name: &QString);

        // Mark first run as complete
        #[qinvokable]
        fn complete_first_run(self: Pin<&mut SuperVtfApp>);
    }

    // Signals
    unsafe extern "RustQt" {
        // Emitted when settings change
        #[qsignal]
        fn settings_changed(self: Pin<&mut SuperVtfApp>);

        // Emitted on status message
        #[qsignal]
        fn status_message(self: Pin<&mut SuperVtfApp>, message: QString);
    }
}

use crate::schema::ShaderRegistry;
use crate::vtf::{VtfBuilder, VtfDecoder};
use qobject::*;

const APP_NAME: &str = "SuperVTF";
const APP_VERSION: &str = env!("CARGO_PKG_VERSION");
const MAX_RECENT_FILES: usize = 10;

// Rust implementation
pub struct SuperVtfAppRust {
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

impl Default for SuperVtfAppRust {
    fn default() -> Self {
        let settings_path = dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("supervtf")
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

impl qobject::SuperVtfApp {
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
            .status_message(QString::from("SuperVTF initialized"));
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
        // Try common Steam paths
        let steam_paths = [
            // Linux
            dirs::home_dir().map(|h| h.join(".steam/steam/steamapps/common")),
            dirs::home_dir().map(|h| h.join(".local/share/Steam/steamapps/common")),
            // Windows
            Some(PathBuf::from(
                "C:\\Program Files (x86)\\Steam\\steamapps\\common",
            )),
            Some(PathBuf::from("C:\\Program Files\\Steam\\steamapps\\common")),
        ];

        for path in steam_paths.into_iter().flatten() {
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
            r#"# SuperVTF Settings
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
            "Garry's Mod/garrysmod/materials",
        ];

        let steam_paths = [
            dirs::home_dir().map(|h| h.join(".steam/steam/steamapps/common")),
            dirs::home_dir().map(|h| h.join(".local/share/Steam/steamapps/common")),
            Some(PathBuf::from(
                "C:\\Program Files (x86)\\Steam\\steamapps\\common",
            )),
            Some(PathBuf::from("C:\\Program Files\\Steam\\steamapps\\common")),
        ];

        for steam_path in steam_paths.into_iter().flatten() {
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
            ("Garry's Mod", "GarrysMod/garrysmod", "GarrysMod/garrysmod/materials", "GarrysMod/garrysmod/resource"),
        ];

        let steam_paths = [
            dirs::home_dir().map(|h| h.join(".steam/steam/steamapps/common")),
            dirs::home_dir().map(|h| h.join(".local/share/Steam/steamapps/common")),
            Some(PathBuf::from("C:\\Program Files (x86)\\Steam\\steamapps\\common")),
            Some(PathBuf::from("C:\\Program Files\\Steam\\steamapps\\common")),
            Some(PathBuf::from("D:\\Steam\\steamapps\\common")),
            Some(PathBuf::from("D:\\SteamLibrary\\steamapps\\common")),
            Some(PathBuf::from("E:\\Steam\\steamapps\\common")),
            Some(PathBuf::from("E:\\SteamLibrary\\steamapps\\common")),
        ];

        for steam_path in steam_paths.into_iter().flatten() {
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
                    self.as_mut().set_materials_root(QString::from(parts[1]));
                    self.as_mut().set_selected_game(game_name.clone());
                    self.as_mut().save_settings();
                    self.as_mut().settings_changed();
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
            return Some(format!("file://{}", icon_path.to_string_lossy()));
        }
    }
    
    // Also check parent directory (some games have it there, lookin at u black mesa)
    if let Some(parent) = resource_path.parent() {
        for icon_name in &icon_names {
            let icon_path = parent.join(icon_name);
            if icon_path.exists() {
                return Some(format!("file://{}", icon_path.to_string_lossy()));
            }
        }
    }
    
    None
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
