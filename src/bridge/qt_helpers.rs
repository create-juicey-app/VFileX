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
    }
}

// Applies war paint to our window (sets the icon)
pub fn set_application_icon(resource_path: &str) {
    ffi::setApplicationIcon(resource_path);
}
