//! VMT file serializer
//!
//! Turns your Material back into a text file

use super::{Material, ParameterValue, Proxy};
use std::fs;
use std::io::Write;
use std::path::Path;
use thiserror::Error;

// Errors that can occur during VMT serialization
#[derive(Error, Debug)]
pub enum VmtSerializeError {
    #[error("Failed to write file: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Invalid material: {0}")]
    InvalidMaterial(String),
}

// Options for VMT serialization
#[derive(Debug, Clone)]
pub struct SerializeOptions {
    // Use tabs instead of spaces for indentation
    pub use_tabs: bool,
    // Number of spaces per indent level (if not using tabs)
    pub indent_size: usize,
    // Add blank line between parameter groups
    pub group_parameters: bool,
    // Include type comments (e.g., // texture)
    pub include_type_comments: bool,
    // Quote all values (even numbers)
    pub quote_all_values: bool,
}

impl Default for SerializeOptions {
    fn default() -> Self {
        Self {
            use_tabs: true,
            indent_size: 4,
            group_parameters: true,
            include_type_comments: false,
            quote_all_values: true,
        }
    }
}

// VMT file serializer
pub struct VmtSerializer {
    options: SerializeOptions,
}

impl VmtSerializer {
    pub fn new() -> Self {
        Self {
            options: SerializeOptions::default(),
        }
    }

    pub fn with_options(options: SerializeOptions) -> Self {
        Self { options }
    }

    // Get the indentation string
    fn indent(&self, level: usize) -> String {
        if self.options.use_tabs {
            "\t".repeat(level)
        } else {
            " ".repeat(self.options.indent_size * level)
        }
    }

    // Serialize a material to a string
    pub fn serialize(&self, material: &Material) -> Result<String, VmtSerializeError> {
        let mut output = String::new();

        // Shader name
        output.push_str(&format!("\"{}\"\n", material.shader));
        output.push_str("{\n");

        // Group parameters by type if requested
        let params = if self.options.group_parameters {
            self.group_parameters(material)
        } else {
            material.parameters.iter().collect()
        };

        let mut last_group = "";

        for param in params {
            // Add group separator
            if self.options.group_parameters {
                let group = self.get_parameter_group(&param.name);
                if group != last_group && !last_group.is_empty() {
                    output.push('\n');
                }
                last_group = group;
            }

            // Format the parameter
            let value_str = self.format_value(&param.value);
            output.push_str(&format!(
                "{}\"{}\"\t{}\n",
                self.indent(1),
                param.name,
                value_str
            ));

            // Add comment if present
            if let Some(comment) = &param.comment {
                output.push_str(&format!(" // {}", comment));
            }
        }

        // Add proxies if present
        if !material.proxies.is_empty() {
            output.push('\n');
            output.push_str(&format!("{}\"Proxies\"\n", self.indent(1)));
            output.push_str(&format!("{}{{\n", self.indent(1)));

            for proxy in &material.proxies {
                self.serialize_proxy(&mut output, proxy, 2)?;
            }

            output.push_str(&format!("{}}}\n", self.indent(1)));
        }

        output.push_str("}\n");

        Ok(output)
    }

    // Serialize a material to a file
    pub fn serialize_to_file<P: AsRef<Path>>(
        &self,
        material: &Material,
        path: P,
    ) -> Result<(), VmtSerializeError> {
        let content = self.serialize(material)?;
        fs::write(path, content)?;
        Ok(())
    }

    // Serialize a material to a writer
    pub fn serialize_to_writer<W: Write>(
        &self,
        material: &Material,
        writer: &mut W,
    ) -> Result<(), VmtSerializeError> {
        let content = self.serialize(material)?;
        writer.write_all(content.as_bytes())?;
        Ok(())
    }

    // Format a parameter value for output
    fn format_value(&self, value: &ParameterValue) -> String {
        match value {
            ParameterValue::Texture(s) => format!("\"{}\"", s),
            ParameterValue::String(s) => format!("\"{}\"", s),
            ParameterValue::Int(i) => {
                if self.options.quote_all_values {
                    format!("\"{}\"", i)
                } else {
                    i.to_string()
                }
            }
            ParameterValue::Float(f) => {
                let formatted = format!("{:.6}", f)
                    .trim_end_matches('0')
                    .trim_end_matches('.')
                    .to_string();
                if self.options.quote_all_values {
                    format!("\"{}\"", formatted)
                } else {
                    formatted
                }
            }
            ParameterValue::Bool(b) => {
                let val = if *b { "1" } else { "0" };
                if self.options.quote_all_values {
                    format!("\"{}\"", val)
                } else {
                    val.to_string()
                }
            }
            ParameterValue::Color(c) => format!("\"{}\"", c.to_vmt_string()),
            ParameterValue::Vector2(v) => format!("\"{}\"", v.to_vmt_string()),
            ParameterValue::Vector3(v) => format!("\"{}\"", v.to_vmt_string()),
            ParameterValue::Transform(t) => format!("\"{}\"", t.to_vmt_string()),
        }
    }

    // Serialize a proxy block
    fn serialize_proxy(
        &self,
        output: &mut String,
        proxy: &Proxy,
        indent_level: usize,
    ) -> Result<(), VmtSerializeError> {
        output.push_str(&format!(
            "{}\"{}\"\n",
            self.indent(indent_level),
            proxy.proxy_type
        ));
        output.push_str(&format!("{}{{\n", self.indent(indent_level)));

        for (key, value) in &proxy.parameters {
            let value_str = self.format_value(value);
            output.push_str(&format!(
                "{}\"{}\"\t{}\n",
                self.indent(indent_level + 1),
                key,
                value_str
            ));
        }

        output.push_str(&format!("{}}}\n", self.indent(indent_level)));

        Ok(())
    }

    // Group parameters by type for organized output
    fn group_parameters<'a>(&self, material: &'a Material) -> Vec<&'a super::Parameter> {
        let mut textures = Vec::new();
        let mut booleans = Vec::new();
        let mut numbers = Vec::new();
        let mut colors = Vec::new();
        let mut transforms = Vec::new();
        let mut others = Vec::new();

        for param in &material.parameters {
            match &param.value {
                ParameterValue::Texture(_) => textures.push(param),
                ParameterValue::Bool(_) => booleans.push(param),
                ParameterValue::Int(_) | ParameterValue::Float(_) => numbers.push(param),
                ParameterValue::Color(_) => colors.push(param),
                ParameterValue::Transform(_) => transforms.push(param),
                ParameterValue::Vector2(_) | ParameterValue::Vector3(_) => colors.push(param),
                ParameterValue::String(_) => others.push(param),
            }
        }

        let mut result = Vec::new();
        result.extend(textures);
        result.extend(booleans);
        result.extend(numbers);
        result.extend(colors);
        result.extend(transforms);
        result.extend(others);
        result
    }

    // Get the parameter group name for organization
    fn get_parameter_group(&self, param_name: &str) -> &'static str {
        let name_lower = param_name.to_lowercase();

        if name_lower.contains("texture") || name_lower.contains("map") {
            "textures"
        } else if name_lower.contains("color") || name_lower.contains("tint") {
            "colors"
        } else if name_lower.contains("transform") {
            "transforms"
        } else {
            "other"
        }
    }
}
// One day, god won't be so merciful
impl Default for VmtSerializer {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vmt::{Color, Material, Parameter, ParameterValue};

    #[test]
    fn test_serialize_basic() {
        let mut material = Material::new("LightmappedGeneric");
        material.parameters.push(Parameter::new(
            "$basetexture",
            ParameterValue::Texture("brick/brickwall001".into()),
        ));
        material
            .parameters
            .push(Parameter::new("$translucent", ParameterValue::Bool(true)));

        let serializer = VmtSerializer::new();
        let output = serializer.serialize(&material).unwrap();

        assert!(output.contains("\"LightmappedGeneric\""));
        assert!(output.contains("\"$basetexture\""));
        assert!(output.contains("\"brick/brickwall001\""));
    }

    #[test]
    fn test_serialize_with_proxies() {
        let mut material = Material::new("VertexLitGeneric");

        let mut proxy = super::super::Proxy::new("AnimatedTexture");
        proxy.parameters.insert(
            "animatedtexturevar".into(),
            ParameterValue::String("$basetexture".into()),
        );
        proxy
            .parameters
            .insert("animatedtextureframerate".into(), ParameterValue::Int(30));
        material.proxies.push(proxy);

        let serializer = VmtSerializer::new();
        let output = serializer.serialize(&material).unwrap();

        assert!(output.contains("\"Proxies\""));
        assert!(output.contains("\"AnimatedTexture\""));
    }

    #[test]
    fn test_roundtrip() {
        use crate::vmt::VmtParser;

        let mut material = Material::new("LightmappedGeneric");
        material.parameters.push(Parameter::new(
            "$basetexture",
            ParameterValue::Texture("test/texture".into()),
        ));
        material.parameters.push(Parameter::new(
            "$color",
            ParameterValue::Color(Color::new(1.0, 0.5, 0.25)),
        ));
        material
            .parameters
            .push(Parameter::new("$alpha", ParameterValue::Float(0.75)));

        let serializer = VmtSerializer::new();
        let output = serializer.serialize(&material).unwrap();

        let parser = VmtParser::new();
        let parsed = parser.parse_str(&output).unwrap();

        assert_eq!(parsed.shader, material.shader);
        assert_eq!(parsed.get_base_texture(), material.get_base_texture());
    }
}
