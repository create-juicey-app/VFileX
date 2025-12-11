import QtQuick
import QtQuick.Effects

// A reusable icon component that can be tinted with a theme color
// Uses Qt6's MultiEffect for color overlay
Item {
    id: iconRoot
    
    // Required: the root of the application to access theme colors
    required property var themeRoot
    
    // Icon source (SVG or image)
    property alias source: iconImage.source
    property alias sourceSize: iconImage.sourceSize
    
    // Color to tint the icon (defaults to theme iconColor)
    property color iconColor: themeRoot ? themeRoot.iconColor : "#e0e0e0"
    
    // Convenience size properties
    property alias fillMode: iconImage.fillMode
    
    // Allow overriding if the icon should be themed or not
    property bool themed: true
    
    implicitWidth: iconImage.implicitWidth
    implicitHeight: iconImage.implicitHeight
    
    Image {
        id: iconImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        visible: !iconRoot.themed
        cache: true
        asynchronous: true
    }
    
    // For themed icons, use layer effect to colorize
    Image {
        id: themedIconImage
        anchors.fill: parent
        source: iconImage.source
        sourceSize: iconImage.sourceSize
        fillMode: iconImage.fillMode
        visible: iconRoot.themed
        cache: true
        asynchronous: true
        
        layer.enabled: iconRoot.themed
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: iconRoot.iconColor
        }
    }
}
