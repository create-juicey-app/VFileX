//! Built-in shader definitions
//!
//! TODO: erase this entire file and load from JSON instead for fucks sake
use super::{NumericRange, ParameterDef, ShaderDef};
use once_cell::sync::Lazy;

// Lazy-loaded shader schemas
pub static SHADER_SCHEMAS: Lazy<Vec<ShaderDef>> = Lazy::new(get_builtin_shaders);

// Common texture parameters shared across shaders
#[allow(dead_code)]
fn common_texture_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::texture(
            "$basetexture",
            "Base Texture",
            "The primary diffuse texture",
        )
        .required()
        .with_category("Textures"),
        ParameterDef::texture(
            "$basetexture2",
            "Base Texture 2",
            "Secondary diffuse texture for blending",
        )
        .with_category("Textures"),
        ParameterDef::texture(
            "$bumpmap",
            "Normal Map",
            "Tangent-space normal map for surface detail",
        )
        .with_category("Textures")
        .with_related(vec!["$basetexture"]),
        ParameterDef::texture(
            "$bumpmap2",
            "Normal Map 2",
            "Secondary normal map for blending",
        )
        .with_category("Textures"),
        ParameterDef::texture(
            "$detail",
            "Detail Texture",
            "Detail texture that tiles at a different scale",
        )
        .with_category("Textures"),
        ParameterDef::texture(
            "$envmapmask",
            "Envmap Mask",
            "Mask for environment map reflections",
        )
        .with_category("Textures"),
    ]
}

// Common flag parameters shared across shaders
#[allow(dead_code)]
fn common_flag_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::boolean(
            "$translucent",
            "Translucent",
            "Enable alpha blending",
            false,
        )
        .with_category("Transparency"),
        ParameterDef::boolean(
            "$alphatest",
            "Alpha Test",
            "Enable alpha testing (1-bit transparency)",
            false,
        )
        .with_category("Transparency"),
        ParameterDef::boolean(
            "$nocull",
            "No Backface Culling",
            "Render both sides of the surface",
            false,
        )
        .with_category("Rendering"),
        ParameterDef::boolean(
            "$additive",
            "Additive Blend",
            "Use additive blending",
            false,
        )
        .with_category("Transparency"),
        ParameterDef::boolean("$decal", "Is Decal", "Mark this material as a decal", false)
            .with_category("Rendering"),
        ParameterDef::boolean(
            "$ignorez",
            "Ignore Z-Buffer",
            "Render without z-buffering",
            false,
        )
        .with_category("Rendering"),
        ParameterDef::boolean("$nofog", "No Fog", "Disable fog on this material", false)
            .with_category("Rendering"),
        ParameterDef::boolean(
            "$nodecal",
            "No Decals",
            "Prevent decals from appearing on this surface",
            false,
        )
        .with_category("Rendering"),
        ParameterDef::boolean(
            "$selfillum",
            "Self-Illumination",
            "Enable self-illumination from alpha channel",
            false,
        )
        .with_category("Lighting"),
    ]
}

// Common value parameters shared across shaders
#[allow(dead_code)]
fn common_value_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::float(
            "$alpha",
            "Alpha",
            "Overall transparency value",
            NumericRange {
                min: 0.0,
                max: 1.0,
                step: Some(0.01),
                default: Some(1.0),
            },
        )
        .with_category("Transparency"),
        ParameterDef::float(
            "$alphatestreference",
            "Alpha Test Reference",
            "Threshold for alpha testing",
            NumericRange {
                min: 0.0,
                max: 1.0,
                step: Some(0.01),
                default: Some(0.5),
            },
        )
        .with_category("Transparency"),
        ParameterDef::color(
            "$color",
            "Color Tint",
            "Color multiplier for the base texture",
        )
        .with_category("Colors"),
        ParameterDef::color("$color2", "Color Tint 2", "Secondary color multiplier")
            .with_category("Colors"),
        ParameterDef::float(
            "$detailscale",
            "Detail Scale",
            "Tiling scale for detail texture",
            NumericRange {
                min: 0.1,
                max: 100.0,
                step: Some(0.1),
                default: Some(4.0),
            },
        )
        .with_category("Detail"),
        ParameterDef::float(
            "$detailblendfactor",
            "Detail Blend Factor",
            "Strength of detail texture",
            NumericRange {
                min: 0.0,
                max: 1.0,
                step: Some(0.01),
                default: Some(1.0),
            },
        )
        .with_category("Detail"),
    ]
}

// Environment map parameters
#[allow(dead_code)]
fn envmap_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::texture("$envmap", "Environment Map", "Cubemap for reflections")
            .with_category("Reflections"),
        ParameterDef::color("$envmaptint", "Envmap Tint", "Color tint for reflections")
            .with_category("Reflections"),
        ParameterDef::float(
            "$envmapcontrast",
            "Envmap Contrast",
            "Contrast of reflections",
            NumericRange {
                min: 0.0,
                max: 1.0,
                step: Some(0.01),
                default: Some(0.0),
            },
        )
        .with_category("Reflections"),
        ParameterDef::float(
            "$envmapsaturation",
            "Envmap Saturation",
            "Saturation of reflections",
            NumericRange {
                min: 0.0,
                max: 1.0,
                step: Some(0.01),
                default: Some(1.0),
            },
        )
        .with_category("Reflections"),
        ParameterDef::boolean(
            "$normalmapalphaenvmapmask",
            "Normal Alpha as Envmap Mask",
            "Use normal map alpha as environment map mask",
            false,
        )
        .with_category("Reflections"),
        ParameterDef::boolean(
            "$basealphaenvmapmask",
            "Base Alpha as Envmap Mask",
            "Use base texture alpha as environment map mask",
            false,
        )
        .with_category("Reflections"),
    ]
}

// Phong shading parameters (for model shaders)
#[allow(dead_code)]
fn phong_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::boolean(
            "$phong",
            "Enable Phong",
            "Enable Phong specular highlights",
            false,
        )
        .with_category("Phong"),
        ParameterDef::float(
            "$phongexponent",
            "Phong Exponent",
            "Shininess/glossiness",
            NumericRange {
                min: 1.0,
                max: 255.0,
                step: Some(1.0),
                default: Some(5.0),
            },
        )
        .with_category("Phong"),
        ParameterDef::float(
            "$phongboost",
            "Phong Boost",
            "Multiplier for phong brightness",
            NumericRange {
                min: 0.0,
                max: 100.0,
                step: Some(0.1),
                default: Some(1.0),
            },
        )
        .with_category("Phong"),
        ParameterDef::color(
            "$phongtint",
            "Phong Tint",
            "Color tint for specular highlights",
        )
        .with_category("Phong"),
        ParameterDef::texture(
            "$phongexponenttexture",
            "Phong Exponent Texture",
            "Texture controlling per-pixel shininess",
        )
        .with_category("Phong"),
        ParameterDef::boolean(
            "$phongfresnelranges",
            "Phong Fresnel Ranges",
            "Enable fresnel effect on phong",
            false,
        )
        .with_category("Phong"),
        ParameterDef::boolean(
            "$basemapalphaphongmask",
            "Base Alpha as Phong Mask",
            "Use base texture alpha as phong mask",
            false,
        )
        .with_category("Phong"),
    ]
}

// Rim lighting parameters
#[allow(dead_code)]
fn rimlight_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::boolean(
            "$rimlight",
            "Enable Rim Light",
            "Enable rim lighting effect",
            false,
        )
        .with_category("Rim Light"),
        ParameterDef::float(
            "$rimlightexponent",
            "Rim Light Exponent",
            "Falloff of rim light",
            NumericRange {
                min: 0.0,
                max: 50.0,
                step: Some(0.1),
                default: Some(4.0),
            },
        )
        .with_category("Rim Light"),
        ParameterDef::float(
            "$rimlightboost",
            "Rim Light Boost",
            "Brightness of rim light",
            NumericRange {
                min: 0.0,
                max: 10.0,
                step: Some(0.1),
                default: Some(1.0),
            },
        )
        .with_category("Rim Light"),
    ]
}

// Transform parameters
#[allow(dead_code)]
fn transform_params() -> Vec<ParameterDef> {
    vec![
        ParameterDef::transform(
            "$basetexturetransform",
            "Base Texture Transform",
            "Transform matrix for base texture UV",
        )
        .with_category("Transforms"),
        ParameterDef::transform(
            "$bumptransform",
            "Bump Transform",
            "Transform matrix for normal map UV",
        )
        .with_category("Transforms"),
        ParameterDef::transform(
            "$basetexture2transform",
            "Base Texture 2 Transform",
            "Transform matrix for secondary texture UV",
        )
        .with_category("Transforms"),
        ParameterDef::transform(
            "$detailtexturetransform",
            "Detail Texture Transform",
            "Transform matrix for detail texture UV",
        )
        .with_category("Transforms"),
    ]
}

// Get all built-in shader definitions
pub fn get_builtin_shaders() -> Vec<ShaderDef> {
    vec![
        // Most common shaders first
        ShaderDef::new("LightmappedGeneric", "Lightmapped Generic", "Standard shader for brush surfaces with lightmaps")
            // Basics - most commonly edited
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Primary diffuse texture").required().with_category("Basics"))
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", "Normal map texture").with_category("Basics"))
            .with_param(ParameterDef::color("$color", "Color", "Color tint multiplier").with_category("Basics"))
            .with_param(ParameterDef::string("$surfaceprop", "Surface Prop", "Physical surface property").with_category("Basics"))
            // Transparency
            .with_param(ParameterDef::boolean("$translucent", "Translucent", "Enable alpha blending", false).with_category("Transparency"))
            .with_param(ParameterDef::boolean("$alphatest", "Alpha Test", "Enable alpha testing", false).with_category("Transparency"))
            .with_param(ParameterDef::float("$alphatestreference", "Alpha Test Reference", "Alpha test threshold", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.5) }).with_category("Transparency"))
            .with_param(ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Transparency"))
            // Reflections
            .with_param(ParameterDef::texture("$envmap", "Environment Map", "Cubemap for reflections").with_category("Reflections"))
            .with_param(ParameterDef::texture("$envmapmask", "Envmap Mask", "Mask for environment reflections").with_category("Reflections"))
            .with_param(ParameterDef::color("$envmaptint", "Envmap Tint", "Color tint for reflections").with_category("Reflections"))
            .with_param(ParameterDef::float("$envmapcontrast", "Envmap Contrast", "Reflection contrast", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.0) }).with_category("Reflections"))
            .with_param(ParameterDef::float("$envmapsaturation", "Envmap Saturation", "Reflection saturation", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Reflections"))
            .with_param(ParameterDef::boolean("$basealphaenvmapmask", "Base Alpha Envmap Mask", "Use base texture alpha as envmap mask", false).with_category("Reflections"))
            .with_param(ParameterDef::boolean("$normalmapalphaenvmapmask", "Normal Alpha Envmap Mask", "Use normal map alpha as envmap mask", false).with_category("Reflections"))
            // Self Illumination
            .with_param(ParameterDef::boolean("$selfillum", "Self Illumination", "Enable self-illumination", false).with_category("Self Illumination"))
            .with_param(ParameterDef::texture("$selfillummask", "Self Illum Mask", "Mask for self-illumination").with_category("Self Illumination"))
            .with_param(ParameterDef::color("$selfillumtint", "Self Illum Tint", "Self-illumination color tint").with_category("Self Illumination"))
            // Detail Texture
            .with_param(ParameterDef::texture("$detail", "Detail Texture", "Detail texture for close viewing").with_category("Detail"))
            .with_param(ParameterDef::float("$detailscale", "Detail Scale", "Detail texture tiling", NumericRange { min: 0.1, max: 100.0, step: Some(0.1), default: Some(4.0) }).with_category("Detail"))
            .with_param(ParameterDef::int("$detailblendmode", "Detail Blend Mode", "How detail blends with base", 0, 12, 0).with_category("Detail"))
            .with_param(ParameterDef::float("$detailblendfactor", "Detail Blend Factor", "Detail blend strength", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Detail"))
            // Blending (for displacements)
            .with_param(ParameterDef::texture("$basetexture2", "Base Texture 2", "Secondary texture for blending").with_category("Blending"))
            .with_param(ParameterDef::texture("$bumpmap2", "Bump Map 2", "Secondary normal map").with_category("Blending"))
            .with_param(ParameterDef::string("$surfaceprop2", "Surface Prop 2", "Secondary surface property").with_category("Blending"))
            // Rendering Options
            .with_param(ParameterDef::boolean("$nocull", "No Cull", "Disable backface culling", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$decal", "Decal", "This is a decal material", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$nodecal", "No Decal", "Prevent decals on this surface", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$ssbump", "SS Bump", "Self-shadowing bump mapping", false).with_category("Rendering"))
            .with_param(ParameterDef::float("$seamless_scale", "Seamless Scale", "Scale for seamless texturing", NumericRange { min: 0.0, max: 1.0, step: Some(0.001), default: Some(0.0) }).with_category("Rendering"))
            // Transforms
            .with_param(ParameterDef::transform("$basetexturetransform", "Base Texture Transform", "UV transform for base texture").with_category("Transforms"))
            .with_param(ParameterDef::transform("$bumptransform", "Bump Transform", "UV transform for bump map").with_category("Transforms"))
            .with_param(ParameterDef::transform("$envmapmasktransform", "Envmap Mask Transform", "UV transform for envmap mask").with_category("Transforms"))
            // Misc
            .with_param(ParameterDef::color("$color2", "Color 2", "Secondary color tint").with_category("Misc"))
            .with_param(ParameterDef::string("$keywords", "Keywords", "Search keywords").with_category("Misc")),

        ShaderDef::new("VertexLitGeneric", "Vertex Lit Generic", "Standard shader for models and props")
            // Basics - most commonly edited
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Primary diffuse texture").required().with_category("Basics"))
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", "Normal map texture").with_category("Basics"))
            .with_param(ParameterDef::color("$color", "Color", "Color tint").with_category("Basics"))
            .with_param(ParameterDef::boolean("$model", "Model", "This is a model material", true).with_category("Basics"))
            .with_param(ParameterDef::string("$surfaceprop", "Surface Prop", "Physical surface property").with_category("Basics"))
            // Transparency
            .with_param(ParameterDef::boolean("$translucent", "Translucent", "Enable alpha blending", false).with_category("Transparency"))
            .with_param(ParameterDef::boolean("$alphatest", "Alpha Test", "Enable alpha testing", false).with_category("Transparency"))
            .with_param(ParameterDef::float("$alphatestreference", "Alpha Test Reference", "Alpha test threshold", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.5) }).with_category("Transparency"))
            .with_param(ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Transparency"))
            // Phong Shading
            .with_param(ParameterDef::boolean("$phong", "Phong", "Enable phong shading", false).with_category("Phong"))
            .with_param(ParameterDef::float("$phongexponent", "Phong Exponent", "Shininess value", NumericRange { min: 1.0, max: 255.0, step: Some(1.0), default: Some(5.0) }).with_category("Phong"))
            .with_param(ParameterDef::float("$phongboost", "Phong Boost", "Phong brightness", NumericRange { min: 0.0, max: 100.0, step: Some(0.1), default: Some(1.0) }).with_category("Phong"))
            .with_param(ParameterDef::color("$phongtint", "Phong Tint", "Phong highlight color").with_category("Phong"))
            .with_param(ParameterDef::texture("$phongexponenttexture", "Phong Exponent Texture", "Per-pixel shininess").with_category("Phong"))
            .with_param(ParameterDef::vector3("$phongfresnelranges", "Phong Fresnel Ranges", "Fresnel parameters").with_category("Phong"))
            .with_param(ParameterDef::boolean("$phongalbedotint", "Phong Albedo Tint", "Tint phong by albedo", false).with_category("Phong"))
            .with_param(ParameterDef::boolean("$basemapalphaphongmask", "Basemap Alpha Phong Mask", "Use base alpha as phong mask", false).with_category("Phong"))
            // Reflections
            .with_param(ParameterDef::texture("$envmap", "Environment Map", "Cubemap for reflections").with_category("Reflections"))
            .with_param(ParameterDef::texture("$envmapmask", "Envmap Mask", "Mask for reflections").with_category("Reflections"))
            .with_param(ParameterDef::color("$envmaptint", "Envmap Tint", "Reflection color tint").with_category("Reflections"))
            .with_param(ParameterDef::float("$envmapcontrast", "Envmap Contrast", "Reflection contrast", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.0) }).with_category("Reflections"))
            .with_param(ParameterDef::float("$envmapsaturation", "Envmap Saturation", "Reflection saturation", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Reflections"))
            .with_param(ParameterDef::boolean("$basealphaenvmapmask", "Base Alpha Envmap Mask", "Use base alpha as envmap mask", false).with_category("Reflections"))
            .with_param(ParameterDef::boolean("$normalmapalphaenvmapmask", "Normal Alpha Envmap Mask", "Use normal alpha as envmap mask", false).with_category("Reflections"))
            // Rim Lighting
            .with_param(ParameterDef::boolean("$rimlight", "Rim Light", "Enable rim lighting", false).with_category("Rim Light"))
            .with_param(ParameterDef::float("$rimlightexponent", "Rim Light Exponent", "Rim light falloff", NumericRange { min: 0.0, max: 50.0, step: Some(0.1), default: Some(4.0) }).with_category("Rim Light"))
            .with_param(ParameterDef::float("$rimlightboost", "Rim Light Boost", "Rim light brightness", NumericRange { min: 0.0, max: 10.0, step: Some(0.1), default: Some(1.0) }).with_category("Rim Light"))
            .with_param(ParameterDef::boolean("$rimmask", "Rim Mask", "Use phong mask for rim", false).with_category("Rim Light"))
            // Self Illumination
            .with_param(ParameterDef::boolean("$selfillum", "Self Illumination", "Enable self-illumination", false).with_category("Self Illumination"))
            .with_param(ParameterDef::texture("$selfillummask", "Self Illum Mask", "Self-illumination mask").with_category("Self Illumination"))
            .with_param(ParameterDef::color("$selfillumtint", "Self Illum Tint", "Self-illumination color").with_category("Self Illumination"))
            .with_param(ParameterDef::boolean("$selfillumfresnel", "Self Illum Fresnel", "Fresnel self-illumination", false).with_category("Self Illumination"))
            .with_param(ParameterDef::vector3("$selfillumfresnelminmaxexp", "Self Illum Fresnel Params", "Fresnel min/max/exp").with_category("Self Illumination"))
            // Detail Texture
            .with_param(ParameterDef::texture("$detail", "Detail Texture", "Detail texture").with_category("Detail"))
            .with_param(ParameterDef::float("$detailscale", "Detail Scale", "Detail texture tiling", NumericRange { min: 0.1, max: 100.0, step: Some(0.1), default: Some(4.0) }).with_category("Detail"))
            .with_param(ParameterDef::int("$detailblendmode", "Detail Blend Mode", "How detail blends", 0, 12, 0).with_category("Detail"))
            .with_param(ParameterDef::float("$detailblendfactor", "Detail Blend Factor", "Detail blend strength", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Detail"))
            // Lighting
            .with_param(ParameterDef::texture("$lightwarptexture", "Lightwarp Texture", "Texture for light warping").with_category("Lighting"))
            .with_param(ParameterDef::boolean("$halflambert", "Half Lambert", "Use half-lambert lighting", false).with_category("Lighting"))
            // Rendering Options
            .with_param(ParameterDef::boolean("$nocull", "No Cull", "Disable backface culling", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$nodecal", "No Decal", "Prevent decals", false).with_category("Rendering"))
            // Transforms
            .with_param(ParameterDef::transform("$basetexturetransform", "Base Texture Transform", "UV transform").with_category("Transforms"))
            .with_param(ParameterDef::transform("$bumptransform", "Bump Transform", "Bump UV transform").with_category("Transforms"))
            // Misc
            .with_param(ParameterDef::color("$color2", "Color 2", "Secondary color").with_category("Misc")),

        ShaderDef::new("UnlitGeneric", "Unlit Generic", "Unlit shader for UI elements and sprites")
            // Basics
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Primary texture").required().with_category("Basics"))
            .with_param(ParameterDef::color("$color", "Color", "Color tint").with_category("Basics"))
            .with_param(ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Basics"))
            // Transparency
            .with_param(ParameterDef::boolean("$translucent", "Translucent", "Enable alpha blending", false).with_category("Transparency"))
            .with_param(ParameterDef::boolean("$alphatest", "Alpha Test", "Enable alpha testing", false).with_category("Transparency"))
            .with_param(ParameterDef::float("$alphatestreference", "Alpha Test Reference", "Alpha test threshold", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.5) }).with_category("Transparency"))
            .with_param(ParameterDef::boolean("$additive", "Additive", "Additive blending", false).with_category("Transparency"))
            // Rendering Options
            .with_param(ParameterDef::boolean("$nocull", "No Cull", "Disable backface culling", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$ignorez", "Ignore Z", "Ignore depth buffer", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$nofog", "No Fog", "Disable fog", false).with_category("Rendering"))
            // Animation
            .with_param(ParameterDef::int("$frame", "Frame", "Animation frame", 0, 999, 0).with_category("Animation"))
            // Transforms
            .with_param(ParameterDef::transform("$basetexturetransform", "Base Texture Transform", "UV transform").with_category("Transforms")),

        ShaderDef::new("UnlitTwoTexture", "Unlit Two Texture", "Unlit shader with two textures")
            // Basics
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Primary texture").required().with_category("Basics"))
            .with_param(ParameterDef::texture("$texture2", "Texture 2", "Secondary texture").with_category("Basics"))
            .with_param(ParameterDef::color("$color", "Color", "Color tint").with_category("Basics"))
            .with_param(ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Basics"))
            // Transparency
            .with_param(ParameterDef::boolean("$translucent", "Translucent", "Enable alpha blending", false).with_category("Transparency"))
            .with_param(ParameterDef::boolean("$additive", "Additive", "Additive blending", false).with_category("Transparency")),

        ShaderDef::new("WorldVertexTransition", "World Vertex Transition", "Shader for terrain blending between two textures")
            // Basics
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Primary texture").required().with_category("Basics"))
            .with_param(ParameterDef::texture("$basetexture2", "Base Texture 2", "Secondary texture for blending").required().with_category("Basics"))
            .with_param(ParameterDef::string("$surfaceprop", "Surface Prop", "Primary surface property").with_category("Basics"))
            .with_param(ParameterDef::string("$surfaceprop2", "Surface Prop 2", "Secondary surface property").with_category("Basics"))
            // Bump Maps
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", "Normal map").with_category("Bump Maps"))
            .with_param(ParameterDef::texture("$bumpmap2", "Bump Map 2", "Secondary normal map").with_category("Bump Maps"))
            // Detail
            .with_param(ParameterDef::texture("$detail", "Detail Texture", "Detail texture").with_category("Detail"))
            .with_param(ParameterDef::float("$detailscale", "Detail Scale", "Detail tiling", NumericRange { min: 0.1, max: 100.0, step: Some(0.1), default: Some(4.0) }).with_category("Detail"))
            // Reflections
            .with_param(ParameterDef::texture("$envmap", "Environment Map", "Cubemap for reflections").with_category("Reflections"))
            .with_param(ParameterDef::color("$envmaptint", "Envmap Tint", "Reflection tint").with_category("Reflections")),

        ShaderDef::new("Water", "Water", "Shader for water surfaces")
            // Basics
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", "Water normal map").required().with_category("Basics"))
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", "Alternative for normal map").with_category("Basics"))
            .with_param(ParameterDef::boolean("$abovewater", "Above Water", "Camera is above water", true).with_category("Basics"))
            // Reflection
            .with_param(ParameterDef::float("$reflectamount", "Reflect Amount", "Reflection strength", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.8) }).with_category("Reflection"))
            .with_param(ParameterDef::color("$reflecttint", "Reflect Tint", "Reflection color tint").with_category("Reflection"))
            // Refraction
            .with_param(ParameterDef::float("$refractamount", "Refract Amount", "Refraction strength", NumericRange { min: 0.0, max: 2.0, step: Some(0.01), default: Some(0.0) }).with_category("Refraction"))
            .with_param(ParameterDef::color("$refracttint", "Refract Tint", "Refraction color tint").with_category("Refraction"))
            // Fog
            .with_param(ParameterDef::color("$fogcolor", "Fog Color", "Underwater fog color").with_category("Fog"))
            .with_param(ParameterDef::float("$fogstart", "Fog Start", "Fog start distance", NumericRange { min: 0.0, max: 10000.0, step: Some(1.0), default: Some(0.0) }).with_category("Fog"))
            .with_param(ParameterDef::float("$fogend", "Fog End", "Fog end distance", NumericRange { min: 0.0, max: 10000.0, step: Some(1.0), default: Some(2000.0) }).with_category("Fog"))
            // Animation
            .with_param(ParameterDef::float("$scroll1", "Scroll 1", "First scroll speed", NumericRange::default()).with_category("Animation"))
            .with_param(ParameterDef::float("$scroll2", "Scroll 2", "Second scroll speed", NumericRange::default()).with_category("Animation"))
            // Performance
            .with_param(ParameterDef::boolean("$cheap", "Cheap", "Use cheap water rendering", false).with_category("Performance"))
            .with_param(ParameterDef::boolean("$expensive", "Expensive", "Use expensive water", false).with_category("Performance")),

        ShaderDef::new("Refract", "Refract", "Shader for refractive surfaces like glass")
            // Basics
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", "Refraction normal map").required().with_category("Basics"))
            .with_param(ParameterDef::float("$refractamount", "Refract Amount", "Refraction strength", NumericRange { min: 0.0, max: 2.0, step: Some(0.01), default: Some(0.2) }).with_category("Basics"))
            .with_param(ParameterDef::color("$refracttint", "Refract Tint", "Refraction color tint").with_category("Basics"))
            // Effects
            .with_param(ParameterDef::float("$bluramount", "Blur Amount", "Blur strength", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(0.0) }).with_category("Effects"))
            .with_param(ParameterDef::boolean("$vertexcolor", "Vertex Color", "Use vertex colors", false).with_category("Effects")),

        ShaderDef::new("Sprite", "Sprite", "Shader for sprite effects")
            // Basics
            .with_param(ParameterDef::texture("$spritesheet", "Sprite Sheet", "Sprite texture").required().with_category("Basics"))
            .with_param(ParameterDef::color("$color", "Color", "Color tint").with_category("Basics"))
            .with_param(ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange { min: 0.0, max: 1.0, step: Some(0.01), default: Some(1.0) }).with_category("Basics"))
            // Rendering
            .with_param(ParameterDef::int("$spriteorientation", "Orientation", "Sprite orientation mode", 0, 3, 0).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$additive", "Additive", "Additive blending", false).with_category("Rendering")),

        ShaderDef::new("SpriteCard", "Sprite Card", "Shader for particle sprites")
            // Basics
            .with_param(ParameterDef::texture("$basetexture", "Base Texture", "Sprite texture").required().with_category("Basics"))
            // Rendering
            .with_param(ParameterDef::boolean("$additive", "Additive", "Additive blending", false).with_category("Rendering"))
            .with_param(ParameterDef::boolean("$translucent", "Translucent", "Enable alpha", false).with_category("Rendering"))
            .with_param(ParameterDef::int("$orientation", "Orientation", "Orientation mode", 0, 3, 0).with_category("Rendering")),

        // Now the rest of the existing shaders...
        ShaderDef::new("Aftershock", "Aftershock", "Aftershock shader")
            .with_param(ParameterDef::float(
                "$bluramount",
                "Blur Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::transform(
                "$bumptransform",
                "Bump Transform",
                "",
            ))
            .with_param(ParameterDef::color("$colortint", "Color Tint", ""))
            .with_param(ParameterDef::float(
                "$groundmax",
                "Ground Max",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$groundmin",
                "Ground Min",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::float(
                "$refractamount",
                "Refract Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::color(
                "$silhouettecolor",
                "Silhouette Color",
                "",
            ))
            .with_param(ParameterDef::float(
                "$silhouettethickness",
                "Silhouette Thickness",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float("$time", "Time", "", NumericRange::default())),
        ShaderDef::new("Bik", "Bik", "Bik movie shader")
            .with_param(ParameterDef::texture("$cbtexture", "Cb Texture", ""))
            .with_param(ParameterDef::texture("$crtexture", "Cr Texture", ""))
            .with_param(ParameterDef::texture("$ytexture", "Y Texture", "")),
        ShaderDef::new("Blob", "Blob", "Blob shader")
            .with_param(ParameterDef::boolean(
                "$animatearmpulses",
                "Animate Arm Pulses",
                "",
                true,
            ))
            .with_param(ParameterDef::boolean("$armature", "Armature", "", false))
            .with_param(ParameterDef::vector3("$armcolor", "Arm Color", ""))
            .with_param(ParameterDef::boolean("$armwiden", "Arm Widen", "", false))
            .with_param(ParameterDef::float(
                "$armwidthbias",
                "Arm Width Bias",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$armwidthexp",
                "Arm Width Exp",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$armwidthscale",
                "Arm Width Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$backsurface", "Back Surface", "", false))
            .with_param(ParameterDef::vector3(
                "$basecolortint",
                "Base Color Tint",
                "",
            ))
            .with_param(ParameterDef::vector3("$bbmax", "BB Max", ""))
            .with_param(ParameterDef::vector3("$bbmin", "BB Min", ""))
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::float(
                "$bumpstrength",
                "Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$contactshadows",
                "Contact Shadows",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$diffuseboost",
                "Diffuse Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$fresnelbumpstrength",
                "Fresnel Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$fresnelwarptexture",
                "Fresnel Warp Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$glowscale",
                "Glow Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$interior", "Interior", "", true))
            .with_param(ParameterDef::float(
                "$interiorambientscale",
                "Interior Ambient Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbackgroundboost",
                "Interior Background Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbacklightscale",
                "Interior Backlight Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$interiorcolor", "Interior Color", ""))
            .with_param(ParameterDef::float(
                "$interiorfoglimit",
                "Interior Fog Limit",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorfognormalboost",
                "Interior Fog Normal Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorfogstrength",
                "Interior Fog Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractblur",
                "Interior Refract Blur",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractstrength",
                "Interior Refract Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$lightwarptexture",
                "Lightwarp Texture",
                "",
            ))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::texture("$opacitytexture", "Opacity Texture", ""))
            .with_param(ParameterDef::float(
                "$phongboost",
                "Phong Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongboost2",
                "Phong Boost 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent",
                "Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent2",
                "Phong Exponent 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$pulse", "Pulse", "", true))
            .with_param(ParameterDef::float(
                "$rimlightboost",
                "Rimlight Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightexponent",
                "Rimlight Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$selfillumfresnel",
                "Self Illum Fresnel",
                "",
                false,
            ))
            .with_param(ParameterDef::vector3(
                "$selfillumfresnelminmaxexp",
                "Self Illum Fresnel Min Max Exp",
                "",
            ))
            .with_param(ParameterDef::vector3("$selfillumtint", "Self Illum Tint", ""))
            .with_param(ParameterDef::texture("$specmasktexture", "Specmask Texture", ""))
            .with_param(ParameterDef::vector3(
                "$translucentfresnelminmaxexp",
                "Translucent Fresnel Min Max Exp",
                "",
            ))
            .with_param(ParameterDef::vector3("$uvprojoffset", "UV Proj Offset", ""))
            .with_param(ParameterDef::float(
                "$uvscale",
                "UV Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$volumetexturetest",
                "Volume Texture Test",
                "",
                true,
            )),
        ShaderDef::new(
            "BufferClearObeyStencil",
            "BufferClearObeyStencil",
            "BufferClearObeyStencil shader",
        )
        .with_param(ParameterDef::float(
            "$clearalpha",
            "Clear Alpha",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$clearcolor",
            "Clear Color",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$cleardepth",
            "Clear Depth",
            "",
            NumericRange::default(),
        )),
        ShaderDef::new("Cable", "Cable", "Cable shader")
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", ""))
            .with_param(ParameterDef::float(
                "$maxlight",
                "Max Light",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$minlight",
                "Min Light",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new("Cloak", "Cloak", "Cloak shader")
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::transform(
                "$bumptransform",
                "Bump Transform",
                "",
            ))
            .with_param(ParameterDef::float(
                "$cloakfactor",
                "Cloak Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$fresnelreflection",
                "Fresnel Reflection",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$lightwarptexture",
                "Lightwarp Texture",
                "",
            ))
            .with_param(ParameterDef::boolean("$masked", "Masked", "", false))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::int("$nowritez", "No Write Z", "", 0, 0, 0))
            .with_param(ParameterDef::boolean(
                "$phongalbedotint",
                "Phong Albedo Tint",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$phongboost",
                "Phong Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent",
                "Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$phongexponenttexture",
                "Phong Exponent Texture",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$phongfresnelranges",
                "Phong Fresnel Ranges",
                "",
            ))
            .with_param(ParameterDef::vector3("$phongtint", "Phong Tint", ""))
            .with_param(ParameterDef::float(
                "$refractamount",
                "Refract Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::color("$refracttint", "Refract Tint", ""))
            .with_param(ParameterDef::texture(
                "$refracttinttexture",
                "Refract Tint Texture",
                "",
            ))
            .with_param(ParameterDef::int(
                "$refracttinttextureframe",
                "Refract Tint Texture Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::boolean("$rimlight", "Rimlight", "", false))
            .with_param(ParameterDef::float(
                "$rimlightboost",
                "Rimlight Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightexponent",
                "Rimlight Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$rimmask", "Rim Mask", "", false))
            .with_param(ParameterDef::float("$time", "Time", "", NumericRange::default())),
        ShaderDef::new("CustomHero", "CustomHero", "CustomHero shader")
            .with_param(ParameterDef::boolean(
                "$allowdiffusemodulation",
                "Allow Diffuse Modulation",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$ambientscale",
                "Ambient Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::texture("$bumpmap", "Bump Map", ""))
            .with_param(ParameterDef::transform(
                "$bumptransform",
                "Bump Transform",
                "",
            ))
            .with_param(ParameterDef::color("$cloakcolortint", "Cloak Color Tint", ""))
            .with_param(ParameterDef::float(
                "$cloakfactor",
                "Cloak Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$cloakintensity",
                "Cloak Intensity",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$cloakpassenabled",
                "Cloak Pass Enabled",
                "",
                false,
            ))
            .with_param(ParameterDef::texture("$colorwarp", "Color Warp", ""))
            .with_param(ParameterDef::float(
                "$colorwarpintensity",
                "Color Warp Intensity",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$detail1", "Detail 1", ""))
            .with_param(ParameterDef::float(
                "$detail1blendfactor",
                "Detail 1 Blend Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$detail1blendmode",
                "Detail 1 Blend Mode",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$detail1blendtofull",
                "Detail 1 Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$detail1frame",
                "Detail 1 Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$detail1scale",
                "Detail 1 Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::transform(
                "$detail1texturetransform",
                "Detail 1 Texture Transform",
                "",
            ))
            .with_param(ParameterDef::texture("$detail2", "Detail 2", ""))
            .with_param(ParameterDef::float(
                "$detail2blendfactor",
                "Detail 2 Blend Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$detail2blendmode",
                "Detail 2 Blend Mode",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::int(
                "$detail2frame",
                "Detail 2 Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$detail2scale",
                "Detail 2 Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::transform(
                "$detail2texturetransform",
                "Detail 2 Texture Transform",
                "",
            ))
            .with_param(ParameterDef::float(
                "$diffusenormalmapbias",
                "Diffuse Normal Map Bias",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$diffusewarp", "Diffuse Warp", ""))
            .with_param(ParameterDef::float(
                "$diffusewarpblendtofull",
                "Diffuse Warp Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$envmap", "Envmap", ""))
            .with_param(ParameterDef::float(
                "$envmapintensity",
                "Envmap Intensity",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$fresnelcolorwarp",
                "Fresnel Color Warp",
                "",
            ))
            .with_param(ParameterDef::float(
                "$fresnelcolorwarpblendtofull",
                "Fresnel Color Warp Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$fresnelwarp", "Fresnel Warp", ""))
            .with_param(ParameterDef::boolean(
                "$maskenvbymetalness",
                "Mask Env By Metalness",
                "",
                false,
            ))
            .with_param(ParameterDef::texture("$maskmap1", "Mask Map 1", ""))
            .with_param(ParameterDef::texture("$maskmap2", "Mask Map 2", ""))
            .with_param(ParameterDef::float(
                "$metalnessblendtofull",
                "Metalness Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::int(
                "$normalmapframe",
                "Normal Map Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$reflectionstintbybaseblendtonone",
                "Reflections Tint By Base Blend To None",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$refractamount",
                "Refract Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightblendtofull",
                "Rimlight Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$rimlightcolor", "Rimlight Color", ""))
            .with_param(ParameterDef::float(
                "$rimlightscale",
                "Rimlight Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$selfillumblendtofull",
                "Self Illum Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$specularblendtofull",
                "Specular Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$specularcolor", "Specular Color", ""))
            .with_param(ParameterDef::float(
                "$specularexponent",
                "Specular Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$specularexponentblendtofull",
                "Specular Exponent Blend To Full",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$specularscale",
                "Specular Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$specularwarp", "Specular Warp", "")),
        ShaderDef::new(
            "DebugTangentSpace",
            "DebugTangentSpace",
            "DebugTangentSpace shader",
        ),
        ShaderDef::new(
            "DebugTextureView",
            "DebugTextureView",
            "DebugTextureView shader",
        )
        .with_param(ParameterDef::boolean("$showalpha", "Show Alpha", "", false)),
        ShaderDef::new("DecalModulate", "DecalModulate", "DecalModulate shader")
            .with_param(ParameterDef::float(
                "$fogexponent",
                "Fog Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$fogscale",
                "Fog Scale",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new(
            "deferred_global_light",
            "deferred_global_light",
            "deferred_global_light shader",
        )
        .with_param(ParameterDef::texture("$depth_texture", "Depth Texture", ""))
        .with_param(ParameterDef::texture("$diffuse_texture", "Diffuse Texture", ""))
        .with_param(ParameterDef::texture("$normal_texture", "Normal Texture", ""))
        .with_param(ParameterDef::texture(
            "$specular_texture",
            "Specular Texture",
            "",
        )),
        ShaderDef::new(
            "deferred_post_process",
            "deferred_post_process",
            "deferred_post_process shader",
        )
        .with_param(ParameterDef::int(
            "$debug_shader",
            "Debug Shader",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::texture("$depth_texture", "Depth Texture", ""))
        .with_param(ParameterDef::texture("$diffuse_texture", "Diffuse Texture", ""))
        .with_param(ParameterDef::texture("$fow", "Fow", ""))
        .with_param(ParameterDef::float(
            "$fow_color_factor",
            "Fow Color Factor",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_darkness",
            "Fow Darkness",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_gray_factor",
            "Fow Gray Factor",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_gray_hilights",
            "Fow Gray Hilights",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_height_adjustment",
            "Fow Height Adjustment",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::color("$fow_height_color", "Fow Height Color", ""))
        .with_param(ParameterDef::float(
            "$fow_height_scale",
            "Fow Height Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_height_scale_1",
            "Fow Height Scale 1",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$fow_height_scale_2",
            "Fow Height Scale 2",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::vector4(
            "$fow_height_scroll",
            "Fow Height Scroll",
            "",
        ))
        .with_param(ParameterDef::texture(
            "$fow_height_texture",
            "Fow Height Texture",
            "",
        ))
        .with_param(ParameterDef::float(
            "$fow_height_world_scale",
            "Fow Height World Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$frame_texture", "Frame Texture", ""))
        .with_param(ParameterDef::texture("$normal_texture", "Normal Texture", ""))
        .with_param(ParameterDef::texture(
            "$specular_texture",
            "Specular Texture",
            "",
        ))
        .with_param(ParameterDef::float(
            "$ssao_intensity",
            "Ssao Intensity",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$ssao_texture", "Ssao Texture", ""))
        .with_param(ParameterDef::color("$ssao_tint", "Ssao Tint", "")),
        ShaderDef::new(
            "deferred_simple_light",
            "deferred_simple_light",
            "deferred_simple_light shader",
        )
        .with_param(ParameterDef::texture("$depth_texture", "Depth Texture", ""))
        .with_param(ParameterDef::texture("$diffuse_texture", "Diffuse Texture", ""))
        .with_param(ParameterDef::texture("$normal_texture", "Normal Texture", ""))
        .with_param(ParameterDef::texture(
            "$specular_texture",
            "Specular Texture",
            "",
        ))
        .with_param(ParameterDef::boolean("$subtractive", "Subtractive", "", false)),
        ShaderDef::new(
            "deferred_specular_bloom",
            "deferred_specular_bloom",
            "deferred_specular_bloom shader",
        )
        .with_param(ParameterDef::int(
            "$debug_shader",
            "Debug Shader",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::texture("$depth_texture", "Depth Texture", ""))
        .with_param(ParameterDef::texture("$diffuse_texture", "Diffuse Texture", ""))
        .with_param(ParameterDef::texture("$frame_texture", "Frame Texture", ""))
        .with_param(ParameterDef::texture("$normal_texture", "Normal Texture", ""))
        .with_param(ParameterDef::float(
            "$specular_bloom_scale",
            "Specular Bloom Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture(
            "$specular_texture",
            "Specular Texture",
            "",
        ))
        .with_param(ParameterDef::texture("$ssao_texture", "Ssao Texture", ""))
        .with_param(ParameterDef::boolean("$subtractive", "Subtractive", "", false)),
        ShaderDef::new("deferred_unlit", "deferred_unlit", "deferred_unlit shader")
            .with_param(ParameterDef::int(
                "$deferred_additive",
                "Deferred Additive",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::texture("$depth_texture", "Depth Texture", ""))
            .with_param(ParameterDef::texture("$diffuse_texture", "Diffuse Texture", ""))
            .with_param(ParameterDef::texture("$normal_texture", "Normal Texture", ""))
            .with_param(ParameterDef::texture(
                "$specular_texture",
                "Specular Texture",
                "",
            )),
        ShaderDef::new("DepthOfField", "DepthOfField", "DepthOfField shader")
            .with_param(ParameterDef::float(
                "$farblurdepth",
                "Far Blur Depth",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$farblurradius",
                "Far Blur Radius",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$farfocusdepth",
                "Far Focus Depth",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$farplane",
                "Far Plane",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$nearblurdepth",
                "Near Blur Depth",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$nearblurradius",
                "Near Blur Radius",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$nearfocusdepth",
                "Near Focus Depth",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$nearplane",
                "Near Plane",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int("$quality", "Quality", "", 0, 0, 0))
            .with_param(ParameterDef::texture("$smallfb", "Small FB", "")),
        ShaderDef::new("Engine_Post", "Engine_Post", "Engine_Post shader")
            .with_param(ParameterDef::boolean("$aaenable", "AA Enable", "", false))
            .with_param(ParameterDef::vector4("$aainternal1", "AA Internal 1", ""))
            .with_param(ParameterDef::vector4("$aainternal2", "AA Internal 2", ""))
            .with_param(ParameterDef::vector4("$aainternal3", "AA Internal 3", ""))
            .with_param(ParameterDef::boolean(
                "$allowlocalcontrast",
                "Allow Local Contrast",
                "",
                false,
            ))
            .with_param(ParameterDef::boolean("$allownoise", "Allow Noise", "", false))
            .with_param(ParameterDef::boolean(
                "$allowvignette",
                "Allow Vignette",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$bloomamount",
                "Bloom Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$bloomenable", "Bloom Enable", "", true))
            .with_param(ParameterDef::boolean(
                "$blurredvignetteenable",
                "Blurred Vignette Enable",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$blurredvignettescale",
                "Blurred Vignette Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$depthblurenable",
                "Depth Blur Enable",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$depthblurfocaldistance",
                "Depth Blur Focal Distance",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$depthblurstrength",
                "Depth Blur Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$desaturateenable",
                "Desaturate Enable",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$desaturation",
                "Desaturation",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int("$fade", "Fade", "", 0, 0, 0))
            .with_param(ParameterDef::vector4("$fadecolor", "Fade Color", ""))
            .with_param(ParameterDef::float(
                "$fadetoblackscale",
                "Fade To Black Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$fbtexture", "FB Texture", ""))
            .with_param(ParameterDef::texture(
                "$internal_vignettetexture",
                "Internal Vignette Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$localcontrastedgescale",
                "Local Contrast Edge Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$localcontrastenable",
                "Local Contrast Enable",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$localcontrastmidtonemask",
                "Local Contrast Midtone Mask",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$localcontrastscale",
                "Local Contrast Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$localcontrastvignetteend",
                "Local Contrast Vignette End",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$localcontrastvignettestart",
                "Local Contrast Vignette Start",
                "",
                false,
            ))
            .with_param(ParameterDef::boolean("$noiseenable", "Noise Enable", "", false))
            .with_param(ParameterDef::float(
                "$noisescale",
                "Noise Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$noisetexture", "Noise Texture", ""))
            .with_param(ParameterDef::float(
                "$num_lookups",
                "Num Lookups",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$screenblurstrength",
                "Screen Blur Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$screeneffecttexture",
                "Screen Effect Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$toolcolorcorrection",
                "Tool Color Correction",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$toolmode", "Tool Mode", "", false))
            .with_param(ParameterDef::float(
                "$tooltime",
                "Tool Time",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int("$tv_gamma", "TV Gamma", "", 0, 0, 0))
            .with_param(ParameterDef::boolean(
                "$vignetteenable",
                "Vignette Enable",
                "",
                false,
            ))
            .with_param(ParameterDef::vector3("$vomitcolor1", "Vomit Color 1", ""))
            .with_param(ParameterDef::vector3("$vomitcolor2", "Vomit Color 2", ""))
            .with_param(ParameterDef::boolean("$vomitenable", "Vomit Enable", "", false))
            .with_param(ParameterDef::float(
                "$vomitrefractscale",
                "Vomit Refract Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$weight0",
                "Weight 0",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$weight1",
                "Weight 1",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$weight2",
                "Weight 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$weight3",
                "Weight 3",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$weight_default",
                "Weight Default",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new("EyeGlint", "EyeGlint", "EyeGlint shader"),
        ShaderDef::new("EyeRefract", "EyeRefract", "EyeRefract shader")
            .with_param(ParameterDef::vector3(
                "$ambientocclcolor",
                "Ambient Occl Color",
                "",
            ))
            .with_param(ParameterDef::texture(
                "$ambientoccltexture",
                "Ambient Occl Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$ambientocclusion",
                "Ambient Occlusion",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::color("$cloakcolortint", "Cloak Color Tint", ""))
            .with_param(ParameterDef::float(
                "$cloakfactor",
                "Cloak Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$cloakpassenabled",
                "Cloak Pass Enabled",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$corneabumpstrength",
                "Cornea Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$corneatexture", "Cornea Texture", ""))
            .with_param(ParameterDef::float(
                "$dilation",
                "Dilation",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$emissiveblendenabled",
                "Emissive Blend Enabled",
                "",
                false,
            ))
            .with_param(ParameterDef::texture(
                "$emissiveblendflowtexture",
                "Emissive Blend Flow Texture",
                "",
            ))
            .with_param(ParameterDef::vector2(
                "$emissiveblendscrollvector",
                "Emissive Blend Scroll Vector",
                "",
            ))
            .with_param(ParameterDef::float(
                "$emissiveblendstrength",
                "Emissive Blend Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$emissiveblendtexture",
                "Emissive Blend Texture",
                "",
            ))
            .with_param(ParameterDef::color(
                "$emissiveblendtint",
                "Emissive Blend Tint",
                "",
            ))
            .with_param(ParameterDef::vector3("$entityorigin", "Entity Origin", ""))
            .with_param(ParameterDef::texture("$envmap", "Envmap", ""))
            .with_param(ParameterDef::float(
                "$eyeballradius",
                "Eyeball Radius",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$eyeorigin", "Eye Origin", ""))
            .with_param(ParameterDef::float(
                "$glossiness",
                "Glossiness",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$intro", "Intro", "", false))
            .with_param(ParameterDef::texture("$iris", "Iris", ""))
            .with_param(ParameterDef::int("$irisframe", "Iris Frame", "", 0, 0, 0))
            .with_param(ParameterDef::vector4("$irisu", "Iris U", ""))
            .with_param(ParameterDef::vector4("$irisv", "Iris V", ""))
            .with_param(ParameterDef::texture(
                "$lightwarptexture",
                "Lightwarp Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$parallaxstrength",
                "Parallax Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$raytracesphere",
                "Raytrace Sphere",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$refractamount",
                "Refract Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$spheretexkillcombo",
                "Sphere Texkill Combo",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$warpparam",
                "Warp Param",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new("eyes", "eyes", "eyes shader")
            .with_param(ParameterDef::float(
                "$dilation",
                "Dilation",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$entityorigin", "Entity Origin", ""))
            .with_param(ParameterDef::vector3("$eyeorigin", "Eye Origin", ""))
            .with_param(ParameterDef::vector3("$eyeup", "Eye Up", ""))
            .with_param(ParameterDef::texture("$glint", "Glint", ""))
            .with_param(ParameterDef::vector4("$glintu", "Glint U", ""))
            .with_param(ParameterDef::vector4("$glintv", "Glint V", ""))
            .with_param(ParameterDef::boolean("$intro", "Intro", "", false))
            .with_param(ParameterDef::texture("$iris", "Iris", ""))
            .with_param(ParameterDef::int("$irisframe", "Iris Frame", "", 0, 0, 0))
            .with_param(ParameterDef::vector4("$irisu", "Iris U", ""))
            .with_param(ParameterDef::vector4("$irisv", "Iris V", ""))
            .with_param(ParameterDef::float(
                "$warpparam",
                "Warp Param",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new("Flesh", "Flesh", "Flesh shader")
            .with_param(ParameterDef::float(
                "$ambientboost",
                "Ambient Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$ambientboostmaskmode",
                "Ambient Boost Mask Mode",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$backscatter",
                "Backscatter",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$bbmax", "BB Max", ""))
            .with_param(ParameterDef::vector3("$bbmin", "BB Min", ""))
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::float(
                "$bumpstrength",
                "Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$colorwarptexture", "Color Warp Texture", ""))
            .with_param(ParameterDef::texture("$detail", "Detail", ""))
            .with_param(ParameterDef::float(
                "$detailblendfactor",
                "Detail Blend Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$detailblendmode",
                "Detail Blend Mode",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::int(
                "$detailframe",
                "Detail Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$detailscale",
                "Detail Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::transform(
                "$detailtexturetransform",
                "Detail Texture Transform",
                "",
            ))
            .with_param(ParameterDef::float(
                "$diffuseexponent",
                "Diffuse Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$diffusesoftnormal",
                "Diffuse Soft Normal",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$effectmaskstexture",
                "Effect Masks Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$forwardscatter",
                "Forward Scatter",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$fresnelbumpstrength",
                "Fresnel Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$fresnelcolorwarptexture",
                "Fresnel Color Warp Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$hueshiftfresnelexponent",
                "Hueshift Fresnel Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$hueshiftintensity",
                "Hueshift Intensity",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$interior", "Interior", "", true))
            .with_param(ParameterDef::float(
                "$interiorambientscale",
                "Interior Ambient Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbackgroundboost",
                "Interior Background Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbacklightscale",
                "Interior Backlight Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$interiorcolor", "Interior Color", ""))
            .with_param(ParameterDef::float(
                "$interiorfogstrength",
                "Interior Fog Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractblur",
                "Interior Refract Blur",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractstrength",
                "Interior Refract Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$iridescenceboost",
                "Iridescence Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$iridescenceexponent",
                "Iridescence Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$iridescentwarp", "Iridescent Warp", ""))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::float(
                "$normal2softness",
                "Normal 2 Softness",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$opacitytexture", "Opacity Texture", ""))
            .with_param(ParameterDef::vector3(
                "$phongcolortint",
                "Phong Color Tint",
                "",
            ))
            .with_param(ParameterDef::float(
                "$phongexponent",
                "Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent2",
                "Phong Exponent 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$phongfresnel", "Phong Fresnel", ""))
            .with_param(ParameterDef::vector3("$phongfresnel2", "Phong Fresnel 2", ""))
            .with_param(ParameterDef::float(
                "$phongscale",
                "Phong Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongscale2",
                "Phong Scale 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phong2softness",
                "Phong 2 Softness",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightexponent",
                "Rimlight Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightscale",
                "Rimlight Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$selfillumtint", "Self Illum Tint", ""))
            .with_param(ParameterDef::float(
                "$ssbentnormalintensity",
                "Ss Bent Normal Intensity",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$sscolortint", "Ss Color Tint", ""))
            .with_param(ParameterDef::float(
                "$ssdepth",
                "Ss Depth",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$sstintbyalbedo",
                "Ss Tint By Albedo",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3(
                "$translucentfresnelminmaxexp",
                "Translucent Fresnel Min Max Exp",
                "",
            ))
            .with_param(ParameterDef::texture(
                "$transmatmaskstexture",
                "Transmat Masks Texture",
                "",
            ))
            .with_param(ParameterDef::vector3("$uvprojoffset", "UV Proj Offset", ""))
            .with_param(ParameterDef::float(
                "$uvscale",
                "UV Scale",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new(
            "floatcombine_autoexpose",
            "floatcombine_autoexpose",
            "floatcombine_autoexpose shader",
        )
        .with_param(ParameterDef::float(
            "$alphasharpenfactor",
            "Alpha Sharpen Factor",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$autoexpose_max",
            "Autoexpose Max",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$autoexpose_min",
            "Autoexpose Min",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$bloomamount",
            "Bloom Amount",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$bloomexponent",
            "Bloom Exponent",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$bloomtexture", "Bloom Texture", ""))
        .with_param(ParameterDef::float(
            "$edge_softness",
            "Edge Softness",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$exposure_texture", "Exposure Texture", ""))
        .with_param(ParameterDef::float(
            "$sharpness",
            "Sharpness",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$vignette_min_bright",
            "Vignette Min Bright",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$vignette_power",
            "Vignette Power",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$woodcut",
            "Woodcut",
            "",
            NumericRange::default(),
        )),
        ShaderDef::new(
            "GlobalLitSimple",
            "GlobalLitSimple",
            "GlobalLitSimple shader",
        )
        .with_param(ParameterDef::texture("$fow", "Fow", ""))
        .with_param(ParameterDef::boolean("$mod2x", "Mod 2x", "", false))
        .with_param(ParameterDef::vector2(
            "$scroll_uv_direction",
            "Scroll UV Direction",
            "",
        ))
        .with_param(ParameterDef::float(
            "$scroll_uv_scale",
            "Scroll UV Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$spectexture", "Spec Texture", ""))
        .with_param(ParameterDef::float(
            "$specular_bloom",
            "Specular Bloom",
            "",
            NumericRange::default(),
        )),
        ShaderDef::new(
            "hsl_filmgrain_pass1",
            "hsl_filmgrain_pass1",
            "hsl_filmgrain_pass1 shader",
        )
        .with_param(ParameterDef::texture("$grain", "Grain", ""))
        .with_param(ParameterDef::vector4("$hslnoisescale", "Hsl Noise Scale", ""))
        .with_param(ParameterDef::texture("$input", "Input", ""))
        .with_param(ParameterDef::vector4("$scalebias", "Scale Bias", "")),
        ShaderDef::new(
            "hsl_filmgrain_pass2",
            "hsl_filmgrain_pass2",
            "hsl_filmgrain_pass2 shader",
        )
        .with_param(ParameterDef::texture("$input", "Input", "")),
        ShaderDef::new("IceSurface", "IceSurface", "IceSurface shader")
            .with_param(ParameterDef::boolean("$backsurface", "Back Surface", "", false))
            .with_param(ParameterDef::vector3(
                "$basecolortint",
                "Base Color Tint",
                "",
            ))
            .with_param(ParameterDef::vector3("$bbmax", "BB Max", ""))
            .with_param(ParameterDef::vector3("$bbmin", "BB Min", ""))
            .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
            .with_param(ParameterDef::float(
                "$bumpstrength",
                "Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$contactshadows",
                "Contact Shadows",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$diffusescale",
                "Diffuse Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$envmap", "Envmap", ""))
            .with_param(ParameterDef::vector3("$envmaptint", "Envmap Tint", ""))
            .with_param(ParameterDef::float(
                "$fresnelbumpstrength",
                "Fresnel Bump Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$fresnelwarptexture",
                "Fresnel Warp Texture",
                "",
            ))
            .with_param(ParameterDef::boolean("$interior", "Interior", "", true))
            .with_param(ParameterDef::float(
                "$interiorambientscale",
                "Interior Ambient Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbackgroundboost",
                "Interior Background Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorbacklightscale",
                "Interior Backlight Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3("$interiorcolor", "Interior Color", ""))
            .with_param(ParameterDef::float(
                "$interiorfoglimit",
                "Interior Fog Limit",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorfognormalboost",
                "Interior Fog Normal Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorfogstrength",
                "Interior Fog Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractblur",
                "Interior Refract Blur",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$interiorrefractstrength",
                "Interior Refract Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$lightwarptexture",
                "Lightwarp Texture",
                "",
            ))
            .with_param(ParameterDef::texture("$normalmap", "Normal Map", ""))
            .with_param(ParameterDef::texture("$opacitytexture", "Opacity Texture", ""))
            .with_param(ParameterDef::float(
                "$phongboost",
                "Phong Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongboost2",
                "Phong Boost 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent",
                "Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$phongexponent2",
                "Phong Exponent 2",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightboost",
                "Rimlight Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightexponent",
                "Rimlight Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$specmasktexture", "Specmask Texture", ""))
            .with_param(ParameterDef::vector3(
                "$translucentfresnelminmaxexp",
                "Translucent Fresnel Min Max Exp",
                "",
            ))
            .with_param(ParameterDef::vector3("$uvprojoffset", "UV Proj Offset", ""))
            .with_param(ParameterDef::float(
                "$uvscale",
                "UV Scale",
                "",
                NumericRange::default(),
            )),
        ShaderDef::new("Infected", "Infected", "Infected shader")
            .with_param(ParameterDef::boolean(
                "$allowdiffusemodulation",
                "Allow Diffuse Modulation",
                "",
                true,
            ))
            .with_param(ParameterDef::float(
                "$ambientocclusion",
                "Ambient Occlusion",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$blendtintbybasealpha",
                "Blend Tint By Base Alpha",
                "",
                false,
            ))
            .with_param(ParameterDef::vector3("$bloodcolor", "Blood Color", ""))
            .with_param(ParameterDef::vector2("$bloodmaskrange", "Blood Mask Range", ""))
            .with_param(ParameterDef::float(
                "$bloodphongexponent",
                "Blood Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$bloodspecboost",
                "Blood Spec Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture(
                "$burndetailtexture",
                "Burn Detail Texture",
                "",
            ))
            .with_param(ParameterDef::boolean("$burning", "Burning", "", false))
            .with_param(ParameterDef::float(
                "$burnstrength",
                "Burn Strength",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$colortintgradient",
                "Color Tint Gradient",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$cutoutdecalmappingscale",
                "Cutout Decal Mapping Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$cutouttexturebias",
                "Cutout Texture Bias",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean(
                "$debugellipsoids",
                "Debug Ellipsoids",
                "",
                false,
            ))
            .with_param(ParameterDef::float(
                "$defaultphongexponent",
                "Default Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$detail", "Detail", ""))
            .with_param(ParameterDef::float(
                "$detailblendfactor",
                "Detail Blend Factor",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::int(
                "$detailframe",
                "Detail Frame",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::float(
                "$detailphongexponent",
                "Detail Phong Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$detailscale",
                "Detail Scale",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidcenter",
                "Ellipsoid Center",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidcenter2",
                "Ellipsoid Center 2",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidlookat",
                "Ellipsoid Lookat",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidlookat2",
                "Ellipsoid Lookat 2",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidscale",
                "Ellipsoid Scale",
                "",
            ))
            .with_param(ParameterDef::vector3(
                "$ellipsoidscale2",
                "Ellipsoid Scale 2",
                "",
            ))
            .with_param(ParameterDef::vector3("$ellipsoidup", "Ellipsoid Up", ""))
            .with_param(ParameterDef::vector3("$ellipsoidup2", "Ellipsoid Up 2", ""))
            .with_param(ParameterDef::int(
                "$ellipsoid2culltype",
                "Ellipsoid 2 Cull Type",
                "",
                0,
                0,
                0,
            ))
            .with_param(ParameterDef::boolean("$eyeglow", "Eyeglow", "", false))
            .with_param(ParameterDef::vector3("$eyeglowcolor", "Eyeglow Color", ""))
            .with_param(ParameterDef::float(
                "$eyeglowflashlightboost",
                "Eyeglow Flashlight Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::texture("$gradienttexture", "Gradient Texture", ""))
            .with_param(ParameterDef::float(
                "$phongboost",
                "Phong Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::vector3(
                "$phongfresnelranges",
                "Phong Fresnel Ranges",
                "",
            ))
            .with_param(ParameterDef::vector3("$phongtint", "Phong Tint", ""))
            .with_param(ParameterDef::texture(
                "$phongwarptexture",
                "Phong Warp Texture",
                "",
            ))
            .with_param(ParameterDef::float(
                "$refractamount",
                "Refract Amount",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$rimlight", "Rimlight", "", false))
            .with_param(ParameterDef::float(
                "$rimlightboost",
                "Rimlight Boost",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::float(
                "$rimlightexponent",
                "Rimlight Exponent",
                "",
                NumericRange::default(),
            ))
            .with_param(ParameterDef::boolean("$rimmask", "Rim Mask", "", false))
            .with_param(ParameterDef::float("$time", "Time", "", NumericRange::default())),
        ShaderDef::new(
            "VertexLit_SOB",
            "VertexLit_SOB",
            "VertexLit_SOB shader",
        )
        .with_param(ParameterDef::texture("$albedo", "Albedo", ""))
        .with_param(ParameterDef::boolean(
            "$allowdiffusemodulation",
            "Allow Diffuse Modulation",
            "",
            true,
        ))
        .with_param(ParameterDef::float(
            "$alphatestreference",
            "Alpha Test Reference",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::boolean("$basechroma", "Base Chroma", "", false))
        .with_param(ParameterDef::vector3(
            "$basechroma_premul_postmul_alphamul",
            "Base Chroma Premul Postmul Alphamul",
            "",
        ))
        .with_param(ParameterDef::vector3(
            "$basechroma_rgbgamma",
            "Base Chroma Rgbgamma",
            "",
        ))
        .with_param(ParameterDef::int(
            "$basemapalphaphongmask",
            "Basemap Alpha Phong Mask",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::int(
            "$basemapluminancephongmask",
            "Basemap Luminance Phong Mask",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::boolean(
            "$blendtintbybasealpha",
            "Blend Tint By Base Alpha",
            "",
            false,
        ))
        .with_param(ParameterDef::int("$bumpframe", "Bump Frame", "", 0, 0, 0))
        .with_param(ParameterDef::texture("$bumpmap", "Bump Map", ""))
        .with_param(ParameterDef::transform(
            "$bumptransform",
            "Bump Transform",
            "",
        ))
        .with_param(ParameterDef::color("$cloakcolortint", "Cloak Color Tint", ""))
        .with_param(ParameterDef::float(
            "$cloakfactor",
            "Cloak Factor",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::boolean(
            "$cloakpassenabled",
            "Cloak Pass Enabled",
            "",
            false,
        ))
        .with_param(ParameterDef::float(
            "$color_flow_lerpexp",
            "Color Flow Lerpexp",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$color_flow_offset",
            "Color Flow Offset",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$color_flow_timeintervalinseconds",
            "Color Flow Timeintervalinseconds",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$color_flow_timescale",
            "Color Flow Timescale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$color_flow_uvscale",
            "Color Flow Uvscale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$color_flow_uvscrolldistance",
            "Color Flow Uvscrolldistance",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$cutoutdecalmappingscale",
            "Cutout Decal Mapping Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$cutouttexture", "Cutout Texture", ""))
        .with_param(ParameterDef::float(
            "$cutouttexturebias",
            "Cutout Texture Bias",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::boolean("$damaged", "Damaged", "", false))
        .with_param(ParameterDef::boolean(
            "$debugellipsoids",
            "Debug Ellipsoids",
            "",
            false,
        ))
        .with_param(ParameterDef::float(
            "$desaturatewithbasealpha",
            "Desaturate With Base Alpha",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$detail", "Detail", ""))
        .with_param(ParameterDef::float(
            "$detailblendfactor",
            "Detail Blend Factor",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::int(
            "$detailblendmode",
            "Detail Blend Mode",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::int(
            "$detailframe",
            "Detail Frame",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::float(
            "$detailscale",
            "Detail Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::transform(
            "$detailtexturetransform",
            "Detail Texture Transform",
            "",
        ))
        .with_param(ParameterDef::color("$detailtint", "Detail Tint", ""))
        .with_param(ParameterDef::texture(
            "$displacementmap",
            "Displacement Map",
            "",
        ))
        .with_param(ParameterDef::boolean(
            "$distancealpha",
            "Distance Alpha",
            "",
            false,
        ))
        .with_param(ParameterDef::boolean(
            "$distancealphafromdetail",
            "Distance Alpha From Detail",
            "",
            false,
        ))
        .with_param(ParameterDef::float(
            "$edgesoftnessend",
            "Edge Softness End",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::float(
            "$edgesoftnessstart",
            "Edge Softness Start",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture("$envmap", "Envmap", ""))
        .with_param(ParameterDef::float(
            "$envmapcontrast",
            "Envmap Contrast",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::int("$envmapframe", "Envmap Frame", "", 0, 0, 0))
        .with_param(ParameterDef::texture("$envmapmask", "Envmap Mask", ""))
        .with_param(ParameterDef::int(
            "$envmapmaskframe",
            "Envmap Mask Frame",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::transform(
            "$envmapmasktransform",
            "Envmap Mask Transform",
            "",
        ))
        .with_param(ParameterDef::float(
            "$envmapsaturation",
            "Envmap Saturation",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::color("$envmaptint", "Envmap Tint", ""))
        .with_param(ParameterDef::texture("$fow", "Fow", ""))
        .with_param(ParameterDef::int("$frame2", "Frame 2", "", 0, 0, 0))
        .with_param(ParameterDef::float(
            "$fresnelreflection",
            "Fresnel Reflection",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::texture(
            "$lightwarptexture",
            "Lightwarp Texture",
            "",
        ))
        .with_param(ParameterDef::int(
            "$maskedblending",
            "Masked Blending",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::int(
            "$nodiffusebumplighting",
            "No Diffuse Bump Lighting",
            "",
            0,
            0,
            0,
        ))
        .with_param(ParameterDef::float(
            "$seamless_scale",
            "Seamless Scale",
            "",
            NumericRange::default(),
        ))
        .with_param(ParameterDef::color("$selfillumtint", "Self Illum Tint", ""))
        .with_param(ParameterDef::int("$ssbump", "Ss Bump", "", 0, 0, 0)),
    ]
}

pub static GLOBAL_PARAMETERS: Lazy<Vec<ParameterDef>> = Lazy::new(get_global_parameters);

fn get_global_parameters() -> Vec<ParameterDef> {
    vec![
        // Compile flags (booleans)
        ParameterDef::boolean("$compilewater", "Compile Water", "Compile as water surface", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilewet", "Compile Wet", "Compile as wet surface", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileorigin", "Compile Origin", "Compile as origin brush", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileshadow", "Compile Shadow", "Include in shadow compilation", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilepassbullets", "Compile Pass Bullets", "Bullets pass through", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilenodraw", "Compile Nodraw", "Do not render this surface", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compiletrigger", "Compile Trigger", "Compile as trigger volume", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilesky", "Compile Sky", "Compile as sky surface", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileclip", "Compile Clip", "Compile as clip brush", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileplayerclip", "Compile Player Clip", "Compile as player clip", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilehint", "Compile Hint", "Compile as hint brush", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileskip", "Compile Skip", "Skip this surface in compile", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilefog", "Compile Fog", "Compile as fog volume", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilephysics", "Compile Physics", "Include in physics compilation", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileinvisible", "Compile Invisible", "Invisible to rendering", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compileladder", "Compile Ladder", "Compile as ladder surface", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilenpcclip", "Compile NPC Clip", "Compile as NPC clip", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$compilegrenadeclip", "Compile Grenade Clip", "Compile as grenade clip", false)
            .with_category("Compile Flags"),
        ParameterDef::boolean("$blocklos", "Block LOS", "Block line of sight", false)
            .with_category("Compile Flags"),
        
        // Texture flags (booleans)
        ParameterDef::boolean("$allowoverbright", "Allow Overbright", "Allow overbright lighting", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nomip", "No Mip", "Disable mipmapping", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nocompress", "No Compress", "Disable texture compression", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$border", "Border", "Use border addressing", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$clamps", "Clamp S", "Clamp texture S coordinate", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$clampt", "Clamp T", "Clamp texture T coordinate", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$point", "Point", "Use point filtering", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$trilinear", "Trilinear", "Use trilinear filtering", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$anisotropic", "Anisotropic", "Use anisotropic filtering", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nicefiltered", "Nice Filtered", "Use nice filtering", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$ssbump", "SS Bump", "Use self-shadowing bump mapping", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$normal", "Normal", "This is a normal map", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$procedural", "Procedural", "Procedural texture", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$rendertarget", "Render Target", "Use as render target", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$depthrendertarget", "Depth Render Target", "Use as depth render target", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nodepth", "No Depth", "Disable depth testing", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$singlecopy", "Single Copy", "Single texture copy", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$premult", "Premult", "Premultiplied alpha", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$allmips", "All Mips", "Generate all mip levels", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nolod", "No LOD", "Disable level of detail", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$dudv", "DUDV", "DuDv map for water", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$loadondemand", "Load On Demand", "Load texture on demand", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$unloadondemand", "Unload On Demand", "Unload texture when not needed", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$stripalphachannels", "Strip Alpha Channels", "Strip alpha channels from texture", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$stripcolorchannels", "Strip Color Channels", "Strip color channels from texture", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$normaltodu", "Normal To DU", "Convert normal to DU", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$nocompression", "No Compression", "Disable compression", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$precomputenormals", "Precompute Normals", "Precompute normal values", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$onebitalpha", "One Bit Alpha", "Use 1-bit alpha", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$eightbitalpha", "Eight Bit Alpha", "Use 8-bit alpha", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$pfm", "PFM", "Use PFM format", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$pfmrect", "PFM Rect", "Use PFM rectangle format", false)
            .with_category("Texture Flags"),
        ParameterDef::boolean("$volume", "Volume", "Volume texture", false)
            .with_category("Texture Flags"),
        
        // Rendering flags (booleans)
        ParameterDef::boolean("$alphatest", "Alpha Test", "Enable alpha testing", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$translucent", "Translucent", "Enable translucency", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$additive", "Additive", "Use additive blending", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$selfillum", "Self Illum", "Enable self-illumination", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$decal", "Decal", "This is a decal material", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$model", "Model", "This is a model material", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$flat", "Flat", "Flat shading", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$nocull", "No Cull", "Disable backface culling", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$nofog", "No Fog", "Disable fog", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$halflambert", "Half Lambert", "Use half-lambert lighting", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$ignorez", "Ignore Z", "Ignore Z-buffer", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$nodecal", "No Decal", "Decals cannot be applied to this", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$vertexcolor", "Vertex Color", "Use vertex colors", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$vertexalpha", "Vertex Alpha", "Use vertex alpha", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$flashlights", "Flashlights", "Affected by flashlights", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$light", "Light", "Affected by lights", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$shadows", "Shadows", "Cast shadows", false)
            .with_category("Rendering"),
        ParameterDef::boolean("$hdr", "HDR", "Use HDR rendering", false)
            .with_category("Rendering"),
        
        // Textures (texture type)
        ParameterDef::texture("$basetexture", "Base Texture", "Primary diffuse texture")
            .with_category("Textures")
            .required(),
        ParameterDef::texture("$basetexture2", "Base Texture 2", "Secondary diffuse texture for blending")
            .with_category("Textures"),
        ParameterDef::texture("$bumpmap", "Bump Map", "Normal map texture")
            .with_category("Textures"),
        ParameterDef::texture("$bumpmap2", "Bump Map 2", "Secondary normal map")
            .with_category("Textures"),
        ParameterDef::texture("$detail", "Detail Texture", "Detail texture for close-up viewing")
            .with_category("Textures"),
        ParameterDef::texture("$envmap", "Environment Map", "Cubemap for reflections")
            .with_category("Textures"),
        ParameterDef::texture("$envmapmask", "Envmap Mask", "Mask texture for environment map")
            .with_category("Textures"),
        ParameterDef::texture("$selfillummask", "Self Illum Mask", "Mask for self-illumination")
            .with_category("Textures"),
        ParameterDef::texture("$lightwarptexture", "Lightwarp Texture", "Texture for light warping")
            .with_category("Textures"),
        ParameterDef::texture("$phongexponenttexture", "Phong Exponent Texture", "Per-pixel phong exponent")
            .with_category("Textures"),
        ParameterDef::texture("$hdrbasetexture", "HDR Base Texture", "HDR version of base texture")
            .with_category("Textures"),
        ParameterDef::texture("$hdrcompressedtexture", "HDR Compressed Texture", "Compressed HDR texture")
            .with_category("Textures"),
        
        // Numeric values (floats)
        ParameterDef::float("$alpha", "Alpha", "Overall transparency", NumericRange {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: Some(1.0),
        }).with_category("Transparency"),
        ParameterDef::float("$alphatestreference", "Alpha Test Reference", "Alpha test threshold", NumericRange {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: Some(0.5),
        }).with_category("Transparency"),
        ParameterDef::float("$detailscale", "Detail Scale", "Detail texture tiling scale", NumericRange {
            min: 0.1,
            max: 100.0,
            step: Some(0.1),
            default: Some(4.0),
        }).with_category("Detail"),
        ParameterDef::float("$detailblendfactor", "Detail Blend Factor", "Detail texture blend strength", NumericRange {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: Some(1.0),
        }).with_category("Detail"),
        ParameterDef::float("$envmapcontrast", "Envmap Contrast", "Environment map contrast", NumericRange {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: Some(0.0),
        }).with_category("Reflections"),
        ParameterDef::float("$envmapsaturation", "Envmap Saturation", "Environment map saturation", NumericRange {
            min: 0.0,
            max: 1.0,
            step: Some(0.01),
            default: Some(1.0),
        }).with_category("Reflections"),
        ParameterDef::float("$phongexponent", "Phong Exponent", "Shininess/glossiness value", NumericRange {
            min: 1.0,
            max: 255.0,
            step: Some(1.0),
            default: Some(5.0),
        }).with_category("Phong"),
        ParameterDef::float("$phongboost", "Phong Boost", "Phong highlight brightness", NumericRange {
            min: 0.0,
            max: 100.0,
            step: Some(0.1),
            default: Some(1.0),
        }).with_category("Phong"),
        ParameterDef::float("$seamless_scale", "Seamless Scale", "Scale for seamless texture mapping", NumericRange {
            min: 0.001,
            max: 1.0,
            step: Some(0.001),
            default: Some(0.0),
        }).with_category("Textures"),
        ParameterDef::float("$bumpscale", "Bump Scale", "Normal map intensity", NumericRange {
            min: 0.0,
            max: 10.0,
            step: Some(0.1),
            default: Some(1.0),
        }).with_category("Textures"),
        ParameterDef::float("$selfillumtint", "Self Illum Tint", "Self-illumination intensity", NumericRange {
            min: 0.0,
            max: 10.0,
            step: Some(0.1),
            default: Some(1.0),
        }).with_category("Rendering"),
        
        // Integer values
        ParameterDef::int("$frame", "Frame", "Animation frame index", 0, 999, 0)
            .with_category("Animation"),
        ParameterDef::int("$detailblendmode", "Detail Blend Mode", "Detail texture blend mode", 0, 12, 0)
            .with_category("Detail"),
        
        // Colors
        ParameterDef::color("$color", "Color", "Color tint multiplier")
            .with_category("Colors"),
        ParameterDef::color("$color2", "Color 2", "Secondary color tint")
            .with_category("Colors"),
        ParameterDef::color("$envmaptint", "Envmap Tint", "Environment map color tint")
            .with_category("Reflections"),
        ParameterDef::color("$phongtint", "Phong Tint", "Phong highlight color tint")
            .with_category("Phong"),
        ParameterDef::color("$selfillumtint", "Self Illum Tint", "Self-illumination color tint")
            .with_category("Rendering"),
        
        // Transforms
        ParameterDef::transform("$basetexturetransform", "Base Texture Transform", "UV transform for base texture")
            .with_category("Transforms"),
        ParameterDef::transform("$bumptransform", "Bump Transform", "UV transform for bump map")
            .with_category("Transforms"),
        ParameterDef::transform("$detailtexturetransform", "Detail Texture Transform", "UV transform for detail texture")
            .with_category("Transforms"),
        ParameterDef::transform("$envmapmasktransform", "Envmap Mask Transform", "UV transform for envmap mask")
            .with_category("Transforms"),
        
        // Vectors
        ParameterDef::vector3("$phongfresnelranges", "Phong Fresnel Ranges", "Fresnel effect parameters [min, mid, max]")
            .with_category("Phong"),
        
        // Strings
        ParameterDef::string("$surfaceprop", "Surface Prop", "Physical surface property name")
            .with_category("Physics"),
        ParameterDef::string("$surfaceprop2", "Surface Prop 2", "Secondary surface property")
            .with_category("Physics"),
        ParameterDef::string("$keywords", "Keywords", "Search keywords for this material")
            .with_category("Metadata"),
        ParameterDef::string("$include", "Include", "Include another VMT file")
            .with_category("Metadata"),
        ParameterDef::string("$proxies", "Proxies", "Material proxies block")
            .with_category("Advanced"),
        
        // Tool flags
        ParameterDef::boolean("$tools", "Tools", "Tool texture mode", false)
            .with_category("Tools"),
        ParameterDef::boolean("$tools_nopaint", "Tools No Paint", "Cannot be painted in tools", false)
            .with_category("Tools"),
        ParameterDef::boolean("$readprocedural", "Read Procedural", "Read from procedural texture", false)
            .with_category("Tools"),
        ParameterDef::boolean("$writeprocedural", "Write Procedural", "Write to procedural texture", false)
            .with_category("Tools"),
        ParameterDef::boolean("$realtime", "Realtime", "Real-time texture updates", false)
            .with_category("Tools"),
        ParameterDef::boolean("$offline", "Offline", "Offline texture processing", false)
            .with_category("Tools"),
    ]
}
