// Theme colors and constants for VFileX
// These are default values that can be overridden by loaded themes

// Main background
var windowBg = "#1e1e1e"

// Panel colors
var panelBg = "#252526"
var panelBorder = "#3c3c3c"

// Dialog/Modal colors
var dialogBg = "#2d2d30"
var dialogBorder = "#3c3c3c"
var dialogHeaderBg = "#252526"

// Accent colors
var accent = "#0e639c"
var accentHover = "#1177bb"
var accentPressed = "#094771"

// Input colors
var inputBg = "#3c3c3c"
var inputBorder = "#5a5a5a"
var inputFocusBorder = "#0e639c"  // Same as accent

// Text colors
var textColor = "#e0e0e0"
var textDim = "#888888"
var textBright = "#ffffff"

// Icon color (for SVG icons that need to be tinted)
var iconColor = "#e0e0e0"

// Button colors
var buttonBg = "#3c3c3c"
var buttonHover = "#4a4a4a"
var buttonPressed = "#5a5a5a"

// Secondary/Cancel button
var buttonSecondaryBg = "#3c3c3c"
var buttonSecondaryHover = "#4a4a4a"
var buttonSecondaryText = "#e0e0e0"

// Danger button (for delete, close, etc.)
var dangerColor = "#c42b1c"
var dangerHover = "#d83b2b"

// Status colors
var success = "#4CAF50"
var warning = "#ff9800"
var error = "#f44336"

// List/Grid item colors
var listItemBg = "transparent"
var listItemHover = "#2a2d2e"
var listItemSelected = "#094771"

// Separator/Divider
var separator = "#3c3c3c"

// Dialog overlay - Note: rgba() doesn't work in JS, use Qt.rgba() in QML or hex with alpha
var overlayBg = "#99000000"  // Black with 60% opacity (0x99 = 153 = 60% of 255)

// Misc
var radius = 6
var radiusSmall = 4
var radiusLarge = 12
var dialogRadius = 8

// Shadow (for dialogs)
var shadowColor = "#40000000"

// Animation settings
var animDurationFast = 120
var animDurationNormal = 200
var animDurationSlow = 350

// Easing types (Qt Easing enum values)
var animEasing = 3        // Easing.OutCubic
var animEasingBounce = 34 // Easing.OutBack

// Apply theme from JSON object
function applyTheme(themeData) {
    if (!themeData) return
    
    // Colors
    if (themeData.windowBg !== undefined) windowBg = themeData.windowBg
    if (themeData.panelBg !== undefined) panelBg = themeData.panelBg
    if (themeData.panelBorder !== undefined) panelBorder = themeData.panelBorder
    if (themeData.dialogBg !== undefined) dialogBg = themeData.dialogBg
    if (themeData.dialogBorder !== undefined) dialogBorder = themeData.dialogBorder
    if (themeData.dialogHeaderBg !== undefined) dialogHeaderBg = themeData.dialogHeaderBg
    if (themeData.accent !== undefined) accent = themeData.accent
    if (themeData.accentHover !== undefined) accentHover = themeData.accentHover
    if (themeData.accentPressed !== undefined) accentPressed = themeData.accentPressed
    if (themeData.inputBg !== undefined) inputBg = themeData.inputBg
    if (themeData.inputBorder !== undefined) inputBorder = themeData.inputBorder
    if (themeData.inputFocusBorder !== undefined) inputFocusBorder = themeData.inputFocusBorder
    if (themeData.textColor !== undefined) textColor = themeData.textColor
    if (themeData.textDim !== undefined) textDim = themeData.textDim
    if (themeData.textBright !== undefined) textBright = themeData.textBright
    if (themeData.iconColor !== undefined) iconColor = themeData.iconColor
    if (themeData.buttonBg !== undefined) buttonBg = themeData.buttonBg
    if (themeData.buttonHover !== undefined) buttonHover = themeData.buttonHover
    if (themeData.buttonPressed !== undefined) buttonPressed = themeData.buttonPressed
    if (themeData.buttonSecondaryBg !== undefined) buttonSecondaryBg = themeData.buttonSecondaryBg
    if (themeData.buttonSecondaryHover !== undefined) buttonSecondaryHover = themeData.buttonSecondaryHover
    if (themeData.buttonSecondaryText !== undefined) buttonSecondaryText = themeData.buttonSecondaryText
    if (themeData.dangerColor !== undefined) dangerColor = themeData.dangerColor
    if (themeData.dangerHover !== undefined) dangerHover = themeData.dangerHover
    if (themeData.success !== undefined) success = themeData.success
    if (themeData.warning !== undefined) warning = themeData.warning
    if (themeData.error !== undefined) error = themeData.error
    if (themeData.listItemBg !== undefined) listItemBg = themeData.listItemBg
    if (themeData.listItemHover !== undefined) listItemHover = themeData.listItemHover
    if (themeData.listItemSelected !== undefined) listItemSelected = themeData.listItemSelected
    if (themeData.separator !== undefined) separator = themeData.separator
    if (themeData.overlayBg !== undefined) overlayBg = themeData.overlayBg
    if (themeData.shadowColor !== undefined) shadowColor = themeData.shadowColor
    
    // Appearance
    if (themeData.radius !== undefined) radius = themeData.radius
    if (themeData.radiusSmall !== undefined) radiusSmall = themeData.radiusSmall
    if (themeData.radiusLarge !== undefined) radiusLarge = themeData.radiusLarge
    if (themeData.dialogRadius !== undefined) dialogRadius = themeData.dialogRadius
    
    // Animation
    if (themeData.animDurationFast !== undefined) animDurationFast = themeData.animDurationFast
    if (themeData.animDurationNormal !== undefined) animDurationNormal = themeData.animDurationNormal
    if (themeData.animDurationSlow !== undefined) animDurationSlow = themeData.animDurationSlow
    if (themeData.animEasing !== undefined) animEasing = themeData.animEasing
    if (themeData.animEasingBounce !== undefined) animEasingBounce = themeData.animEasingBounce
}
