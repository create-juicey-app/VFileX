import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

MenuBar {
    id: menuBarRoot
    
    // Theme colors (from themeRoot)
    readonly property color panelBg: themeRoot.panelBg
    readonly property color panelBorder: themeRoot.panelBorder
    readonly property color textColor: themeRoot.textColor
    readonly property color textDim: themeRoot.textDim
    readonly property color accent: themeRoot.accent
    readonly property color buttonHover: themeRoot.buttonHover
    readonly property int animDurationFast: themeRoot.animDurationFast
    
    required property var materialModel
    required property var previewPane
    required property var app
    required property var themeRoot
    
    property var shortcutMap: ({})
    property string currentTheme: "Default"
    property var availableThemes: []
    
    signal newMaterial()
    signal openFile()
    signal openVmtOnly()
    signal openVtfOnly()
    signal saveFile()
    signal saveFileAs()
    signal exitApp()
    signal textureBrowser()
    signal imageToVtf()
    signal selectGame()
    signal browseMaterialsFolder()
    signal showAbout()
    signal themeChanged(string themeName)
    
    function getShortcutFor(text) {
        return shortcutMap[text] || ""
    }
    
    function loadAvailableThemes() {
        var themes = app.get_available_themes()
        availableThemes = themes
    }
    
    Component.onCompleted: {
        loadAvailableThemes()
        // Set current theme from app settings
        if (app.theme !== "") {
            currentTheme = app.theme
        }
    }
    
    background: Rectangle { color: panelBg }
    
    delegate: MenuBarItem {
        id: menuBarItem
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8
            Text {
                text: menuBarItem.text.replace("&", "")
                font: menuBarItem.font
                color: textColor
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
        }
        background: Rectangle {
            anchors.fill: parent
            color: menuBarItem.highlighted ? accent : (menuBarItem.hovered ? buttonHover : "transparent")
            Behavior on color { ColorAnimation { duration: animDurationFast } }
        }
    }
    
    Menu {
        title: "&File"
        
        delegate: MenuItem {
            id: fileMenuItem
            implicitWidth: contentItem.implicitWidth
            contentItem: RowLayout {
                spacing: 8
                ThemedIcon {
                    source: fileMenuItem.icon.source
                    sourceSize: Qt.size(16, 16)
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: fileMenuItem.icon.source != ""
                    themeRoot: menuBarRoot.themeRoot
                }
                Text {
                    text: fileMenuItem.text
                    color: fileMenuItem.enabled ? textColor : textDim
                    font: fileMenuItem.font
                    Layout.fillWidth: true
                }
                Text {
                    text: menuBarRoot.getShortcutFor(fileMenuItem.text)
                    color: textDim
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }
            background: Rectangle { anchors.fill: parent; color: fileMenuItem.highlighted ? accent : "transparent"; radius: 4 }
        }
        background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
        
        Action { text: "New..."; icon.source: "qrc:/media/file-new.svg"; onTriggered: menuBarRoot.newMaterial() }
        Action { text: "Open..."; icon.source: "qrc:/media/file-open.svg"; onTriggered: menuBarRoot.openFile() }
        
        Menu {
            title: "Open Specific"
            delegate: MenuItem {
                id: openSpecificMenuItem
                implicitWidth: contentItem.implicitWidth
                contentItem: RowLayout {
                    spacing: 8
                    ThemedIcon {
                        source: openSpecificMenuItem.icon.source
                        sourceSize: Qt.size(16, 16)
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        visible: openSpecificMenuItem.icon.source != ""
                        themeRoot: menuBarRoot.themeRoot
                    }
                    Text {
                        text: openSpecificMenuItem.text
                        color: textColor
                        font: openSpecificMenuItem.font
                        Layout.fillWidth: true
                    }
                }
                background: Rectangle { anchors.fill: parent; color: openSpecificMenuItem.highlighted ? accent : "transparent"; radius: 4 }
            }
            background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
            
            Action { text: "Open VMT Only..."; icon.source: "qrc:/media/file-open.svg"; onTriggered: menuBarRoot.openVmtOnly() }
            Action { text: "Open VTF Only..."; icon.source: "qrc:/media/image.svg"; onTriggered: menuBarRoot.openVtfOnly() }
        }
        
        MenuSeparator {}
        Action { text: "Save"; icon.source: "qrc:/media/save.svg"; enabled: materialModel.is_loaded; onTriggered: menuBarRoot.saveFile() }
        Action { text: "Save As..."; icon.source: "qrc:/media/save-as.svg"; enabled: materialModel.is_loaded; onTriggered: menuBarRoot.saveFileAs() }
        MenuSeparator {}
        Action { text: "Exit"; icon.source: "qrc:/media/close.svg"; onTriggered: menuBarRoot.exitApp() }
    }
    
    Menu {
        title: "&View"
        delegate: MenuItem {
            id: viewMenuItem
            implicitWidth: contentItem.implicitWidth
            contentItem: RowLayout {
                spacing: 8
                ThemedIcon {
                    source: viewMenuItem.icon.source
                    sourceSize: Qt.size(16, 16)
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: viewMenuItem.icon.source != ""
                    themeRoot: menuBarRoot.themeRoot
                }
                Text {
                    text: viewMenuItem.text
                    color: viewMenuItem.enabled ? textColor : textDim
                    font: viewMenuItem.font
                    Layout.fillWidth: true
                }
                Text {
                    text: menuBarRoot.getShortcutFor(viewMenuItem.text)
                    color: textDim
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }
            background: Rectangle { anchors.fill: parent; color: viewMenuItem.highlighted ? accent : "transparent"; radius: 4 }
        }
        background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
        
        Action { text: "Zoom In"; icon.source: "qrc:/media/plus.svg"; onTriggered: previewPane.zoomIn() }
        Action { text: "Zoom Out"; icon.source: "qrc:/media/minus.svg"; onTriggered: previewPane.zoomOut() }
        Action { text: "Reset Zoom"; icon.source: "qrc:/media/refresh.svg"; onTriggered: previewPane.resetZoom() }
        Action { text: "Fit to View"; icon.source: "qrc:/media/fit-screen.svg"; onTriggered: previewPane.fitToView() }
        MenuSeparator {}
        Action { text: "Actual Size (1:1)"; icon.source: "qrc:/media/layers.svg"; onTriggered: previewPane.setActualSize() }
    }
    
    Menu {
        title: "&Tools"
        delegate: MenuItem {
            id: toolsMenuItem
            implicitWidth: contentItem.implicitWidth
            contentItem: RowLayout {
                spacing: 8
                ThemedIcon {
                    source: toolsMenuItem.icon.source
                    sourceSize: Qt.size(16, 16)
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: toolsMenuItem.icon.source != ""
                    themeRoot: menuBarRoot.themeRoot
                }
                Text {
                    text: toolsMenuItem.text
                    color: toolsMenuItem.enabled ? textColor : textDim
                    font: toolsMenuItem.font
                    Layout.fillWidth: true
                }
                Text {
                    text: menuBarRoot.getShortcutFor(toolsMenuItem.text)
                    color: textDim
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }
            background: Rectangle { anchors.fill: parent; color: toolsMenuItem.highlighted ? accent : "transparent"; radius: 4 }
        }
        background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
        
        Action { text: "Texture Browser..."; icon.source: "qrc:/media/texture.svg"; onTriggered: menuBarRoot.textureBrowser() }
        MenuSeparator {}
        Action { text: "Image to VTF Converter..."; icon.source: "qrc:/media/image.svg"; onTriggered: menuBarRoot.imageToVtf() }
    }
    
    Menu {
        title: "&Settings"
        
        property string selectedGame: ""
        
        delegate: MenuItem {
            id: settingsMenuItem
            implicitWidth: contentItem.implicitWidth
            contentItem: RowLayout {
                spacing: 8
                ThemedIcon {
                    source: settingsMenuItem.icon.source
                    sourceSize: Qt.size(16, 16)
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: settingsMenuItem.icon.source != ""
                    themeRoot: menuBarRoot.themeRoot
                }
                Text {
                    text: settingsMenuItem.text
                    color: settingsMenuItem.enabled ? textColor : textDim
                    font: settingsMenuItem.font
                    Layout.fillWidth: true
                }
                Text {
                    text: menuBarRoot.getShortcutFor(settingsMenuItem.text)
                    color: textDim
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }
            background: Rectangle { anchors.fill: parent; color: settingsMenuItem.highlighted ? accent : "transparent"; radius: 4 }
        }
        background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
        
        Action { text: "Select Game..."; icon.source: "qrc:/media/gamepad.svg"; onTriggered: menuBarRoot.selectGame() }
        Action { text: "Browse Materials Folder..."; icon.source: "qrc:/media/folder.svg"; onTriggered: menuBarRoot.browseMaterialsFolder() }
        MenuSeparator {}
        
        Menu {
            id: themeSubmenu
            title: "Theme"
            
            delegate: MenuItem {
                id: themeMenuItem
                implicitWidth: contentItem.implicitWidth
                contentItem: RowLayout {
                    spacing: 8
                    ThemedIcon {
                        source: themeMenuItem.icon.source
                        sourceSize: Qt.size(16, 16)
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        visible: themeMenuItem.icon.source != ""
                        themeRoot: menuBarRoot.themeRoot
                    }
                    Text {
                        text: themeMenuItem.text
                        color: textColor
                        font: themeMenuItem.font
                        Layout.fillWidth: true
                    }
                    Text {
                        text: themeMenuItem.text === menuBarRoot.currentTheme ? "✓" : ""
                        color: accent
                        font.pixelSize: 12
                    }
                }
                background: Rectangle { anchors.fill: parent; color: themeMenuItem.highlighted ? accent : "transparent"; radius: 4 }
            }
            background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
            
            Instantiator {
                model: menuBarRoot.availableThemes
                delegate: Action {
                    text: modelData
                    icon.source: "qrc:/media/palette.svg"
                    onTriggered: {
                        menuBarRoot.currentTheme = modelData
                        menuBarRoot.app.set_current_theme(modelData)
                    }
                }
                onObjectAdded: (index, object) => themeSubmenu.insertAction(index, object)
                onObjectRemoved: (index, object) => themeSubmenu.removeAction(object)
            }
            
            MenuSeparator {}
            Action { 
                text: "Open Themes Folder..."
                icon.source: "qrc:/media/folder.svg"
                onTriggered: menuBarRoot.app.reveal_in_explorer(menuBarRoot.app.get_themes_dir())
            }
        }
        
        MenuSeparator {}
        Action { text: "Current: " + (menuBarRoot.selectedGame || "Not Set"); icon.source: "qrc:/media/info.svg"; enabled: false }
    }
    
    Menu {
        title: "&Help"
        delegate: MenuItem {
            id: helpMenuItem
            implicitWidth: contentItem.implicitWidth
            contentItem: RowLayout {
                spacing: 8
                ThemedIcon {
                    source: helpMenuItem.icon.source
                    sourceSize: Qt.size(16, 16)
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: helpMenuItem.icon.source != ""
                    themeRoot: menuBarRoot.themeRoot
                }
                Text {
                    text: helpMenuItem.text
                    color: helpMenuItem.enabled ? textColor : textDim
                    font: helpMenuItem.font
                    Layout.fillWidth: true
                }
                Text {
                    text: menuBarRoot.getShortcutFor(helpMenuItem.text)
                    color: textDim
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }
            background: Rectangle { anchors.fill: parent; color: helpMenuItem.highlighted ? accent : "transparent"; radius: 4 }
        }
        background: Rectangle { color: panelBg; border.color: panelBorder; radius: 6 }
        
        Action { text: "About VFileX"; icon.source: "qrc:/media/help.svg"; onTriggered: menuBarRoot.showAbout() }
    }
    
    property string selectedGame: ""
}
