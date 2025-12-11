import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

Dialog {
    id: root
    
    required property var themeRoot
    property var targetTextField: null
    property color initialColor: "white"
    property color currentColor: "white"
    property real hue: 0
    property real saturation: 1
    property real brightness: 1
    
    modal: true
    anchors.centerIn: parent
    width: 340
    padding: 0
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: applyColor()
    Keys.onEnterPressed: applyColor()
    
    function applyColor() {
        if (targetTextField) {
            var r = Math.round(currentColor.r * 255)
            var g = Math.round(currentColor.g * 255)
            var b = Math.round(currentColor.b * 255)
            targetTextField.text = "[" + r + " " + g + " " + b + "]"
        }
        close()
    }
    
    function setInitialColor(color) {
        initialColor = color
        currentColor = color
        hue = color.hsvHue >= 0 ? color.hsvHue : 0
        saturation = color.hsvSaturation
        brightness = color.hsvValue
    }
    
    // Smooth enter/exit animations
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: themeRoot.animDurationNormal; easing.type: themeRoot.animEasing }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: themeRoot.animDurationNormal; easing.type: themeRoot.animEasingBounce }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: themeRoot.animDurationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: themeRoot.animDurationFast; easing.type: Easing.InCubic }
        }
    }
    
    onCurrentColorChanged: {
        hue = currentColor.hsvHue >= 0 ? currentColor.hsvHue : 0
        saturation = currentColor.hsvSaturation
        brightness = currentColor.hsvValue
    }
    
    background: Rectangle {
        color: themeRoot.dialogBg
        border.color: themeRoot.dialogBorder
        radius: themeRoot.dialogRadius
    }
    
    header: Item { height: 0 }
    footer: Item { height: 0 }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: themeRoot.dialogHeaderBg
            
            Text {
                anchors.centerIn: parent
                text: "Color Picker"
                color: themeRoot.textColor
                font.pixelSize: 14
                font.bold: true
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: themeRoot.separator
            }
        }
        
        // Color picker content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 16
            
            // Saturation/Brightness picker
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 4
                
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.hsva(root.hue, 1, 1, 1)
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FFFFFF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                }
                
                Rectangle {
                    x: root.saturation * (parent.width - 12)
                    y: (1 - root.brightness) * (parent.height - 12)
                    width: 12
                    height: 12
                    radius: 6
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: "transparent"
                        border.color: "black"
                        border.width: 1
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    
                    function updateColor(mouseX, mouseY) {
                        root.saturation = Math.max(0, Math.min(1, mouseX / width))
                        root.brightness = Math.max(0, Math.min(1, 1 - mouseY / height))
                        root.currentColor = Qt.hsva(root.hue, root.saturation, root.brightness, 1)
                    }
                    
                    onPressed: function(mouse) { updateColor(mouse.x, mouse.y) }
                    onPositionChanged: function(mouse) { if (pressed) updateColor(mouse.x, mouse.y) }
                }
            }
            
            // Hue slider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                radius: 4
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#FF0000" }
                    GradientStop { position: 0.167; color: "#FFFF00" }
                    GradientStop { position: 0.333; color: "#00FF00" }
                    GradientStop { position: 0.5; color: "#00FFFF" }
                    GradientStop { position: 0.667; color: "#0000FF" }
                    GradientStop { position: 0.833; color: "#FF00FF" }
                    GradientStop { position: 1.0; color: "#FF0000" }
                }
                
                Rectangle {
                    x: root.hue * (parent.width - 8)
                    y: -2
                    width: 8
                    height: parent.height + 4
                    radius: 2
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                }
                
                MouseArea {
                    anchors.fill: parent
                    
                    function updateHue(mouseX) {
                        root.hue = Math.max(0, Math.min(1, mouseX / width))
                        root.currentColor = Qt.hsva(root.hue, root.saturation, root.brightness, 1)
                    }
                    
                    onPressed: function(mouse) { updateHue(mouse.x) }
                    onPositionChanged: function(mouse) { if (pressed) updateHue(mouse.x) }
                }
            }
            
            // Color preview and RGB values
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                ColumnLayout {
                    spacing: 4
                    
                    Text {
                        text: "New"
                        color: themeRoot.textDim
                        font.pixelSize: 10
                    }
                    
                    Rectangle {
                        width: 50
                        height: 30
                        radius: 4
                        color: root.currentColor
                        border.color: themeRoot.inputBorder
                    }
                    
                    Text {
                        text: "Old"
                        color: themeRoot.textDim
                        font.pixelSize: 10
                    }
                    
                    Rectangle {
                        width: 50
                        height: 30
                        radius: 4
                        color: root.initialColor
                        border.color: themeRoot.inputBorder
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentColor = root.initialColor
                        }
                    }
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 8
                    
                    Text { text: "R"; color: "#e74c3c"; font.pixelSize: 12; font.bold: true }
                    TextField {
                        id: redInput
                        Layout.fillWidth: true
                        text: activeFocus ? text : Math.round(root.currentColor.r * 255).toString()
                        validator: IntValidator { bottom: 0; top: 255 }
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextEdited: {
                            var r = parseInt(text) || 0
                            root.currentColor = Qt.rgba(r/255, root.currentColor.g, root.currentColor.b, 1)
                        }
                        background: Rectangle {
                            implicitHeight: 26
                            color: themeRoot.inputBg
                            border.color: redInput.activeFocus ? "#e74c3c" : themeRoot.inputBorder
                            radius: 4
                        }
                        color: themeRoot.textColor
                        font.pixelSize: 12
                    }
                    
                    Text { text: "G"; color: "#2ecc71"; font.pixelSize: 12; font.bold: true }
                    TextField {
                        id: greenInput
                        Layout.fillWidth: true
                        text: activeFocus ? text : Math.round(root.currentColor.g * 255).toString()
                        validator: IntValidator { bottom: 0; top: 255 }
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextEdited: {
                            var g = parseInt(text) || 0
                            root.currentColor = Qt.rgba(root.currentColor.r, g/255, root.currentColor.b, 1)
                        }
                        background: Rectangle {
                            implicitHeight: 26
                            color: themeRoot.inputBg
                            border.color: greenInput.activeFocus ? "#2ecc71" : themeRoot.inputBorder
                            radius: 4
                        }
                        color: themeRoot.textColor
                        font.pixelSize: 12
                    }
                    
                    Text { text: "B"; color: "#3498db"; font.pixelSize: 12; font.bold: true }
                    TextField {
                        id: blueInput
                        Layout.fillWidth: true
                        text: activeFocus ? text : Math.round(root.currentColor.b * 255).toString()
                        validator: IntValidator { bottom: 0; top: 255 }
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextEdited: {
                            var b = parseInt(text) || 0
                            root.currentColor = Qt.rgba(root.currentColor.r, root.currentColor.g, b/255, 1)
                        }
                        background: Rectangle {
                            implicitHeight: 26
                            color: themeRoot.inputBg
                            border.color: blueInput.activeFocus ? "#3498db" : themeRoot.inputBorder
                            radius: 4
                        }
                        color: themeRoot.textColor
                        font.pixelSize: 12
                    }
                }
            }
        }
        
        // Footer with buttons
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: themeRoot.dialogHeaderBg
            
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: themeRoot.separator
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 12
                
                Rectangle {
                    id: cancelColorBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: cancelColorMouse.containsMouse || cancelColorBtn.activeFocus ? themeRoot.buttonHover : themeRoot.buttonBg
                    border.color: cancelColorBtn.activeFocus ? themeRoot.accent : "transparent"
                    border.width: 1
                    
                    scale: cancelColorMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.close()
                    Keys.onEnterPressed: root.close()
                    Keys.onSpacePressed: root.close()
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: themeRoot.textColor
                        font.pixelSize: 13
                    }
                    
                    MouseArea {
                        id: cancelColorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
                
                Rectangle {
                    id: okColorBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: okColorMouse.containsMouse || okColorBtn.activeFocus ? themeRoot.accentHover : themeRoot.accent
                    border.color: okColorBtn.activeFocus ? "#ffffff" : "transparent"
                    border.width: 1
                    
                    scale: okColorMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.applyColor()
                    Keys.onEnterPressed: root.applyColor()
                    Keys.onSpacePressed: root.applyColor()
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: okColorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyColor()
                    }
                }
            }
        }
    }
}
