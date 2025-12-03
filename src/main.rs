//! SuperVTF - VTF/VMT Editor
//!
//! Abandon all hope, ye who enter here.
//! (Just kidding, it's actually pretty nice)
pub mod bridge;
pub mod schema;
pub mod vmt;
pub mod vtf;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};
use std::env;

fn main() {
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
        engine.load(&QUrl::from("qrc:/qt/qml/com/supervtf/qml/Main.qml"));
    }

    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
