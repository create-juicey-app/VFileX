import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import com.supervtf 1.0
// i need to separate this code, it's getting big
ApplicationWindow {
    id: root
    
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
            for (var i = 0; i < shaders.length; ++i) {
                shaderModel.append({"name": shaders[i]})
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
            var path = selectedFile.toString()
            if (path.startsWith("file://")) {
                path = path.substring(7)
            }
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
            var path = selectedFile.toString()
            if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            materialModel.save_file(path)
        }
    }
    
    FileDialog {
        id: openVtfDialog
        title: "Open VTF Texture"
        nameFilters: ["VTF Files (*.vtf)", "All Files (*)"]
        onAccepted: {
            var path = selectedFile.toString()
            if (path.startsWith("file://")) {
                path = path.substring(7)
            }
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
                color: menuBarItem.highlighted ? root.accent : "transparent"
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
                            
                            background: Rectangle { color: "transparent" }
                            
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
                        
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        
                        section.property: "paramCategory"
                        section.criteria: ViewSection.FullString
                        section.delegate: Rectangle {
                            width: paramList.width - 10
                            height: 36
                            color: "transparent"
                            
                            property bool isCollapsed: root.isCategoryCollapsed(section)
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleCategory(section)
                            }
                            
                            RowLayout {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -4
                                spacing: 6
                                
                                Text {
                                    text: root.isCategoryCollapsed(section) ? "▶" : "▼"
                                    color: root.textDim
                                    font.pixelSize: 10
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
                            width: paramList.width - 10
                            height: root.isCategoryCollapsed(model.paramCategory) ? 0 : paramContent.height + 16
                            visible: !root.isCategoryCollapsed(model.paramCategory)
                            color: paramMouse.containsMouse ? "#2a2d2e" : "transparent"
                            radius: root.radius
                            border.color: root.panelBorder
                            border.width: visible ? 1 : 0
                            clip: true
                            
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
                                            onClicked: colorDialog.open()
                                        }
                                    }
                                    
                                    TextField {
                                        id: colorTextField
                                        Layout.fillWidth: true
                                        text: delegateRoot.pValue
                                        
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
                                    
                                    ColorDialog {
                                        id: colorDialog
                                        title: "Choose " + delegateRoot.pDisplayName
                                        selectedColor: colorPreview.color
                                        
                                        onAccepted: {
                                            var r = Math.round(selectedColor.r * 255)
                                            var g = Math.round(selectedColor.g * 255)
                                            var b = Math.round(selectedColor.b * 255)
                                            colorTextField.text = "[" + r + " " + g + " " + b + "]"
                                        }
                                    }
                                }
                                
                                // Texture control
                                RowLayout {
                                    visible: delegateRoot.pDataType.toLowerCase() === "texture"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        color: root.inputBg
                                        border.color: root.inputBorder
                                        radius: 4
                                        
                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            fillMode: Image.PreserveAspectFit
                                            source: delegateRoot.pValue ? "image://vtf/" + delegateRoot.pValue : ""
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "?"
                                                color: root.textDim
                                                font.pixelSize: 14
                                                visible: parent.status !== Image.Ready
                                            }
                                        }
                                    }
                                    
                                    TextField {
                                        id: textureField
                                        Layout.fillWidth: true
                                        text: delegateRoot.pValue
                                        placeholderText: "path/to/texture"
                                        
                                        onTextChanged: {
                                            if (parent.visible) {
                                                materialModel.set_parameter_value(delegateRoot.pName, text)
                                                // Update preview if this is the base texture
                                                if (delegateRoot.pName.toLowerCase() === "$basetexture") {
                                                    textureProvider.load_from_material_path(text, app.materials_root)
                                                }
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
    footer: Rectangle {
        height: 28
        color: "#007acc"
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            
            Text {
                id: statusBar
                text: "Ready"
                color: "#ffffff"
                font.pixelSize: 12
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: textureProvider.is_loaded ? 
                      `${textureProvider.texture_width}×${textureProvider.texture_height} | ${textureProvider.format_name}` : ""
                color: "#ffffff"
                font.pixelSize: 12
            }
        }
    }
    
    // ===== DIALOGS =====
    
    // New Material Dialog
    Dialog {
        id: newMaterialDialog
        modal: true
        anchors.centerIn: parent
        width: 400
        padding: 0
        
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
                    model: shaderModel
                    textRole: "name"
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
                        color: cancelNewMouse.containsMouse ? root.buttonHover : root.buttonBg
                        
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
                        width: 90
                        height: 32
                        radius: 4
                        color: okNewMouse.containsMouse ? "#1177bb" : root.accent
                        
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
                            text: "Version 0.7.0"
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
                
                // Features
                Rectangle {
                    Layout.fillWidth: true
                    height: featuresCol.height + 16
                    color: "#1e1e1e"
                    radius: 6
                    
    
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
}
