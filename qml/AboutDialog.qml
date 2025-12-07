import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Dialog {
    id: root
    
    modal: true
    anchors.centerIn: parent
    width: 420
    padding: 0
    
    Overlay.modal: Rectangle { color: Theme.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: close()
    Keys.onEnterPressed: close()
    
    onOpened: aboutCloseBtn.forceActiveFocus()
    
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
    
    background: Rectangle {
        color: Theme.panelBg
        border.color: Theme.panelBorder
        border.width: 0
        radius: 12
    }
    
    header: Item { height: 0 }
    footer: Item { height: 0 }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Gradient header
        Rectangle {
            Layout.fillWidth: true
            height: 100
            radius: 12
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1a3a5c" }
                GradientStop { position: 1.0; color: Theme.panelBg }
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: Theme.panelBg
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                Image {
                    width: 48
                    height: 48
                    source: "qrc:/media/icon.png"
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                }
                
                ColumnLayout {
                    spacing: 2
                    
                    Text {
                        text: "VFileX"
                        color: "white"
                        font.pixelSize: 24
                        font.bold: true
                    }
                    
                    Text {
                        text: "Version 0.8.2"
                        color: "#88ccff"
                        font.pixelSize: 12
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
        
        // Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 24
            spacing: 16
            
            Text {
                Layout.fillWidth: true
                text: "A high-speed, cross-platform editor for Valve Material (.VMT) files."
                color: Theme.textColor
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                lineHeight: 1.4
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.panelBorder
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Made by JuiceyDev & Olxgs"
                    color: Theme.textDim
                    font.pixelSize: 11
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Built with Rust + Qt"
                    color: Theme.textDim
                    font.pixelSize: 11
                }
            }
        }
        
        // Close button area
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
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                radius: 12
                color: "#1e1e1e"
                
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 6
                    color: "#1e1e1e"
                }
            }
            
            Rectangle {
                id: aboutCloseBtn
                anchors.centerIn: parent
                width: 90
                height: 32
                radius: 4
                color: closeAboutMouse.containsMouse || aboutCloseBtn.activeFocus ? Theme.accentHover : Theme.accent
                border.color: aboutCloseBtn.activeFocus ? "#ffffff" : "transparent"
                border.width: 1
                
                activeFocusOnTab: true
                Keys.onReturnPressed: root.close()
                Keys.onEnterPressed: root.close()
                Keys.onSpacePressed: root.close()
                
                scale: closeAboutMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }
                
                MouseArea {
                    id: closeAboutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }
}
