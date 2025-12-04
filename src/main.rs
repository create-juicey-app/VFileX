//! VFileX - VTF/VMT Editor
//!
//! Abandon all hope, ye who enter here.
//! (Just kidding, it's actually pretty nice)
pub mod bridge;
pub mod schema;
pub mod vmt;
pub mod vpk_archive;
pub mod vtf;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};
use std::env;

fn main() {
    // Check for VPK test command
    let args: Vec<String> = env::args().collect();
    if args.len() >= 3 && args[1] == "--test-vpk" {
        let game_dir = std::path::Path::new(&args[2]);
        let test_path = if args.len() >= 4 {
            &args[3]
        } else {
            "materials/brick/brickfloor001a.vtf"
        };
        
        println!("Testing VPK loading...");
        println!("Game dir: {}", game_dir.display());
        println!("Test path: {}", test_path);
        
        match vpk_archive::test_vpk_loading(game_dir, test_path) {
            Ok(size) => {
                println!("SUCCESS: Read {} bytes from VPK!", size);
                std::process::exit(0);
            }
            Err(e) => {
                println!("FAILED: {}", e);
                std::process::exit(1);
            }
        }
    }

    // whatever that shit is
    if env::var("QT_QPA_PLATFORMTHEME").is_err() {
            unsafe {
        env::set_var("QT_QPA_PLATFORMTHEME", "xdgdesktopportal");
    }
    }

    let mut app = QGuiApplication::new();

    bridge::set_application_icon(":/media/icon.png");

    let mut engine = QQmlApplicationEngine::new();

    // top tier code
    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from("qrc:/qt/qml/com/VFileX/qml/Main.qml"));
    }

    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
