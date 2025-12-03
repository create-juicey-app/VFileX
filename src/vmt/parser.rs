//! VMT file parser
//!
//! "Thanks, and have fun" - Gabe Newell

use super::{Material, Parameter, ParameterValue, Proxy};
use keyvalues_parser::Vdf;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use thiserror::Error;

// Errors that can occur during VMT parsing
#[derive(Error, Debug)]
pub enum VmtParseError {
    #[error("Failed to read file: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Failed to parse VDF: {0}")]
    VdfError(String),

    #[error("Invalid VMT structure: {0}")]
    InvalidStructure(String),

    #[error("Missing shader name")]
    MissingShader,
}

// VMT file parser
pub struct VmtParser {
    // Type hints from shader schema for better type inference
    type_hints: HashMap<String, String>,
}

impl VmtParser {
    pub fn new() -> Self {
        Self {
            type_hints: Self::default_type_hints(),
        }
    }

    // Create parser with custom type hints
    pub fn with_type_hints(type_hints: HashMap<String, String>) -> Self {
        let mut hints = Self::default_type_hints();
        hints.extend(type_hints);
        Self { type_hints: hints }
    }

    // Default type hints for common VMT parameters
    fn default_type_hints() -> HashMap<String, String> {
        let mut hints = HashMap::new();

        // Texture parameters
        for param in &[
            "$basetexture",
            "$basetexture2",
            "$bumpmap",
            "$bumpmap2",
            "$envmap",
            "$envmapmask",
            "$detail",
            "$detailblendtexture",
            "$normalmap",
            "$phongexponenttexture",
            "$selfillummask",
            "$blendmodulatetexture",
            "$lightwarptexture",
            "$selfillumtexture",
        ] {
            hints.insert(param.to_string(), "texture".to_string());
        }

        // Boolean parameters
        for param in &[
            "$translucent",
            "$alphatest",
            "$nocull",
            "$additive",
            "$model",
            "$selfillum",
            "$halflambert",
            "$phong",
            "$normalmapalphaenvmapmask",
            "$basemapalphaphongmask",
            "$basemapalphaenvmapmask",
            "$envmaptint",
            "$parallaxmap",
            "$decal",
            "$vertexcolor",
            "$vertexalpha",
            "$ignorez",
            "$nofog",
            "$nodecal",
            "$no_fullbright",
        ] {
            hints.insert(param.to_string(), "bool".to_string());
        }

        // Float parameters
        for param in &[
            "$alpha",
            "$alphatestreference",
            "$envmapcontrast",
            "$envmapsaturation",
            "$detailblendfactor",
            "$detailscale",
            "$phongboost",
            "$phongexponent",
            "$phongfresnelranges",
            "$bumpscale",
            "$parallaxmapscale",
            "$seamless_scale",
            "$selfillumtint",
            "$reflectivity",
        ] {
            hints.insert(param.to_string(), "float".to_string());
        }

        // Color parameters
        for param in &[
            "$color",
            "$color2",
            "$envmaptint",
            "$selfillumtint",
            "$phongtint",
            "$reflectivitytint",
        ] {
            hints.insert(param.to_string(), "color".to_string());
        }

        // Transform parameters
        for param in &[
            "$basetexturetransform",
            "$basetexture2transform",
            "$bumptransform",
            "$detailtexturetransform",
        ] {
            hints.insert(param.to_string(), "transform".to_string());
        }

        hints
    }

    // Parse VMT content from a string
    pub fn parse_str(&self, content: &str) -> Result<Material, VmtParseError> {
        // Pre-process content to handle VMT quirks
        let processed = self.preprocess_vmt(content);

        // Parse as VDF
        let vdf =
            Vdf::parse(&processed).map_err(|e| VmtParseError::VdfError(format!("{:?}", e)))?;

        // The VDF root key IS the shader name
        let shader_name = vdf.key.to_string();

        eprintln!("DEBUG: VDF key (shader): '{}'", shader_name);

        // Get the shader's content object
        let shader_obj = vdf.value.get_obj().ok_or(VmtParseError::InvalidStructure(
            "Shader content must be an object".into(),
        ))?;

        let mut material = Material::new(&shader_name);

        // Parse the shader content
        self.parse_material_content(&mut material, shader_obj)?;

        Ok(material)
    }

    // Parse VMT content from a file
    pub fn parse_file<P: AsRef<Path>>(&self, path: P) -> Result<Material, VmtParseError> {
        let content = fs::read_to_string(path.as_ref())?;
        let mut material = self.parse_str(&content)?;
        material.file_path = Some(path.as_ref().to_string_lossy().to_string());
        Ok(material)
    }

    // Pre-process VMT content to handle common formatting issues
    fn preprocess_vmt(&self, content: &str) -> String {
        let mut result = String::with_capacity(content.len());
        let mut first_line = true;

        for line in content.lines() {
            // Remove BOM if present
            let line = line.trim_start_matches('\u{feff}');

            // Skip empty lines and comments for parsing (they'll be handled separately)
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with("//") {
                result.push_str(line);
                result.push('\n');
                continue;
            }

            // Handle lines with inline comments
            let line_without_comment = if let Some(idx) = line.find("//") {
                &line[..idx]
            } else {
                line
            };

            // Handle malformed first line like "ShaderName vmt{" or "ShaderName {"
            if first_line {
                first_line = false;
                let trimmed_line = line_without_comment.trim();

                // Check for patterns like "ShaderName vmt{" or "ShaderName {"
                if let Some(brace_pos) = trimmed_line.find('{') {
                    let before_brace = trimmed_line[..brace_pos].trim();
                    // Remove "vmt" suffix if present
                    let shader_name = before_brace
                        .trim_end_matches(|c: char| c.is_whitespace())
                        .trim_end_matches("vmt")
                        .trim_end_matches("VMT")
                        .trim();

                    if !shader_name.is_empty() && !shader_name.starts_with('"') {
                        // Add quotes around shader name
                        result.push_str(&format!("\"{}\"\n{{\n", shader_name));
                        continue;
                    }
                }
            }

            result.push_str(line_without_comment);
            result.push('\n');
        }

        result
    }

    // Parse the content inside a shader block
    fn parse_material_content(
        &self,
        material: &mut Material,
        obj: &keyvalues_parser::Obj,
    ) -> Result<(), VmtParseError> {
        for (key, values) in obj.iter() {
            let key_str: &str = &key;
            let key_lower = key_str.to_lowercase();

            // Handle Proxies block
            if key_lower == "proxies" {
                if let Some(proxies_obj) = values.first().and_then(|v| v.get_obj()) {
                    self.parse_proxies(material, proxies_obj)?;
                }
                continue;
            }

            // Handle regular parameters
            if let Some(value) = values.first() {
                if let Some(str_val) = value.get_str() {
                    let type_hint = self.type_hints.get(&key_lower).map(|s| s.as_str());
                    let param_value = ParameterValue::from_string(&*str_val, type_hint);
                    material
                        .parameters
                        .push(Parameter::new(key_str, param_value));
                } else if value.get_obj().is_some() {
                    // Nested object that's not "Proxies" - store as string for now
                    material.parameters.push(Parameter::new(
                        key_str,
                        ParameterValue::String(format!("{{nested:{}}}", key_str)),
                    ));
                }
            }
        }

        Ok(())
    }

    // Parse the Proxies block
    fn parse_proxies(
        &self,
        material: &mut Material,
        obj: &keyvalues_parser::Obj,
    ) -> Result<(), VmtParseError> {
        for (proxy_type, values) in obj.iter() {
            let mut proxy = Proxy::new(&**proxy_type);

            if let Some(proxy_obj) = values.first().and_then(|v| v.get_obj()) {
                for (param_key, param_values) in proxy_obj.iter() {
                    if let Some(value) = param_values.first().and_then(|v| v.get_str()) {
                        let param_value = ParameterValue::from_string(&*value, None);
                        proxy.parameters.insert(param_key.to_string(), param_value);
                    }
                }
            }

            material.proxies.push(proxy);
        }

        Ok(())
    }

    // Get type hint for a parameter
    pub fn get_type_hint(&self, param_name: &str) -> Option<&str> {
        self.type_hints
            .get(&param_name.to_lowercase())
            .map(|s| s.as_str())
    }

    // Add a custom type hint
    pub fn add_type_hint(&mut self, param_name: impl Into<String>, type_name: impl Into<String>) {
        self.type_hints
            .insert(param_name.into().to_lowercase(), type_name.into());
    }
}

impl Default for VmtParser {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_VMT: &str = r#"
"LightmappedGeneric"
{
    "$basetexture" "brick/brickwall001"
    "$bumpmap" "brick/brickwall001_normal"
    "$translucent" "1"
    "$alpha" "0.5"
    "$color" "[1 0.5 0.25]"
    
    "Proxies"
    {
        "AnimatedTexture"
        {
            "animatedtexturevar" "$basetexture"
            "animatedtextureframenumvar" "$frame"
            "animatedtextureframerate" "30"
        }
    }
}
"#;

    #[test]
    fn test_parse_basic_vmt() {
        let parser = VmtParser::new();
        let material = parser.parse_str(TEST_VMT).unwrap();

        assert_eq!(material.shader, "LightmappedGeneric");
        assert_eq!(material.get_base_texture(), Some("brick/brickwall001"));
        assert!(material.is_translucent());
    }

    #[test]
    fn test_parse_proxies() {
        let parser = VmtParser::new();
        let material = parser.parse_str(TEST_VMT).unwrap();

        assert_eq!(material.proxies.len(), 1);
        assert_eq!(material.proxies[0].proxy_type, "AnimatedTexture");
    }

    #[test]
    fn test_parse_color() {
        let parser = VmtParser::new();
        let material = parser.parse_str(TEST_VMT).unwrap();

        let color_param = material.get_parameter("$color").unwrap();
        if let ParameterValue::Color(c) = &color_param.value {
            assert!((c.r - 1.0).abs() < 0.001);
            assert!((c.g - 0.5).abs() < 0.001);
        } else {
            panic!("Expected color parameter");
        }
    }
}
