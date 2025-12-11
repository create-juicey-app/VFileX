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
    color: panelBgColor  // Use dynamic property
    
    // Theme version counter to trigger rebinds
    property int themeVersion: 0
    
    // Dynamic theme colors (updated when theme changes)
    property color windowBgColor: Theme.windowBg
    property color panelBgColor: Theme.panelBg
    property color panelBorderColor: Theme.panelBorder
    property color dialogBgColor: Theme.dialogBg
    property color dialogBorderColor: Theme.dialogBorder
    property color dialogHeaderBgColor: Theme.dialogHeaderBg
    property color inputBgColor: Theme.inputBg
    property color inputBorderColor: Theme.inputBorder
    property color inputFocusBorderColor: Theme.inputFocusBorder
    property color textColorValue: Theme.textColor
    property color textDimColor: Theme.textDim
    property color textBrightColor: Theme.textBright
    property color iconColorValue: Theme.iconColor
    property color accentColor: Theme.accent
    property color accentHoverColor: Theme.accentHover
    property color accentPressedColor: Theme.accentPressed
    property color buttonBgColor: Theme.buttonBg
    property color buttonHoverColor: Theme.buttonHover
    property color buttonPressedColor: Theme.buttonPressed
    property color buttonSecondaryBgColor: Theme.buttonSecondaryBg
    property color buttonSecondaryHoverColor: Theme.buttonSecondaryHover
    property color buttonSecondaryTextColor: Theme.buttonSecondaryText
    property color dangerColorValue: Theme.dangerColor
    property color dangerHoverColor: Theme.dangerHover
    property color successColor: Theme.success
    property color warningColor: Theme.warning
    property color errorColor: Theme.error
    property color listItemBgColor: Theme.listItemBg
    property color listItemHoverColor: Theme.listItemHover
    property color listItemSelectedColor: Theme.listItemSelected
    property color separatorColor: Theme.separator
    property color overlayBgColor: Theme.overlayBg
    property color shadowColorValue: Theme.shadowColor
    property int radiusValue: Theme.radius
    property int radiusSmallValue: Theme.radiusSmall
    property int radiusLargeValue: Theme.radiusLarge
    property int dialogRadiusValue: Theme.dialogRadius

    property int animDurationFastValue: Theme.animDurationFast
    property int animDurationNormalValue: Theme.animDurationNormal
    property int animDurationSlowValue: Theme.animDurationSlow
    property int animEasingValue: Theme.animEasing
    property int animEasingBounceValue: Theme.animEasingBounce
    
    // Backwards-compatible aliases (for components that use root.*)
    readonly property color panelBg: panelBgColor
    readonly property color panelBorder: panelBorderColor
    readonly property color dialogBg: dialogBgColor
    readonly property color dialogBorder: dialogBorderColor
    readonly property color dialogHeaderBg: dialogHeaderBgColor
    readonly property color inputBg: inputBgColor
    readonly property color inputBorder: inputBorderColor
    readonly property color inputFocusBorder: inputFocusBorderColor
    readonly property color textColor: textColorValue
    readonly property color textDim: textDimColor
    readonly property color textBright: textBrightColor
    readonly property color iconColor: iconColorValue
    readonly property color accent: accentColor
    readonly property color accentHover: accentHoverColor
    readonly property color accentPressed: accentPressedColor
    readonly property color buttonBg: buttonBgColor
    readonly property color buttonHover: buttonHoverColor
    readonly property color buttonPressed: buttonPressedColor
    readonly property color buttonSecondaryBg: buttonSecondaryBgColor
    readonly property color buttonSecondaryHover: buttonSecondaryHoverColor
    readonly property color buttonSecondaryText: buttonSecondaryTextColor
    readonly property color dangerColor: dangerColorValue
    readonly property color dangerHover: dangerHoverColor
    readonly property color success: successColor
    readonly property color warning: warningColor
    readonly property color error: errorColor
    readonly property color listItemBg: listItemBgColor
    readonly property color listItemHover: listItemHoverColor
    readonly property color listItemSelected: listItemSelectedColor
    readonly property color separator: separatorColor
    readonly property color overlayBg: overlayBgColor
    readonly property color shadowColor: shadowColorValue
    readonly property int radius: radiusValue
    readonly property int radiusSmall: radiusSmallValue
    readonly property int radiusLarge: radiusLargeValue
    readonly property int dialogRadius: dialogRadiusValue
    readonly property int animDurationFast: animDurationFastValue
    readonly property int animDurationNormal: animDurationNormalValue
    readonly property int animDurationSlow: animDurationSlowValue
    readonly property int animEasing: animEasingValue
    readonly property int animEasingBounce: animEasingBounceValue
    
    // Function to apply a theme from JSON content
    function applyTheme(themeContentJson) {
        if (!themeContentJson || themeContentJson === "") return
        
        try {
            var themeData = JSON.parse(themeContentJson)
            
            // Apply theme to JS module
            Theme.applyTheme(themeData)
            
            // Update dynamic properties - Colors
            if (themeData.windowBg) windowBgColor = themeData.windowBg
            if (themeData.panelBg) panelBgColor = themeData.panelBg
            if (themeData.panelBorder) panelBorderColor = themeData.panelBorder
            if (themeData.dialogBg) dialogBgColor = themeData.dialogBg
            if (themeData.dialogBorder) dialogBorderColor = themeData.dialogBorder
            if (themeData.dialogHeaderBg) dialogHeaderBgColor = themeData.dialogHeaderBg
            if (themeData.inputBg) inputBgColor = themeData.inputBg
            if (themeData.inputBorder) inputBorderColor = themeData.inputBorder
            if (themeData.inputFocusBorder) inputFocusBorderColor = themeData.inputFocusBorder
            if (themeData.textColor) textColorValue = themeData.textColor
            if (themeData.textDim) textDimColor = themeData.textDim
            if (themeData.textBright) textBrightColor = themeData.textBright
            if (themeData.iconColor) iconColorValue = themeData.iconColor
            if (themeData.accent) accentColor = themeData.accent
            if (themeData.accentHover) accentHoverColor = themeData.accentHover
            if (themeData.accentPressed) accentPressedColor = themeData.accentPressed
            if (themeData.buttonBg) buttonBgColor = themeData.buttonBg
            if (themeData.buttonHover) buttonHoverColor = themeData.buttonHover
            if (themeData.buttonPressed) buttonPressedColor = themeData.buttonPressed
            if (themeData.buttonSecondaryBg) buttonSecondaryBgColor = themeData.buttonSecondaryBg
            if (themeData.buttonSecondaryHover) buttonSecondaryHoverColor = themeData.buttonSecondaryHover
            if (themeData.buttonSecondaryText) buttonSecondaryTextColor = themeData.buttonSecondaryText
            if (themeData.dangerColor) dangerColorValue = themeData.dangerColor
            if (themeData.dangerHover) dangerHoverColor = themeData.dangerHover
            if (themeData.success) successColor = themeData.success
            if (themeData.warning) warningColor = themeData.warning
            if (themeData.error) errorColor = themeData.error
            if (themeData.listItemBg) listItemBgColor = themeData.listItemBg
            if (themeData.listItemHover) listItemHoverColor = themeData.listItemHover
            if (themeData.listItemSelected) listItemSelectedColor = themeData.listItemSelected
            if (themeData.separator) separatorColor = themeData.separator
            if (themeData.overlayBg) overlayBgColor = themeData.overlayBg
            if (themeData.shadowColor) shadowColorValue = themeData.shadowColor
            
            // Update dynamic properties - Appearance
            if (themeData.radius !== undefined) radiusValue = themeData.radius
            if (themeData.radiusSmall !== undefined) radiusSmallValue = themeData.radiusSmall
            if (themeData.radiusLarge !== undefined) radiusLargeValue = themeData.radiusLarge
            if (themeData.dialogRadius !== undefined) dialogRadiusValue = themeData.dialogRadius
            
            // Update dynamic properties - Animation
            if (themeData.animDurationFast !== undefined) animDurationFastValue = themeData.animDurationFast
            if (themeData.animDurationNormal !== undefined) animDurationNormalValue = themeData.animDurationNormal
            if (themeData.animDurationSlow !== undefined) animDurationSlowValue = themeData.animDurationSlow
            if (themeData.animEasing !== undefined) animEasingValue = themeData.animEasing
            if (themeData.animEasingBounce !== undefined) animEasingBounceValue = themeData.animEasingBounce
            
            // Increment version to trigger any remaining rebinds
            themeVersion++
            
            console.log("Theme applied successfully")
        } catch (e) {
            console.log("Error applying theme: " + e)
        }
    }
    
    // Dialog overlay styling
    Overlay.modal: Rectangle {
        color: root.overlayBg
        Behavior on opacity { NumberAnimation { duration: root.animDurationFast } }
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
            initializeTheme()
        }
        
        onTheme_content_changed: function(themeContent) {
            root.applyTheme(themeContent)
        }
        
        function initializeTheme() {
            // Ensure default theme exists
            ensure_default_theme()
            
            // Load current theme
            var themeName = theme || "Default"
            var themeContent = get_theme_content(themeName)
            root.applyTheme(themeContent)
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
        app: app
        themeRoot: root
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
            color: root.success
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
                                color: shaderCombo.pressed ? root.buttonPressed : (shaderCombo.hovered ? root.buttonHover : "transparent")
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
                            
                            indicator: ThemedIcon {
                                x: parent.width - width - 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 10
                                source: "qrc:/media/nav-arrow.svg"
                                sourceSize: Qt.size(10, 10)
                                themeRoot: root
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
                                    
                                    ThemedIcon {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        visible: shaderDelegate.isFirstInCategory
                                        source: shaderDelegate.model.category === "Common" ? "qrc:/media/star.svg" : "qrc:/media/star-outline.svg"
                                        sourceSize: Qt.size(12, 12)
                                        themeRoot: root
                                    }
                                    
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: shaderDelegate.model.name
                                        color: shaderDelegate.highlighted ? root.textBright : root.textColor
                                        font.pixelSize: 13
                                    }
                                }
                                
                                background: Rectangle { 
                                    color: shaderDelegate.highlighted ? root.accent : (shaderDelegate.hovered ? root.listItemHover : "transparent")
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
                                    color: root.dialogBg
                                    border.color: root.dialogBorder
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
                                
                                ThemedIcon {
                                    width: 10
                                    height: 10
                                    source: "qrc:/media/nav-arrow.svg"
                                    sourceSize: Qt.size(10, 10)
                                    themeRoot: root
                                    
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
                            themeRoot: root
                            
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
                    color: addBtn.pressed ? root.accentPressed : (addBtn.containsMouse ? root.accentHover : root.accent)
                    radius: root.radius
                    
                    Text {
                        anchors.centerIn: parent
                        text: "+ Add Parameter"
                        color: root.textBright
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
            color: root.windowBg
            
            PreviewPane {
                id: previewPane
                anchors.fill: parent
                textureProvider: globalTextureProvider
                themeRoot: root
            }
        }
    }
    
    
    NewMaterialDialog {
        id: newMaterialDialog
        shaderModel: shaderModel
        themeRoot: root
        onCreateMaterial: function(shaderName) {
            materialModel.new_material(shaderName)
        }
    }

    AddParameterDialog {
        id: addParamDialog
        themeRoot: root
        onAddParameter: function(name, value) {
            materialModel.set_parameter_value(name, value)
        }
    }

    AboutDialog {
        id: aboutDialog
        themeRoot: root
    }

    WelcomeDialog {
        id: welcomeDialog
        app: app
        themeRoot: root
        onGameSelected: {
        }
        onSkipped: {
        }
    }

    ImageToVtfDialog {
        id: imageToVtfDialog
        app: app
        themeRoot: root
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
        themeRoot: root
    }

    TextureBrowser {
        id: globalTextureBrowser
        app: app
        textureProvider: globalTextureProvider
        themeRoot: root
    }
}

