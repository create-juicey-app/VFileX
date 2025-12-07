// Theme colors and constants for VFileX

// Main background
var windowBg = "#1e1e1e"

// Panel colors
var panelBg = "#252526"
var panelBorder = "#3c3c3c"

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

// Button colors
var buttonBg = "#3c3c3c"
var buttonHover = "#4a4a4a"
var buttonPressed = "#5a5a5a"

// Status colors
var success = "#4CAF50"
var warning = "#ff9800"
var error = "#f44336"

// Dialog overlay - Note: rgba() doesn't work in JS, use Qt.rgba() in QML or hex with alpha
var overlayBg = "#99000000"  // Black with 60% opacity (0x99 = 153 = 60% of 255)

// Misc
var radius = 6
var radiusSmall = 4
var radiusLarge = 12

// Animation settings
var animDurationFast = 120
var animDurationNormal = 200
var animDurationSlow = 350

// Easing types (Qt Easing enum values)
var animEasing = 3        // Easing.OutCubic
var animEasingBounce = 34 // Easing.OutBack
