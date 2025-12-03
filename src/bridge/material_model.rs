//! Material Model

use cxx_qt::CxxQtType;
use std::pin::Pin;

use crate::schema::{DataType, ParameterDef, ShaderRegistry, GLOBAL_PARAMETERS};
use crate::vmt::{Material, ParameterValue, VmtParser, VmtSerializer};

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;

        include!("cxx-qt-lib/qvariant.h");
        type QVariant = cxx_qt_lib::QVariant;

        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;

        include!("cxx-qt-lib/qurl.h");
        type QUrl = cxx_qt_lib::QUrl;
    }

    // A single parameter entry for QML
    #[derive(Default, Clone)]
    pub struct QParameterEntry {
        // Parameter name (e.g., "$basetexture")
        pub name: QString,
        // Display name for UI
        pub display_name: QString,
        // Description/tooltip
        pub description: QString,
        // Data type ("texture", "bool", "float", "color", etc.)
        pub data_type: QString,
        // Control type ("TexturePicker", "Checkbox", "Slider", etc.)
        pub control_type: QString,
        // Current value as string
        pub value: QString,
        // Default value as string
        pub default_value: QString,
        // Category for grouping
        pub category: QString,
        // Min value for numeric types
        pub min_value: f64,
        // Max value for numeric types
        pub max_value: f64,
        // Step value for numeric types
        pub step_value: f64,
        // Whether parameter is required
        pub required: bool,
        // Whether parameter has a value set
        pub has_value: bool,
    }

    unsafe extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, shader_name)]
        #[qproperty(QString, file_path)]
        #[qproperty(bool, is_modified)]
        #[qproperty(bool, is_loaded)]
        #[qproperty(QString, error_message)]
        #[qproperty(i32, parameter_count)]
        type MaterialModel = super::MaterialModelRust;
    }

    unsafe extern "RustQt" {
        // Get all available shader names
        #[qinvokable]
        fn get_shader_names(self: &MaterialModel) -> QStringList;

        // Get shader description
        #[qinvokable]
        fn get_shader_description(self: &MaterialModel, shader: &QString) -> QString;

        // Load a VMT file
        #[qinvokable]
        fn load_file(self: Pin<&mut MaterialModel>, path: &QString) -> bool;

        // Save the current material to file
        #[qinvokable]
        fn save_file(self: Pin<&mut MaterialModel>, path: &QString) -> bool;

        // Save to the original file path
        #[qinvokable]
        fn save(self: Pin<&mut MaterialModel>) -> bool;

        // Create a new material with specified shader
        #[qinvokable]
        fn new_material(self: Pin<&mut MaterialModel>, shader: &QString);

        // Change the shader
        #[qinvokable]
        fn set_shader(self: Pin<&mut MaterialModel>, shader: &QString);

        // Get a parameter value by name
        #[qinvokable]
        fn get_parameter_value(self: &MaterialModel, name: &QString) -> QString;

        // Set a parameter value by name
        #[qinvokable]
        fn set_parameter_value(self: Pin<&mut MaterialModel>, name: &QString, value: &QString);

        // Remove a parameter
        #[qinvokable]
        fn remove_parameter(self: Pin<&mut MaterialModel>, name: &QString);

        // Get parameter definition at index
        #[qinvokable]
        fn get_parameter_at(self: &MaterialModel, index: i32) -> QParameterEntry;

        // Get parameter name at index
        #[qinvokable]
        fn get_param_name(self: &MaterialModel, index: i32) -> QString;

        // Get parameter display name at index
        #[qinvokable]
        fn get_param_display_name(self: &MaterialModel, index: i32) -> QString;

        // Get parameter value at index
        #[qinvokable]
        fn get_param_value(self: &MaterialModel, index: i32) -> QString;

        // Get parameter data type at index
        #[qinvokable]
        fn get_param_data_type(self: &MaterialModel, index: i32) -> QString;

        // Get parameter min value at index
        #[qinvokable]
        fn get_param_min(self: &MaterialModel, index: i32) -> f64;

        // Get parameter max value at index
        #[qinvokable]
        fn get_param_max(self: &MaterialModel, index: i32) -> f64;

        // Get parameter category at index
        #[qinvokable]
        fn get_param_category(self: &MaterialModel, index: i32) -> QString;

        // Get all texture paths referenced by the material
        #[qinvokable]
        fn get_texture_paths(self: &MaterialModel) -> QStringList;

        // Get the base texture path
        #[qinvokable]
        fn get_base_texture(self: &MaterialModel) -> QString;

        // Validate the material
        #[qinvokable]
        fn validate(self: &MaterialModel) -> QStringList;

        // Get the raw VMT text
        #[qinvokable]
        fn get_vmt_text(self: &MaterialModel) -> QString;

        // Load from VMT text
        #[qinvokable]
        fn load_from_text(self: Pin<&mut MaterialModel>, text: &QString) -> bool;
    }

    // Signals
    unsafe extern "RustQt" {
        // Emitted when a parameter value changes
        #[qsignal]
        fn parameter_changed(self: Pin<&mut MaterialModel>, name: QString);

        // Emitted when the material is loaded
        #[qsignal]
        fn material_loaded(self: Pin<&mut MaterialModel>);

        // Emitted when the material is saved
        #[qsignal]
        fn material_saved(self: Pin<&mut MaterialModel>);

        // Emitted when the shader changes
        #[qsignal]
        fn shader_changed(self: Pin<&mut MaterialModel>);

        // Emitted when an error occurs
        #[qsignal]
        fn error_occurred(self: Pin<&mut MaterialModel>, message: QString);
    }
}

use qobject::*;

// The Rust implementation of MaterialModel
pub struct MaterialModelRust {
    // Current material
    material: Option<Material>,
    // Shader registry
    shader_registry: ShaderRegistry,
    // VMT parser
    parser: VmtParser,
    // VMT serializer
    serializer: VmtSerializer,

    // Q_PROPERTY backing fields
    shader_name: QString,
    file_path: QString,
    is_modified: bool,
    is_loaded: bool,
    error_message: QString,
    parameter_count: i32,
}

impl Default for MaterialModelRust {
    fn default() -> Self {
        Self {
            material: None,
            shader_registry: ShaderRegistry::with_builtin_shaders(),
            parser: VmtParser::new(),
            serializer: VmtSerializer::new(),
            shader_name: QString::default(),
            file_path: QString::default(),
            is_modified: false,
            is_loaded: false,
            error_message: QString::default(),
            parameter_count: 0,
        }
    }
}

impl qobject::MaterialModel {
    // Get all available shader names
    fn get_shader_names(&self) -> QStringList {
        let names: Vec<cxx_qt_lib::QString> = self
            .shader_registry
            .shader_names()
            .into_iter()
            .map(|name| QString::from(name))
            .collect();
        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = names.into();
        QStringList::from(&qlist)
    }

    // Get shader description
    fn get_shader_description(&self, shader: &QString) -> QString {
        self.shader_registry
            .get(&shader.to_string())
            .map(|s| QString::from(s.description.as_str()))
            .unwrap_or_default()
    }

    // Load a VMT file
    fn load_file(mut self: Pin<&mut Self>, path: &QString) -> bool {
        let path_str = path.to_string();

        match self.parser.parse_file(&path_str) {
            Ok(material) => {
                let shader = material.shader.clone();
                let param_count = self.get_parameter_definitions(&shader).len() as i32;

                self.as_mut()
                    .set_shader_name(QString::from(shader.as_str()));
                self.as_mut().set_file_path(path.clone());
                self.as_mut().set_is_modified(false);
                self.as_mut().set_is_loaded(true);
                self.as_mut().set_error_message(QString::default());
                self.as_mut().set_parameter_count(param_count);

                self.as_mut().rust_mut().material = Some(material);

                self.as_mut().material_loaded();
                true
            }
            Err(e) => {
                let msg = QString::from(format!("Failed to load file: {}", e).as_str());
                self.as_mut().set_error_message(msg.clone());
                self.as_mut().error_occurred(msg);
                false
            }
        }
    }

    // Save the current material to file
    fn save_file(mut self: Pin<&mut Self>, path: &QString) -> bool {
        let path_str = path.to_string();

        if let Some(ref material) = self.material {
            match self.serializer.serialize_to_file(material, &path_str) {
                Ok(()) => {
                    self.as_mut().set_file_path(path.clone());
                    self.as_mut().set_is_modified(false);
                    self.as_mut().material_saved();
                    true
                }
                Err(e) => {
                    let msg = QString::from(format!("Failed to save file: {}", e).as_str());
                    self.as_mut().set_error_message(msg.clone());
                    self.as_mut().error_occurred(msg);
                    false
                }
            }
        } else {
            let msg = QString::from("No material loaded");
            self.as_mut().set_error_message(msg.clone());
            self.as_mut().error_occurred(msg);
            false
        }
    }

    // Save to the original file path
    fn save(mut self: Pin<&mut Self>) -> bool {
        let path = self.file_path.clone();
        if path.is_empty() {
            let msg = QString::from("No file path set");
            self.as_mut().set_error_message(msg.clone());
            self.as_mut().error_occurred(msg);
            return false;
        }
        self.save_file(&path)
    }

    // Create a new material with specified shader
    fn new_material(mut self: Pin<&mut Self>, shader: &QString) {
        let shader_str = shader.to_string();
        let mut material = Material::new(&shader_str);

        // Add default required parameters from schema
        if let Some(shader_def) = self.shader_registry.get(&shader_str) {
            for param in shader_def.required_parameters() {
                if let Some(default) = &param.default_value {
                    let value = ParameterValue::from_string(
                        default,
                        Some(data_type_to_str(&param.data_type)),
                    );
                    material.set_parameter(&param.name, value);
                }
            }
        }

        let param_count = self.get_parameter_definitions(&shader_str).len() as i32;

        self.as_mut().rust_mut().material = Some(material);
        self.as_mut().set_shader_name(shader.clone());
        self.as_mut().set_file_path(QString::default());
        self.as_mut().set_is_modified(true);
        self.as_mut().set_is_loaded(true);
        self.as_mut().set_error_message(QString::default());
        self.as_mut().set_parameter_count(param_count);

        self.as_mut().shader_changed();
        self.as_mut().material_loaded();
    }

    // Change the shader
    fn set_shader(mut self: Pin<&mut Self>, shader: &QString) {
        if let Some(ref mut material) = self.as_mut().rust_mut().material {
            material.shader = shader.to_string();
            material.modified = true;
        }

        let shader_str = shader.to_string();
        let param_count = self.get_parameter_definitions(&shader_str).len() as i32;

        self.as_mut().set_shader_name(shader.clone());
        self.as_mut().set_is_modified(true);
        self.as_mut().set_parameter_count(param_count);
        self.as_mut().shader_changed();
    }

    // Get a parameter value by name
    fn get_parameter_value(&self, name: &QString) -> QString {
        let name_str = name.to_string();

        self.material
            .as_ref()
            .and_then(|m| m.get_parameter(&name_str))
            .map(|p| QString::from(p.value.to_vmt_string().as_str()))
            .unwrap_or_default()
    }

    // Set a parameter value by name
    fn set_parameter_value(mut self: Pin<&mut Self>, name: &QString, value: &QString) {
        let name_str = name.to_string();
        let value_str = value.to_string();

        // Get type hint from schema
        let type_hint = self
            .shader_registry
            .get(&self.shader_name.to_string())
            .and_then(|s| s.get_parameter(&name_str))
            .map(|p| data_type_to_str(&p.data_type).to_string());

        let param_value = ParameterValue::from_string(&value_str, type_hint.as_deref());

        if let Some(ref mut material) = self.as_mut().rust_mut().material {
            material.set_parameter(&name_str, param_value);
        }

        self.as_mut().set_is_modified(true);
        self.as_mut().parameter_changed(name.clone());
    }

    // Remove a parameter
    fn remove_parameter(mut self: Pin<&mut Self>, name: &QString) {
        let name_str = name.to_string();

        if let Some(ref mut material) = self.as_mut().rust_mut().material {
            material.remove_parameter(&name_str);
        }

        self.as_mut().set_is_modified(true);
        self.as_mut().parameter_changed(name.clone());
    }

    // Get parameter definition at index
    fn get_parameter_at(&self, index: i32) -> QParameterEntry {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QParameterEntry::default();
        }

        let param_def = &params[index as usize];
        let current_value = self
            .material
            .as_ref()
            .and_then(|m| m.get_parameter(&param_def.name))
            .map(|p| p.value.to_vmt_string())
            .unwrap_or_default();

        QParameterEntry {
            name: QString::from(param_def.name.as_str()),
            display_name: QString::from(param_def.display_name.as_str()),
            description: QString::from(param_def.description.as_str()),
            data_type: QString::from(data_type_to_str(&param_def.data_type)),
            control_type: QString::from(control_type_to_str(&param_def.control)),
            value: QString::from(current_value.as_str()),
            default_value: QString::from(param_def.default_value.as_deref().unwrap_or("")),
            category: QString::from(param_def.category.as_str()),
            min_value: param_def
                .range
                .as_ref()
                .map(|r| r.min as f64)
                .unwrap_or(0.0),
            max_value: param_def
                .range
                .as_ref()
                .map(|r| r.max as f64)
                .unwrap_or(1.0),
            step_value: param_def
                .range
                .as_ref()
                .and_then(|r| r.step)
                .map(|s| s as f64)
                .unwrap_or(0.01),
            required: param_def.required,
            has_value: !current_value.is_empty(),
        }
    }

    // Get parameter name at index
    fn get_param_name(&self, index: i32) -> QString {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QString::default();
        }

        QString::from(params[index as usize].name.as_str())
    }

    // Get parameter display name at index
    fn get_param_display_name(&self, index: i32) -> QString {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QString::default();
        }

        QString::from(params[index as usize].display_name.as_str())
    }

    // Get parameter value at index (strips quotes for display)
    fn get_param_value(&self, index: i32) -> QString {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QString::default();
        }

        let param_def = &params[index as usize];
        let current_value = self
            .material
            .as_ref()
            .and_then(|m| m.get_parameter(&param_def.name))
            .map(|p| {
                let s = p.value.to_vmt_string();
                // Strip surrounding quotes for display
                if s.starts_with('"') && s.ends_with('"') && s.len() >= 2 {
                    s[1..s.len() - 1].to_string()
                } else {
                    s
                }
            })
            .unwrap_or_default();

        QString::from(current_value.as_str())
    }

    // Get parameter data type at index
    fn get_param_data_type(&self, index: i32) -> QString {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QString::from("string");
        }

        QString::from(data_type_to_str(&params[index as usize].data_type))
    }

    // Get parameter min value at index
    fn get_param_min(&self, index: i32) -> f64 {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return 0.0;
        }

        params[index as usize]
            .range
            .as_ref()
            .map(|r| r.min as f64)
            .unwrap_or(0.0)
    }

    // Get parameter max value at index
    fn get_param_max(&self, index: i32) -> f64 {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return 1.0;
        }

        params[index as usize]
            .range
            .as_ref()
            .map(|r| r.max as f64)
            .unwrap_or(1.0)
    }

    // Get parameter category at index
    fn get_param_category(&self, index: i32) -> QString {
        let shader = self.shader_name.to_string();
        let params = self.get_parameter_definitions(&shader);

        if index < 0 || index as usize >= params.len() {
            return QString::from("Other");
        }

        QString::from(params[index as usize].category.as_str())
    }

    // Get all texture paths referenced by the material
    fn get_texture_paths(&self) -> QStringList {
        if let Some(ref material) = self.material {
            let paths: Vec<cxx_qt_lib::QString> = material
                .get_texture_paths()
                .into_iter()
                .map(|path| QString::from(path))
                .collect();
            let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = paths.into();
            QStringList::from(&qlist)
        } else {
            QStringList::default()
        }
    }

    // Get the base texture path
    fn get_base_texture(&self) -> QString {
        self.material
            .as_ref()
            .and_then(|m| m.get_base_texture())
            .map(|s| QString::from(s))
            .unwrap_or_default()
    }

    // Validate the material
    fn validate(&self) -> QStringList {
        let mut error_strings: Vec<cxx_qt_lib::QString> = Vec::new();

        if let Some(ref material) = self.material {
            // Check required parameters
            if let Some(shader_def) = self.shader_registry.get(&material.shader) {
                for param in shader_def.required_parameters() {
                    if material.get_parameter(&param.name).is_none() {
                        error_strings.push(QString::from(
                            format!("Missing required parameter: {}", param.display_name).as_str(),
                        ));
                    }
                }
            }

            // Check for unknown shader
            if self.shader_registry.get(&material.shader).is_none() {
                error_strings.push(QString::from(
                    format!("Unknown shader: {}", material.shader).as_str(),
                ));
            }
        } else {
            error_strings.push(QString::from("No material loaded"));
        }

        let qlist: cxx_qt_lib::QList<cxx_qt_lib::QString> = error_strings.into();
        QStringList::from(&qlist)
    }

    // Get the raw VMT text
    fn get_vmt_text(&self) -> QString {
        self.material
            .as_ref()
            .and_then(|m| self.serializer.serialize(m).ok())
            .map(|s| QString::from(s.as_str()))
            .unwrap_or_default()
    }

    // Load from VMT text
    fn load_from_text(mut self: Pin<&mut Self>, text: &QString) -> bool {
        let text_str = text.to_string();

        match self.parser.parse_str(&text_str) {
            Ok(material) => {
                let shader = material.shader.clone();
                let param_count = self.get_parameter_definitions(&shader).len() as i32;

                self.as_mut()
                    .set_shader_name(QString::from(shader.as_str()));
                self.as_mut().set_file_path(QString::default());
                self.as_mut().set_is_modified(true);
                self.as_mut().set_is_loaded(true);
                self.as_mut().set_error_message(QString::default());
                self.as_mut().set_parameter_count(param_count);

                self.as_mut().rust_mut().material = Some(material);

                self.as_mut().material_loaded();
                true
            }
            Err(e) => {
                let msg = QString::from(format!("Failed to parse VMT: {}", e).as_str());
                self.as_mut().set_error_message(msg.clone());
                self.as_mut().error_occurred(msg);
                false
            }
        }
    }
}

impl MaterialModelRust {
    // Get parameter definitions for a shader (from schema and existing material params)
    fn get_parameter_definitions(&self, shader: &str) -> Vec<ParameterDef> {
        let mut params = Vec::new();

        // Add params from shader schema only
        if let Some(shader_def) = self.shader_registry.get(shader) {
            params.extend(shader_def.parameters.clone());
        }

        // Add custom params from material that aren't in schema
        // This allows showing parameters that exist in the loaded VMT file
        // even if they're not in the shader's schema

        // That surely wont backfire later, right?
        if let Some(ref material) = self.material {
            for param in &material.parameters {
                // Skip empty parameter names
                if param.name.trim().is_empty() {
                    continue;
                }
                let name_lower = param.name.to_lowercase();
                if !params.iter().any(|p| p.name.to_lowercase() == name_lower) {
                    // Check if it's a known global parameter to get proper type info
                    let global_def = GLOBAL_PARAMETERS
                        .iter()
                        .find(|p| p.name.to_lowercase() == name_lower);

                    if let Some(def) = global_def {
                        // Use the global parameter definition for proper typing
                        params.push(def.clone());
                    } else {
                        // Infer type from the value for truly unknown parameters
                        params.push(ParameterDef {
                            name: param.name.clone(),
                            display_name: param.name.clone(),
                            description: "Custom parameter".to_string(),
                            data_type: infer_data_type(&param.value),
                            control: infer_control_type(&param.value),
                            required: false,
                            default_value: None,
                            range: None,
                            options: None,
                            category: "Custom".to_string(),
                            related_params: Vec::new(),
                        });
                    }
                }
            }
        }

        params
    }
}

// Convert DataType to string
fn data_type_to_str(dt: &DataType) -> &'static str {
    match dt {
        DataType::Texture => "texture",
        DataType::Bool => "bool",
        DataType::Int => "int",
        DataType::Float => "float",
        DataType::Color => "color",
        DataType::Vector2 => "vector2",
        DataType::Vector3 => "vector3",
        DataType::Transform => "transform",
        DataType::String => "string",
    }
}

// Convert ControlType to string
fn control_type_to_str(ct: &crate::schema::ControlType) -> &'static str {
    match ct {
        crate::schema::ControlType::TexturePicker => "TexturePicker",
        crate::schema::ControlType::Checkbox => "Checkbox",
        crate::schema::ControlType::Slider => "Slider",
        crate::schema::ControlType::Spinner => "Spinner",
        crate::schema::ControlType::ColorPicker => "ColorPicker",
        crate::schema::ControlType::Vector2Input => "Vector2Input",
        crate::schema::ControlType::Vector3Input => "Vector3Input",
        crate::schema::ControlType::TransformEditor => "TransformEditor",
        crate::schema::ControlType::Dropdown => "Dropdown",
        crate::schema::ControlType::TextInput => "TextInput",
    }
}

// Infer data type from parameter value
fn infer_data_type(value: &ParameterValue) -> DataType {
    match value {
        ParameterValue::Texture(_) => DataType::Texture,
        ParameterValue::Bool(_) => DataType::Bool,
        ParameterValue::Int(_) => DataType::Int,
        ParameterValue::Float(_) => DataType::Float,
        ParameterValue::Color(_) => DataType::Color,
        ParameterValue::Vector2(_) => DataType::Vector2,
        ParameterValue::Vector3(_) => DataType::Vector3,
        ParameterValue::Transform(_) => DataType::Transform,
        ParameterValue::String(_) => DataType::String,
    }
}

// Infer control type from parameter value
fn infer_control_type(value: &ParameterValue) -> crate::schema::ControlType {
    match value {
        ParameterValue::Texture(_) => crate::schema::ControlType::TexturePicker,
        ParameterValue::Bool(_) => crate::schema::ControlType::Checkbox,
        ParameterValue::Int(_) => crate::schema::ControlType::Spinner,
        ParameterValue::Float(_) => crate::schema::ControlType::Slider,
        ParameterValue::Color(_) => crate::schema::ControlType::ColorPicker,
        ParameterValue::Vector2(_) => crate::schema::ControlType::Vector2Input,
        ParameterValue::Vector3(_) => crate::schema::ControlType::Vector3Input,
        ParameterValue::Transform(_) => crate::schema::ControlType::TransformEditor,
        ParameterValue::String(_) => crate::schema::ControlType::TextInput,
    }
}
