import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Dialog {
    id: root
    
    required property var shaderModel
    signal createMaterial(string shaderName)
    
    modal: true
    anchors.centerIn: parent
    width: 400
    padding: 0
    
    Overlay.modal: Rectangle { color: Theme.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: { createMaterial(newShaderCombo.currentText); close() }
    Keys.onEnterPressed: { createMaterial(newShaderCombo.currentText); close() }
    
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
    
    onOpened: { newShaderCombo.setDefaultShader(); newShaderCombo.forceActiveFocus() }
    
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
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Image {
                    width: 18
                    height: 18
                    source: "qrc:/media/file-new.svg"
                    sourceSize: Qt.size(18, 18)
                }
                
                Text {
                    text: "New Material"
                    color: Theme.textColor
                    font.pixelSize: 15
                    font.bold: true
                }
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
            
            Text {
                text: "Select shader for new material:"
                color: Theme.textColor
                font.pixelSize: 12
            }
            
            ComboBox {
                id: newShaderCombo
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                model: root.shaderModel
                textRole: "name"
                font.pixelSize: 13
                
                Component.onCompleted: setDefaultShader()
                
                function setDefaultShader() {
                    for (var i = 0; i < root.shaderModel.count; i++) {
                        if (root.shaderModel.get(i).name.toLowerCase() === "lightmappedgeneric") {
                            currentIndex = i
                            break
                        }
                    }
                }
                
                background: Rectangle {
                    color: newShaderCombo.pressed ? "#2a2d2e" : (newShaderCombo.hovered ? "#3c3c3c" : Theme.inputBg)
                    border.color: newShaderCombo.activeFocus ? Theme.accent : Theme.inputBorder
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Text {
                    leftPadding: 12
                    rightPadding: 30
                    text: newShaderCombo.displayText
                    color: Theme.textColor
                    font: newShaderCombo.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                indicator: Image {
                    x: parent.width - width - 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    source: "qrc:/media/nav-arrow.svg"
                    sourceSize: Qt.size(10, 10)
                }
                
                delegate: ItemDelegate {
                    id: newShaderDelegate
                    required property int index
                    required property var model
                    
                    property bool isFirstInCategory: {
                        if (index === 0) return true
                        var prevItem = root.shaderModel.get(index - 1)
                        return prevItem ? prevItem.category !== model.category : true
                    }
                    
                    width: newShaderCombo.width
                    height: 32
                    hoverEnabled: true
                    padding: 0
                    
                    contentItem: Item {
                        anchors.fill: parent
                        
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Theme.panelBorder
                            visible: newShaderDelegate.isFirstInCategory && newShaderDelegate.index > 0
                        }
                        
                        Image {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            visible: newShaderDelegate.isFirstInCategory
                            source: newShaderDelegate.model.category === "Common" ? "qrc:/media/star.svg" : "qrc:/media/star-outline.svg"
                            sourceSize: Qt.size(12, 12)
                        }
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: newShaderDelegate.model.name
                            color: newShaderDelegate.highlighted ? "#ffffff" : Theme.textColor
                            font.pixelSize: 13
                        }
                    }
                    
                    background: Rectangle { 
                        color: newShaderDelegate.highlighted ? Theme.accent : (newShaderDelegate.hovered ? "#3c3c3c" : "transparent")
                    }
                    highlighted: newShaderCombo.highlightedIndex === index
                }
                
                popup: Popup {
                    y: newShaderCombo.height + 2
                    width: newShaderCombo.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 2, 300)
                    padding: 1
                    
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: newShaderCombo.popup.visible ? newShaderCombo.delegateModel : null
                        currentIndex: newShaderCombo.highlightedIndex
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    
                    background: Rectangle {
                        color: "#1e1e1e"
                        border.color: Theme.panelBorder
                        border.width: 1
                        radius: 4
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
                    id: cancelNewBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: cancelNewMouse.containsMouse || cancelNewBtn.activeFocus ? Theme.buttonHover : Theme.buttonBg
                    border.color: cancelNewBtn.activeFocus ? Theme.accent : "transparent"
                    border.width: 1
                    
                    focus: false
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.close()
                    Keys.onEnterPressed: root.close()
                    Keys.onSpacePressed: root.close()
                    
                    scale: cancelNewMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textColor
                        font.pixelSize: 13
                    }
                    
                    MouseArea {
                        id: cancelNewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
                
                Rectangle {
                    id: createNewBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: okNewMouse.containsMouse || createNewBtn.activeFocus ? Theme.accentHover : Theme.accent
                    border.color: createNewBtn.activeFocus ? "#ffffff" : "transparent"
                    border.width: 1
                    
                    focus: true
                    activeFocusOnTab: true
                    Keys.onReturnPressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    Keys.onEnterPressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    Keys.onSpacePressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    
                    scale: okNewMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Create"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: okNewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.createMaterial(newShaderCombo.currentText)
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
