//! Build script for VFileX
//!
//! handles basically CXX-Qt code generation and Qt resource compilation

use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    let qml_module = QmlModule::new("com.VFileX")
        .version(1, 0)
        .qml_file("qml/Main.qml")
        .qml_file("qml/AppMenuBar.qml")
        .qml_file("qml/ParameterItemDelegate.qml")
        .qml_file("qml/PreviewPane.qml")
        .qml_file("qml/ThemedIcon.qml")
        .qml_file("qml/NewMaterialDialog.qml")
        .qml_file("qml/AddParameterDialog.qml")
        .qml_file("qml/AboutDialog.qml")
        .qml_file("qml/ColorPickerDialog.qml")
        .qml_file("qml/WelcomeDialog.qml")
        .qml_file("qml/ImageToVtfDialog.qml")
        .qml_file("qml/TextureBrowser.qml");

    let builder = CxxQtBuilder::new_qml_module(qml_module)
        .file("src/bridge/material_model.rs")
        .file("src/bridge/image_provider.rs")
        .file("src/bridge/application.rs")
        .qrc_resources(["qml/ThemeColors.js"]);

    unsafe {
        builder.cc_builder(|cc: &mut cc::Build| {
            cc.include(".");
        })
    }
    // CXX bridge for custom helpers
    .file("src/bridge/qt_helpers.rs")
    // Add icon as Qt resource
    .qrc("resources.qrc")
    // Link Qt Widgets for native dialogs
    .qt_module("Widgets")
    .build();
}
