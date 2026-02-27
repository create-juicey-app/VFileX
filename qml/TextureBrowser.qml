import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0

Popup {
    id: textureBrowser
    
    required property var app
    required property var textureProvider
    required property var themeRoot
    
    property TextField targetTextField: null
    property string selectedTexture: ""
    property bool openMode: false
    
    signal textureSelected(string texturePath)
    signal textureOpened(string texturePath)
    
    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width - 40, 900)
    height: Math.min(parent.height - 40, 700)
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: if (selectedTexture) selectCurrentTexture()
    Keys.onEnterPressed: if (selectedTexture) selectCurrentTexture()
    
    function selectCurrentTexture() {
        if (openMode) {
            // Open mode: load in preview pane
            textureProvider.load_from_material_path(selectedTexture, app.materials_root)
            textureOpened(selectedTexture)
            close()
        } else if (targetTextField) {
            // Select mode: fill text field
            targetTextField.text = selectedTexture
            textureSelected(selectedTexture)
            close()
        }
    }
    
    // Smooth enter/exit animations
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: themeRoot.animDurationNormal; easing.type: themeRoot.animEasing }
            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: themeRoot.animDurationNormal; easing.type: themeRoot.animEasingBounce }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: themeRoot.animDurationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: themeRoot.animDurationFast; easing.type: Easing.InCubic }
        }
    }
    
    background: Rectangle {
        color: themeRoot.panelBg
        border.color: themeRoot.panelBorder
        border.width: 1
        radius: 8
    }
    
    // Store textures
    property var allTextures: []
    property var filteredTextures: []
    property string selectedCategory: "all"
    property var categories: ["all", "custom", "brick", "concrete", "metal", "wood", "glass", "nature", "decals", "models", "effects", "other"]
    property bool isLoading: false
    
    // Chunked loading properties
    property var _rawVpkList: []
    property var _rawCustomList: []
    property var _addedPaths: ({})
    property int _loadStep: 0 // 0: init, 1: vpk, 2: custom, 3: finish
    property int _loadIndex: 0
    property int _totalCount: 0
    
    onOpened: {
        isLoading = true
        allTextures = []
        filteredTextures = []
        textureGrid.model = []
        _loadStep = 0
        _loadIndex = 0
        _addedPaths = {}
        initLoadTimer.start()
        searchField.forceActiveFocus()
    }
    
    // Timer to allow the 'Loading' overlay to render before heavy lifting starts
    Timer {
        id: initLoadTimer
        interval: 50
        repeat: false
        onTriggered: {
            _rawVpkList = app.get_texture_completions("", -1)
            _rawCustomList = app.get_custom_textures(-1)
            _totalCount = _rawVpkList.length + _rawCustomList.length
            _loadStep = 1
            chunkLoadTimer.start()
        }
    }
    
    Timer {
        id: chunkLoadTimer
        interval: 1
        repeat: true
        onTriggered: {
            var chunkSize = 300
            var count = 0
            
            if (_loadStep === 1) {
                // Processing VPK textures
                while (count < chunkSize && _loadIndex < _rawVpkList.length) {
                    var path = _rawVpkList[_loadIndex]
                    var category = categorizeTexture(path)
                    allTextures.push({
                        path: path,
                        category: category,
                        isCustom: false
                    })
                    _addedPaths[path.toLowerCase()] = true
                    _loadIndex++
                    count++
                }
                
                if (_loadIndex >= _rawVpkList.length) {
                    _loadStep = 2
                    _loadIndex = 0
                }
            } else if (_loadStep === 2) {
                // Processing Custom textures
                while (count < chunkSize && _loadIndex < _rawCustomList.length) {
                    var customPath = _rawCustomList[_loadIndex]
                    if (!_addedPaths[customPath.toLowerCase()]) {
                        var customCategory = categorizeTexture(customPath)
                        allTextures.push({
                            path: customPath,
                            category: customCategory,
                            isCustom: true
                        })
                        _addedPaths[customPath.toLowerCase()] = true
                    }
                    _loadIndex++
                    count++
                }
                
                if (_loadIndex >= _rawCustomList.length) {
                    _loadStep = 3
                }
            }
            
            if (_loadStep === 3) {
                stop()
                isLoading = false
                filterTextures()
            }
        }
    }
    
    function loadTextures() {
        // Now handled by timers
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
            
            ThemedIcon {
                width: 20
                height: 20
                source: "qrc:/media/texture.svg"
                sourceSize: Qt.size(20, 20)
                themeRoot: textureBrowser.themeRoot
            }
            
            Text {
                text: textureBrowser.openMode ? "Texture Browser - Open" : "Texture Browser - Select"
                color: themeRoot.textColor
                font.pixelSize: 18
                font.bold: true
            }
            
            Item { Layout.fillWidth: true }
            
            // Search field
            Rectangle {
                Layout.preferredWidth: 300
                Layout.preferredHeight: 32
                color: themeRoot.inputBg
                border.color: searchField.activeFocus ? themeRoot.accent : themeRoot.inputBorder
                border.width: 1
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8
                    
                    ThemedIcon {
                        width: 14
                        height: 14
                        source: "qrc:/media/search.svg"
                        sourceSize: Qt.size(14, 14)
                        themeRoot: textureBrowser.themeRoot
                    }
                    
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search textures..."
                        activeFocusOnTab: true
                        
                        Keys.onDownPressed: textureGrid.forceActiveFocus()
                        Keys.onReturnPressed: textureGrid.forceActiveFocus()
                        Keys.onEnterPressed: textureGrid.forceActiveFocus()
                        
                        onTextChanged: {
                            searchTimer.restart()
                        }
                        
                        Timer {
                            id: searchTimer
                            interval: 200
                            onTriggered: textureBrowser.filterTextures()
                        }
                        
                        background: Rectangle { color: "transparent" }
                        color: themeRoot.textColor
                        font.pixelSize: 13
                    }
                    
                    // Clear button
                    ThemedIcon {
                        width: 10
                        height: 10
                        source: "qrc:/media/close.svg"
                        sourceSize: Qt.size(10, 10)
                        themeRoot: textureBrowser.themeRoot
                        visible: searchField.text.length > 0
                        opacity: clearSearchMouse.containsMouse ? 1.0 : 0.6
                        
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
                id: closeBrowserBtn
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 4
                color: closeBrowserMouse.containsMouse ? themeRoot.dangerColor : themeRoot.inputBg
                
                // Smooth hover animation
                scale: closeBrowserMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                
                ThemedIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "qrc:/media/close.svg"
                    sourceSize: Qt.size(14, 14)
                    themeRoot: textureBrowser.themeRoot
                }
                
                MouseArea {
                    id: closeBrowserMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: textureBrowser.close()
                }
            }
        }
        
        // Category tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Repeater {
                model: textureBrowser.categories
                
                Rectangle {
                    id: categoryRect
                    width: categoryText.implicitWidth + 16
                    height: 28
                    radius: 4
                    color: textureBrowser.selectedCategory === modelData ? themeRoot.accent : (categoryMouse.containsMouse ? themeRoot.buttonHover : themeRoot.buttonBg)
                    border.color: textureBrowser.selectedCategory === modelData ? themeRoot.accent : themeRoot.inputBorder
                    border.width: 1
                    
                    // Smooth hover animations (scale down on press only)
                    scale: categoryMouse.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                    Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                    
                    Text {
                        id: categoryText
                        anchors.centerIn: parent
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        color: themeRoot.textColor
                        font.pixelSize: 11
                        font.bold: textureBrowser.selectedCategory === modelData
                    }
                    
                    MouseArea {
                        id: categoryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            textureBrowser.selectedCategory = modelData
                            textureBrowser.filterTextures()
                        }
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Results count
            Text {
                text: textureGrid.count + " textures"
                color: themeRoot.textDim
                font.pixelSize: 11
            }
        }
        
        // Selected texture info bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: textureBrowser.selectedTexture ? 40 : 0
            color: themeRoot.inputBg
            border.color: themeRoot.accent
            border.width: 1
            radius: 4
            visible: textureBrowser.selectedTexture !== ""
            clip: true
            
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                Text {
                    text: "Selected:"
                    color: themeRoot.textDim
                    font.pixelSize: 12
                }
                
                Text {
                    Layout.fillWidth: true
                    text: textureBrowser.selectedTexture
                    color: themeRoot.textColor
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                
                Rectangle {
                    width: copyBtn.implicitWidth + 28
                    height: 24
                    radius: 3
                    color: copyMouse.containsMouse ? themeRoot.accentHover : themeRoot.accent
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        ThemedIcon { width: 14; height: 14; source: "qrc:/media/clipboard.svg"; sourceSize: Qt.size(14, 14); themeRoot: textureBrowser.themeRoot }
                        Text {
                            id: copyBtn
                            text: "Copy"
                            color: "white"
                            font.pixelSize: 11
                        }
                    }
                    
                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // TODO: Copy to clipboard (implement in Rust)
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
                    focus: true
                    activeFocusOnTab: true
                    keyNavigationEnabled: true
                    highlightMoveDuration: 100
                    
                    // Sync keyboard navigation with selectedTexture
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < model.length) {
                            textureBrowser.selectedTexture = model[currentIndex].path
                        }
                    }
                    
                    Keys.onReturnPressed: if (textureBrowser.selectedTexture) textureBrowser.selectCurrentTexture()
                    Keys.onEnterPressed: if (textureBrowser.selectedTexture) textureBrowser.selectCurrentTexture()
                    
                    highlight: Rectangle {
                        color: "transparent"
                        border.color: themeRoot.accent
                        border.width: 2
                        radius: 6
                    }
                    highlightFollowsCurrentItem: true
                    
                    delegate: Rectangle {
                        id: gridItemRect
                        required property int index
                        required property var modelData
                        width: 115
                        height: 135
                        color: gridItemMouse.containsMouse ? themeRoot.buttonHover : "transparent"
                        border.color: textureBrowser.selectedTexture === modelData.path ? themeRoot.accent : (gridItemMouse.containsMouse ? themeRoot.accent : "transparent")
                        border.width: textureBrowser.selectedTexture === modelData.path ? 2 : 1
                        radius: 6
                        
                        // Smooth hover animations (no scale up)
                        Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                        Behavior on border.color { ColorAnimation { duration: themeRoot.animDurationFast } }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4
                            
                            // Texture preview
                            Rectangle {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 100
                                Layout.alignment: Qt.AlignHCenter
                                color: themeRoot.inputBg
                                border.color: themeRoot.inputBorder
                                border.width: 1
                                radius: 4
                                
                                // Thumbnail loading with delay to avoid spamming
                                property string thumbnailSource: ""
                                property bool thumbnailRequested: false
                                
                                Timer {
                                    id: thumbnailTimer
                                    interval: 50 + Math.random() * 100  // Stagger requests
                                    onTriggered: {
                                        if (!parent.thumbnailRequested && textureBrowser.app.materials_root.length > 0) {
                                            parent.thumbnailRequested = true
                                            var result = textureBrowser.textureProvider.get_thumbnail_for_texture(gridItemRect.modelData.path, textureBrowser.app.materials_root)
                                            // Only set source if result is a valid file:// URL
                                            if (result && result.length > 0 && result.toString().startsWith("file://")) {
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
                                    source: parent.thumbnailSource && parent.thumbnailSource.startsWith("file://") ? parent.thumbnailSource : ""
                                    asynchronous: true
                                    cache: true
                                    
                                    // Smooth fade-in when loaded
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: themeRoot.animDurationNormal; easing.type: themeRoot.animEasing } }
                                    
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
                                                ctx.strokeStyle = themeRoot.inputBorder
                                                ctx.lineWidth = 2
                                                ctx.beginPath()
                                                ctx.arc(width/2, height/2, 9, 0, Math.PI * 2)
                                                ctx.stroke()
                                                ctx.strokeStyle = themeRoot.accent
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
                                                ctx.strokeStyle = themeRoot.inputBorder
                                                ctx.lineWidth = 2
                                                ctx.beginPath()
                                                ctx.arc(width/2, height/2, 9, 0, Math.PI * 2)
                                                ctx.stroke()
                                                ctx.strokeStyle = themeRoot.accent
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
                                        color: themeRoot.textDim
                                        font.pixelSize: 24
                                        visible: gridThumbnailImage.status === Image.Error || gridThumbnailImage.status === Image.Null
                                    }
                                }
                                
                                // Custom texture badge
                                Rectangle {
                                    visible: gridItemRect.modelData.isCustom === true
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: themeRoot.success
                                    border.color: Qt.darker(themeRoot.success, 1.3)
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
                                    var parts = gridItemRect.modelData.path.split("/")
                                    return parts[parts.length - 1]
                                }
                                color: themeRoot.textColor
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
                                textureGrid.currentIndex = gridItemRect.index
                                textureBrowser.selectedTexture = gridItemRect.modelData.path
                            }
                            
                            onDoubleClicked: {
                                textureGrid.currentIndex = gridItemRect.index
                                textureBrowser.selectedTexture = gridItemRect.modelData.path
                                if (textureBrowser.openMode) {
                                    // Open mode: load in preview pane
                                    textureBrowser.textureProvider.load_from_material_path(gridItemRect.modelData.path, textureBrowser.app.materials_root)
                                    textureBrowser.textureOpened(gridItemRect.modelData.path)
                                } else if (textureBrowser.targetTextField) {
                                    // Select mode: fill text field
                                    textureBrowser.targetTextField.text = gridItemRect.modelData.path
                                    textureBrowser.textureSelected(gridItemRect.modelData.path)
                                }
                                textureBrowser.close()
                            }
                        }
                        
                        ToolTip {
                            visible: gridItemMouse.containsMouse
                            text: gridItemRect.modelData.path + (textureBrowser.openMode ? "\nDouble-click to open" : "\nDouble-click to select")
                            delay: 500
                        }
                    }
                }
            }
            
            // Loading overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.7)
                visible: textureBrowser.isLoading
                radius: 8
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 60; height: 60
                        color: "transparent"
                        
                        ThemedIcon {
                            anchors.fill: parent
                            source: "qrc:/media/refresh.svg"
                            sourceSize: Qt.size(60, 60)
                            themeRoot: textureBrowser.themeRoot
                            
                            RotationAnimation on rotation {
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: textureBrowser.isLoading
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Indexing Textures..."
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (textureBrowser._totalCount === 0) return "Scanning..."
                                var current = (textureBrowser._loadStep === 1) ? textureBrowser._loadIndex : (textureBrowser._rawVpkList.length + textureBrowser._loadIndex)
                                return current + " / " + textureBrowser._totalCount
                            }
                            color: Qt.rgba(1, 1, 1, 0.7)
                            font.pixelSize: 13
                        }
                    }
                }
                
                // Block clicks while loading
                MouseArea { anchors.fill: parent; preventStealing: true }
            }
        }
        
        // Footer with actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: {
                    if (textureBrowser.selectedTexture) {
                        return textureBrowser.openMode 
                            ? "Double-click or press Open to view texture" 
                            : "Double-click or press Select to use texture"
                    }
                    return textureBrowser.openMode 
                        ? "Click a texture to select, double-click to open" 
                        : "Click a texture to select, double-click to use"
                }
                color: themeRoot.textDim
                font.pixelSize: 11
            }
            
            Item { Layout.fillWidth: true }
            
            Rectangle {
                id: cancelBtn
                width: 90
                height: 32
                radius: 4
                color: cancelMouse.containsMouse || cancelBtn.activeFocus ? themeRoot.buttonHover : themeRoot.buttonBg
                border.color: cancelBtn.activeFocus ? themeRoot.accent : "transparent"
                border.width: 1
                
                activeFocusOnTab: true
                Keys.onReturnPressed: textureBrowser.close()
                Keys.onEnterPressed: textureBrowser.close()
                Keys.onSpacePressed: textureBrowser.close()
                
                // Smooth hover animation
                scale: cancelMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: themeRoot.textColor
                    font.pixelSize: 13
                }
                
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: textureBrowser.close()
                }
            }
            
            Rectangle {
                id: selectBtn
                width: 90
                height: 32
                radius: 4
                color: selectMouse.containsMouse || selectBtn.activeFocus ? themeRoot.accentHover : themeRoot.accent
                border.color: selectBtn.activeFocus ? themeRoot.textBright : "transparent"
                border.width: 1
                opacity: textureBrowser.selectedTexture ? 1.0 : 0.5
                
                activeFocusOnTab: true
                Keys.onReturnPressed: if (textureBrowser.selectedTexture) textureBrowser.selectCurrentTexture()
                Keys.onEnterPressed: if (textureBrowser.selectedTexture) textureBrowser.selectCurrentTexture()
                Keys.onSpacePressed: if (textureBrowser.selectedTexture) textureBrowser.selectCurrentTexture()
                
                // Smooth hover animation (scale down on press only)
                scale: selectMouse.pressed && textureBrowser.selectedTexture ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                
                Text {
                    anchors.centerIn: parent
                    text: textureBrowser.openMode ? "Open" : "Select"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }
                
                MouseArea {
                    id: selectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: textureBrowser.selectedTexture ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: textureBrowser.selectedTexture !== ""
                    onClicked: textureBrowser.selectCurrentTexture()
                }
            }
        }
    }
}
