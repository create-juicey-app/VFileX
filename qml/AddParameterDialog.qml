import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

Dialog {
    id: root
    
    required property var themeRoot
    signal addParameter(string name, string value)
    
    modal: true
    anchors.centerIn: parent
    width: 400
    padding: 0
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    Keys.onEscapePressed: close()
    
    function doAdd() {
        if (newParamName.text !== "") {
            addParameter(newParamName.text, newParamValue.text)
            newParamName.text = ""
            newParamValue.text = ""
        }
        close()
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
    
    onOpened: newParamName.forceActiveFocus()
    
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
            height: 48
            color: themeRoot.dialogHeaderBg
            
            Text {
                anchors.centerIn: parent
                text: "Add Parameter"
                color: themeRoot.textColor
                font.pixelSize: 15
                font.bold: true
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: themeRoot.separator
            }
        }
        
        // Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 12
            
            Text { text: "Parameter Name:"; color: themeRoot.textColor; font.pixelSize: 12 }
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: themeRoot.inputBg
                border.color: newParamName.activeFocus ? themeRoot.accent : themeRoot.inputBorder
                radius: 4
                
                TextInput {
                    id: newParamName
                    anchors.fill: parent
                    anchors.margins: 10
                    color: themeRoot.textColor
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    inputMethodHints: Qt.ImhNoPredictiveText
                    activeFocusOnTab: true
                    Keys.onReturnPressed: newParamValue.forceActiveFocus()
                    Keys.onEnterPressed: newParamValue.forceActiveFocus()
                    Keys.onTabPressed: newParamValue.forceActiveFocus()
                    
                    Text {
                        visible: !parent.text
                        text: "$parametername"
                        color: themeRoot.textDim
                        font.pixelSize: 13
                    }
                }
            }
            
            Text { text: "Value:"; color: themeRoot.textColor; font.pixelSize: 12 }
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: themeRoot.inputBg
                border.color: newParamValue.activeFocus ? themeRoot.accent : themeRoot.inputBorder
                radius: 4
                
                TextInput {
                    id: newParamValue
                    anchors.fill: parent
                    anchors.margins: 10
                    color: themeRoot.textColor
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    inputMethodHints: Qt.ImhNoPredictiveText
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.doAdd()
                    Keys.onEnterPressed: root.doAdd()
                    
                    Text {
                        visible: !parent.text
                        text: "value"
                        color: themeRoot.textDim
                        font.pixelSize: 13
                    }
                }
            }
        }
        
        // Footer with buttons
        Rectangle {
            Layout.fillWidth: true
            height: 56
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
                    id: cancelParamBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: cancelParamMouse.containsMouse || cancelParamBtn.activeFocus ? themeRoot.buttonHover : themeRoot.buttonBg
                    border.color: cancelParamBtn.activeFocus ? themeRoot.accent : "transparent"
                    border.width: 1
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.close()
                    Keys.onEnterPressed: root.close()
                    Keys.onSpacePressed: root.close()
                    
                    scale: cancelParamMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: themeRoot.textColor
                        font.pixelSize: 13
                    }
                    
                    MouseArea {
                        id: cancelParamMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
                
                Rectangle {
                    id: okParamBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: okParamMouse.containsMouse || okParamBtn.activeFocus ? themeRoot.accentHover : themeRoot.accent
                    border.color: okParamBtn.activeFocus ? "#ffffff" : "transparent"
                    border.width: 1
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.doAdd()
                    Keys.onEnterPressed: root.doAdd()
                    Keys.onSpacePressed: root.doAdd()
                    
                    scale: okParamMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Add"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: okParamMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doAdd()
                    }
                }
            }
        }
    }
}
