//! Qt helper functions bridge
//!
//! JUST FOR THE ICON. THAT'S IT. FUCK C++.

#[cxx::bridge]
mod ffi {
    unsafe extern "C++" {
        include!("cpp/helpers.h");

        // Summons the application icon from the Qt resource dimension
        #[namespace = "VFileX"]
        fn setApplicationIcon(resource_path: &str);
        #[namespace = "VFileX"]
        fn readResourceFile(resource_path: &str) -> String;
    }
}

// Applies war paint to our window (sets the icon)
pub fn set_application_icon(resource_path: &str) {
    ffi::setApplicationIcon(resource_path);
}

pub fn read_resource_file(resource_path: &str) -> String {
    ffi::readResourceFile(resource_path)
}
