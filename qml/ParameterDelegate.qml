import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    
    property var parameterEntry
    property bool expanded: parameterEntry.has_value || parameterEntry.required
    
    readonly property color panelBackground: "#252526"
    readonly property color panelBorder: "#3c3c3c"
    readonly property color inputBackground: "#3c3c3c"
    readonly property color inputBorder: "#5a5a5a"
    readonly property color textPrimary: "#cccccc"
    readonly property color textSecondary: "#808080"
    readonly property color accent: "#0e639c"
    readonly property color hoverBackground: "#2a2d2e"
    readonly property color toggleOn: "#4ec9b0"
    readonly property color toggleOff: "#5a5a5a"
    
    // Animation settings
    readonly property int animDurationFast: 120
    readonly property int animDurationNormal: 200
    readonly property int animEasing: Easing.OutCubic
    
    signal valueChanged(string name, string value)
    signal removeClicked(string name)
    
    implicitWidth: parent ? parent.width : 300
    implicitHeight: expanded ? contentColumn.implicitHeight : headerRow.implicitHeight
    
    Behavior on implicitHeight {
        NumberAnimation { duration: root.animDurationNormal; easing.type: root.animEasing }
    }
    
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 4
        
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8
            
            CheckBox {
                id: enableCheckbox
                checked: parameterEntry.has_value
                onCheckedChanged: {
                    if (!checked && parameterEntry.has_value) {
                        removeClicked(parameterEntry.name)
                    }
                    expanded = checked || parameterEntry.required
                }
                
                indicator: Rectangle {
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 3
                    color: enableCheckbox.checked ? accent : inputBackground
                    border.color: enableCheckbox.checked ? accent : inputBorder
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                    
                    scale: enableCheckbox.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "\u2713"
                        color: "white"
                        font.pixelSize: 12
                        visible: enableCheckbox.checked
                        opacity: enableCheckbox.checked ? 1.0 : 0.0
                        scale: enableCheckbox.checked ? 1.0 : 0.5
                        Behavior on opacity { NumberAnimation { duration: root.animDurationFast } }
                        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutBack } }
                    }
                }
            }
            
            Text {
                text: parameterEntry.display_name
                color: expanded ? textPrimary : textSecondary
                font.pixelSize: 13
                Layout.fillWidth: true
                elide: Text.ElideRight
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: expanded = !expanded
                }
            }
            
            Text {
                text: parameterEntry.data_type
                color: textSecondary
                font.pixelSize: 11
                font.italic: true
            }
        }
        
        Loader {
            id: controlLoader
            Layout.fillWidth: true
            Layout.leftMargin: 24
            visible: expanded
            active: expanded
            opacity: expanded ? 1.0 : 0.0
            
            Behavior on opacity { NumberAnimation { duration: root.animDurationFast } }
            
            sourceComponent: {
                switch (parameterEntry.data_type.toLowerCase()) {
                    case "bool":
                        return boolComponent
                    case "int":
                        return intComponent
                    case "float":
                        return floatComponent
                    case "color":
                        return colorComponent
                    case "vector2":
                        return vector2Component
                    case "vector3":
                        return vector3Component
                    case "transform":
                        return transformComponent
                    case "texture":
                        return textureComponent
                    default:
                        return stringComponent
                }
            }
        }
    }
    
    Component {
        id: boolComponent
        
        Switch {
            id: boolSwitch
            checked: parameterEntry.value === "1" || parameterEntry.value.toLowerCase() === "true"
            
            onCheckedChanged: {
                valueChanged(parameterEntry.name, checked ? "1" : "0")
            }
            
            indicator: Rectangle {
                implicitWidth: 44
                implicitHeight: 22
                x: boolSwitch.leftPadding
                y: parent.height / 2 - height / 2
                radius: 11
                color: boolSwitch.checked ? toggleOn : toggleOff
                
                Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                
                Rectangle {
                    x: boolSwitch.checked ? parent.width - width - 3 : 3
                    y: 3
                    width: 16
                    height: 16
                    radius: 8
                    color: "white"
                    
                    Behavior on x {
                        NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing }
                    }
                }
            }
            
            contentItem: Text {
                text: boolSwitch.checked ? "On" : "Off"
                color: textSecondary
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                leftPadding: boolSwitch.indicator.width + 8
                
                Behavior on text { 
                    SequentialAnimation {
                        NumberAnimation { target: boolSwitch.contentItem; property: "opacity"; to: 0; duration: 60 }
                        PropertyAction { }
                        NumberAnimation { target: boolSwitch.contentItem; property: "opacity"; to: 1; duration: 60 }
                    }
                }
            }
        }
    }
    
    Component {
        id: intComponent
        
        RowLayout {
            spacing: 8
            
            SpinBox {
                id: intSpinBox
                Layout.preferredWidth: 120
                from: parameterEntry.min_value !== "" ? parseInt(parameterEntry.min_value) : -2147483647
                to: parameterEntry.max_value !== "" ? parseInt(parameterEntry.max_value) : 2147483647
                value: parseInt(parameterEntry.value) || 0
                editable: true
                
                onValueChanged: {
                    root.valueChanged(parameterEntry.name, value.toString())
                }
                
                background: Rectangle {
                    implicitWidth: 120
                    implicitHeight: 28
                    color: inputBackground
                    border.color: intSpinBox.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                    
                    Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                }
                
                contentItem: TextInput {
                    text: intSpinBox.textFromValue(intSpinBox.value, intSpinBox.locale)
                    font.pixelSize: 13
                    color: textPrimary
                    selectionColor: accent
                    selectedTextColor: "white"
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    readOnly: !intSpinBox.editable
                    validator: intSpinBox.validator
                }
                
                up.indicator: Rectangle {
                    x: parent.width - width
                    height: parent.height / 2
                    implicitWidth: 20
                    implicitHeight: 14
                    color: intSpinBox.up.pressed ? hoverBackground : "transparent"
                    
                    Text {
                        text: "\u25B2"
                        font.pixelSize: 8
                        color: textSecondary
                        anchors.centerIn: parent
                    }
                }
                
                down.indicator: Rectangle {
                    x: parent.width - width
                    y: parent.height / 2
                    height: parent.height / 2
                    implicitWidth: 20
                    implicitHeight: 14
                    color: intSpinBox.down.pressed ? hoverBackground : "transparent"
                    
                    Text {
                        text: "\u25BC"
                        font.pixelSize: 8
                        color: textSecondary
                        anchors.centerIn: parent
                    }
                }
            }
            
            Slider {
                id: intSlider
                Layout.fillWidth: true
                visible: parameterEntry.min_value !== "" && parameterEntry.max_value !== ""
                from: parameterEntry.min_value !== "" ? parseInt(parameterEntry.min_value) : 0
                to: parameterEntry.max_value !== "" ? parseInt(parameterEntry.max_value) : 100
                stepSize: 1
                value: parseInt(parameterEntry.value) || 0
                
                onValueChanged: {
                    intSpinBox.value = value
                }
                
                background: Rectangle {
                    x: intSlider.leftPadding
                    y: intSlider.topPadding + intSlider.availableHeight / 2 - height / 2
                    width: intSlider.availableWidth
                    height: 4
                    radius: 2
                    color: inputBorder
                    
                    Rectangle {
                        width: intSlider.visualPosition * parent.width
                        height: parent.height
                        color: accent
                        radius: 2
                        
                        Behavior on width { NumberAnimation { duration: 50 } }
                    }
                }
                
                handle: Rectangle {
                    x: intSlider.leftPadding + intSlider.visualPosition * (intSlider.availableWidth - width)
                    y: intSlider.topPadding + intSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: intSlider.pressed ? Qt.lighter(accent, 1.2) : accent
                    border.color: Qt.darker(accent, 1.1)
                    border.width: 1
                    
                    scale: intSlider.pressed ? 1.2 : (intSlider.hovered ? 1.1 : 1.0)
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                }
            }
        }
    }
    
    Component {
        id: floatComponent
        
        RowLayout {
            spacing: 8
            
            TextField {
                id: floatField
                Layout.preferredWidth: 100
                text: parameterEntry.value
                validator: DoubleValidator { }
                
                onTextChanged: {
                    if (acceptableInput) {
                        root.valueChanged(parameterEntry.name, text)
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: floatField.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
                selectionColor: accent
            }
            
            Slider {
                id: floatSlider
                Layout.fillWidth: true
                visible: parameterEntry.min_value !== "" && parameterEntry.max_value !== ""
                from: parameterEntry.min_value !== "" ? parseFloat(parameterEntry.min_value) : 0.0
                to: parameterEntry.max_value !== "" ? parseFloat(parameterEntry.max_value) : 1.0
                value: parseFloat(parameterEntry.value) || 0.0
                
                onValueChanged: {
                    floatField.text = value.toFixed(3)
                }
                
                background: Rectangle {
                    x: floatSlider.leftPadding
                    y: floatSlider.topPadding + floatSlider.availableHeight / 2 - height / 2
                    width: floatSlider.availableWidth
                    height: 4
                    radius: 2
                    color: inputBorder
                    
                    Rectangle {
                        width: floatSlider.visualPosition * parent.width
                        height: parent.height
                        color: accent
                        radius: 2
                        
                        Behavior on width { NumberAnimation { duration: 50 } }
                    }
                }
                
                handle: Rectangle {
                    x: floatSlider.leftPadding + floatSlider.visualPosition * (floatSlider.availableWidth - width)
                    y: floatSlider.topPadding + floatSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: floatSlider.pressed ? Qt.lighter(accent, 1.2) : accent
                    border.color: Qt.darker(accent, 1.1)
                    border.width: 1
                    
                    scale: floatSlider.pressed ? 1.2 : (floatSlider.hovered ? 1.1 : 1.0)
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                }
            }
        }
    }
    
    Component {
        id: colorComponent
        
        RowLayout {
            spacing: 8
            
            Rectangle {
                id: colorPreview
                Layout.preferredWidth: 48
                Layout.preferredHeight: 28
                radius: 3
                border.color: colorPreviewMouse.containsMouse ? accent : inputBorder
                border.width: 1
                
                Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                
                property color parsedColor: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        if (parts.length >= 3) {
                            return Qt.rgba(
                                parseFloat(parts[0]) / 255,
                                parseFloat(parts[1]) / 255,
                                parseFloat(parts[2]) / 255,
                                1.0
                            )
                        }
                    } else if (val.charAt(0) === '{') {
                        var nums = val.slice(1, -1).split(/\s+/)
                        if (nums.length >= 3) {
                            return Qt.rgba(
                                parseFloat(nums[0]),
                                parseFloat(nums[1]),
                                parseFloat(nums[2]),
                                1.0
                            )
                        }
                    }
                    return Qt.rgba(1, 1, 1, 1)
                }
                
                color: parsedColor
                Behavior on color { ColorAnimation { duration: root.animDurationNormal } }
                
                scale: colorPreviewMouse.pressed ? 0.95 : (colorPreviewMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                
                MouseArea {
                    id: colorPreviewMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: colorDialog.open()
                }
            }
            
            TextField {
                id: colorTextField
                Layout.fillWidth: true
                text: parameterEntry.value
                
                onTextChanged: {
                    root.valueChanged(parameterEntry.name, text)
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: colorTextField.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                    
                    Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
                selectionColor: accent
            }
            
            ColorDialog {
                id: colorDialog
                title: "Choose " + parameterEntry.display_name
                selectedColor: colorPreview.parsedColor
                
                onAccepted: {
                    var r = Math.round(selectedColor.r * 255)
                    var g = Math.round(selectedColor.g * 255)
                    var b = Math.round(selectedColor.b * 255)
                    colorTextField.text = "[" + r + " " + g + " " + b + "]"
                }
            }
        }
    }
    
    Component {
        id: vector2Component
        
        RowLayout {
            spacing: 8
            
            Text {
                text: "X"
                color: textSecondary
                font.pixelSize: 12
            }
            
            TextField {
                id: v2x
                Layout.preferredWidth: 70
                text: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        return parts[0] || "0"
                    }
                    return "0"
                }
                validator: DoubleValidator { }
                
                onTextChanged: updateVector2()
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: v2x.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
            }
            
            Text {
                text: "Y"
                color: textSecondary
                font.pixelSize: 12
            }
            
            TextField {
                id: v2y
                Layout.preferredWidth: 70
                text: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        return parts[1] || "0"
                    }
                    return "0"
                }
                validator: DoubleValidator { }
                
                onTextChanged: updateVector2()
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: v2y.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
            }
            
            function updateVector2() {
                root.valueChanged(parameterEntry.name, "[" + v2x.text + " " + v2y.text + "]")
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    Component {
        id: vector3Component
        
        RowLayout {
            spacing: 8
            
            Text {
                text: "X"
                color: textSecondary
                font.pixelSize: 12
            }
            
            TextField {
                id: v3x
                Layout.preferredWidth: 60
                text: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        return parts[0] || "0"
                    }
                    return "0"
                }
                validator: DoubleValidator { }
                
                onTextChanged: updateVector3()
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: v3x.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
            }
            
            Text {
                text: "Y"
                color: textSecondary
                font.pixelSize: 12
            }
            
            TextField {
                id: v3y
                Layout.preferredWidth: 60
                text: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        return parts[1] || "0"
                    }
                    return "0"
                }
                validator: DoubleValidator { }
                
                onTextChanged: updateVector3()
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: v3y.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
            }
            
            Text {
                text: "Z"
                color: textSecondary
                font.pixelSize: 12
            }
            
            TextField {
                id: v3z
                Layout.preferredWidth: 60
                text: {
                    var val = parameterEntry.value
                    if (val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        return parts[2] || "0"
                    }
                    return "0"
                }
                validator: DoubleValidator { }
                
                onTextChanged: updateVector3()
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBackground
                    border.color: v3z.activeFocus ? accent : inputBorder
                    border.width: 1
                    radius: 3
                }
                
                color: textPrimary
                font.pixelSize: 13
                selectByMouse: true
            }
            
            function updateVector3() {
                root.valueChanged(parameterEntry.name, "[" + v3x.text + " " + v3y.text + " " + v3z.text + "]")
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    Component {
        id: transformComponent
        
        GridLayout {
            columns: 4
            rowSpacing: 6
            columnSpacing: 8
            
            Text { text: "Center"; color: textSecondary; font.pixelSize: 12 }
            TextField {
                id: centerX
                Layout.preferredWidth: 60
                text: "0.5"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: centerX.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            TextField {
                id: centerY
                Layout.preferredWidth: 60
                text: "0.5"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: centerY.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            Item { Layout.fillWidth: true }
            
            Text { text: "Scale"; color: textSecondary; font.pixelSize: 12 }
            TextField {
                id: scaleX
                Layout.preferredWidth: 60
                text: "1"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: scaleX.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            TextField {
                id: scaleY
                Layout.preferredWidth: 60
                text: "1"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: scaleY.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            Item { Layout.fillWidth: true }
            
            Text { text: "Rotate"; color: textSecondary; font.pixelSize: 12 }
            TextField {
                id: rotateField
                Layout.preferredWidth: 60
                text: "0"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: rotateField.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            Text { text: "deg"; color: textSecondary; font.pixelSize: 12 }
            Item { Layout.fillWidth: true }
            
            Text { text: "Translate"; color: textSecondary; font.pixelSize: 12 }
            TextField {
                id: translateX
                Layout.preferredWidth: 60
                text: "0"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: translateX.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            TextField {
                id: translateY
                Layout.preferredWidth: 60
                text: "0"
                validator: DoubleValidator { }
                onTextChanged: updateTransform()
                background: Rectangle { implicitHeight: 26; color: inputBackground; border.color: translateY.activeFocus ? accent : inputBorder; border.width: 1; radius: 3 }
                color: textPrimary; font.pixelSize: 12; selectByMouse: true
            }
            Item { Layout.fillWidth: true }
            
            function updateTransform() {
                var parts = []
                parts.push("center " + centerX.text + " " + centerY.text)
                parts.push("scale " + scaleX.text + " " + scaleY.text)
                parts.push("rotate " + rotateField.text)
                parts.push("translate " + translateX.text + " " + translateY.text)
                root.valueChanged(parameterEntry.name, "[" + parts.join(" ") + "]")
            }
        }
    }
    
    Component {
        id: textureComponent
        
        ColumnLayout {
            spacing: 4
            
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                
                // Texture preview thumbnail - clickable to open browser
                Rectangle {
                    id: texturePreviewRect
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    color: previewMouseArea.containsMouse ? hoverBackground : inputBackground
                    border.color: previewMouseArea.containsMouse ? accent : inputBorder
                    border.width: 1
                    radius: 3
                    
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                    
                    scale: previewMouseArea.pressed ? 0.95 : (previewMouseArea.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    
                    // Thumbnail source from texture provider
                    property string thumbnailSource: ""
                    
                    function updateThumbnail() {
                        if (parameterEntry.value && typeof textureProvider !== 'undefined' && typeof app !== 'undefined' && app.materials_root.length > 0) {
                            var result = textureProvider.get_thumbnail_for_texture(parameterEntry.value, app.materials_root)
                            if (result.length > 0) {
                                thumbnailSource = result
                            } else {
                                thumbnailSource = ""
                            }
                        } else {
                            thumbnailSource = ""
                        }
                    }
                    
                    Component.onCompleted: updateThumbnail()
                    
                    Connections {
                        target: parameterEntry
                        function onValueChanged() {
                            texturePreviewRect.updateThumbnail()
                        }
                    }
                    
                    Image {
                        id: texturePreviewImage
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        source: texturePreviewRect.thumbnailSource
                        
                        Text {
                            anchors.centerIn: parent
                            text: "?"
                            color: textSecondary
                            font.pixelSize: 16
                            visible: parent.status !== Image.Ready
                        }
                    }
                    
                    MouseArea {
                        id: previewMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            // Use the global texture browser from Main.qml
                            if (typeof globalTextureBrowser !== 'undefined') {
                                globalTextureBrowser.targetTextField = textureField
                                globalTextureBrowser.selectedTexture = ""
                                globalTextureBrowser.open()
                            }
                        }
                    }
                    
                    ToolTip {
                        visible: previewMouseArea.containsMouse
                        text: "Click to browse textures"
                        delay: 500
                    }
                }
                
                // Text field with ghost autocomplete
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    
                    // Background for the text field
                    Rectangle {
                        anchors.fill: parent
                        color: inputBackground
                        border.color: textureField.activeFocus ? accent : inputBorder
                        border.width: 1
                        radius: 3
                        
                        Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                    }
                    
                    // Ghost text (shown behind the input)
                    Text {
                        id: ghostText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        color: "#555555"
                        font.pixelSize: 13
                        text: {
                            if (!textureField.activeFocus || textureField.text.length < 1) return ""
                            var ghost = app.get_texture_ghost(textureField.text)
                            if (ghost.length > 0) {
                                return textureField.text + ghost
                            }
                            return ""
                        }
                        visible: ghostText.text.length > textureField.text.length
                    }
                    
                    TextField {
                        id: textureField
                        anchors.fill: parent
                        text: parameterEntry.value
                        placeholderText: "texture path (Tab to autocomplete)"
                        
                        property string lastGhost: ""
                        property bool suppressValueUpdate: false
                        
                        onTextChanged: {
                            // Only update ghost, not the actual value (to avoid loading partial textures)
                            if (activeFocus && !suppressValueUpdate) {
                                lastGhost = app.get_texture_ghost(text)
                                // Show autocomplete popup if we have suggestions
                                if (text.length >= 2) {
                                    autocompleteTimer.restart()
                                }
                            }
                        }
                        
                        // Commit value on focus loss or Enter
                        onEditingFinished: {
                            root.valueChanged(parameterEntry.name, text)
                        }
                        
                        onActiveFocusChanged: {
                            if (activeFocus) {
                                lastGhost = app.get_texture_ghost(text)
                            } else {
                                autocompletePopup.close()
                                // Commit the value when losing focus
                                root.valueChanged(parameterEntry.name, text)
                            }
                        }
                        
                        Keys.onTabPressed: function(event) {
                            // Accept ghost completion
                            if (lastGhost.length > 0) {
                                suppressValueUpdate = true
                                text = text + lastGhost
                                cursorPosition = text.length
                                suppressValueUpdate = false
                                lastGhost = app.get_texture_ghost(text)
                                event.accepted = true
                            }
                        }
                        
                        Keys.onDownPressed: {
                            if (autocompletePopup.visible && autocompleteList.count > 0) {
                                autocompleteList.currentIndex = Math.min(autocompleteList.currentIndex + 1, autocompleteList.count - 1)
                            }
                        }
                        
                        Keys.onUpPressed: {
                            if (autocompletePopup.visible && autocompleteList.count > 0) {
                                autocompleteList.currentIndex = Math.max(autocompleteList.currentIndex - 1, 0)
                            }
                        }
                        
                        Keys.onReturnPressed: {
                            if (autocompletePopup.visible && autocompleteList.currentIndex >= 0) {
                                text = autocompleteList.model[autocompleteList.currentIndex]
                                autocompletePopup.close()
                                // Commit the selected value
                                root.valueChanged(parameterEntry.name, text)
                            }
                        }
                        
                        Keys.onEscapePressed: {
                            autocompletePopup.close()
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            border.color: "transparent"
                        }
                        
                        color: textPrimary
                        font.pixelSize: 13
                        selectByMouse: true
                        selectionColor: accent
                        
                        Timer {
                            id: autocompleteTimer
                            interval: 150
                            onTriggered: {
                                if (textureField.text.length >= 2) {
                                    var completions = app.get_texture_completions(textureField.text, 10)
                                    if (completions.length > 0) {
                                        autocompleteList.model = completions
                                        autocompleteList.currentIndex = 0
                                        autocompletePopup.open()
                                    } else {
                                        autocompletePopup.close()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Autocomplete dropdown popup
                    Popup {
                        id: autocompletePopup
                        y: parent.height + 2
                        width: parent.width
                        height: Math.min(autocompleteList.contentHeight + 8, 200)
                        padding: 4
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        
                        background: Rectangle {
                            color: panelBackground
                            border.color: inputBorder
                            border.width: 1
                            radius: 3
                        }
                        
                        ListView {
                            id: autocompleteList
                            anchors.fill: parent
                            clip: true
                            currentIndex: 0
                            
                            delegate: Rectangle {
                                width: autocompleteList.width
                                height: 24
                                color: index === autocompleteList.currentIndex ? hoverBackground : "transparent"
                                
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                    color: textPrimary
                                    font.pixelSize: 12
                                    elide: Text.ElideMiddle
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: autocompleteList.currentIndex = index
                                    onClicked: {
                                        textureField.text = modelData
                                        autocompletePopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Browse button
                Button {
                    id: browseBtn
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    text: "..."
                    
                    onClicked: {
                        // Use the global texture browser from Main.qml
                        if (typeof globalTextureBrowser !== 'undefined') {
                            globalTextureBrowser.targetTextField = textureField
                            globalTextureBrowser.selectedTexture = ""
                            globalTextureBrowser.open()
                        }
                    }
                    
                    background: Rectangle {
                        color: browseBtn.pressed ? hoverBackground : (browseBtn.hovered ? "#363636" : inputBackground)
                        border.color: browseBtn.hovered ? accent : inputBorder
                        border.width: 1
                        radius: 3
                        
                        Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                        Behavior on border.color { ColorAnimation { duration: root.animDurationFast } }
                    }
                    
                    scale: browseBtn.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: root.animEasing } }
                    
                    contentItem: Text {
                        text: parent.text
                        color: textPrimary
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    
    Component {
        id: stringComponent
        
        TextField {
            id: stringField
            text: parameterEntry.value
            
            onTextChanged: {
                root.valueChanged(parameterEntry.name, text)
            }
            
            background: Rectangle {
                implicitHeight: 28
                color: inputBackground
                border.color: stringField.activeFocus ? accent : inputBorder
                border.width: 1
                radius: 3
            }
            
            color: textPrimary
            font.pixelSize: 13
            selectByMouse: true
            selectionColor: accent
        }
    }
}
