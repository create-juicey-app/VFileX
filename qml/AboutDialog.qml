import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

Dialog {
    id: root
    
    required property var themeRoot
    
    modal: true
    anchors.centerIn: parent
    width: 420
    padding: 0
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: close()
    Keys.onEnterPressed: close()
    
    onOpened: aboutCloseBtn.forceActiveFocus()
    
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
    
    background: Rectangle {
        color: themeRoot.dialogBg
        border.color: themeRoot.dialogBorder
        border.width: 0
        radius: themeRoot.dialogRadius
    }
    
    header: Item { height: 0 }
    footer: Item { height: 0 }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Gradient header
        Rectangle {
            Layout.fillWidth: true
            height: 100
            radius: themeRoot.dialogRadius
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.darker(themeRoot.accent, 1.5) }
                GradientStop { position: 1.0; color: themeRoot.dialogBg }
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: themeRoot.dialogBg
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
                        text: "Version 0.8.5"
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
                color: themeRoot.textColor
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                lineHeight: 1.4
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeRoot.panelBorder
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Made by JuiceyDev & Olxgs"
                    color: themeRoot.textDim
                    font.pixelSize: 11
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Built with Rust + Qt"
                    color: themeRoot.textDim
                    font.pixelSize: 11
                }
            }
        }
        
        // Close button area
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
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                radius: themeRoot.dialogRadius
                color: themeRoot.dialogHeaderBg
                
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 6
                    color: themeRoot.dialogHeaderBg
                }
            }
            
            Rectangle {
                id: aboutCloseBtn
                anchors.centerIn: parent
                width: 90
                height: 32
                radius: 4
                color: closeAboutMouse.containsMouse || aboutCloseBtn.activeFocus ? themeRoot.accentHover : themeRoot.accent
                border.color: aboutCloseBtn.activeFocus ? "#ffffff" : "transparent"
                border.width: 1
                
                activeFocusOnTab: true
                Keys.onReturnPressed: root.close()
                Keys.onEnterPressed: root.close()
                Keys.onSpacePressed: root.close()
                
                scale: closeAboutMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                
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
