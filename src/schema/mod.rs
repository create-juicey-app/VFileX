//! Shader schema system
//!
//! If you think this is over-engineered, you haven't seen Valve's actual shader code.

mod definitions;

pub use definitions::SHADER_SCHEMAS;
pub use definitions::GLOBAL_PARAMETERS;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// The type of UI control to use for a parameter
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ControlType {
    // Text input for texture paths
    TexturePicker,
    // Checkbox for boolean values
    Checkbox,
    // Slider for numeric values
    Slider,
    // Spinner for integer values
    Spinner,
    // Color picker
    ColorPicker,
    // Vector input (2 components)
    Vector2Input,
    // Vector input (3 components)
    Vector3Input,
    // Texture transform editor
    TransformEditor,
    // Dropdown/combo box
    Dropdown,
    // Plain text input
    TextInput,
}

// The data type of a parameter
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DataType {
    Texture,
    Bool,
    Int,
    Float,
    Color,
    Vector2,
    Vector3,
    Transform,
    String,
}

// Range constraints for numeric values
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NumericRange {
    pub min: f32,
    pub max: f32,
    pub step: Option<f32>,
    pub default: Option<f32>,
}

impl Default for NumericRange {
    fn default() -> Self {
        Self {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: None,
        }
    }
}

// Definition of a single shader parameter
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParameterDef {
    // Parameter name (e.g., "$basetexture")
    pub name: String,
    // Display name for UI
    pub display_name: String,
    // Description/tooltip
    pub description: String,
    // Data type
    pub data_type: DataType,
    // UI control type
    pub control: ControlType,
    // Whether this parameter is required
    pub required: bool,
    // Default value (as string)
    pub default_value: Option<String>,
    // Numeric range (for sliders/spinners)
    pub range: Option<NumericRange>,
    // Options for dropdown controls
    pub options: Option<Vec<String>>,
    // Category for grouping in UI
    pub category: String,
    // Related parameters (e.g., $bumpmap relates to $basetexture)
    pub related_params: Vec<String>,
}
// Be careful bad code ahead.
impl ParameterDef {
    pub fn texture(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Texture,
            control: ControlType::TexturePicker,
            required: false,
            default_value: None,
            range: None,
            options: None,
            category: "Textures".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn boolean(name: &str, display_name: &str, description: &str, default: bool) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Bool,
            control: ControlType::Checkbox,
            required: false,
            default_value: Some(if default { "1" } else { "0" }.to_string()),
            range: None,
            options: None,
            category: "Flags".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn float(name: &str, display_name: &str, description: &str, range: NumericRange) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Float,
            control: ControlType::Slider,
            required: false,
            default_value: range.default.map(|d| d.to_string()),
            range: Some(range),
            options: None,
            category: "Values".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn int(
        name: &str,
        display_name: &str,
        description: &str,
        min: i32,
        max: i32,
        default: i32,
    ) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Int,
            control: ControlType::Spinner,
            required: false,
            default_value: Some(default.to_string()),
            range: Some(NumericRange {
                min: min as f32,
                max: max as f32,
                step: Some(1.0),
                default: Some(default as f32),
            }),
            options: None,
            category: "Values".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn color(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Color,
            control: ControlType::ColorPicker,
            required: false,
            default_value: Some("[1 1 1]".to_string()),
            range: None,
            options: None,
            category: "Colors".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn transform(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Transform,
            control: ControlType::TransformEditor,
            required: false,
            default_value: Some("center .5 .5 scale 1 1 rotate 0 translate 0 0".to_string()),
            range: None,
            options: None,
            category: "Transforms".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn vector2(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Vector2,
            control: ControlType::Vector2Input,
            required: false,
            default_value: Some("[0 0]".to_string()),
            range: None,
            options: None,
            category: "Vectors".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn vector3(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Vector3,
            control: ControlType::Vector3Input,
            required: false,
            default_value: Some("[0 0 0]".to_string()),
            range: None,
            options: None,
            category: "Vectors".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn string(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::String,
            control: ControlType::TextInput,
            required: false,
            default_value: None,
            range: None,
            options: None,
            category: "General".to_string(),
            related_params: Vec::new(),
        }
    }

    pub fn vector4(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            data_type: DataType::Color, // Vector4 uses the same type as Color
            control: ControlType::ColorPicker,
            required: false,
            default_value: Some("[0 0 0 0]".to_string()),
            range: None,
            options: None,
            category: "Vectors".to_string(),
            related_params: Vec::new(),
        }
    }

    // Set default value
    pub fn with_default(mut self, default: &str) -> Self {
        self.default_value = Some(default.to_string());
        self
    }

    // Mark this parameter as required
    pub fn required(mut self) -> Self {
        self.required = true;
        self
    }

    // Set the category
    pub fn with_category(mut self, category: &str) -> Self {
        self.category = category.to_string();
        self
    }

    // Add related parameters
    pub fn with_related(mut self, related: Vec<&str>) -> Self {
        self.related_params = related.into_iter().map(|s| s.to_string()).collect();
        self
    }
}

// Definition of a shader
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShaderDef {
    // Shader name (e.g., "LightmappedGeneric")
    pub name: String,
    // Display name
    pub display_name: String,
    // Description
    pub description: String,
    // Supported games/engines
    pub supported_games: Vec<String>,
    // Whether this is a model shader (vs world shader)
    pub is_model_shader: bool,
    // Parameter definitions
    pub parameters: Vec<ParameterDef>,
}

impl ShaderDef {
    pub fn new(name: &str, display_name: &str, description: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            description: description.to_string(),
            supported_games: vec!["Source".to_string()],
            is_model_shader: false,
            parameters: Vec::new(),
        }
    }

    pub fn model_shader(mut self) -> Self {
        self.is_model_shader = true;
        self
    }

    pub fn with_param(mut self, param: ParameterDef) -> Self {
        self.parameters.push(param);
        self
    }

    pub fn with_params(mut self, params: Vec<ParameterDef>) -> Self {
        self.parameters.extend(params);
        self
    }

    pub fn with_games(mut self, games: Vec<&str>) -> Self {
        self.supported_games = games.into_iter().map(|s| s.to_string()).collect();
        self
    }

    // Get a parameter definition by name
    pub fn get_parameter(&self, name: &str) -> Option<&ParameterDef> {
        let name_lower = name.to_lowercase();
        self.parameters
            .iter()
            .find(|p| p.name.to_lowercase() == name_lower)
    }

    // Get all required parameters
    pub fn required_parameters(&self) -> Vec<&ParameterDef> {
        self.parameters.iter().filter(|p| p.required).collect()
    }

    // Get parameters by category
    pub fn parameters_by_category(&self) -> HashMap<&str, Vec<&ParameterDef>> {
        let mut result: HashMap<&str, Vec<&ParameterDef>> = HashMap::new();
        for param in &self.parameters {
            result
                .entry(param.category.as_str())
                .or_default()
                .push(param);
        }
        result
    }
}

// Still trying to be polite
// Bad code alert, once again
#[derive(Debug, Clone, Default)]
pub struct ShaderRegistry {
    shaders: HashMap<String, ShaderDef>,
}

impl ShaderRegistry {
    pub fn new() -> Self {
        Self {
            shaders: HashMap::new(),
        }
    }

    // Create registry with built-in shaders
    pub fn with_builtin_shaders() -> Self {
        let mut registry = Self::new();
        for shader in definitions::get_builtin_shaders() {
            registry.register(shader);
        }
        registry
    }

    // Register a shader
    pub fn register(&mut self, shader: ShaderDef) {
        self.shaders.insert(shader.name.to_lowercase(), shader);
    }

    // Get a shader by name
    pub fn get(&self, name: &str) -> Option<&ShaderDef> {
        self.shaders.get(&name.to_lowercase())
    }

    // Get all shader names
    pub fn shader_names(&self) -> Vec<&str> {
        self.shaders.values().map(|s| s.name.as_str()).collect()
    }

    // Get all model shaders
    pub fn model_shaders(&self) -> Vec<&ShaderDef> {
        self.shaders
            .values()
            .filter(|s| s.is_model_shader)
            .collect()
    }

    // Get all world/brush shaders
    pub fn world_shaders(&self) -> Vec<&ShaderDef> {
        self.shaders
            .values()
            .filter(|s| !s.is_model_shader)
            .collect()
    }

    // Try to auto-detect shader from parameters
    pub fn detect_shader(&self, param_names: &[&str]) -> Option<&ShaderDef> {
        let param_set: std::collections::HashSet<_> =
            param_names.iter().map(|s| s.to_lowercase()).collect();

        let mut best_match: Option<&ShaderDef> = None;
        let mut best_score = 0;

        for shader in self.shaders.values() {
            let mut score = 0;

            // Check required parameters
            for param in shader.required_parameters() {
                if param_set.contains(&param.name.to_lowercase()) {
                    score += 10;
                }
            }

            // Check optional parameters
            for param in &shader.parameters {
                if param_set.contains(&param.name.to_lowercase()) {
                    score += 1;
                }
            }

            if score > best_score {
                best_score = score;
                best_match = Some(shader);
            }
        }

        best_match
    }

    // Load shaders from a TOML file
    pub fn load_from_toml(&mut self, content: &str) -> Result<(), toml::de::Error> {
        #[derive(Deserialize)]
        struct ShaderFile {
            shaders: Vec<ShaderDef>,
        }

        let file: ShaderFile = toml::from_str(content)?;
        for shader in file.shaders {
            self.register(shader);
        }
        Ok(())
    }

    // Export shaders to TOML format
    pub fn export_to_toml(&self) -> Result<String, toml::ser::Error> {
        #[derive(Serialize)]
        struct ShaderFile<'a> {
            shaders: Vec<&'a ShaderDef>,
        }

        let file = ShaderFile {
            shaders: self.shaders.values().collect(),
        };
        toml::to_string_pretty(&file)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shader_registry() {
        let registry = ShaderRegistry::with_builtin_shaders();

        let lmg = registry.get("LightmappedGeneric").unwrap();
        assert!(!lmg.is_model_shader);
        assert!(lmg.get_parameter("$basetexture").is_some());
    }

    #[test]
    fn test_shader_detection() {
        let registry = ShaderRegistry::with_builtin_shaders();

        let params = vec!["$basetexture", "$model", "$phong"];
        let detected = registry.detect_shader(&params);

        assert!(detected.is_some());
    }

    #[test]
    fn test_parameter_categories() {
        let registry = ShaderRegistry::with_builtin_shaders();
        let shader = registry.get("VertexLitGeneric").unwrap();

        let by_category = shader.parameters_by_category();
        assert!(by_category.contains_key("Textures"));
    }
}
