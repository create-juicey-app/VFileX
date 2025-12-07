import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Rectangle {
    id: delegateRoot
    
    // Required properties from model
    required property int index
    required property string paramName
    required property string paramDisplayName
    required property string paramValue
    required property string paramDataType
    required property real paramMinValue
    required property real paramMaxValue
    required property string paramCategory
    
    // Function to initialize texture thumbnail - called from multiple places
    function tryLoadTextureThumbnail() {
        if (paramDataType && paramDataType.toLowerCase() === "texture" && paramValue && paramValue.length > 0) {
            if (textureControlRow && textureControlRow.visible && textureThumbnailRect) {
                var texPath = paramValue.replace(/\.vtf$/i, "")
                if (textureThumbnailRect.pendingTexture !== texPath || textureThumbnailRect.thumbnailSource.length === 0) {
                    textureThumbnailRect.pendingTexture = texPath
                    if (textureProvider && materialsRoot && materialsRoot.length > 0) {
                        textureThumbnailRect.thumbnailDebounce.restart()
                    }
                }
            }
        }
    }
    
    // Watch for paramValue changes from the model
    onParamValueChanged: Qt.callLater(tryLoadTextureThumbnail)
    
    // Watch for textureProvider becoming available
    onTextureProviderChanged: Qt.callLater(tryLoadTextureThumbnail)
    
    // Watch for materialsRoot becoming available
    onMaterialsRootChanged: Qt.callLater(tryLoadTextureThumbnail)
    
    // Required properties from parent
    required property real listWidth
    required property real scrollBarWidth
    required property bool isCollapsed
    required property var textureProvider
    required property string materialsRoot
    
    // Callback signals
    signal parameterChanged(string name, string value)
    signal openColorPicker(var targetField, color initialColor)
    signal openTextureBrowser(var targetField)
    signal loadTexturePreview(string texturePath)
    signal getThumbnail(string texturePath, var callback)
    
    // Local properties
    property string pName: paramName || ""
    property string pDisplayName: paramDisplayName || ""
    property string pValue: paramValue || ""
    property string pDataType: paramDataType || "string"
    property real pMinValue: paramMinValue || 0
    property real pMaxValue: paramMaxValue || 1
    
    // Theme colors (use Theme singleton)
    readonly property color panelBg: Theme.panelBg
    readonly property color panelBorder: Theme.panelBorder
    readonly property color inputBg: Theme.inputBg
    readonly property color inputBorder: Theme.inputBorder
    readonly property color textColor: Theme.textColor
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent
    readonly property color accentHover: Theme.accentHover
    readonly property int animDurationFast: Theme.animDurationFast
    readonly property int animDurationNormal: Theme.animDurationNormal
    readonly property int animEasing: Theme.animEasing
    readonly property int themeRadius: Theme.radius
    
    width: listWidth - 10 - scrollBarWidth
    height: isCollapsed ? 0 : paramContent.height + 16
    visible: !isCollapsed
    color: paramMouse.containsMouse ? "#2a2d2e" : "transparent"
    radius: themeRadius
    border.color: panelBorder
    border.width: visible ? 1 : 0
    clip: true
    
    Behavior on height { NumberAnimation { duration: animDurationNormal; easing.type: animEasing } }
    Behavior on color { ColorAnimation { duration: animDurationFast } }
    
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
        
        // Header row
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: delegateRoot.pDisplayName
                color: textColor
                font.pixelSize: 12
                font.bold: true
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: delegateRoot.pDataType
                color: textDim
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
                    delegateRoot.parameterChanged(delegateRoot.pName, checked ? "1" : "0")
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
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
            }
            
            contentItem: Text {
                text: boolSwitch.checked ? "On" : "Off"
                color: textDim
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
                        delegateRoot.parameterChanged(delegateRoot.pName, value.toString())
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBg
                    border.color: intSpinBox.activeFocus ? accent : inputBorder
                    radius: 4
                }
                
                contentItem: TextInput {
                    text: intSpinBox.textFromValue(intSpinBox.value, intSpinBox.locale)
                    font.pixelSize: 12
                    color: textColor
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
                        delegateRoot.parameterChanged(delegateRoot.pName, Math.round(value).toString())
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
                    color: inputBorder
                    
                    Rectangle {
                        width: intSlider.visualPosition * parent.width
                        height: parent.height
                        color: accent
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: intSlider.leftPadding + intSlider.visualPosition * (intSlider.availableWidth - width)
                    y: intSlider.topPadding + intSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: intSlider.pressed ? Qt.lighter(accent, 1.2) : accent
                    border.color: Qt.darker(accent, 1.2)
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
                        delegateRoot.parameterChanged(delegateRoot.pName, text)
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBg
                    border.color: floatField.activeFocus ? accent : inputBorder
                    radius: 4
                }
                
                color: textColor
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
                        delegateRoot.parameterChanged(delegateRoot.pName, value.toFixed(3))
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
                    color: inputBorder
                    
                    Rectangle {
                        width: floatSlider.visualPosition * parent.width
                        height: parent.height
                        color: accent
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: floatSlider.leftPadding + floatSlider.visualPosition * (floatSlider.availableWidth - width)
                    y: floatSlider.topPadding + floatSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: floatSlider.pressed ? Qt.lighter(accent, 1.2) : accent
                    border.color: Qt.darker(accent, 1.2)
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
                border.color: inputBorder
                border.width: 1
                
                function parseColorValue(val) {
                    if (val && val.length > 2 && val.charAt(0) === '[') {
                        var parts = val.slice(1, -1).split(/\s+/)
                        if (parts.length >= 3) {
                            var r = parseFloat(parts[0])
                            var g = parseFloat(parts[1])
                            var b = parseFloat(parts[2])
                            if (r <= 1 && g <= 1 && b <= 1 && r >= 0 && g >= 0 && b >= 0) {
                                if (r % 1 !== 0 || g % 1 !== 0 || b % 1 !== 0 || (r <= 1 && g <= 1 && b <= 1)) {
                                    return Qt.rgba(r, g, b, 1.0)
                                }
                            }
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
                        delegateRoot.openColorPicker(colorTextField, colorPreview.color)
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
                        delegateRoot.parameterChanged(delegateRoot.pName, text)
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBg
                    border.color: colorTextField.activeFocus ? accent : inputBorder
                    radius: 4
                }
                
                color: textColor
                font.pixelSize: 12
                selectByMouse: true
            }
        }
        
        // Texture control
        RowLayout {
            id: textureControlRow
            visible: delegateRoot.pDataType.toLowerCase() === "texture"
            Layout.fillWidth: true
            spacing: 8
            
            // Trigger thumbnail load when this row becomes visible
            onVisibleChanged: {
                if (visible) {
                    delegateRoot.tryLoadTextureThumbnail()
                }
            }
            
            Rectangle {
                id: textureThumbnailRect
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                color: inputBg
                border.color: inputBorder
                radius: 4
                clip: true
                
                property string pendingTexture: ""
                property string thumbnailSource: ""
                property alias thumbnailDebounce: thumbnailDebounce
                
                function updateThumbnail(texturePath) {
                    var texPath = (texturePath || "").replace(/\.vtf$/i, "")
                    if (texPath !== pendingTexture || thumbnailSource === "") {
                        pendingTexture = texPath
                        thumbnailSource = ""
                        thumbnailDebounce.restart()
                    }
                }
                
                Timer {
                    id: thumbnailDebounce
                    interval: 150
                    onTriggered: {
                        if (textureThumbnailRect.pendingTexture.length > 0 && delegateRoot.textureProvider && delegateRoot.materialsRoot && delegateRoot.materialsRoot.length > 0) {
                            var result = delegateRoot.textureProvider.get_thumbnail_for_texture(textureThumbnailRect.pendingTexture, delegateRoot.materialsRoot)
                            if (result && result.toString().length > 0 && result.toString().startsWith("file://")) {
                                textureThumbnailRect.thumbnailSource = result.toString()
                            } else {
                                textureThumbnailRect.thumbnailSource = ""
                            }
                        } else {
                            textureThumbnailRect.thumbnailSource = ""
                        }
                    }
                }
                
                Component.onCompleted: {
                    // Delay thumbnail load to allow all bindings to complete
                    Qt.callLater(function() {
                        delegateRoot.tryLoadTextureThumbnail()
                    })
                }
                
                Image {
                    id: textureThumbnail
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    source: textureThumbnailRect.thumbnailSource && textureThumbnailRect.thumbnailSource.startsWith("file://") ? textureThumbnailRect.thumbnailSource : ""
                    
                    Item {
                        id: loadingSpinner
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        visible: thumbnailDebounce.running || textureThumbnail.status === Image.Loading
                        
                        Canvas {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            property real angle: 0
                            NumberAnimation on angle { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: loadingSpinner.visible }
                            onAngleChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.strokeStyle = accent
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
                    
                    Text {
                        anchors.centerIn: parent
                        text: textureThumbnail.status === Image.Error ? "!" : "?"
                        color: textureThumbnail.status === Image.Error ? "#ff6b6b" : textDim
                        font.pixelSize: 14
                        visible: !loadingSpinner.visible && textureThumbnail.status !== Image.Ready
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: delegateRoot.openTextureBrowser(textureField)
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
                        delegateRoot.parameterChanged(delegateRoot.pName, text)
                        if (delegateRoot.pName.toLowerCase() === "$basetexture") {
                            delegateRoot.loadTexturePreview(text)
                        }
                        textureThumbnailRect.updateThumbnail(text)
                    }
                }
                
                background: Rectangle {
                    implicitHeight: 28
                    color: inputBg
                    border.color: textureField.activeFocus ? accent : inputBorder
                    radius: 4
                }
                
                color: textColor
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
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: inputBg
                radius: 4
                border.color: inputBorder
                
                Canvas {
                    anchors.fill: parent
                    anchors.margins: 4
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = panelBorder
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 4; i++) {
                            var x = i * width / 4
                            var y = i * height / 4
                            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                        }
                    }
                }
                
                Rectangle {
                    width: 8; height: 8; radius: 4; color: accent
                    x: parent.width / 2 + (parent.parent.vec2Values[0] * parent.width / 4) - 4
                    y: parent.height / 2 - (parent.parent.vec2Values[1] * parent.height / 4) - 4
                }
                
                property var vec2Values: parent.vec2Values
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text { text: "X"; color: textDim; font.pixelSize: 11 }
                TextField {
                    id: vec2X
                    Layout.fillWidth: true
                    text: parent.parent.vec2Values[0].toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onTextChanged: {
                        if (parent.parent.visible && acceptableInput) {
                            delegateRoot.parameterChanged(delegateRoot.pName, "[" + text + " " + vec2Y.text + "]")
                        }
                    }
                    background: Rectangle { implicitHeight: 24; color: inputBg; border.color: vec2X.activeFocus ? accent : inputBorder; radius: 4 }
                    color: textColor; font.pixelSize: 11
                }
                
                Text { text: "Y"; color: textDim; font.pixelSize: 11 }
                TextField {
                    id: vec2Y
                    Layout.fillWidth: true
                    text: parent.parent.vec2Values[1].toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onTextChanged: {
                        if (parent.parent.visible && acceptableInput) {
                            delegateRoot.parameterChanged(delegateRoot.pName, "[" + vec2X.text + " " + text + "]")
                        }
                    }
                    background: Rectangle { implicitHeight: 24; color: inputBg; border.color: vec2Y.activeFocus ? accent : inputBorder; radius: 4 }
                    color: textColor; font.pixelSize: 11
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
                            delegateRoot.parameterChanged(delegateRoot.pName, "[" + text + " " + vec3Y.text + " " + vec3Z.text + "]")
                        }
                    }
                    background: Rectangle { implicitHeight: 24; color: inputBg; border.color: vec3X.activeFocus ? "#e74c3c" : inputBorder; radius: 4 }
                    color: textColor; font.pixelSize: 11
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
                            delegateRoot.parameterChanged(delegateRoot.pName, "[" + vec3X.text + " " + text + " " + vec3Z.text + "]")
                        }
                    }
                    background: Rectangle { implicitHeight: 24; color: inputBg; border.color: vec3Y.activeFocus ? "#2ecc71" : inputBorder; radius: 4 }
                    color: textColor; font.pixelSize: 11
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
                            delegateRoot.parameterChanged(delegateRoot.pName, "[" + vec3X.text + " " + vec3Y.text + " " + text + "]")
                        }
                    }
                    background: Rectangle { implicitHeight: 24; color: inputBg; border.color: vec3Z.activeFocus ? "#3498db" : inputBorder; radius: 4 }
                    color: textColor; font.pixelSize: 11
                }
            }
        }
        
        // Transform control
        ColumnLayout {
            visible: delegateRoot.pDataType.toLowerCase() === "transform"
            Layout.fillWidth: true
            spacing: 6
            
            property var transformValues: {
                var val = delegateRoot.pValue || ""
                var result = { centerX: 0.5, centerY: 0.5, scaleX: 1, scaleY: 1, rotate: 0, translateX: 0, translateY: 0 }
                var centerMatch = val.match(/center\s+([\d.-]+)\s+([\d.-]+)/)
                if (centerMatch) { result.centerX = parseFloat(centerMatch[1]); result.centerY = parseFloat(centerMatch[2]) }
                var scaleMatch = val.match(/scale\s+([\d.-]+)\s+([\d.-]+)/)
                if (scaleMatch) { result.scaleX = parseFloat(scaleMatch[1]); result.scaleY = parseFloat(scaleMatch[2]) }
                var rotateMatch = val.match(/rotate\s+([\d.-]+)/)
                if (rotateMatch) { result.rotate = parseFloat(rotateMatch[1]) }
                var translateMatch = val.match(/translate\s+([\d.-]+)\s+([\d.-]+)/)
                if (translateMatch) { result.translateX = parseFloat(translateMatch[1]); result.translateY = parseFloat(translateMatch[2]) }
                return result
            }
            
            function buildTransformString() {
                return "center " + transformValues.centerX + " " + transformValues.centerY + 
                       " scale " + transformValues.scaleX + " " + transformValues.scaleY +
                       " rotate " + transformValues.rotate +
                       " translate " + transformValues.translateX + " " + transformValues.translateY
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: inputBg
                radius: 4
                border.color: inputBorder
                clip: true
                
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = panelBorder
                        ctx.lineWidth = 1
                        for (var i = 0; i <= 8; i++) {
                            var x = i * width / 8; var y = i * height / 8
                            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                        }
                    }
                }
                
                Rectangle {
                    width: 40 * parent.parent.transformValues.scaleX
                    height: 40 * parent.parent.transformValues.scaleY
                    x: parent.width * parent.parent.transformValues.centerX + parent.parent.transformValues.translateX * 40 - width/2
                    y: parent.height * parent.parent.transformValues.centerY + parent.parent.transformValues.translateY * 40 - height/2
                    color: Qt.rgba(accent.r, accent.g, accent.b, 0.5)
                    border.color: accent
                    border.width: 2
                    rotation: parent.parent.transformValues.rotate
                    Rectangle { width: 6; height: 6; radius: 3; color: "#ff6b6b"; anchors.centerIn: parent }
                }
            }
            
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 4
                columnSpacing: 4
                
                Text { text: "Scale"; color: textDim; font.pixelSize: 10 }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.scaleX.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.scaleX = parseFloat(text) || 1; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.scaleY.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.scaleY = parseFloat(text) || 1; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                Item { width: 1 }
                
                Text { text: "Rotate"; color: textDim; font.pixelSize: 10 }
                TextField {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    text: parent.parent.transformValues.rotate.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.rotate = parseFloat(text) || 0; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                Text { text: "°"; color: textDim; font.pixelSize: 10 }
                
                Text { text: "Translate"; color: textDim; font.pixelSize: 10 }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.translateX.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.translateX = parseFloat(text) || 0; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.translateY.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.translateY = parseFloat(text) || 0; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                Item { width: 1 }
                
                Text { text: "Center"; color: textDim; font.pixelSize: 10 }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.centerX.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.centerX = parseFloat(text) || 0.5; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                TextField {
                    Layout.fillWidth: true
                    text: parent.parent.transformValues.centerY.toString()
                    validator: DoubleValidator {}
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onEditingFinished: { parent.parent.transformValues.centerY = parseFloat(text) || 0.5; delegateRoot.parameterChanged(delegateRoot.pName, parent.parent.buildTransformString()) }
                    background: Rectangle { implicitHeight: 22; color: inputBg; border.color: inputBorder; radius: 3 }
                    color: textColor
                    font.pixelSize: 10
                }
                Item { width: 1 }
            }
            
            TextField {
                Layout.fillWidth: true
                text: delegateRoot.pValue
                placeholderText: "center .5 .5 scale 1 1 rotate 0 translate 0 0"
                inputMethodHints: Qt.ImhNoPredictiveText
                onTextChanged: {
                    if (parent.visible && activeFocus) {
                        delegateRoot.parameterChanged(delegateRoot.pName, text)
                    }
                }
                background: Rectangle { implicitHeight: 24; color: inputBg; border.color: activeFocus ? accent : inputBorder; radius: 4 }
                color: textColor; font.pixelSize: 10; font.family: "monospace"
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
                    delegateRoot.parameterChanged(delegateRoot.pName, text)
                }
            }
            
            background: Rectangle {
                implicitHeight: 28
                color: inputBg
                border.color: stringField.activeFocus ? accent : inputBorder
                radius: 4
            }
            
            color: textColor
            font.pixelSize: 12
            selectByMouse: true
        }
    }
}
