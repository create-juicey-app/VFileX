//! Build script for VFileX
//!
//! handles basically CXX-Qt code generation and Qt resource compilation

use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        // register QML module
        .qml_module(QmlModule {
            uri: "com.VFileX",
            rust_files: &[
                "src/bridge/material_model.rs",
                "src/bridge/image_provider.rs",
                "src/bridge/application.rs",
            ],
            qml_files: &[
                "qml/Main.qml",
                "qml/ParameterDelegate.qml",
                "qml/PreviewPane.qml",
            ],
            ..Default::default()
        })
        // Include custom C++ helpers
        .cc_builder(|cc| {
            cc.include(".");
        })
        // CXX bridge for custom helpers
        .file("src/bridge/qt_helpers.rs")
        // Add icon as Qt resource
        .qrc("resources.qrc")
        // Link Qt Widgets for native dialogs (had a rough time with it)
        .qt_module("Widgets")
        .build();
}
