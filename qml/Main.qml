import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import com.supervtf 1.0
// i need to separate this code, it's getting big
ApplicationWindow {
    id: root
    
    // fucking windows file url bullshit fuck windows
    function urlToLocalPath(url) {
        var path = url.toString()
        if (path.startsWith("file:///")) {
            // Check if it's a Windows path (has drive letter like C:)
            // file:///C:/path -> C:/path (Windows)
            // file:///home/user -> /home/user (Unix)
            var afterScheme = path.substring(8) // Remove "file:///"
            if (afterScheme.length >= 2 && afterScheme[1] === ':') {
                // Windows path: file:///C:/... -> C:/...
                return afterScheme
            } else {
                // Unix path: file:///home/... -> /home/...
                return "/" + afterScheme
            }
        } else if (path.startsWith("file://")) {
            // Fallback for file:// without third slash
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
           `SuperVTF - ${materialModel.file_path || "Untitled"}*` :
           `SuperVTF - ${materialModel.file_path || "Untitled"}`
    color: "#1e1e1e"
    
    // Custom colors
    readonly property color panelBg: "#252526"
    readonly property color panelBorder: "#3c3c3c"
    readonly property color inputBg: "#3c3c3c"
    readonly property color inputBorder: "#5a5a5a"
    readonly property color textColor: "#e0e0e0"
    readonly property color textDim: "#888888"
    readonly property color accent: "#0e639c"
    readonly property color accentHover: "#1177bb"
    readonly property color buttonBg: "#3c3c3c"
    readonly property color buttonHover: "#4a4a4a"
    readonly property int radius: 6
    
    // Animation settings - smooth & snappy
    readonly property int animDurationFast: 120      // Quick micro-interactions
    readonly property int animDurationNormal: 200    // Standard transitions
    readonly property int animDurationSlow: 350      // Dialogs, major transitions
    readonly property int animEasing: Easing.OutCubic  // Smooth deceleration
    readonly property int animEasingBounce: Easing.OutBack  // Slight overshoot for playfulness

    // Application controller
    SuperVtfApp {
        id: app
        Component.onCompleted: {
            initialize()
            loadShaders()
        }
        
        function loadShaders() {
            shaderModel.clear()
            var shaders = get_supported_shaders()
            
            // Define common/priority shaders that should appear first
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
            
            // Add those common shaders first with category
            for (var i = 0; i < commonShaders.length; i++) {
                for (var j = 0; j < shaders.length; j++) {
                    if (shaders[j].toLowerCase() === commonShaders[i].toLowerCase()) {
                        shaderModel.append({"name": shaders[j], "category": "Common"})
                        break
                    }
                }
            }
            
            // Add remaining shaders
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
            
            console.log("Loaded", shaderModel.count, "shaders")
        }
    }
    
    ListModel { id: shaderModel }
    ListModel { id: parameterListModel }
    
    // Track collapsed categories (persists across file loads during session)
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
    
    // Helper function to rebuild parameter list model
    function rebuildParameterList() {
        parameterListModel.clear()
        var count = materialModel.parameter_count
        console.log("Rebuilding parameter list, count:", count)
        for (var i = 0; i < count; i++) {
            var name = materialModel.get_param_name(i)
            var displayName = materialModel.get_param_display_name(i)
            var value = materialModel.get_param_value(i)
            var dataType = materialModel.get_param_data_type(i)
            var minVal = materialModel.get_param_min(i)
            var maxVal = materialModel.get_param_max(i)
            var category = materialModel.get_param_category(i)
            
            console.log("Param", i, ":", name, displayName, dataType, value, "category:", category)
            
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
    
    // Material model
    MaterialModel {
        id: materialModel
        onMaterial_loaded: {
            console.log("Material loaded! Shader:", shader_name, "Params:", parameter_count)
            // Rebuild parameter list model completely
            rebuildParameterList()
            // Update shader combo to match loaded material
            for (var i = 0; i < shaderModel.count; i++) {
                if (shaderModel.get(i).name.toLowerCase() === shader_name.toLowerCase()) {
                    shaderCombo.currentIndex = i
                    break
                }
            }
            // Load base texture if available
            if (get_base_texture() !== "") {
                textureProvider.load_from_material_path(get_base_texture(), app.materials_root)
            }
        }
        onParameter_countChanged: {
            // Also refresh when parameter_count property changes
            rebuildParameterList()
        }
        onParameter_changed: function(name) {
            console.log("Parameter changed:", name)
            // Update preview when base texture changes
            if (name.toLowerCase() === "$basetexture") {
                var texturePath = get_parameter_value(name)
                if (texturePath !== "") {
                    textureProvider.load_from_material_path(texturePath, app.materials_root)
                }
            }
            // Update the parameter list model value
            for (var i = 0; i < parameterListModel.count; i++) {
                if (parameterListModel.get(i).paramName === name) {
                    parameterListModel.setProperty(i, "paramValue", get_parameter_value(name))
                    break
                }
            }
        }
        onError_occurred: function(msg) {
            console.log("Material error:", msg)
        }
    }
    
    // Texture provider
    TextureProvider {
        id: textureProvider
    }
    
    // ===== NATIVE FILE DIALOGS =====
    FileDialog {
        id: openFileDialog
        title: "Open VMT File"
        nameFilters: ["VMT Files (*.vmt)", "All Files (*)"]
        onAccepted: {
            // Convert file:// URL to local path
            var path = root.urlToLocalPath(selectedFile)
            console.log("Loading VMT file:", path)
            materialModel.load_file(path)
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
        id: openVtfDialog
        title: "Open VTF Texture"
        nameFilters: ["VTF Files (*.vtf)", "All Files (*)"]
        onAccepted: {
            var path = root.urlToLocalPath(selectedFile)
            textureProvider.load_texture(path)
        }
    }
    
    // ===== GLOBAL SHORTCUTS =====
    Shortcut { sequence: "Ctrl+N"; onActivated: newMaterialDialog.open() }
    Shortcut { sequence: "Ctrl+O"; onActivated: openFileDialog.open() }
    Shortcut { sequence: "Ctrl+S"; onActivated: if (materialModel.is_loaded) materialModel.save_file(materialModel.file_path) }
    Shortcut { sequence: "Ctrl+Shift+S"; onActivated: if (materialModel.is_loaded) saveFileDialog.open() }
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
    Shortcut { sequence: "Ctrl+="; onActivated: previewPane.zoomIn() }
    Shortcut { sequence: "Ctrl+-"; onActivated: previewPane.zoomOut() }
    Shortcut { sequence: "Ctrl+0"; onActivated: previewPane.resetZoom() }
    Shortcut { sequence: "Ctrl+1"; onActivated: previewPane.fitToView() }
    
    // ===== MENU BAR =====
    menuBar: MenuBar {
        background: Rectangle { color: root.panelBg }
        
        delegate: MenuBarItem {
            id: menuBarItem
            contentItem: Text {
                text: menuBarItem.text
                font: menuBarItem.font
                color: root.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: menuBarItem.highlighted ? root.accent : (menuBarItem.hovered ? root.buttonHover : "transparent")
                Behavior on color { ColorAnimation { duration: root.animDurationFast } }
            }
        }
        
        Menu {
            title: "File"
            Action { text: "New..."; onTriggered: newMaterialDialog.open() }
            Action { text: "Open VMT..."; onTriggered: openFileDialog.open() }
            Action { text: "Open VTF..."; onTriggered: openVtfDialog.open() }
            MenuSeparator {}
            Action { text: "Save"; enabled: materialModel.is_loaded; onTriggered: materialModel.save_file(materialModel.file_path) }
            Action { text: "Save As..."; enabled: materialModel.is_loaded; onTriggered: saveFileDialog.open() }
            MenuSeparator {}
            Action { text: "Exit"; onTriggered: Qt.quit() }
        }
        
        Menu {
            title: "View"
            Action { text: "Zoom In"; onTriggered: previewPane.zoomIn() }
            Action { text: "Zoom Out"; onTriggered: previewPane.zoomOut() }
            Action { text: "Reset Zoom"; onTriggered: previewPane.resetZoom() }
            Action { text: "Fit to View"; onTriggered: previewPane.fitToView() }
        }
        
        Menu {
            title: "Tools"
            Action { 
                text: "Texture Browser..."
                onTriggered: {
                    globalTextureBrowser.openMode = true
                    globalTextureBrowser.targetTextField = null
                    globalTextureBrowser.open()
                }
            }
        }
        
        Menu {
            title: "Settings"
            Action { 
                text: "Select Game..."
                onTriggered: {
                    welcomeDialog.loadDetectedGames()
                    welcomeDialog.selectedIndex = -1
                    welcomeDialog.open()
                }
            }
            Action {
                text: "Browse Materials Folder..."
                onTriggered: browseMaterialsDialog.open()
            }
            MenuSeparator {}
            Menu {
                title: "Current: " + (app.selected_game || "Not Set")
                enabled: false
            }
        }
        
        Menu {
            title: "Help"
            Action { text: "About SuperVTF"; onTriggered: aboutDialog.open() }
        }
    }
    
    // ===== MAIN LAYOUT =====
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 5
            color: SplitHandle.hovered ? root.accent : root.panelBorder
        }
        
        // LEFT PANEL - Shader & Parameters
        Rectangle {
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 300
            color: root.panelBg
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // File info header
                Text {
                    visible: materialModel.is_loaded
                    Layout.fillWidth: true
                    text: materialModel.file_path.toString().split('/').pop() || "Untitled"
                    color: root.textColor
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                
                // Shader Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "Shader"
                        color: root.textDim
                        font.pixelSize: 11
                        font.bold: true
                    }
                    
                    // Shader display (read-only when file loaded)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: root.inputBg
                        border.color: root.inputBorder
                        border.width: 1
                        radius: root.radius
                        
                        // Show shader name when loaded, or combo when creating new
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
                            
                            indicator: Text {
                                x: parent.width - width - 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▼"
                                color: root.textDim
                                font.pixelSize: 10
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
                                    
                                    // Category separator line
                                    Rectangle {
                                        anchors.top: parent.top
                                        width: parent.width
                                        height: 1
                                        color: root.panelBorder
                                        visible: shaderDelegate.isFirstInCategory && shaderDelegate.index > 0
                                    }
                                    
                                    // Category indicator
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: shaderDelegate.isFirstInCategory
                                        text: shaderDelegate.model.category === "Common" ? "★" : "○"
                                        color: shaderDelegate.model.category === "Common" ? "#f1c40f" : root.textDim
                                        font.pixelSize: 10
                                    }
                                    
                                    // Shader name
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
                                
                                // Smooth fucking enter/exit animation
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
                    
                    // Shader description
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
                
                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.panelBorder
                }
                
                // Parameters Section
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
                    
                    // Parameter List
                    ListView {
                        id: paramList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: parameterListModel
                        
                        // Account for scrollbar width on Windows (ofc)
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
                            
                            // Hover effect
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
                                
                                Text {
                                    text: "▶"
                                    color: root.textDim
                                    font.pixelSize: 10
                                    
                                    // Smooth rotation for expand/collapse icon
                                    rotation: root.isCategoryCollapsed(section) ? 0 : 90
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
                        
                        delegate: Rectangle {
                            id: delegateRoot
                            width: paramList.width - 10 - paramList.scrollBarWidth
                            height: root.isCategoryCollapsed(model.paramCategory) ? 0 : paramContent.height + 16
                            visible: !root.isCategoryCollapsed(model.paramCategory)
                            color: paramMouse.containsMouse ? "#2a2d2e" : "transparent"
                            radius: root.radius
                            border.color: root.panelBorder
                            border.width: visible ? 1 : 0
                            clip: true
                            
                            // Smooth expand/collapse animation
                            Behavior on height { NumberAnimation { duration: root.animDurationNormal; easing.type: root.animEasing } }
                            
                            // Smooth hover effect
                            Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                            
                            // Store model data in delegate-local properties
                            property string pName: model.paramName || ""
                            property string pDisplayName: model.paramDisplayName || ""
                            property string pValue: model.paramValue || ""
                            property string pDataType: model.paramDataType || "string"
                            property real pMinValue: model.paramMinValue || 0
                            property real pMaxValue: model.paramMaxValue || 1
                            
                            MouseArea {
                                id: paramMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                            
                            ColumnLayout {
                                id: paramContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 4
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        text: delegateRoot.pDisplayName
                                        color: root.textColor
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Text {
                                        text: delegateRoot.pDataType
                                        color: root.textDim
                                        font.pixelSize: 10
                                        font.italic: true
                                    }
                                }
                                
                                // Bool control
                                Switch {
                                    id: boolSwitch
                                    visible: delegateRoot.pDataType.toLowerCase() === "bool"
                                    Layout.fillWidth: true
                                    checked: delegateRoot.pValue === "1" || delegateRoot.pValue.toLowerCase() === "true"
                                    
                                    onCheckedChanged: {
                                        if (visible) {
                                            materialModel.set_parameter_value(delegateRoot.pName, checked ? "1" : "0")
                                        }
                                    }
                                    
                                    indicator: Rectangle {
                                        implicitWidth: 44
                                        implicitHeight: 22
                                        x: boolSwitch.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 11
                                        color: boolSwitch.checked ? "#4ec9b0" : "#5a5a5a"
                                        
                                        Rectangle {
                                            x: boolSwitch.checked ? parent.width - width - 3 : 3
                                            y: 3
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: "white"
                                            
                                            Behavior on x {
                                                NumberAnimation { duration: 150 }
                                            }
                                        }
                                    }
                                    
                                    contentItem: Text {
                                        text: boolSwitch.checked ? "On" : "Off"
                                        color: root.textDim
                                        font.pixelSize: 12
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: boolSwitch.indicator.width + 8
                                    }
                                }
                                
                                // Int control
                                RowLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "int"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    SpinBox {
                                        id: intSpinBox
                                        Layout.preferredWidth: 100
                                        from: delegateRoot.pMinValue || -2147483647
                                        to: delegateRoot.pMaxValue || 2147483647
                                        value: parseInt(delegateRoot.pValue) || 0
                                        editable: true
                                        
                                        onValueChanged: {
                                            if (parent.visible) {
                                                materialModel.set_parameter_value(delegateRoot.pName, value.toString())
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            implicitHeight: 28
                                            color: root.inputBg
                                            border.color: intSpinBox.activeFocus ? root.accent : root.inputBorder
                                            radius: 4
                                        }
                                        
                                        contentItem: TextInput {
                                            text: intSpinBox.textFromValue(intSpinBox.value, intSpinBox.locale)
                                            font.pixelSize: 12
                                            color: root.textColor
                                            horizontalAlignment: Qt.AlignHCenter
                                            verticalAlignment: Qt.AlignVCenter
                                            readOnly: !intSpinBox.editable
                                            validator: intSpinBox.validator
                                            selectByMouse: true
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                        }
                                    }
                                    
                                    Slider {
                                        id: intSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        from: 0
                                        to: 100
                                        stepSize: 1
                                        value: parseInt(delegateRoot.pValue) || 0
                                        live: true
                                        
                                        onValueChanged: {
                                            if (pressed) {
                                                intSpinBox.value = value
                                                materialModel.set_parameter_value(delegateRoot.pName, Math.round(value).toString())
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            x: intSlider.leftPadding
                                            y: intSlider.topPadding + intSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: intSlider.availableWidth
                                            height: 6
                                            radius: 3
                                            color: root.inputBorder
                                            
                                            Rectangle {
                                                width: intSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: root.accent
                                                radius: 3
                                            }
                                        }
                                        
                                        handle: Rectangle {
                                            x: intSlider.leftPadding + intSlider.visualPosition * (intSlider.availableWidth - width)
                                            y: intSlider.topPadding + intSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: intSlider.pressed ? Qt.lighter(root.accent, 1.2) : root.accent
                                            border.color: Qt.darker(root.accent, 1.2)
                                            border.width: 1
                                        }
                                    }
                                }
                                
                                // Float control
                                RowLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "float"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    TextField {
                                        id: floatField
                                        Layout.preferredWidth: 80
                                        text: delegateRoot.pValue
                                        validator: DoubleValidator { }
                                        inputMethodHints: Qt.ImhNoPredictiveText
                                        
                                        onTextChanged: {
                                            if (parent.visible && acceptableInput) {
                                                materialModel.set_parameter_value(delegateRoot.pName, text)
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            implicitHeight: 28
                                            color: root.inputBg
                                            border.color: floatField.activeFocus ? root.accent : root.inputBorder
                                            radius: 4
                                        }
                                        
                                        color: root.textColor
                                        font.pixelSize: 12
                                        selectByMouse: true
                                    }
                                    
                                    Slider {
                                        id: floatSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        from: 0.0
                                        to: 1.0
                                        stepSize: 0.01
                                        value: parseFloat(delegateRoot.pValue) || 0.0
                                        live: true
                                        
                                        onValueChanged: {
                                            if (pressed) {
                                                floatField.text = value.toFixed(3)
                                                materialModel.set_parameter_value(delegateRoot.pName, value.toFixed(3))
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            x: floatSlider.leftPadding
                                            y: floatSlider.topPadding + floatSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: floatSlider.availableWidth
                                            height: 6
                                            radius: 3
                                            color: root.inputBorder
                                            
                                            Rectangle {
                                                width: floatSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: root.accent
                                                radius: 3
                                            }
                                        }
                                        
                                        handle: Rectangle {
                                            x: floatSlider.leftPadding + floatSlider.visualPosition * (floatSlider.availableWidth - width)
                                            y: floatSlider.topPadding + floatSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: floatSlider.pressed ? Qt.lighter(root.accent, 1.2) : root.accent
                                            border.color: Qt.darker(root.accent, 1.2)
                                            border.width: 1
                                        }
                                    }
                                }
                                
                                // Color control
                                RowLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "color"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Rectangle {
                                        id: colorPreview
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 28
                                        radius: 4
                                        border.color: root.inputBorder
                                        border.width: 1
                                        
                                        function parseColorValue(val) {
                                            if (val && val.length > 2 && val.charAt(0) === '[') {
                                                var parts = val.slice(1, -1).split(/\s+/)
                                                if (parts.length >= 3) {
                                                    var r = parseFloat(parts[0])
                                                    var g = parseFloat(parts[1])
                                                    var b = parseFloat(parts[2])
                                                    // Check if values are 0-1 range or 0-255 range
                                                    if (r <= 1 && g <= 1 && b <= 1 && r >= 0 && g >= 0 && b >= 0) {
                                                        // Could be 0-1 range, check if any are fractional
                                                        if (r % 1 !== 0 || g % 1 !== 0 || b % 1 !== 0 || (r <= 1 && g <= 1 && b <= 1)) {
                                                            return Qt.rgba(r, g, b, 1.0)
                                                        }
                                                    }
                                                    // Assume 0-255 range
                                                    return Qt.rgba(r / 255, g / 255, b / 255, 1.0)
                                                }
                                            }
                                            return Qt.rgba(1, 1, 1, 1)
                                        }
                                        
                                        color: parseColorValue(colorTextField.text)
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                colorPickerDialog.targetTextField = colorTextField
                                                colorPickerDialog.initialColor = colorPreview.color
                                                colorPickerDialog.currentColor = colorPreview.color
                                                colorPickerDialog.open()
                                            }
                                        }
                                    }
                                    
                                    TextField {
                                        id: colorTextField
                                        Layout.fillWidth: true
                                        text: delegateRoot.pValue
                                        inputMethodHints: Qt.ImhNoPredictiveText
                                        
                                        onTextChanged: {
                                            if (parent.visible) {
                                                materialModel.set_parameter_value(delegateRoot.pName, text)
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            implicitHeight: 28
                                            color: root.inputBg
                                            border.color: colorTextField.activeFocus ? root.accent : root.inputBorder
                                            radius: 4
                                        }
                                        
                                        color: root.textColor
                                        font.pixelSize: 12
                                        selectByMouse: true
                                    }
                                }
                                
                                // Texture control
                                RowLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "texture"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Rectangle {
                                        id: textureThumbnailRect
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        color: root.inputBg
                                        border.color: root.inputBorder
                                        radius: 4
                                        clip: true
                                        
                                        // Debounced thumbnail source
                                        property string pendingTexture: ""
                                        property string thumbnailSource: ""
                                        
                                        // Function to update thumbnail (called from textureField)
                                        function updateThumbnail(texturePath) {
                                            var texPath = (texturePath || "").replace(/\.vtf$/i, "")
                                            if (texPath !== pendingTexture || thumbnailSource === "") {
                                                pendingTexture = texPath
                                                thumbnailSource = ""  // Clear while loading
                                                thumbnailDebounce.restart()
                                            }
                                        }
                                        
                                        Timer {
                                            id: thumbnailDebounce
                                            interval: 150  // Wait 150ms after typing stops
                                            onTriggered: {
                                                if (textureThumbnailRect.pendingTexture.length > 0 && app.materials_root.length > 0) {
                                                    var result = textureProvider.get_thumbnail_for_texture(textureThumbnailRect.pendingTexture, app.materials_root)
                                                    textureThumbnailRect.thumbnailSource = result
                                                } else {
                                                    textureThumbnailRect.thumbnailSource = ""
                                                }
                                            }
                                        }
                                        
                                        // Initial load
                                        Component.onCompleted: {
                                            if (delegateRoot.pValue && delegateRoot.pValue.length > 0) {
                                                var texPath = delegateRoot.pValue.replace(/\.vtf$/i, "")
                                                pendingTexture = texPath
                                                // Check cache immediately (fast), defer full load
                                                thumbnailDebounce.start()
                                            }
                                        }
                                        
                                        Image {
                                            id: textureThumbnail
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            fillMode: Image.PreserveAspectFit
                                            cache: false  // Don't cache - we want fresh images
                                            asynchronous: true
                                            source: textureThumbnailRect.thumbnailSource
                                            
                                            // Loading spinner
                                            Item {
                                                id: loadingSpinner
                                                anchors.centerIn: parent
                                                width: 20
                                                height: 20
                                                visible: thumbnailDebounce.running || textureThumbnail.status === Image.Loading
                                                
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: root.inputBorder
                                                }
                                                
                                                Rectangle {
                                                    id: spinnerArc
                                                    anchors.centerIn: parent
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: root.accent
                                                    
                                                    // Create arc effect with clip
                                                    visible: false
                                                }
                                                
                                                // Animated spinner segment
                                                Canvas {
                                                    id: spinnerCanvas
                                                    anchors.centerIn: parent
                                                    width: 18
                                                    height: 18
                                                    
                                                    property real angle: 0
                                                    
                                                    NumberAnimation on angle {
                                                        from: 0
                                                        to: 360
                                                        duration: 1000
                                                        loops: Animation.Infinite
                                                        running: loadingSpinner.visible
                                                    }
                                                    
                                                    onAngleChanged: requestPaint()
                                                    
                                                    onPaint: {
                                                        var ctx = getContext("2d")
                                                        ctx.reset()
                                                        ctx.strokeStyle = root.accent
                                                        ctx.lineWidth = 2
                                                        ctx.lineCap = "round"
                                                        ctx.beginPath()
                                                        var startAngle = (angle - 90) * Math.PI / 180
                                                        var endAngle = (angle + 90) * Math.PI / 180
                                                        ctx.arc(width/2, height/2, 7, startAngle, endAngle)
                                                        ctx.stroke()
                                                    }
                                                }
                                            }
                                            
                                            // Fallback text when image fails or not set
                                            Text {
                                                anchors.centerIn: parent
                                                text: textureThumbnail.status === Image.Error ? "!" : "?"
                                                color: textureThumbnail.status === Image.Error ? "#ff6b6b" : root.textDim
                                                font.pixelSize: 14
                                                visible: !loadingSpinner.visible && textureThumbnail.status !== Image.Ready
                                            }
                                        }
                                        
                                        // Click to open texture browser
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                globalTextureBrowser.openMode = false
                                                globalTextureBrowser.targetTextField = textureField
                                                globalTextureBrowser.selectedTexture = ""
                                                globalTextureBrowser.open()
                                            }
                                        }
                                    }
                                    
                                    TextField {
                                        id: textureField
                                        Layout.fillWidth: true
                                        text: delegateRoot.pValue
                                        placeholderText: "texture.vtf"
                                        inputMethodHints: Qt.ImhNoPredictiveText
                                        
                                        onTextChanged: {
                                            if (parent.visible) {
                                                materialModel.set_parameter_value(delegateRoot.pName, text)
                                                // Update preview if this is the base texture
                                                if (delegateRoot.pName.toLowerCase() === "$basetexture") {
                                                    textureProvider.load_from_material_path(text, app.materials_root)
                                                }
                                                // Also update the small thumbnail preview
                                                textureThumbnailRect.updateThumbnail(text)
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            implicitHeight: 28
                                            color: root.inputBg
                                            border.color: textureField.activeFocus ? root.accent : root.inputBorder
                                            radius: 4
                                        }
                                        
                                        color: root.textColor
                                        font.pixelSize: 12
                                        selectByMouse: true
                                    }
                                }
                                
                                // Vector2 control
                                ColumnLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "vector2"
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    property var vec2Values: {
                                        var val = delegateRoot.pValue
                                        if (val && val.length > 2 && val.charAt(0) === '[') {
                                            var parts = val.slice(1, -1).split(/\s+/)
                                            if (parts.length >= 2) {
                                                return [parseFloat(parts[0]) || 0, parseFloat(parts[1]) || 0]
                                            }
                                        }
                                        return [0, 0]
                                    }
                                    
                                    // Visual preview
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        color: root.inputBg
                                        radius: 4
                                        border.color: root.inputBorder
                                        
                                        // Grid
                                        Canvas {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.strokeStyle = root.panelBorder
                                                ctx.lineWidth = 1
                                                // Draw grid
                                                for (var i = 0; i <= 4; i++) {
                                                    var x = i * width / 4
                                                    var y = i * height / 4
                                                    ctx.beginPath()
                                                    ctx.moveTo(x, 0)
                                                    ctx.lineTo(x, height)
                                                    ctx.stroke()
                                                    ctx.beginPath()
                                                    ctx.moveTo(0, y)
                                                    ctx.lineTo(width, y)
                                                    ctx.stroke()
                                                }
                                            }
                                        }
                                        
                                        // Vector arrow
                                        Rectangle {
                                            id: vec2Point
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: root.accent
                                            x: parent.width / 2 + (parent.vec2Values[0] * parent.width / 4) - 4
                                            y: parent.height / 2 - (parent.vec2Values[1] * parent.height / 4) - 4
                                        }
                                        
                                        property var vec2Values: parent.vec2Values
                                    }
                                    
                                    // Input fields
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        
                                        Text { text: "X"; color: root.textDim; font.pixelSize: 11 }
                                        TextField {
                                            id: vec2X
                                            Layout.fillWidth: true
                                            text: parent.parent.vec2Values[0].toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onTextChanged: {
                                                if (parent.parent.visible && acceptableInput) {
                                                    var newVal = "[" + text + " " + vec2Y.text + "]"
                                                    materialModel.set_parameter_value(delegateRoot.pName, newVal)
                                                }
                                            }
                                            background: Rectangle {
                                                implicitHeight: 24
                                                color: root.inputBg
                                                border.color: vec2X.activeFocus ? root.accent : root.inputBorder
                                                radius: 4
                                            }
                                            color: root.textColor
                                            font.pixelSize: 11
                                        }
                                        
                                        Text { text: "Y"; color: root.textDim; font.pixelSize: 11 }
                                        TextField {
                                            id: vec2Y
                                            Layout.fillWidth: true
                                            text: parent.parent.vec2Values[1].toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onTextChanged: {
                                                if (parent.parent.visible && acceptableInput) {
                                                    var newVal = "[" + vec2X.text + " " + text + "]"
                                                    materialModel.set_parameter_value(delegateRoot.pName, newVal)
                                                }
                                            }
                                            background: Rectangle {
                                                implicitHeight: 24
                                                color: root.inputBg
                                                border.color: vec2Y.activeFocus ? root.accent : root.inputBorder
                                                radius: 4
                                            }
                                            color: root.textColor
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                                
                                // Vector3 control
                                ColumnLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "vector3"
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    property var vec3Values: {
                                        var val = delegateRoot.pValue
                                        if (val && val.length > 2 && val.charAt(0) === '[') {
                                            var parts = val.slice(1, -1).split(/\s+/)
                                            if (parts.length >= 3) {
                                                return [parseFloat(parts[0]) || 0, parseFloat(parts[1]) || 0, parseFloat(parts[2]) || 0]
                                            }
                                        }
                                        return [0, 0, 0]
                                    }
                                    
                                    // Input fields
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        
                                        Text { text: "X"; color: "#e74c3c"; font.pixelSize: 11; font.bold: true }
                                        TextField {
                                            id: vec3X
                                            Layout.fillWidth: true
                                            text: parent.parent.vec3Values[0].toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onTextChanged: {
                                                if (parent.parent.visible && acceptableInput) {
                                                    var newVal = "[" + text + " " + vec3Y.text + " " + vec3Z.text + "]"
                                                    materialModel.set_parameter_value(delegateRoot.pName, newVal)
                                                }
                                            }
                                            background: Rectangle {
                                                implicitHeight: 24
                                                color: root.inputBg
                                                border.color: vec3X.activeFocus ? "#e74c3c" : root.inputBorder
                                                radius: 4
                                            }
                                            color: root.textColor
                                            font.pixelSize: 11
                                        }
                                        
                                        Text { text: "Y"; color: "#2ecc71"; font.pixelSize: 11; font.bold: true }
                                        TextField {
                                            id: vec3Y
                                            Layout.fillWidth: true
                                            text: parent.parent.vec3Values[1].toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onTextChanged: {
                                                if (parent.parent.visible && acceptableInput) {
                                                    var newVal = "[" + vec3X.text + " " + text + " " + vec3Z.text + "]"
                                                    materialModel.set_parameter_value(delegateRoot.pName, newVal)
                                                }
                                            }
                                            background: Rectangle {
                                                implicitHeight: 24
                                                color: root.inputBg
                                                border.color: vec3Y.activeFocus ? "#2ecc71" : root.inputBorder
                                                radius: 4
                                            }
                                            color: root.textColor
                                            font.pixelSize: 11
                                        }
                                        
                                        Text { text: "Z"; color: "#3498db"; font.pixelSize: 11; font.bold: true }
                                        TextField {
                                            id: vec3Z
                                            Layout.fillWidth: true
                                            text: parent.parent.vec3Values[2].toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onTextChanged: {
                                                if (parent.parent.visible && acceptableInput) {
                                                    var newVal = "[" + vec3X.text + " " + vec3Y.text + " " + text + "]"
                                                    materialModel.set_parameter_value(delegateRoot.pName, newVal)
                                                }
                                            }
                                            background: Rectangle {
                                                implicitHeight: 24
                                                color: root.inputBg
                                                border.color: vec3Z.activeFocus ? "#3498db" : root.inputBorder
                                                radius: 4
                                            }
                                            color: root.textColor
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                                
                                // Transform control
                                ColumnLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "transform"
                                    Layout.fillWidth: true
                                    spacing: 6
                                    
                                    // Parse transform: "center .5 .5 scale 1 1 rotate 0 translate 0 0"
                                    property var transformValues: {
                                        var val = delegateRoot.pValue || ""
                                        var result = { centerX: 0.5, centerY: 0.5, scaleX: 1, scaleY: 1, rotate: 0, translateX: 0, translateY: 0 }
                                        
                                        var centerMatch = val.match(/center\s+([\d.-]+)\s+([\d.-]+)/)
                                        if (centerMatch) {
                                            result.centerX = parseFloat(centerMatch[1])
                                            result.centerY = parseFloat(centerMatch[2])
                                        }
                                        
                                        var scaleMatch = val.match(/scale\s+([\d.-]+)\s+([\d.-]+)/)
                                        if (scaleMatch) {
                                            result.scaleX = parseFloat(scaleMatch[1])
                                            result.scaleY = parseFloat(scaleMatch[2])
                                        }
                                        
                                        var rotateMatch = val.match(/rotate\s+([\d.-]+)/)
                                        if (rotateMatch) {
                                            result.rotate = parseFloat(rotateMatch[1])
                                        }
                                        
                                        var translateMatch = val.match(/translate\s+([\d.-]+)\s+([\d.-]+)/)
                                        if (translateMatch) {
                                            result.translateX = parseFloat(translateMatch[1])
                                            result.translateY = parseFloat(translateMatch[2])
                                        }
                                        
                                        return result
                                    }
                                    
                                    function buildTransformString() {
                                        return "center " + transformValues.centerX + " " + transformValues.centerY + 
                                               " scale " + transformValues.scaleX + " " + transformValues.scaleY +
                                               " rotate " + transformValues.rotate +
                                               " translate " + transformValues.translateX + " " + transformValues.translateY
                                    }
                                    
                                    // Visual transform preview
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 80
                                        color: root.inputBg
                                        radius: 4
                                        border.color: root.inputBorder
                                        clip: true
                                        
                                        // Grid background
                                        Canvas {
                                            anchors.fill: parent
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.strokeStyle = root.panelBorder
                                                ctx.lineWidth = 1
                                                for (var i = 0; i <= 8; i++) {
                                                    var x = i * width / 8
                                                    var y = i * height / 8
                                                    ctx.beginPath()
                                                    ctx.moveTo(x, 0)
                                                    ctx.lineTo(x, height)
                                                    ctx.stroke()
                                                    ctx.beginPath()
                                                    ctx.moveTo(0, y)
                                                    ctx.lineTo(width, y)
                                                    ctx.stroke()
                                                }
                                            }
                                        }
                                        
                                        // Transformed rectangle preview
                                        Rectangle {
                                            id: transformPreview
                                            width: 40 * parent.parent.transformValues.scaleX
                                            height: 40 * parent.parent.transformValues.scaleY
                                            x: parent.width * parent.parent.transformValues.centerX + parent.parent.transformValues.translateX * 40 - width/2
                                            y: parent.height * parent.parent.transformValues.centerY + parent.parent.transformValues.translateY * 40 - height/2
                                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
                                            border.color: root.accent
                                            border.width: 2
                                            rotation: parent.parent.transformValues.rotate
                                            
                                            // Center point
                                            Rectangle {
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: "#ff6b6b"
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }
                                    
                                    // Transform controls
                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 4
                                        rowSpacing: 4
                                        columnSpacing: 4
                                        
                                        Text { text: "Scale"; color: root.textDim; font.pixelSize: 10 }
                                        TextField {
                                            id: tfScaleX
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.scaleX.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.scaleX = parseFloat(text) || 1
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        TextField {
                                            id: tfScaleY
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.scaleY.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.scaleY = parseFloat(text) || 1
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        Item { width: 1 }
                                        
                                        Text { text: "Rotate"; color: root.textDim; font.pixelSize: 10 }
                                        TextField {
                                            id: tfRotate
                                            Layout.fillWidth: true
                                            Layout.columnSpan: 2
                                            text: parent.parent.transformValues.rotate.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.rotate = parseFloat(text) || 0
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        Text { text: "°"; color: root.textDim; font.pixelSize: 10 }
                                        
                                        Text { text: "Translate"; color: root.textDim; font.pixelSize: 10 }
                                        TextField {
                                            id: tfTransX
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.translateX.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.translateX = parseFloat(text) || 0
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        TextField {
                                            id: tfTransY
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.translateY.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.translateY = parseFloat(text) || 0
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        Item { width: 1 }
                                        
                                        Text { text: "Center"; color: root.textDim; font.pixelSize: 10 }
                                        TextField {
                                            id: tfCenterX
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.centerX.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.centerX = parseFloat(text) || 0.5
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        TextField {
                                            id: tfCenterY
                                            Layout.fillWidth: true
                                            text: parent.parent.transformValues.centerY.toString()
                                            validator: DoubleValidator {}
                                            inputMethodHints: Qt.ImhNoPredictiveText
                                            onEditingFinished: {
                                                parent.parent.transformValues.centerY = parseFloat(text) || 0.5
                                                materialModel.set_parameter_value(delegateRoot.pName, parent.parent.buildTransformString())
                                            }
                                            background: Rectangle { implicitHeight: 22; color: root.inputBg; border.color: root.inputBorder; radius: 3 }
                                            color: root.textColor; font.pixelSize: 10
                                        }
                                        Item { width: 1 }
                                    }
                                    
                                    // Raw text field
                                    TextField {
                                        id: transformRawField
                                        Layout.fillWidth: true
                                        text: delegateRoot.pValue
                                        placeholderText: "center .5 .5 scale 1 1 rotate 0 translate 0 0"
                                        inputMethodHints: Qt.ImhNoPredictiveText
                                        
                                        onTextChanged: {
                                            if (parent.visible && activeFocus) {
                                                materialModel.set_parameter_value(delegateRoot.pName, text)
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            implicitHeight: 24
                                            color: root.inputBg
                                            border.color: transformRawField.activeFocus ? root.accent : root.inputBorder
                                            radius: 4
                                        }
                                        color: root.textColor
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                    }
                                }
                                
                                // String control (default)
                                TextField {
                                    id: stringField
                                    visible: {
                                        var dt = delegateRoot.pDataType.toLowerCase()
                                        return dt !== "bool" && dt !== "int" && dt !== "float" && 
                                               dt !== "color" && dt !== "texture" && 
                                               dt !== "vector2" && dt !== "vector3" && dt !== "transform"
                                    }
                                    Layout.fillWidth: true
                                    text: delegateRoot.pValue
                                    inputMethodHints: Qt.ImhNoPredictiveText
                                    
                                    onTextChanged: {
                                        if (visible) {
                                            materialModel.set_parameter_value(delegateRoot.pName, text)
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        implicitHeight: 28
                                        color: root.inputBg
                                        border.color: stringField.activeFocus ? root.accent : root.inputBorder
                                        radius: 4
                                    }
                                    
                                    color: root.textColor
                                    font.pixelSize: 12
                                    selectByMouse: true
                                }
                            }
                        }
                    }
                }
                
                // Add Parameter Button
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
        
        // CENTER PANEL - Preview
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400
            color: "#1a1a1a"
            
            PreviewPane {
                id: previewPane
                anchors.fill: parent
                textureProvider: textureProvider
            }
        }
    }
    
    // ===== STATUS BAR =====
    // Status bar removed for cleaner look
    
    // ===== DIALOGS =====
    
    // New Material Dialog
    Dialog {
        id: newMaterialDialog
        modal: true
        anchors.centerIn: parent
        width: 400
        padding: 0
        
        // Smooth enter/exit animations
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationNormal; easing.type: root.animEasing }
                NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: root.animDurationNormal; easing.type: root.animEasingBounce }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationFast; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: root.animDurationFast; easing.type: Easing.InCubic }
            }
        }
        
        onOpened: newShaderCombo.setDefaultShader()
        
        background: Rectangle {
            color: root.panelBg
            border.color: root.panelBorder
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
                color: root.panelBg
                
                Text {
                    anchors.centerIn: parent
                    text: "New Material"
                    color: root.textColor
                    font.pixelSize: 15
                    font.bold: true
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: root.panelBorder
                }
            }
            
            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 12
                
                Text {
                    text: "Select shader for new material:"
                    color: root.textColor
                    font.pixelSize: 12
                }
                
                ComboBox {
                    id: newShaderCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    model: shaderModel
                    textRole: "name"
                    font.pixelSize: 13
                    
                    // Set default to LightmappedGeneric when dialog opens
                    Component.onCompleted: setDefaultShader()
                    
                    function setDefaultShader() {
                        for (var i = 0; i < shaderModel.count; i++) {
                            if (shaderModel.get(i).name.toLowerCase() === "lightmappedgeneric") {
                                currentIndex = i
                                break
                            }
                        }
                    }
                    
                    background: Rectangle {
                        color: newShaderCombo.pressed ? "#2a2d2e" : (newShaderCombo.hovered ? "#3c3c3c" : root.inputBg)
                        border.color: newShaderCombo.activeFocus ? root.accent : root.inputBorder
                        border.width: 1
                        radius: 4
                    }
                    
                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 30
                        text: newShaderCombo.displayText
                        color: root.textColor
                        font: newShaderCombo.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    
                    indicator: Text {
                        x: parent.width - width - 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▼"
                        color: root.textDim
                        font.pixelSize: 10
                    }
                    
                    delegate: ItemDelegate {
                        id: newShaderDelegate
                        required property int index
                        required property var model
                        
                        // Check if this is the first item of a new category
                        property bool isFirstInCategory: {
                            if (index === 0) return true
                            var prevItem = shaderModel.get(index - 1)
                            return prevItem ? prevItem.category !== model.category : true
                        }
                        
                        width: newShaderCombo.width
                        height: 32
                        hoverEnabled: true
                        padding: 0
                        
                        contentItem: Item {
                            anchors.fill: parent
                            
                            // Category separator line
                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: 1
                                color: root.panelBorder
                                visible: newShaderDelegate.isFirstInCategory && newShaderDelegate.index > 0
                            }
                            
                            // Category label (small, on the left)
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: newShaderDelegate.isFirstInCategory
                                text: newShaderDelegate.model.category === "Common" ? "★" : "○"
                                color: newShaderDelegate.model.category === "Common" ? "#f1c40f" : root.textDim
                                font.pixelSize: 10
                            }
                            
                            // Shader name
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: newShaderDelegate.model.name
                                color: newShaderDelegate.highlighted ? "#ffffff" : root.textColor
                                font.pixelSize: 13
                            }
                        }
                        
                        background: Rectangle { 
                            color: newShaderDelegate.highlighted ? root.accent : (newShaderDelegate.hovered ? "#3c3c3c" : "transparent")
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
                            border.color: root.panelBorder
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
                    color: root.panelBorder
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Rectangle {
                        id: cancelNewBtn
                        width: 90
                        height: 32
                        radius: 4
                        color: cancelNewMouse.containsMouse ? root.buttonHover : root.buttonBg
                        
                        // Smooth hover animation
                        scale: cancelNewMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                        Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: root.textColor
                            font.pixelSize: 13
                        }
                        
                        MouseArea {
                            id: cancelNewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: newMaterialDialog.close()
                        }
                    }
                    
                    Rectangle {
                        id: createNewBtn
                        width: 90
                        height: 32
                        radius: 4
                        color: okNewMouse.containsMouse ? "#1177bb" : root.accent
                        
                        // Smooth hover animation
                        scale: okNewMouse.pressed ? 0.95 : (okNewMouse.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                        Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        
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
                                materialModel.new_material(newShaderCombo.currentText)
                                newMaterialDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Parameter Dialog
    Dialog {
        id: addParamDialog
        modal: true
        anchors.centerIn: parent
        width: 400
        padding: 0
        
        // Smooth enter/exit animations
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationNormal; easing.type: root.animEasing }
                NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: root.animDurationNormal; easing.type: root.animEasingBounce }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationFast; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: root.animDurationFast; easing.type: Easing.InCubic }
            }
        }
        
        background: Rectangle {
            color: root.panelBg
            border.color: root.panelBorder
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
                color: root.panelBg
                
                Text {
                    anchors.centerIn: parent
                    text: "Add Parameter"
                    color: root.textColor
                    font.pixelSize: 15
                    font.bold: true
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: root.panelBorder
                }
            }
            
            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 12
                
                Text { text: "Parameter Name:"; color: root.textColor; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: root.inputBg
                    border.color: newParamName.activeFocus ? root.accent : root.inputBorder
                    radius: 4
                    
                    TextInput {
                        id: newParamName
                        anchors.fill: parent
                        anchors.margins: 10
                        color: root.textColor
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        inputMethodHints: Qt.ImhNoPredictiveText
                        
                        Text {
                            visible: !parent.text
                            text: "$parametername"
                            color: root.textDim
                            font.pixelSize: 13
                        }
                    }
                }
                
                Text { text: "Value:"; color: root.textColor; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: root.inputBg
                    border.color: newParamValue.activeFocus ? root.accent : root.inputBorder
                    radius: 4
                    
                    TextInput {
                        id: newParamValue
                        anchors.fill: parent
                        anchors.margins: 10
                        color: root.textColor
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        inputMethodHints: Qt.ImhNoPredictiveText
                        
                        Text {
                            visible: !parent.text
                            text: "value"
                            color: root.textDim
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
                    color: root.panelBorder
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Rectangle {
                        width: 90
                        height: 32
                        radius: 4
                        color: cancelParamMouse.containsMouse ? root.buttonHover : root.buttonBg
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: root.textColor
                            font.pixelSize: 13
                        }
                        
                        MouseArea {
                            id: cancelParamMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addParamDialog.close()
                        }
                    }
                    
                    Rectangle {
                        width: 90
                        height: 32
                        radius: 4
                        color: okParamMouse.containsMouse ? "#1177bb" : root.accent
                        
                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        
                        MouseArea {
                            id: okParamMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (newParamName.text !== "") {
                                    materialModel.set_parameter_value(newParamName.text, newParamValue.text)
                                    newParamName.text = ""
                                    newParamValue.text = ""
                                }
                                addParamDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // About Dialog - Fancy version
    Dialog {
        id: aboutDialog
        modal: true
        anchors.centerIn: parent
        width: 420
        padding: 0
        
        background: Rectangle {
            color: root.panelBg
            border.color: root.panelBorder
            border.width: 0
            radius: 12
        }
        
        header: Item { height: 0 }  // No header
        footer: Item { height: 0 }  // No footer buttons
        
        contentItem: ColumnLayout {
            spacing: 0
            
            // Gradient header
            Rectangle {
                Layout.fillWidth: true
                height: 100
                radius: 12
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a3a5c" }
                    GradientStop { position: 1.0; color: root.panelBg }
                }
                
                // Top corners need masking
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 12
                    color: root.panelBg
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16
                    
                    // Logo/Icon
                    Image {
                        width: 48
                        height: 48
                        source: "qrc:/media/icon.png"
                        smooth: false  // Pixel art - no linear scaling
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        
                        Text {
                            text: "SuperVTF"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                        }
                        
                        Text {
                            text: "Version 0.8.0"
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
                    color: root.textColor
                    wrapMode: Text.WordWrap
                    font.pixelSize: 13
                    lineHeight: 1.4
                }
                
                
                
                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.panelBorder
                }
                
                // Footer info
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Made by JuiceyDev & Olxgs"
                        color: root.textDim
                        font.pixelSize: 11
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: "Built with Rust + Qt"
                        color: root.textDim
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
                    color: root.panelBorder
                }
                
                // Bottom corners rounding
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
                    anchors.centerIn: parent
                    width: 100
                    height: 32
                    radius: 6
                    color: closeAboutMouse.containsMouse ? "#1177bb" : root.accent
                    
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
                        onClicked: aboutDialog.close()
                    }
                }
            }
        }
    }
    
    // ===== WELCOME / GAME SETUP DIALOG =====
    Dialog {
        id: welcomeDialog
        modal: true
        anchors.centerIn: parent
        width: 500
        padding: 0
        closePolicy: Popup.NoAutoClose
        
        // Smooth enter/exit animations
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationSlow; easing.type: root.animEasing }
                NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: root.animDurationSlow; easing.type: root.animEasingBounce }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationNormal; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: root.animDurationNormal; easing.type: Easing.InCubic }
            }
        }
        
        // Show on first run
        Component.onCompleted: {
            if (app.is_first_run) {
                loadDetectedGames()
                open()
            }
        }
        
        property var detectedGames: []
        property int selectedIndex: -1
        
        function loadDetectedGames() {
            detectedGames = []
            var games = app.get_detected_games()
            for (var i = 0; i < games.length; i++) {
                var parts = games[i].split("|")
                if (parts.length >= 2) {
                    detectedGames.push({
                        name: parts[0],
                        path: parts[1],
                        icon: parts.length >= 3 ? parts[2] : ""
                    })
                }
            }
            detectedGamesChanged()
        }
        
        background: Rectangle {
            color: root.panelBg
            radius: 12
        }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: root.accent
                radius: 12
                
                // Square off bottom corners
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 12
                    color: parent.color
                }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "👋 Welcome to SuperVTF!"
                        font.pixelSize: 22
                        font.bold: true
                        color: "white"
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Let's set up your Source game"
                        font.pixelSize: 13
                        color: Qt.rgba(1, 1, 1, 0.8)
                    }
                }
            }
            
            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 16
                
                Text {
                    Layout.fillWidth: true
                    text: welcomeDialog.detectedGames.length > 0 
                        ? "We found these Source games installed. Select one to use its textures:"
                        : "No Source games detected. You can browse for a materials folder manually."
                    font.pixelSize: 13
                    color: root.textColor
                    wrapMode: Text.WordWrap
                }
                
                // Game list
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: root.inputBg
                    border.color: root.inputBorder
                    radius: 6
                    visible: welcomeDialog.detectedGames.length > 0
                    
                    ListView {
                        id: gameListView
                        anchors.fill: parent
                        anchors.margins: 4
                        clip: true
                        model: welcomeDialog.detectedGames
                        spacing: 4
                        
                        delegate: Rectangle {
                            id: gameItemRect
                            width: gameListView.width
                            height: 52
                            color: welcomeDialog.selectedIndex === index ? root.accent : 
                                   (gameMouseArea.containsMouse ? root.buttonHover : "transparent")
                            radius: 6
                            
                            // Smooth hover animations
                            scale: gameMouseArea.pressed ? 0.98 : 1.0
                            Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                            Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12
                                
                                // Game icon
                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    Layout.alignment: Qt.AlignVCenter
                                    color: "transparent"
                                    
                                    Image {
                                        id: gameIcon
                                        anchors.fill: parent
                                        source: modelData.icon || ""
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready
                                        smooth: true
                                        mipmap: true
                                    }
                                    
                                    // Fallback emoji when no icon
                                    Text {
                                        anchors.centerIn: parent
                                        text: "🎮"
                                        font.pixelSize: 24
                                        visible: gameIcon.status !== Image.Ready
                                    }
                                }
                                
                                // Game name and path
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: welcomeDialog.selectedIndex === index ? "white" : root.textColor
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.path
                                        font.pixelSize: 10
                                        color: welcomeDialog.selectedIndex === index ? Qt.rgba(1,1,1,0.7) : root.textDim
                                        elide: Text.ElideMiddle
                                    }
                                }
                                
                                // Checkmark when selected
                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: welcomeDialog.selectedIndex === index ? "✓" : ""
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "white"
                                }
                            }
                            
                            MouseArea {
                                id: gameMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: welcomeDialog.selectedIndex = index
                            }
                        }
                        
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }
                
                // Or browse manually
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: browseMouseArea.containsMouse ? root.buttonHover : root.inputBg
                    border.color: root.inputBorder
                    radius: 6
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        
                        // Folder icon placeholder
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "📁"
                                font.pixelSize: 24
                            }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: "Browse for materials folder manually..."
                            font.pixelSize: 14
                            color: root.textColor
                        }
                    }
                    
                    MouseArea {
                        id: browseMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: browseMaterialsDialog.open()
                    }
                }
                
                // Selected path display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manualPathField.implicitHeight + 16
                    color: root.inputBg
                    border.color: root.inputBorder
                    radius: 6
                    visible: manualPathField.text.length > 0
                    
                    TextField {
                        id: manualPathField
                        anchors.fill: parent
                        anchors.margins: 4
                        background: null
                        color: root.textColor
                        font.pixelSize: 11
                        readOnly: true
                        text: welcomeDialog.selectedIndex >= 0 && welcomeDialog.detectedGames.length > 0
                            ? welcomeDialog.detectedGames[welcomeDialog.selectedIndex].path
                            : ""
                    }
                }
            }
            
            // Footer buttons
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: Qt.darker(root.panelBg, 1.1)
                
                // Round bottom corners
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 12
                    color: parent.color
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    Button {
                        id: skipButton
                        text: "Skip for Now"
                        flat: true
                        onClicked: {
                            app.complete_first_run()
                            welcomeDialog.close()
                        }
                        
                        // Smooth hover animation
                        scale: hovered ? 1.02 : (pressed ? 0.98 : 1.0)
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 13
                            color: root.textDim
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: skipButton.hovered ? root.buttonHover : "transparent"
                            radius: 6
                            Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        }
                    }
                    
                    Button {
                        id: continueButton
                        text: "Continue"
                        enabled: welcomeDialog.selectedIndex >= 0 || manualPathField.text.length > 0
                        onClicked: {
                            if (welcomeDialog.selectedIndex >= 0 && welcomeDialog.detectedGames.length > 0) {
                                var game = welcomeDialog.detectedGames[welcomeDialog.selectedIndex]
                                app.select_game(game.name)
                            }
                            app.complete_first_run()
                            welcomeDialog.close()
                        }
                        
                        // Smooth hover animation
                        scale: hovered ? 1.03 : (pressed ? 0.97 : 1.0)
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                        
                        contentItem: Text {
                            text: continueButton.text
                            font.pixelSize: 13
                            font.bold: true
                            color: continueButton.enabled ? "white" : root.textDim
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: continueButton.enabled 
                                ? (continueButton.hovered ? root.accentHover : root.accent)
                                : root.buttonBg
                            radius: 6
                            Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        }
                    }
                }
            }
        }
    }
    
    // Browse materials folder dialog
    FolderDialog {
        id: browseMaterialsDialog
        title: "Select Materials Folder"
        onAccepted: {
            var path = root.urlToLocalPath(selectedFolder)
            app.set_materials_root_path(path)
            manualPathField.text = path
            welcomeDialog.selectedIndex = -1
        }
    }
    
    // Custom Color Picker Dialog
    Dialog {
        id: colorPickerDialog
        modal: true
        anchors.centerIn: parent
        width: 340
        padding: 0
        
        property var targetTextField: null
        property color initialColor: "white"
        property color currentColor: "white"
        property real hue: 0
        property real saturation: 1
        property real brightness: 1
        
        // Smooth enter/exit animations
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationNormal; easing.type: root.animEasing }
                NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: root.animDurationNormal; easing.type: root.animEasingBounce }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationFast; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: root.animDurationFast; easing.type: Easing.InCubic }
            }
        }
        
        onCurrentColorChanged: {
            hue = currentColor.hsvHue >= 0 ? currentColor.hsvHue : 0
            saturation = currentColor.hsvSaturation
            brightness = currentColor.hsvValue
        }
        
        background: Rectangle {
            color: root.panelBg
            border.color: root.panelBorder
            radius: 8
        }
        
        header: Item { height: 0 }
        footer: Item { height: 0 }
        
        contentItem: ColumnLayout {
            spacing: 0
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: root.panelBg
                
                Text {
                    anchors.centerIn: parent
                    text: "Color Picker"
                    color: root.textColor
                    font.pixelSize: 14
                    font.bold: true
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: root.panelBorder
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
                    
                    // Hue background
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Qt.hsva(colorPickerDialog.hue, 1, 1, 1)
                    }
                    
                    // Saturation gradient (white to transparent)
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#FFFFFF" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                    
                    // Brightness gradient (transparent to black)
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "#000000" }
                        }
                    }
                    
                    // Selection cursor
                    Rectangle {
                        x: colorPickerDialog.saturation * (parent.width - 12)
                        y: (1 - colorPickerDialog.brightness) * (parent.height - 12)
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
                            colorPickerDialog.saturation = Math.max(0, Math.min(1, mouseX / width))
                            colorPickerDialog.brightness = Math.max(0, Math.min(1, 1 - mouseY / height))
                            colorPickerDialog.currentColor = Qt.hsva(colorPickerDialog.hue, colorPickerDialog.saturation, colorPickerDialog.brightness, 1)
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
                        x: colorPickerDialog.hue * (parent.width - 8)
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
                            colorPickerDialog.hue = Math.max(0, Math.min(1, mouseX / width))
                            colorPickerDialog.currentColor = Qt.hsva(colorPickerDialog.hue, colorPickerDialog.saturation, colorPickerDialog.brightness, 1)
                        }
                        
                        onPressed: function(mouse) { updateHue(mouse.x) }
                        onPositionChanged: function(mouse) { if (pressed) updateHue(mouse.x) }
                    }
                }
                
                // Color preview and RGB values
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // Preview boxes
                    ColumnLayout {
                        spacing: 4
                        
                        Text {
                            text: "New"
                            color: root.textDim
                            font.pixelSize: 10
                        }
                        
                        Rectangle {
                            width: 50
                            height: 30
                            radius: 4
                            color: colorPickerDialog.currentColor
                            border.color: root.inputBorder
                        }
                        
                        Text {
                            text: "Old"
                            color: root.textDim
                            font.pixelSize: 10
                        }
                        
                        Rectangle {
                            width: 50
                            height: 30
                            radius: 4
                            color: colorPickerDialog.initialColor
                            border.color: root.inputBorder
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: colorPickerDialog.currentColor = colorPickerDialog.initialColor
                            }
                        }
                    }
                    
                    // RGB inputs
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 8
                        
                        Text { text: "R"; color: "#e74c3c"; font.pixelSize: 12; font.bold: true }
                        TextField {
                            id: redInput
                            Layout.fillWidth: true
                            text: activeFocus ? text : Math.round(colorPickerDialog.currentColor.r * 255).toString()
                            validator: IntValidator { bottom: 0; top: 255 }
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextEdited: {
                                var r = parseInt(text) || 0
                                colorPickerDialog.currentColor = Qt.rgba(r/255, colorPickerDialog.currentColor.g, colorPickerDialog.currentColor.b, 1)
                            }
                            background: Rectangle {
                                implicitHeight: 26
                                color: root.inputBg
                                border.color: redInput.activeFocus ? "#e74c3c" : root.inputBorder
                                radius: 4
                            }
                            color: root.textColor
                            font.pixelSize: 12
                        }
                        
                        Text { text: "G"; color: "#2ecc71"; font.pixelSize: 12; font.bold: true }
                        TextField {
                            id: greenInput
                            Layout.fillWidth: true
                            text: activeFocus ? text : Math.round(colorPickerDialog.currentColor.g * 255).toString()
                            validator: IntValidator { bottom: 0; top: 255 }
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextEdited: {
                                var g = parseInt(text) || 0
                                colorPickerDialog.currentColor = Qt.rgba(colorPickerDialog.currentColor.r, g/255, colorPickerDialog.currentColor.b, 1)
                            }
                            background: Rectangle {
                                implicitHeight: 26
                                color: root.inputBg
                                border.color: greenInput.activeFocus ? "#2ecc71" : root.inputBorder
                                radius: 4
                            }
                            color: root.textColor
                            font.pixelSize: 12
                        }
                        
                        Text { text: "B"; color: "#3498db"; font.pixelSize: 12; font.bold: true }
                        TextField {
                            id: blueInput
                            Layout.fillWidth: true
                            text: activeFocus ? text : Math.round(colorPickerDialog.currentColor.b * 255).toString()
                            validator: IntValidator { bottom: 0; top: 255 }
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextEdited: {
                                var b = parseInt(text) || 0
                                colorPickerDialog.currentColor = Qt.rgba(colorPickerDialog.currentColor.r, colorPickerDialog.currentColor.g, b/255, 1)
                            }
                            background: Rectangle {
                                implicitHeight: 26
                                color: root.inputBg
                                border.color: blueInput.activeFocus ? "#3498db" : root.inputBorder
                                radius: 4
                            }
                            color: root.textColor
                            font.pixelSize: 12
                        }
                    }
                }
            }
            
            // Footer with buttons
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: "#1e1e1e"
                
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: root.panelBorder
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Rectangle {
                        width: 80
                        height: 30
                        radius: 4
                        color: cancelColorMouse.containsMouse ? root.buttonHover : root.buttonBg
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: root.textColor
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            id: cancelColorMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: colorPickerDialog.close()
                        }
                    }
                    
                    Rectangle {
                        width: 80
                        height: 30
                        radius: 4
                        color: okColorMouse.containsMouse ? root.accentHover : root.accent
                        
                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        
                        MouseArea {
                            id: okColorMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (colorPickerDialog.targetTextField) {
                                    var r = Math.round(colorPickerDialog.currentColor.r * 255)
                                    var g = Math.round(colorPickerDialog.currentColor.g * 255)
                                    var b = Math.round(colorPickerDialog.currentColor.b * 255)
                                    colorPickerDialog.targetTextField.text = "[" + r + " " + g + " " + b + "]"
                                }
                                colorPickerDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ===== GLOBAL TEXTURE BROWSER =====
    Popup {
        id: globalTextureBrowser
        
        property var targetTextField: null
        property string selectedTexture: ""
        property bool openMode: false  // When true, "Open" loads in preview; when false, "Select" fills text field
        
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width - 40, 900)
        height: Math.min(parent.height - 40, 700)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        // Smooth enter/exit animations
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animDurationNormal; easing.type: root.animEasing }
                NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: root.animDurationNormal; easing.type: root.animEasingBounce }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.animDurationFast; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: root.animDurationFast; easing.type: Easing.InCubic }
            }
        }
        
        background: Rectangle {
            color: root.panelBg
            border.color: root.panelBorder
            border.width: 1
            radius: 8
        }
        
        // Store textures
        property var allTextures: []
        property var filteredTextures: []
        property string selectedCategory: "all"
        property var categories: ["all", "custom", "brick", "concrete", "metal", "wood", "glass", "nature", "decals", "models", "effects", "other"]
        property bool isLoading: false
        
        onOpened: {
            loadTextures()
            searchField.forceActiveFocus()
        }
        
        function loadTextures() {
            isLoading = true
            // Get textures from VPK
            var vpkTextures = app.get_texture_completions("", 5000)
            allTextures = []
            
            // Track paths we've already added to avoid duplicates
            var addedPaths = {}
            
            for (var i = 0; i < vpkTextures.length; i++) {
                var path = vpkTextures[i]
                var category = categorizeTexture(path)
                allTextures.push({
                    path: path,
                    category: category,
                    isCustom: false
                })
                addedPaths[path.toLowerCase()] = true
            }
            
            // Get custom textures from disk
            var customTextures = app.get_custom_textures(2000)
            for (var j = 0; j < customTextures.length; j++) {
                var customPath = customTextures[j]
                // Skip if already added from VPK
                if (addedPaths[customPath.toLowerCase()]) {
                    continue
                }
                var customCategory = categorizeTexture(customPath)
                allTextures.push({
                    path: customPath,
                    category: customCategory,
                    isCustom: true
                })
                addedPaths[customPath.toLowerCase()] = true
            }
            
            isLoading = false
            filterTextures()
        }
        
        function categorizeTexture(path) {
            var lower = path.toLowerCase()
            if (lower.indexOf("brick") !== -1) return "brick"
            if (lower.indexOf("concrete") !== -1 || lower.indexOf("concretewall") !== -1) return "concrete"
            if (lower.indexOf("metal") !== -1) return "metal"
            if (lower.indexOf("wood") !== -1 || lower.indexOf("plywood") !== -1) return "wood"
            if (lower.indexOf("glass") !== -1) return "glass"
            if (lower.indexOf("nature") !== -1 || lower.indexOf("grass") !== -1 || lower.indexOf("dirt") !== -1 || lower.indexOf("rock") !== -1 || lower.indexOf("sand") !== -1) return "nature"
            if (lower.indexOf("decal") !== -1 || lower.indexOf("overlay") !== -1) return "decals"
            if (lower.indexOf("models/") !== -1) return "models"
            if (lower.indexOf("effects") !== -1 || lower.indexOf("sprites") !== -1 || lower.indexOf("particle") !== -1) return "effects"
            return "other"
        }
        
        function filterTextures() {
            var searchText = searchField.text.toLowerCase()
            filteredTextures = []
            
            for (var i = 0; i < allTextures.length; i++) {
                var tex = allTextures[i]
                
                // Category filter
                if (selectedCategory === "custom") {
                    // Special case: show only custom textures
                    if (!tex.isCustom) continue
                } else if (selectedCategory !== "all" && tex.category !== selectedCategory) {
                    continue
                }
                
                // Search filter
                if (searchText.length > 0 && tex.path.toLowerCase().indexOf(searchText) === -1) {
                    continue
                }
                
                filteredTextures.push(tex)
                
                // Limit results for performance
                if (filteredTextures.length >= 500) break
            }
            
            textureGrid.model = filteredTextures
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: globalTextureBrowser.openMode ? "🖼 Texture Browser - Open" : "🖼 Texture Browser - Select"
                    color: root.textColor
                    font.pixelSize: 18
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                // Search field
                Rectangle {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 32
                    color: root.inputBg
                    border.color: searchField.activeFocus ? root.accent : root.inputBorder
                    border.width: 1
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8
                        
                        Text {
                            text: "🔍"
                            color: root.textDim
                            font.pixelSize: 14
                        }
                        
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search textures..."
                            
                            onTextChanged: {
                                searchTimer.restart()
                            }
                            
                            Timer {
                                id: searchTimer
                                interval: 200
                                onTriggered: globalTextureBrowser.filterTextures()
                            }
                            
                            background: Rectangle { color: "transparent" }
                            color: root.textColor
                            font.pixelSize: 13
                        }
                        
                        // Clear button
                        Text {
                            text: "✕"
                            color: clearSearchMouse.containsMouse ? root.textColor : root.textDim
                            font.pixelSize: 12
                            visible: searchField.text.length > 0
                            
                            MouseArea {
                                id: clearSearchMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }
                
                // Close button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 4
                    color: closeBrowserMouse.containsMouse ? "#c42b1c" : root.inputBg
                    
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: root.textColor
                        font.pixelSize: 18
                    }
                    
                    MouseArea {
                        id: closeBrowserMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: globalTextureBrowser.close()
                    }
                }
            }
            
            // Category tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Repeater {
                    model: globalTextureBrowser.categories
                    
                    Rectangle {
                        id: categoryRect
                        width: categoryText.implicitWidth + 16
                        height: 28
                        radius: 4
                        color: globalTextureBrowser.selectedCategory === modelData ? root.accent : (categoryMouse.containsMouse ? root.buttonHover : root.buttonBg)
                        border.color: globalTextureBrowser.selectedCategory === modelData ? root.accent : root.inputBorder
                        border.width: 1
                        
                        // Smooth hover animations
                        scale: categoryMouse.pressed ? 0.95 : (categoryMouse.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                        Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        
                        Text {
                            id: categoryText
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            color: root.textColor
                            font.pixelSize: 11
                            font.bold: globalTextureBrowser.selectedCategory === modelData
                        }
                        
                        MouseArea {
                            id: categoryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                globalTextureBrowser.selectedCategory = modelData
                                globalTextureBrowser.filterTextures()
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Results count
                Text {
                    text: textureGrid.count + " textures"
                    color: root.textDim
                    font.pixelSize: 11
                }
            }
            
            // Selected texture info bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: globalTextureBrowser.selectedTexture ? 40 : 0
                color: root.inputBg
                border.color: root.accent
                border.width: 1
                radius: 4
                visible: globalTextureBrowser.selectedTexture !== ""
                clip: true
                
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Text {
                        text: "Selected:"
                        color: root.textDim
                        font.pixelSize: 12
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: globalTextureBrowser.selectedTexture
                        color: root.textColor
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideMiddle
                    }
                    
                    Rectangle {
                        width: copyBtn.implicitWidth + 16
                        height: 24
                        radius: 3
                        color: copyMouse.containsMouse ? root.accentHover : root.accent
                        
                        Text {
                            id: copyBtn
                            anchors.centerIn: parent
                            text: "📋 Copy"
                            color: "white"
                            font.pixelSize: 11
                        }
                        
                        MouseArea {
                            id: copyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Copy to clipboard (we'd need to implement this in Rust)
                                console.log("Copy texture path: " + globalTextureBrowser.selectedTexture)
                            }
                        }
                    }
                }
            }
            
            // Texture grid with loading overlay
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    
                    GridView {
                        id: textureGrid
                        cellWidth: 120
                        cellHeight: 140
                        
                        delegate: Rectangle {
                            id: gridItemRect
                            width: 115
                            height: 135
                            color: gridItemMouse.containsMouse ? root.buttonHover : "transparent"
                            border.color: globalTextureBrowser.selectedTexture === modelData.path ? root.accent : (gridItemMouse.containsMouse ? root.accent : "transparent")
                            border.width: globalTextureBrowser.selectedTexture === modelData.path ? 2 : 1
                            radius: 6
                            
                            // Smooth hover animations
                            scale: gridItemMouse.containsMouse ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                            Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                            Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                            spacing: 4
                            
                            // Texture preview
                            Rectangle {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 100
                                Layout.alignment: Qt.AlignHCenter
                                color: root.inputBg
                                border.color: root.inputBorder
                                border.width: 1
                                radius: 4
                                
                                // Thumbnail loading with delay to avoid spamming
                                property string thumbnailSource: ""
                                property bool thumbnailRequested: false
                                
                                Timer {
                                    id: thumbnailTimer
                                    interval: 50 + Math.random() * 100  // Stagger requests
                                    onTriggered: {
                                        if (!parent.thumbnailRequested && app.materials_root.length > 0) {
                                            parent.thumbnailRequested = true
                                            var result = textureProvider.get_thumbnail_for_texture(modelData.path, app.materials_root)
                                            if (result.length > 0) {
                                                parent.thumbnailSource = result
                                            }
                                        }
                                    }
                                }
                                
                                Component.onCompleted: thumbnailTimer.start()
                                
                                Image {
                                    id: gridThumbnailImage
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    fillMode: Image.PreserveAspectFit
                                    source: parent.thumbnailSource
                                    asynchronous: true
                                    cache: true
                                    
                                    // Smooth fade-in when loaded
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: root.animDurationNormal; easing.type: root.animEasing } }
                                    
                                    // Loading spinner - waiting for thumbnail request
                                    Item {
                                        id: waitingSpinner
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        visible: gridThumbnailImage.source === "" && !gridThumbnailImage.parent.thumbnailRequested
                                        
                                        Canvas {
                                            anchors.centerIn: parent
                                            width: 24
                                            height: 24
                                            
                                            property real angle: 0
                                            
                                            NumberAnimation on angle {
                                                from: 0
                                                to: 360
                                                duration: 800
                                                loops: Animation.Infinite
                                                running: waitingSpinner.visible
                                            }
                                            
                                            onAngleChanged: requestPaint()
                                            
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.reset()
                                                ctx.strokeStyle = root.inputBorder
                                                ctx.lineWidth = 2
                                                ctx.beginPath()
                                                ctx.arc(width/2, height/2, 9, 0, Math.PI * 2)
                                                ctx.stroke()
                                                ctx.strokeStyle = root.accent
                                                ctx.lineCap = "round"
                                                ctx.beginPath()
                                                var startAngle = (angle - 90) * Math.PI / 180
                                                var endAngle = (angle + 90) * Math.PI / 180
                                                ctx.arc(width/2, height/2, 9, startAngle, endAngle)
                                                ctx.stroke()
                                            }
                                        }
                                    }
                                    
                                    // Loading spinner - image actively loading
                                    Item {
                                        id: loadingImageSpinner
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        visible: gridThumbnailImage.status === Image.Loading
                                        
                                        Canvas {
                                            anchors.centerIn: parent
                                            width: 24
                                            height: 24
                                            
                                            property real angle: 0
                                            
                                            NumberAnimation on angle {
                                                from: 0
                                                to: 360
                                                duration: 600
                                                loops: Animation.Infinite
                                                running: loadingImageSpinner.visible
                                            }
                                            
                                            onAngleChanged: requestPaint()
                                            
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.reset()
                                                ctx.strokeStyle = root.inputBorder
                                                ctx.lineWidth = 2
                                                ctx.beginPath()
                                                ctx.arc(width/2, height/2, 9, 0, Math.PI * 2)
                                                ctx.stroke()
                                                ctx.strokeStyle = root.accent
                                                ctx.lineCap = "round"
                                                ctx.beginPath()
                                                var startAngle = (angle - 90) * Math.PI / 180
                                                var endAngle = (angle + 90) * Math.PI / 180
                                                ctx.arc(width/2, height/2, 9, startAngle, endAngle)
                                                ctx.stroke()
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "?"
                                        color: root.textDim
                                        font.pixelSize: 24
                                        visible: gridThumbnailImage.status === Image.Error || gridThumbnailImage.status === Image.Null
                                    }
                                }
                                
                                // Custom texture badge
                                Rectangle {
                                    visible: modelData.isCustom === true
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#4CAF50"
                                    border.color: "#2E7D32"
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "C"
                                        color: "white"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                    
                                    ToolTip.visible: customBadgeMouse.containsMouse
                                    ToolTip.text: "Custom texture (on disk)"
                                    ToolTip.delay: 500
                                    
                                    MouseArea {
                                        id: customBadgeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                            
                            // Texture name
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var parts = modelData.path.split("/")
                                    return parts[parts.length - 1]
                                }
                                color: root.textColor
                                font.pixelSize: 10
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        MouseArea {
                            id: gridItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                globalTextureBrowser.selectedTexture = modelData.path
                            }
                            
                            onDoubleClicked: {
                                globalTextureBrowser.selectedTexture = modelData.path
                                if (globalTextureBrowser.openMode) {
                                    // Open mode: load in preview pane
                                    textureProvider.load_from_material_path(modelData.path, app.materials_root)
                                } else if (globalTextureBrowser.targetTextField) {
                                    // Select mode: fill text field
                                    globalTextureBrowser.targetTextField.text = modelData.path
                                }
                                globalTextureBrowser.close()
                            }
                        }
                        
                        ToolTip {
                            visible: gridItemMouse.containsMouse
                            text: modelData.path + (globalTextureBrowser.openMode ? "\nDouble-click to open" : "\nDouble-click to select")
                            delay: 500
                        }
                    }
                }
                }
                
                // Loading overlay
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.7)
                    visible: globalTextureBrowser.isLoading
                    opacity: globalTextureBrowser.isLoading ? 1.0 : 0.0
                    
                    Behavior on opacity { NumberAnimation { duration: root.animDurationNormal } }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        
                        // Animated loading spinner
                        Canvas {
                            id: loadingSpinner
                            width: 48
                            height: 48
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            property real angle: 0
                            
                            NumberAnimation on angle {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: globalTextureBrowser.isLoading
                            }
                            
                            onAngleChanged: requestPaint()
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.strokeStyle = root.accent
                                ctx.lineWidth = 4
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                var startAngle = (angle - 90) * Math.PI / 180
                                var endAngle = (angle + 180) * Math.PI / 180
                                ctx.arc(width/2, height/2, 18, startAngle, endAngle)
                                ctx.stroke()
                            }
                        }
                        
                        Text {
                            text: "Loading textures..."
                            color: root.textColor
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
            
            // Footer with actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: {
                        if (globalTextureBrowser.selectedTexture) {
                            return globalTextureBrowser.openMode 
                                ? "Double-click or press Open to view texture" 
                                : "Double-click or press Select to use texture"
                        }
                        return globalTextureBrowser.openMode 
                            ? "Click a texture to select, double-click to open" 
                            : "Click a texture to select, double-click to use"
                    }
                    color: root.textDim
                    font.pixelSize: 11
                }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    id: cancelBtn
                    width: 80
                    height: 30
                    radius: 4
                    color: cancelMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: cancelMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: root.textColor
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: globalTextureBrowser.close()
                    }
                }
                
                Rectangle {
                    id: selectBtn
                    width: 80
                    height: 30
                    radius: 4
                    color: selectMouse.containsMouse ? root.accentHover : root.accent
                    opacity: globalTextureBrowser.selectedTexture ? 1.0 : 0.5
                    
                    // Smooth hover animation
                    scale: selectMouse.pressed ? 0.95 : (selectMouse.containsMouse && globalTextureBrowser.selectedTexture ? 1.03 : 1.0)
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: globalTextureBrowser.openMode ? "Open" : "Select"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: selectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: globalTextureBrowser.selectedTexture ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: globalTextureBrowser.selectedTexture !== ""
                        onClicked: {
                            if (globalTextureBrowser.openMode) {
                                // Open mode: load in preview pane
                                textureProvider.load_from_material_path(globalTextureBrowser.selectedTexture, app.materials_root)
                            } else if (globalTextureBrowser.targetTextField) {
                                // Select mode: fill text field
                                globalTextureBrowser.targetTextField.text = globalTextureBrowser.selectedTexture
                            }
                            globalTextureBrowser.close()
                        }
                    }
                }
            }
        }
    }
}
