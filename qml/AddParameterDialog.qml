import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Dialog {
    id: root
    
    signal addParameter(string name, string value)
    
    modal: true
    anchors.centerIn: parent
    width: 400
    padding: 0
    
    Overlay.modal: Rectangle { color: Theme.overlayBg }
    
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
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animDurationNormal; easing.type: Theme.animEasing }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.animDurationNormal; easing.type: Theme.animEasingBounce }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animDurationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: Theme.animDurationFast; easing.type: Easing.InCubic }
        }
    }
    
    onOpened: newParamName.forceActiveFocus()
    
    background: Rectangle {
        color: Theme.panelBg
        border.color: Theme.panelBorder
        radius: 8
    }
    
    header: Item { height: 0 }
    footer: Item { height: 0 }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: Theme.panelBg
            
            Text {
                anchors.centerIn: parent
                text: "Add Parameter"
                color: Theme.textColor
                font.pixelSize: 15
                font.bold: true
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.panelBorder
            }
        }
        
        // Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 12
            
            Text { text: "Parameter Name:"; color: Theme.textColor; font.pixelSize: 12 }
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: Theme.inputBg
                border.color: newParamName.activeFocus ? Theme.accent : Theme.inputBorder
                radius: 4
                
                TextInput {
                    id: newParamName
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.textColor
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
                        color: Theme.textDim
                        font.pixelSize: 13
                    }
                }
            }
            
            Text { text: "Value:"; color: Theme.textColor; font.pixelSize: 12 }
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: Theme.inputBg
                border.color: newParamValue.activeFocus ? Theme.accent : Theme.inputBorder
                radius: 4
                
                TextInput {
                    id: newParamValue
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.textColor
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    inputMethodHints: Qt.ImhNoPredictiveText
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.doAdd()
                    Keys.onEnterPressed: root.doAdd()
                    
                    Text {
                        visible: !parent.text
                        text: "value"
                        color: Theme.textDim
                        font.pixelSize: 13
                    }
                }
            }
        }
        
        // Footer with buttons
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "#1e1e1e"
            
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.panelBorder
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 12
                
                Rectangle {
                    id: cancelParamBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: cancelParamMouse.containsMouse || cancelParamBtn.activeFocus ? Theme.buttonHover : Theme.buttonBg
                    border.color: cancelParamBtn.activeFocus ? Theme.accent : "transparent"
                    border.width: 1
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.close()
                    Keys.onEnterPressed: root.close()
                    Keys.onSpacePressed: root.close()
                    
                    scale: cancelParamMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textColor
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
                    color: okParamMouse.containsMouse || okParamBtn.activeFocus ? Theme.accentHover : Theme.accent
                    border.color: okParamBtn.activeFocus ? "#ffffff" : "transparent"
                    border.width: 1
                    
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.doAdd()
                    Keys.onEnterPressed: root.doAdd()
                    Keys.onSpacePressed: root.doAdd()
                    
                    scale: okParamMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    
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
