import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import com.VFileX 1.0
import "ThemeColors.js" as Theme

ApplicationWindow {
    id: root
    
    function urlToLocalPath(url) {
        var path = url.toString()
        if (path.startsWith("file:///")) {
            var afterScheme = path.substring(8)
            if (afterScheme.length >= 2 && afterScheme[1] === ':') {
                return afterScheme
            } else {
                return "/" + afterScheme
            }
        } else if (path.startsWith("file://")) {
            return path.substring(7)
        }
        return path
    }
    
    width: 1400
    height: 900
    minimumWidth: 1000
    minimumHeight: 600
    visible: true
    title: materialModel.is_modified ? 
           `VFileX - ${materialModel.file_path || "Untitled"}*` :
           `VFileX - ${materialModel.file_path || "Untitled"}`
    color: Theme.windowBg
    
    // Use Theme singleton for all colors
    readonly property color panelBg: Theme.panelBg
    readonly property color panelBorder: Theme.panelBorder
    readonly property color inputBg: Theme.inputBg
    readonly property color inputBorder: Theme.inputBorder
    readonly property color textColor: Theme.textColor
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent
    readonly property color accentHover: Theme.accentHover
    readonly property color buttonBg: Theme.buttonBg
    readonly property color buttonHover: Theme.buttonHover
    readonly property int radius: Theme.radius

    readonly property int animDurationFast: Theme.animDurationFast
    readonly property int animDurationNormal: Theme.animDurationNormal
    readonly property int animDurationSlow: Theme.animDurationSlow
    readonly property int animEasing: Theme.animEasing
    readonly property int animEasingBounce: Theme.animEasingBounce
    
    // Dialog overlay styling
    Overlay.modal: Rectangle {
        color: Theme.overlayBg
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
    }
    Overlay.modeless: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.3)
    }

    function showNotification(message, bgColor, iconSrc) {
        notificationText.text = message
        notificationBg.color = bgColor || Theme.accent
        if (iconSrc && iconSrc !== "") {
            notificationIcon.source = iconSrc
            notificationIcon.visible = true
        } else {
            notificationIcon.visible = false
        }
        notificationPopup.open()
        notificationTimer.restart()
    }

    VFileXApp {
        id: app
        Component.onCompleted: {
            initialize()
            loadShaders()
        }
        
        function loadShaders() {
            shaderModel.clear()
            var shaders = get_supported_shaders()
            
            var commonShaders = [
                "LightmappedGeneric",
                "VertexLitGeneric", 
                "UnlitGeneric",
                "WorldVertexTransition",
                "Water",
                "Refract",
                "SDK_Eyes",
                "Teeth",
                "DecalModulate"
            ]
            
            for (var i = 0; i < commonShaders.length; i++) {
                for (var j = 0; j < shaders.length; j++) {
                    if (shaders[j].toLowerCase() === commonShaders[i].toLowerCase()) {
                        shaderModel.append({"name": shaders[j], "category": "Common"})
                        break
                    }
                }
            }
            
            for (var k = 0; k < shaders.length; k++) {
                var isCommon = false
                for (var l = 0; l < commonShaders.length; l++) {
                    if (shaders[k].toLowerCase() === commonShaders[l].toLowerCase()) {
                        isCommon = true
                        break
                    }
                }
                if (!isCommon) {
                    shaderModel.append({"name": shaders[k], "category": "Other"})
                }
            }
        }
    }
    
    ListModel { id: shaderModel }
    ListModel { id: parameterListModel }
    
    property var collapsedCategories: ({})
    
    function isCategoryCollapsed(category) {
        return collapsedCategories[category] === true
    }
    
    function toggleCategory(category) {
        var newState = !isCategoryCollapsed(category)
        var updated = Object.assign({}, collapsedCategories)
        updated[category] = newState
        collapsedCategories = updated
    }
    
    function rebuildParameterList() {
        parameterListModel.clear()
        var count = materialModel.parameter_count
        for (var i = 0; i < count; i++) {
            var name = materialModel.get_param_name(i)
            var displayName = materialModel.get_param_display_name(i)
            var value = materialModel.get_param_value(i)
            var dataType = materialModel.get_param_data_type(i)
            var minVal = materialModel.get_param_min(i)
            var maxVal = materialModel.get_param_max(i)
            var category = materialModel.get_param_category(i)
            
            parameterListModel.append({
                "paramIndex": i,
                "paramName": name || "",
                "paramDisplayName": displayName || name || "",
                "paramValue": value || "",
                "paramDataType": dataType || "string",
                "paramMinValue": minVal || 0,
                "paramMaxValue": maxVal || 1,
                "paramCategory": category || "Other"
            })
        }
    }
    
    MaterialModel {
        id: materialModel
        onMaterial_loaded: {
            rebuildParameterList()
            for (var i = 0; i < shaderModel.count; i++) {
                if (shaderModel.get(i).name.toLowerCase() === shader_name.toLowerCase()) {
                    shaderCombo.currentIndex = i
                    break
                }
            }
            if (get_base_texture() !== "") {
                globalTextureProvider.load_from_material_path(get_base_texture(), app.materials_root)
            }
        }
        onParameter_countChanged: {
            rebuildParameterList()
        }
        onParameter_changed: function(name) {
            if (name.toLowerCase() === "$basetexture") {
                var texturePath = get_parameter_value(name)
                if (texturePath !== "") {
                    globalTextureProvider.load_from_material_path(texturePath, app.materials_root)
                }
            }
            for (var i = 0; i < parameterListModel.count; i++) {
                if (parameterListModel.get(i).paramName === name) {
                    parameterListModel.setProperty(i, "paramValue", get_parameter_value(name))
                    break
                }
            }
        }
        onError_occurred: function(msg) {
            // Error handling - could show a toast/notification here
        }
    }
    
    TextureProvider {
        id: globalTextureProvider
    }
    
    
    FileDialog {
        id: openFileDialog
        title: "Open File"
        nameFilters: ["Source Files (*.vmt *.vtf)", "VMT Files (*.vmt)", "VTF Files (*.vtf)", "All Files (*)"]
        onAccepted: {
            var path = root.urlToLocalPath(selectedFile)
            root.openFile(path)
        }
    }
    
    function openFile(path) {
        var lowerPath = path.toLowerCase()
        
        if (lowerPath.endsWith(".vmt")) {
            materialModel.load_file(path)
            tryLoadAssociatedVtf(path)
        } else if (lowerPath.endsWith(".vtf")) {
            globalTextureProvider.load_texture(path)
            tryLoadAssociatedVmt(path)
        } else {
            if (!materialModel.load_file(path)) {
                globalTextureProvider.load_texture(path)
            }
        }
    }
    
    function tryLoadAssociatedVtf(vmtPath) {
        Qt.callLater(function() {
            if (materialModel.is_loaded) {
                var baseTexture = materialModel.get_parameter_value("$basetexture")
                if (baseTexture && baseTexture.length > 0) {
                    if (app.materials_root.length > 0) {
                        globalTextureProvider.load_from_material_path(baseTexture, app.materials_root)
                    } else {
                        var vtfPath = vmtPath.replace(/\.vmt$/i, ".vtf")
                        globalTextureProvider.load_texture(vtfPath)
                    }
                } else {
                    var vtfPath = vmtPath.replace(/\.vmt$/i, ".vtf")
                    globalTextureProvider.load_texture(vtfPath)
                }
            }
        })
    }
    
    function tryLoadAssociatedVmt(vtfPath) {
        var vmtPath = vtfPath.replace(/\.vtf$/i, ".vmt")
        var lowerPath = vtfPath.toLowerCase()
        if (lowerPath.indexOf("/materials/") !== -1) {
            materialModel.load_file(vmtPath)
        } else {
            materialModel.load_file(vmtPath)
        }
    }
    
    FileDialog {
        id: saveFileDialog
        title: "Save VMT File"
        fileMode: FileDialog.SaveFile
        nameFilters: ["VMT Files (*.vmt)"]
        onAccepted: {
            var path = root.urlToLocalPath(selectedFile)
            materialModel.save_file(path)
        }
    }
    
    FileDialog {
        id: openVmtDialog
        title: "Open VMT File"
        nameFilters: ["VMT Files (*.vmt)", "All Files (*)"]
        onAccepted: {
            var path = root.urlToLocalPath(selectedFile)
            materialModel.load_file(path)
            tryLoadAssociatedVtf(path)
        }
    }
    
    FileDialog {
        id: openVtfDialog
        title: "Open VTF Texture"
        nameFilters: ["VTF Files (*.vtf)", "All Files (*)"]
        onAccepted: {
            var path = root.urlToLocalPath(selectedFile)
            globalTextureProvider.load_texture(path)
            tryLoadAssociatedVmt(path)
        }
    }
    
    property var shortcutMap: ({
        "New...": "Ctrl+N",
        "Open...": "Ctrl+O",
        "Save": "Ctrl+S",
        "Save As...": "Ctrl+Shift+S",
        "Exit": "Ctrl+Q",
        "Zoom In": "Ctrl+=",
        "Zoom Out": "Ctrl+-",
        "Reset Zoom": "Ctrl+0",
        "Fit to View": "Ctrl+1",
        "Actual Size (1:1)": "Ctrl+2",
        "Texture Browser...": "Ctrl+T",
        "Image to VTF Converter...": "Ctrl+I",
        "Select Game...": "Ctrl+G",
        "About VFileX": "F1"
    })
    
    function getShortcutFor(text) {
        return shortcutMap[text] || ""
    }
    
    Shortcut { sequence: "Ctrl+N"; context: Qt.ApplicationShortcut; onActivated: newMaterialDialog.open() }
    Shortcut { sequence: "Ctrl+O"; context: Qt.ApplicationShortcut; onActivated: openFileDialog.open() }
    Shortcut { sequence: "Ctrl+S"; context: Qt.ApplicationShortcut; onActivated: if (materialModel.is_loaded) materialModel.save_file(materialModel.file_path) }
    Shortcut { sequence: "Ctrl+Shift+S"; context: Qt.ApplicationShortcut; onActivated: if (materialModel.is_loaded) saveFileDialog.open() }
    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequence: "Ctrl+="; context: Qt.ApplicationShortcut; onActivated: previewPane.zoomIn() }
    Shortcut { sequence: "Ctrl+-"; context: Qt.ApplicationShortcut; onActivated: previewPane.zoomOut() }
    Shortcut { sequence: "Ctrl+0"; context: Qt.ApplicationShortcut; onActivated: previewPane.resetZoom() }
    Shortcut { sequence: "Ctrl+1"; context: Qt.ApplicationShortcut; onActivated: previewPane.fitToView() }
    Shortcut { sequence: "Ctrl+2"; context: Qt.ApplicationShortcut; onActivated: previewPane.setActualSize() }
    Shortcut { sequence: "Ctrl+T"; context: Qt.ApplicationShortcut; onActivated: { globalTextureBrowser.openMode = true; globalTextureBrowser.targetTextField = null; globalTextureBrowser.open() } }
    Shortcut { sequence: "Ctrl+I"; context: Qt.ApplicationShortcut; onActivated: imageToVtfDialog.open() }
    Shortcut { sequence: "Ctrl+G"; context: Qt.ApplicationShortcut; onActivated: { welcomeDialog.loadDetectedGames(); welcomeDialog.selectedIndex = -1; welcomeDialog.open() } }
    Shortcut { sequence: "F1"; context: Qt.ApplicationShortcut; onActivated: aboutDialog.open() }
    
    menuBar: AppMenuBar {
        id: appMenuBar
        materialModel: materialModel
        previewPane: previewPane
        shortcutMap: root.shortcutMap
        selectedGame: app.selected_game
        
        onNewMaterial: newMaterialDialog.open()
        onOpenFile: openFileDialog.open()
        onOpenVmtOnly: openVmtDialog.open()
        onOpenVtfOnly: openVtfDialog.open()
        onSaveFile: materialModel.save_file(materialModel.file_path)
        onSaveFileAs: saveFileDialog.open()
        onExitApp: Qt.quit()
        onTextureBrowser: { globalTextureBrowser.openMode = true; globalTextureBrowser.targetTextField = null; globalTextureBrowser.open() }
        onImageToVtf: imageToVtfDialog.open()
        onSelectGame: { welcomeDialog.loadDetectedGames(); welcomeDialog.selectedIndex = -1; welcomeDialog.open() }
        onBrowseMaterialsFolder: {
            var path = app.browse_folder_native("Select Materials Folder")
            if (path.length > 0) app.set_materials_root_path(path)
        }
        onShowAbout: aboutDialog.open()
    }
    
    Popup {
        id: notificationPopup
        x: (root.width - width) / 2
        y: root.height - height - 40
        width: Math.min(400, notificationText.implicitWidth + 48)
        height: 48
        padding: 0
        closePolicy: Popup.NoAutoClose
        
        background: Rectangle {
            id: notificationBg
            color: "#4CAF50"
            radius: 8
            border.width: 1
            border.color: Qt.lighter(color, 1.2)
            
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                color: "transparent"
                radius: 10
                border.width: 4
                border.color: Qt.rgba(0, 0, 0, 0.3)
            }
        }
        
        contentItem: Rectangle {
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                
                Image {
                    id: notificationIcon
                    width: 18; height: 18
                    visible: false
                    fillMode: Image.PreserveAspectFit
                }
                
                Text {
                    id: notificationText
                    text: ""
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                NumberAnimation { property: "y"; from: root.height; to: root.height - notificationPopup.height - 40; duration: 200; easing.type: Easing.OutCubic }
            }
        }
        
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
                NumberAnimation { property: "y"; to: root.height; duration: 200; easing.type: Easing.InCubic }
            }
        }
    }
    
    Timer {
        id: notificationTimer
        interval: 3000
        onTriggered: notificationPopup.close()
    }
    
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 5
            color: SplitHandle.hovered ? root.accent : root.panelBorder
        }
        
        Rectangle {
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 300
            color: root.panelBg
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                Text {
                    visible: materialModel.is_loaded
                    Layout.fillWidth: true
                    text: materialModel.file_path.toString().split('/').pop() || "Untitled"
                    color: root.textColor
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "Shader"
                        color: root.textDim
                        font.pixelSize: 11
                        font.bold: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: root.inputBg
                        border.color: root.inputBorder
                        border.width: 1
                        radius: root.radius
                        
                        Text {
                            visible: materialModel.is_loaded
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            text: materialModel.shader_name
                            color: root.textColor
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        ComboBox {
                            id: shaderCombo
                            visible: !materialModel.is_loaded
                            anchors.fill: parent
                            anchors.margins: 2
                            model: shaderModel
                            textRole: "name"
                            font.pixelSize: 13
                            
                            background: Rectangle { 
                                color: shaderCombo.pressed ? "#2a2d2e" : (shaderCombo.hovered ? "#323232" : "transparent")
                                radius: 4
                                Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                            }
                            
                            contentItem: Text {
                                leftPadding: 12
                                text: shaderCombo.displayText || "Select a shader..."
                                color: shaderCombo.displayText ? root.textColor : root.textDim
                                font: shaderCombo.font
                                verticalAlignment: Text.AlignVCenter
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
                                id: shaderDelegate
                                required property int index
                                required property var model
                                
                                property bool isFirstInCategory: {
                                    if (index === 0) return true
                                    var prevItem = shaderModel.get(index - 1)
                                    return prevItem ? prevItem.category !== model.category : true
                                }
                                
                                width: shaderCombo.width
                                height: 32
                                hoverEnabled: true
                                padding: 0
                                
                                contentItem: Item {
                                    anchors.fill: parent
                                    
                                    Rectangle {
                                        anchors.top: parent.top
                                        width: parent.width
                                        height: 1
                                        color: root.panelBorder
                                        visible: shaderDelegate.isFirstInCategory && shaderDelegate.index > 0
                                    }
                                    
                                    Image {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        visible: shaderDelegate.isFirstInCategory
                                        source: shaderDelegate.model.category === "Common" ? "qrc:/media/star.svg" : "qrc:/media/star-outline.svg"
                                        sourceSize: Qt.size(12, 12)
                                    }
                                    
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: shaderDelegate.model.name
                                        color: shaderDelegate.highlighted ? "#ffffff" : root.textColor
                                        font.pixelSize: 13
                                    }
                                }
                                
                                background: Rectangle { 
                                    color: shaderDelegate.highlighted ? root.accent : (shaderDelegate.hovered ? "#3c3c3c" : "transparent")
                                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                                }
                                highlighted: shaderCombo.highlightedIndex === index
                            }
                            
                            popup: Popup {
                                y: shaderCombo.height
                                width: shaderCombo.width
                                implicitHeight: Math.min(contentItem.implicitHeight + 2, 300)
                                padding: 1
                                
                                enter: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationFast; easing.type: root.animEasing }
                                        NumberAnimation { property: "y"; from: shaderCombo.height - 8; to: shaderCombo.height; duration: root.animDurationFast; easing.type: root.animEasing }
                                    }
                                }
                                exit: Transition {
                                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationFast; easing.type: Easing.InCubic }
                                }
                                
                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: shaderCombo.popup.visible ? shaderCombo.delegateModel : null
                                    currentIndex: shaderCombo.highlightedIndex
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                }
                                
                                background: Rectangle {
                                    color: "#1e1e1e"
                                    border.color: root.panelBorder
                                    border.width: 1
                                    radius: 4
                                }
                            }
                            
                            onActivated: {
                                if (currentText !== materialModel.shader_name) {
                                    materialModel.set_shader(currentText)
                                }
                            }
                        }
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: materialModel.is_loaded ? 
                              materialModel.get_shader_description(materialModel.shader_name) :
                              (shaderCombo.currentText ? materialModel.get_shader_description(shaderCombo.currentText) : "")
                        color: root.textDim
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.panelBorder
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    
                    Text {
                        text: "Parameters"
                        color: root.textColor
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    ListView {
                        id: paramList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: parameterListModel
                        
                        property real scrollBarWidth: paramListScrollBar.visible ? paramListScrollBar.width : 0
                        
                        ScrollBar.vertical: ScrollBar { 
                            id: paramListScrollBar
                            policy: ScrollBar.AsNeeded 
                        }
                        
                        section.property: "paramCategory"
                        section.criteria: ViewSection.FullString
                        section.delegate: Rectangle {
                            width: paramList.width - 10 - paramList.scrollBarWidth
                            height: 36
                            color: "transparent"
                            
                            property bool isCollapsed: root.isCategoryCollapsed(section)
                            
                            MouseArea {
                                id: sectionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleCategory(section)
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                color: sectionMouseArea.containsMouse ? Qt.rgba(1,1,1,0.03) : "transparent"
                                radius: 4
                                Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                            }
                            
                            RowLayout {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -4
                                spacing: 6
                                
                                Image {
                                    width: 10
                                    height: 10
                                    source: "qrc:/media/nav-arrow.svg"
                                    sourceSize: Qt.size(10, 10)
                                    
                                    rotation: root.isCategoryCollapsed(section) ? 0 : -90
                                    Behavior on rotation { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                                }
                                
                                Text {
                                    text: section
                                    color: root.accent
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.capitalization: Font.AllUppercase
                                }
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6
                                height: 1
                                color: root.panelBorder
                            }
                        }
                        
                        delegate: ParameterItemDelegate {
                            listWidth: paramList.width
                            scrollBarWidth: paramList.scrollBarWidth
                            isCollapsed: root.isCategoryCollapsed(paramCategory)
                            textureProvider: globalTextureProvider
                            materialsRoot: app.materials_root
                            
                            onParameterChanged: function(name, value) {
                                materialModel.set_parameter_value(name, value)
                            }
                            onOpenColorPicker: function(targetField, initialColor) {
                                colorPickerDialog.targetTextField = targetField
                                colorPickerDialog.setInitialColor(initialColor)
                                colorPickerDialog.open()
                            }
                            onOpenTextureBrowser: function(targetField) {
                                globalTextureBrowser.targetTextField = targetField
                                globalTextureBrowser.openMode = false  // Selection mode, not open mode
                                globalTextureBrowser.open()
                            }
                            onLoadTexturePreview: function(texturePath) {
                                if (texturePath && texturePath.length > 0 && globalTextureProvider) {
                                    globalTextureProvider.load_from_material_path(texturePath, app.materials_root)
                                }
                            }
                        }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: addBtn.pressed ? "#094771" : (addBtn.containsMouse ? root.accentHover : root.accent)
                    radius: root.radius
                    
                    Text {
                        anchors.centerIn: parent
                        text: "+ Add Parameter"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: addBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addParamDialog.open()
                    }
                }
            }
        }
        
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400
            color: "#1a1a1a"
            
            PreviewPane {
                id: previewPane
                anchors.fill: parent
                textureProvider: globalTextureProvider
            }
        }
    }
    
    
    NewMaterialDialog {
        id: newMaterialDialog
        shaderModel: shaderModel
        onCreateMaterial: function(shaderName) {
            materialModel.new_material(shaderName)
        }
    }

    AddParameterDialog {
        id: addParamDialog
        onAddParameter: function(name, value) {
            materialModel.set_parameter_value(name, value)
        }
    }

    AboutDialog {
        id: aboutDialog
    }

    WelcomeDialog {
        id: welcomeDialog
        app: app
        onGameSelected: {
        }
        onSkipped: {
        }
    }

    ImageToVtfDialog {
        id: imageToVtfDialog
        app: app
        urlToLocalPath: root.urlToLocalPath
        onConversionComplete: function(successCount, totalCount) {
            if (successCount > 0) {
                root.showNotification(successCount + " of " + totalCount + " images converted successfully!", "#4CAF50", "qrc:/media/checkmark.svg")
            }
        }
    }

    FileDialog {
        id: addImageDialog
        title: "Select Images"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Image Files (*.png *.jpg *.jpeg *.bmp *.tga *.gif)", "All Files (*)"]
        onAccepted: {
            var paths = []
            for (var i = 0; i < selectedFiles.length; i++) {
                paths.push(root.urlToLocalPath(selectedFiles[i]))
            }
            imageToVtfDialog.selectedImages = imageToVtfDialog.selectedImages.concat(paths)
        }
    }

    ColorPickerDialog {
        id: colorPickerDialog
    }

    TextureBrowser {
        id: globalTextureBrowser
        app: app
        textureProvider: globalTextureProvider
    }
}

