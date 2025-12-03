//! VMT (Valve Material Type) data model and parsing
//!
//! why json they said

mod parser;
mod serializer;

pub use parser::VmtParser;
pub use serializer::VmtSerializer;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Represents a color value in VMT files
// Can be specified as RGB [0-255] or normalized [0.0-1.0]
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Color {
    pub r: f32,
    pub g: f32,
    pub b: f32,
}

impl Color {
    pub fn new(r: f32, g: f32, b: f32) -> Self {
        Self { r, g, b }
    }

    pub fn from_rgb(r: u8, g: u8, b: u8) -> Self {
        Self {
            r: r as f32 / 255.0,
            g: g as f32 / 255.0,
            b: b as f32 / 255.0,
        }
    }

    pub fn to_rgb(&self) -> (u8, u8, u8) {
        (
            (self.r * 255.0).clamp(0.0, 255.0) as u8,
            (self.g * 255.0).clamp(0.0, 255.0) as u8,
            (self.b * 255.0).clamp(0.0, 255.0) as u8,
        )
    }

    // Parse from VMT format: "[r g b]" or "r g b"
    pub fn from_vmt_string(s: &str) -> Option<Self> {
        let s = s.trim().trim_start_matches('[').trim_end_matches(']');
        let parts: Vec<&str> = s.split_whitespace().collect();
        if parts.len() >= 3 {
            let r: f32 = parts[0].parse().ok()?;
            let g: f32 = parts[1].parse().ok()?;
            let b: f32 = parts[2].parse().ok()?;
            // Detect if values are 0-255 range or 0-1 range
            if r > 1.0 || g > 1.0 || b > 1.0 {
                Some(Self::from_rgb(r as u8, g as u8, b as u8))
            } else {
                Some(Self::new(r, g, b))
            }
        } else {
            None
        }
    }

    pub fn to_vmt_string(&self) -> String {
        format!("[{} {} {}]", self.r, self.g, self.b)
    }
}

impl Default for Color {
    fn default() -> Self {
        Self::new(1.0, 1.0, 1.0)
    }
}

// Represents a 2D vector (commonly used for texture transforms)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Vector2 {
    pub x: f32,
    pub y: f32,
}

impl Vector2 {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }

    pub fn from_vmt_string(s: &str) -> Option<Self> {
        let s = s.trim().trim_start_matches('[').trim_end_matches(']');
        let parts: Vec<&str> = s.split_whitespace().collect();
        if parts.len() >= 2 {
            Some(Self {
                x: parts[0].parse().ok()?,
                y: parts[1].parse().ok()?,
            })
        } else {
            None
        }
    }

    pub fn to_vmt_string(&self) -> String {
        format!("[{} {}]", self.x, self.y)
    }
}

impl Default for Vector2 {
    fn default() -> Self {
        Self::new(1.0, 1.0)
    }
}

// Represents a 3D vector
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Vector3 {
    pub x: f32,
    pub y: f32,
    pub z: f32,
}

impl Vector3 {
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }

    pub fn from_vmt_string(s: &str) -> Option<Self> {
        let s = s.trim().trim_start_matches('[').trim_end_matches(']');
        let parts: Vec<&str> = s.split_whitespace().collect();
        if parts.len() >= 3 {
            Some(Self {
                x: parts[0].parse().ok()?,
                y: parts[1].parse().ok()?,
                z: parts[2].parse().ok()?,
            })
        } else {
            None
        }
    }

    pub fn to_vmt_string(&self) -> String {
        format!("[{} {} {}]", self.x, self.y, self.z)
    }
}

impl Default for Vector3 {
    fn default() -> Self {
        Self::new(0.0, 0.0, 0.0)
    }
}

// Texture transform matrix for VMT
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TextureTransform {
    pub center: Vector2,
    pub scale: Vector2,
    pub rotate: f32,
    pub translate: Vector2,
}

impl Default for TextureTransform {
    fn default() -> Self {
        Self {
            center: Vector2::new(0.5, 0.5),
            scale: Vector2::new(1.0, 1.0),
            rotate: 0.0,
            translate: Vector2::new(0.0, 0.0),
        }
    }
}

impl TextureTransform {
    pub fn from_vmt_string(s: &str) -> Option<Self> {
        // Format: "center .5 .5 scale 1 1 rotate 0 translate 0 0"
        let s = s.trim().trim_matches('"');
        let parts: Vec<&str> = s.split_whitespace().collect();

        let mut transform = Self::default();
        let mut i = 0;

        while i < parts.len() {
            match parts[i].to_lowercase().as_str() {
                "center" if i + 2 < parts.len() => {
                    transform.center.x = parts[i + 1].parse().ok()?;
                    transform.center.y = parts[i + 2].parse().ok()?;
                    i += 3;
                }
                "scale" if i + 2 < parts.len() => {
                    transform.scale.x = parts[i + 1].parse().ok()?;
                    transform.scale.y = parts[i + 2].parse().ok()?;
                    i += 3;
                }
                "rotate" if i + 1 < parts.len() => {
                    transform.rotate = parts[i + 1].parse().ok()?;
                    i += 2;
                }
                "translate" if i + 2 < parts.len() => {
                    transform.translate.x = parts[i + 1].parse().ok()?;
                    transform.translate.y = parts[i + 2].parse().ok()?;
                    i += 3;
                }
                _ => i += 1,
            }
        }

        Some(transform)
    }

    pub fn to_vmt_string(&self) -> String {
        format!(
            "center {} {} scale {} {} rotate {} translate {} {}",
            self.center.x,
            self.center.y,
            self.scale.x,
            self.scale.y,
            self.rotate,
            self.translate.x,
            self.translate.y
        )
    }
}

// Different types of parameter values in VMT files
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "value")]
pub enum ParameterValue {
    // Texture path (e.g., "materials/brick/brickwall001")
    Texture(String),
    // Integer value
    Int(i32),
    // Floating point value
    Float(f32),
    // Boolean (represented as 0/1 in VMT)
    Bool(bool),
    // Color value ([r g b])
    Color(Color),
    // 2D vector
    Vector2(Vector2),
    // 3D vector
    Vector3(Vector3),
    // Texture transform matrix
    Transform(TextureTransform),
    // Raw string (for unknown/custom parameters)
    String(String),
}

impl ParameterValue {
    // Parse a value from a VMT string, with type hints from schema
    pub fn from_string(value: &str, type_hint: Option<&str>) -> Self {
        let value = value.trim().trim_matches('"');

        match type_hint {
            Some("texture") => ParameterValue::Texture(value.to_string()),
            Some("int") => value
                .parse()
                .map(ParameterValue::Int)
                .unwrap_or(ParameterValue::String(value.to_string())),
            Some("float") => value
                .parse()
                .map(ParameterValue::Float)
                .unwrap_or(ParameterValue::String(value.to_string())),
            Some("bool") => match value {
                "1" | "true" | "yes" => ParameterValue::Bool(true),
                "0" | "false" | "no" => ParameterValue::Bool(false),
                _ => ParameterValue::String(value.to_string()),
            },
            Some("color") => Color::from_vmt_string(value)
                .map(ParameterValue::Color)
                .unwrap_or(ParameterValue::String(value.to_string())),
            Some("vector2") => Vector2::from_vmt_string(value)
                .map(ParameterValue::Vector2)
                .unwrap_or(ParameterValue::String(value.to_string())),
            Some("vector3") => Vector3::from_vmt_string(value)
                .map(ParameterValue::Vector3)
                .unwrap_or(ParameterValue::String(value.to_string())),
            Some("transform") => TextureTransform::from_vmt_string(value)
                .map(ParameterValue::Transform)
                .unwrap_or(ParameterValue::String(value.to_string())),
            _ => Self::infer_type(value),
        }
    }

    // Try to infer the type from the value itself
    fn infer_type(value: &str) -> Self {
        // Try boolean
        if value == "0" || value == "1" {
            return ParameterValue::Bool(value == "1");
        }

        // Try integer
        if let Ok(i) = value.parse::<i32>() {
            return ParameterValue::Int(i);
        }

        // Try float
        if let Ok(f) = value.parse::<f32>() {
            return ParameterValue::Float(f);
        }

        // Try color/vector (starts with '[')
        if value.starts_with('[') {
            let parts: Vec<&str> = value
                .trim_start_matches('[')
                .trim_end_matches(']')
                .split_whitespace()
                .collect();

            match parts.len() {
                2 => {
                    if let Some(v) = Vector2::from_vmt_string(value) {
                        return ParameterValue::Vector2(v);
                    }
                }
                3 => {
                    if let Some(c) = Color::from_vmt_string(value) {
                        return ParameterValue::Color(c);
                    }
                }
                _ => {}
            }
        }

        // Try texture transform
        if value.contains("center") || value.contains("scale") || value.contains("rotate") {
            if let Some(t) = TextureTransform::from_vmt_string(value) {
                return ParameterValue::Transform(t);
            }
        }

        // Check if it looks like a texture path
        if value.contains('/') || value.contains('\\') {
            return ParameterValue::Texture(value.to_string());
        }

        // Default to string
        ParameterValue::String(value.to_string())
    }

    // Convert to VMT string representation
    pub fn to_vmt_string(&self) -> String {
        match self {
            ParameterValue::Texture(s) => format!("\"{}\"", s),
            ParameterValue::Int(i) => i.to_string(),
            ParameterValue::Float(f) => format!("{:.6}", f)
                .trim_end_matches('0')
                .trim_end_matches('.')
                .to_string(),
            ParameterValue::Bool(b) => if *b { "1" } else { "0" }.to_string(),
            ParameterValue::Color(c) => c.to_vmt_string(),
            ParameterValue::Vector2(v) => v.to_vmt_string(),
            ParameterValue::Vector3(v) => v.to_vmt_string(),
            ParameterValue::Transform(t) => format!("\"{}\"", t.to_vmt_string()),
            ParameterValue::String(s) => format!("\"{}\"", s),
        }
    }
}

// A single parameter in a VMT file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Parameter {
    // Parameter name (e.g., "$basetexture")
    pub name: String,
    // Parameter value
    pub value: ParameterValue,
    // Original line number for preserving formatting
    #[serde(skip)]
    pub line_number: Option<usize>,
    // Comment associated with this parameter
    pub comment: Option<String>,
}

impl Parameter {
    pub fn new(name: impl Into<String>, value: ParameterValue) -> Self {
        Self {
            name: name.into(),
            value,
            line_number: None,
            comment: None,
        }
    }

    pub fn with_comment(mut self, comment: impl Into<String>) -> Self {
        self.comment = Some(comment.into());
        self
    }
}

// Represents a material proxy (dynamic material effects)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Proxy {
    // Proxy type name (e.g., "AnimatedTexture", "TextureScroll")
    pub proxy_type: String,
    // Proxy parameters
    pub parameters: HashMap<String, ParameterValue>,
}

impl Proxy {
    pub fn new(proxy_type: impl Into<String>) -> Self {
        Self {
            proxy_type: proxy_type.into(),
            parameters: HashMap::new(),
        }
    }

    pub fn with_parameter(mut self, name: impl Into<String>, value: ParameterValue) -> Self {
        self.parameters.insert(name.into(), value);
        self
    }
}

// The complete material definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Material {
    // Shader name (e.g., "LightmappedGeneric", "VertexLitGeneric")
    pub shader: String,
    // Material parameters
    pub parameters: Vec<Parameter>,
    // Material proxies
    pub proxies: Vec<Proxy>,
    // File path (if loaded from file)
    #[serde(skip)]
    pub file_path: Option<String>,
    // Whether the material has been modified
    #[serde(skip)]
    pub modified: bool,
}

impl Material {
    pub fn new(shader: impl Into<String>) -> Self {
        Self {
            shader: shader.into(),
            parameters: Vec::new(),
            proxies: Vec::new(),
            file_path: None,
            modified: false,
        }
    }

    // Get a parameter by name (case-insensitive)
    pub fn get_parameter(&self, name: &str) -> Option<&Parameter> {
        let name_lower = name.to_lowercase();
        self.parameters
            .iter()
            .find(|p| p.name.to_lowercase() == name_lower)
    }

    // Get a mutable parameter by name (case-insensitive)
    pub fn get_parameter_mut(&mut self, name: &str) -> Option<&mut Parameter> {
        let name_lower = name.to_lowercase();
        self.parameters
            .iter_mut()
            .find(|p| p.name.to_lowercase() == name_lower)
    }

    // Set or add a parameter
    pub fn set_parameter(&mut self, name: impl Into<String>, value: ParameterValue) {
        let name = name.into();
        if let Some(param) = self.get_parameter_mut(&name) {
            param.value = value;
        } else {
            self.parameters.push(Parameter::new(name, value));
        }
        self.modified = true;
    }

    // Remove a parameter by name
    pub fn remove_parameter(&mut self, name: &str) -> bool {
        let name_lower = name.to_lowercase();
        let len_before = self.parameters.len();
        self.parameters
            .retain(|p| p.name.to_lowercase() != name_lower);
        let removed = self.parameters.len() < len_before;
        if removed {
            self.modified = true;
        }
        removed
    }

    // Get the base texture path
    pub fn get_base_texture(&self) -> Option<&str> {
        self.get_parameter("$basetexture")
            .and_then(|p| match &p.value {
                ParameterValue::Texture(s) | ParameterValue::String(s) => Some(s.as_str()),
                _ => None,
            })
    }

    // Get the bump map texture path
    pub fn get_bump_map(&self) -> Option<&str> {
        self.get_parameter("$bumpmap").and_then(|p| match &p.value {
            ParameterValue::Texture(s) | ParameterValue::String(s) => Some(s.as_str()),
            _ => None,
        })
    }

    // Check if the material is translucent
    pub fn is_translucent(&self) -> bool {
        self.get_parameter("$translucent")
            .map(|p| matches!(p.value, ParameterValue::Bool(true) | ParameterValue::Int(1)))
            .unwrap_or(false)
    }

    // Check if alpha test is enabled
    pub fn is_alpha_test(&self) -> bool {
        self.get_parameter("$alphatest")
            .map(|p| matches!(p.value, ParameterValue::Bool(true) | ParameterValue::Int(1)))
            .unwrap_or(false)
    }

    // Add a proxy to the material
    pub fn add_proxy(&mut self, proxy: Proxy) {
        self.proxies.push(proxy);
        self.modified = true;
    }

    // Remove all proxies of a given type
    pub fn remove_proxies(&mut self, proxy_type: &str) {
        let type_lower = proxy_type.to_lowercase();
        self.proxies
            .retain(|p| p.proxy_type.to_lowercase() != type_lower);
        self.modified = true;
    }

    // Get all texture paths referenced by this material
    pub fn get_texture_paths(&self) -> Vec<&str> {
        self.parameters
            .iter()
            .filter_map(|p| match &p.value {
                ParameterValue::Texture(s) => Some(s.as_str()),
                _ => None,
            })
            .collect()
    }
}

impl Default for Material {
    fn default() -> Self {
        Self::new("LightmappedGeneric")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_color_parsing() {
        let color = Color::from_vmt_string("[1 0.5 0.25]").unwrap();
        assert!((color.r - 1.0).abs() < 0.001);
        assert!((color.g - 0.5).abs() < 0.001);
        assert!((color.b - 0.25).abs() < 0.001);

        let color_rgb = Color::from_vmt_string("[255 128 64]").unwrap();
        assert!((color_rgb.r - 1.0).abs() < 0.01);
        assert!((color_rgb.g - 0.5).abs() < 0.01);
        assert!((color_rgb.b - 0.25).abs() < 0.01);
    }

    #[test]
    fn test_material_parameters() {
        let mut mat = Material::new("VertexLitGeneric");
        mat.set_parameter(
            "$basetexture",
            ParameterValue::Texture("models/test/diffuse".into()),
        );
        mat.set_parameter("$translucent", ParameterValue::Bool(true));

        assert_eq!(mat.get_base_texture(), Some("models/test/diffuse"));
        assert!(mat.is_translucent());
    }

    #[test]
    fn test_parameter_value_inference() {
        assert!(matches!(
            ParameterValue::infer_type("1"),
            ParameterValue::Bool(true)
        ));
        assert!(matches!(
            ParameterValue::infer_type("0"),
            ParameterValue::Bool(false)
        ));
        assert!(matches!(
            ParameterValue::infer_type("42"),
            ParameterValue::Int(42)
        ));
        assert!(matches!(
            ParameterValue::infer_type("3.14"),
            ParameterValue::Float(_)
        ));
        assert!(matches!(
            ParameterValue::infer_type("models/test"),
            ParameterValue::Texture(_)
        ));
    }
}
