import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

Dialog {
    id: root
    
    required property var shaderModel
    required property var themeRoot
    signal createMaterial(string shaderName)
    
    modal: true
    anchors.centerIn: parent
    width: 400
    padding: 0
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: { createMaterial(newShaderCombo.currentText); close() }
    Keys.onEnterPressed: { createMaterial(newShaderCombo.currentText); close() }
    
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
    
    onOpened: { newShaderCombo.setDefaultShader(); newShaderCombo.forceActiveFocus() }
    
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
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                
                ThemedIcon {
                    width: 18
                    height: 18
                    source: "qrc:/media/file-new.svg"
                    sourceSize: Qt.size(18, 18)
                    themeRoot: root.themeRoot
                }
                
                Text {
                    text: "New Material"
                    color: themeRoot.textColor
                    font.pixelSize: 15
                    font.bold: true
                }
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
            
            Text {
                text: "Select shader for new material:"
                color: themeRoot.textColor
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
                    color: newShaderCombo.pressed ? themeRoot.buttonPressed : (newShaderCombo.hovered ? themeRoot.buttonHover : themeRoot.inputBg)
                    border.color: newShaderCombo.activeFocus ? themeRoot.accent : themeRoot.inputBorder
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Text {
                    leftPadding: 12
                    rightPadding: 30
                    text: newShaderCombo.displayText
                    color: themeRoot.textColor
                    font: newShaderCombo.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                indicator: ThemedIcon {
                    x: parent.width - width - 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    source: "qrc:/media/nav-arrow.svg"
                    sourceSize: Qt.size(10, 10)
                    themeRoot: root.themeRoot
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
                            color: themeRoot.panelBorder
                            visible: newShaderDelegate.isFirstInCategory && newShaderDelegate.index > 0
                        }
                        
                        ThemedIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            visible: newShaderDelegate.isFirstInCategory
                            source: newShaderDelegate.model.category === "Common" ? "qrc:/media/star.svg" : "qrc:/media/star-outline.svg"
                            sourceSize: Qt.size(12, 12)
                            themeRoot: root.themeRoot
                        }
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: newShaderDelegate.model.name
                            color: newShaderDelegate.highlighted ? themeRoot.textBright : themeRoot.textColor
                            font.pixelSize: 13
                        }
                    }
                    
                    background: Rectangle { 
                        color: newShaderDelegate.highlighted ? themeRoot.accent : (newShaderDelegate.hovered ? themeRoot.listItemHover : "transparent")
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
                        color: themeRoot.dialogBg
                        border.color: themeRoot.dialogBorder
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
                    id: cancelNewBtn
                    width: 90
                    height: 32
                    radius: 4
                    color: cancelNewMouse.containsMouse || cancelNewBtn.activeFocus ? themeRoot.buttonHover : themeRoot.buttonBg
                    border.color: cancelNewBtn.activeFocus ? themeRoot.accent : "transparent"
                    border.width: 1
                    
                    focus: false
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.close()
                    Keys.onEnterPressed: root.close()
                    Keys.onSpacePressed: root.close()
                    
                    scale: cancelNewMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: themeRoot.textColor
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
                    color: okNewMouse.containsMouse || createNewBtn.activeFocus ? themeRoot.accentHover : themeRoot.accent
                    border.color: createNewBtn.activeFocus ? "#ffffff" : "transparent"
                    border.width: 1
                    
                    focus: true
                    activeFocusOnTab: true
                    Keys.onReturnPressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    Keys.onEnterPressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    Keys.onSpacePressed: { root.createMaterial(newShaderCombo.currentText); root.close() }
                    
                    scale: okNewMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
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
