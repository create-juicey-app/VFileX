import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    property var textureProvider
    property real zoom: 1.0
    property real minZoom: 0.1
    property real maxZoom: 10.0
    property int previewVersion: 0  // Increment to force image reload
    
    // Animation settings (matching Main.qml)
    readonly property int animDurationFast: 120
    readonly property int animDurationNormal: 200
    readonly property int animDurationSlow: 300
    
    // Note: Zoom is intentionally not animated - changes are applied instantly
    
    // Colors
    readonly property color textColor: "#e0e0e0"
    readonly property color textDim: "#888888"
    readonly property color panelBg: "#252526"
    readonly property color buttonBg: "#3c3c3c"
    readonly property color buttonHover: "#4a4a4a"
    readonly property color accent: "#0e639c"
    
    // Color picker state
    property bool showColorPicker: false
    property int pickedPixelX: 0
    property int pickedPixelY: 0
    property color pickedColor: "transparent"
    property point colorPickerPos: Qt.point(0, 0)
    
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
    
    // fuck this too
    function localPathToUrl(path) {
        var pathStr = path.toString()
        // Remove any existing file:// prefix first
        if (pathStr.startsWith("file:///")) {
            pathStr = urlToLocalPath(pathStr)
        } else if (pathStr.startsWith("file://")) {
            pathStr = pathStr.substring(7)
        }
        // Add file:// prefix back properly
        if (pathStr.length >= 2 && pathStr[1] === ':') {
            // Windows path: C:/... -> file:///C:/...
            return "file:///" + pathStr
        } else if (pathStr.startsWith("/")) {
            // Unix path: /home/... -> file:///home/...
            return "file://" + pathStr
        }
        return "file:///" + pathStr
    }
    
    // Debounce timer for mipmap/frame changes
    Timer {
        id: refreshDebounce
        interval: 50
        onTriggered: root.previewVersion++
    }
    
    // Connect to texture provider signals
    Connections {
        target: textureProvider
        function onTexture_loaded() { 
            root.previewVersion++
            root.resetZoom()
        }
        function onFrame_changed() {
            refreshDebounce.restart()
        }
        function onMipmap_changed() {
            refreshDebounce.restart()
        }
    }
    
    // Simple zoom - just change the zoom property
    function zoomIn() { 
        zoom = Math.min(zoom * 1.25, maxZoom)
    }
    function zoomOut() { 
        zoom = Math.max(zoom / 1.25, minZoom)
    }
    function resetZoom() { 
        imageArea.animatePan = true
        zoom = 1.0
        imageArea.panX = 0
        imageArea.panY = 0
        // Disable pan animation after a short delay
        panAnimDisableTimer.restart()
    }
    function fitToView() {
        if (!textureProvider || !textureProvider.is_loaded) return
        imageArea.animatePan = true
        var scaleX = imageArea.width / textureProvider.texture_width
        var scaleY = imageArea.height / textureProvider.texture_height
        zoom = Math.min(scaleX, scaleY, 1.0)
        imageArea.panX = 0
        imageArea.panY = 0
        panAnimDisableTimer.restart()
    }
    
    // Timer to disable pan animation after programmatic reset
    Timer {
        id: panAnimDisableTimer
        interval: 250
        onTriggered: imageArea.animatePan = false
    }
    
    // Checkerboard background
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var size = 12
            ctx.fillStyle = "#1a1a1a"
            ctx.fillRect(0, 0, width, height)
            ctx.fillStyle = "#242424"
            for (var y = 0; y < height; y += size * 2) {
                for (var x = 0; x < width; x += size * 2) {
                    ctx.fillRect(x, y, size, size)
                    ctx.fillRect(x + size, y + size, size, size)
                }
            }
        }
    }
    
    // Image area - simple ScrollView approach
    Item {
        id: imageArea
        anchors.fill: parent
        anchors.topMargin: 56
        anchors.bottomMargin: 36
        clip: true
        
        // Panning state with smooth animation
        property real panX: 0
        property real panY: 0
        
        // Smooth pan reset animation (only for programmatic resets)
        property bool animatePan: false
        Behavior on panX { 
            enabled: imageArea.animatePan
            NumberAnimation { duration: root.animDurationNormal; easing.type: Easing.OutCubic } 
        }
        Behavior on panY { 
            enabled: imageArea.animatePan
            NumberAnimation { duration: root.animDurationNormal; easing.type: Easing.OutCubic } 
        }
        
        Image {
            id: previewImage
            
            // Size based on zoom
            width: sourceSize.width * root.zoom
            height: sourceSize.height * root.zoom
            
            // Center in view, offset by pan
            x: (imageArea.width - width) / 2 - imageArea.panX
            y: (imageArea.height - height) / 2 - imageArea.panY
            
            fillMode: Image.PreserveAspectFit
            smooth: root.zoom < 2
            mipmap: root.zoom < 1
            visible: textureProvider && textureProvider.is_loaded
            cache: false
            
            // Smooth fade-in when image loads
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.animDurationNormal; easing.type: Easing.OutCubic } }
            
            source: {
                if (textureProvider && textureProvider.is_loaded && root.previewVersion >= 0) {
                    var path = textureProvider.get_preview_path()
                    if (path) {
                        // Convert to proper file URL for the platform
                        var cleanPath = root.urlToLocalPath(path)
                        return root.localPathToUrl(cleanPath) + "?v=" + root.previewVersion
                    }
                }
                return ""
            }
        }
        
        MouseArea {
            id: imageMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            
            property bool panning: false
            property bool rightPressed: false
            property real lastX: 0
            property real lastY: 0
            
            // Scroll wheel zoom
            onWheel: function(wheel) {
                var factor = wheel.angleDelta.y > 0 ? 1.2 : 0.833
                var oldZoom = root.zoom
                var newZoom = Math.max(root.minZoom, Math.min(root.maxZoom, root.zoom * factor))
                
                if (newZoom !== oldZoom) {
                    // Zoom toward mouse position
                    var scale = newZoom / oldZoom
                    
                    // Mouse position relative to image center
                    var imgCenterX = imageArea.width / 2 - imageArea.panX
                    var imgCenterY = imageArea.height / 2 - imageArea.panY
                    var dx = wheel.x - imgCenterX
                    var dy = wheel.y - imgCenterY
                    
                    // Adjust pan to zoom toward cursor
                    imageArea.panX += dx * (scale - 1)
                    imageArea.panY += dy * (scale - 1)
                    
                    root.zoom = newZoom
                }
            }
            
            onPressed: function(mouse) {
                if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                    panning = true
                    lastX = mouse.x
                    lastY = mouse.y
                } else if (mouse.button === Qt.RightButton) {
                    rightPressed = true
                    updateColorPicker(mouse.x, mouse.y)
                }
            }
            
            onReleased: function(mouse) {
                if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                    panning = false
                } else if (mouse.button === Qt.RightButton) {
                    rightPressed = false
                    root.showColorPicker = false
                }
            }
            
            onPositionChanged: function(mouse) {
                if (panning) {
                    imageArea.panX -= (mouse.x - lastX)
                    imageArea.panY -= (mouse.y - lastY)
                    lastX = mouse.x
                    lastY = mouse.y
                }
                if (rightPressed) {
                    updateColorPicker(mouse.x, mouse.y)
                }
            }
            
            function updateColorPicker(mouseX, mouseY) {
                if (!previewImage.visible) return
                
                var relX = mouseX - previewImage.x
                var relY = mouseY - previewImage.y
                
                if (relX >= 0 && relY >= 0 && relX < previewImage.width && relY < previewImage.height) {
                    root.pickedPixelX = Math.floor(relX / root.zoom)
                    root.pickedPixelY = Math.floor(relY / root.zoom)
                    root.colorPickerPos = Qt.point(mouseX, mouseY + 56)
                    root.showColorPicker = true
                }
            }
        }
        
        // Invisible canvas for grabbing pixel colors
        Canvas {
            id: colorGrabber
            visible: false
            width: previewImage.sourceSize.width > 0 ? previewImage.sourceSize.width : 1
            height: previewImage.sourceSize.height > 0 ? previewImage.sourceSize.height : 1
            
            property var imageSource: previewImage.source
            
            onImageSourceChanged: {
                if (imageSource !== "") {
                    loadImage(imageSource)
                }
            }
            
            onImageLoaded: {
                requestPaint()
            }
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (isImageLoaded(previewImage.source)) {
                    ctx.drawImage(previewImage.source, 0, 0)
                }
            }
            
            function getPixelColor(x, y) {
                var ctx = getContext("2d")
                if (!ctx) return Qt.rgba(0, 0, 0, 1)
                try {
                    var imgData = ctx.getImageData(x, y, 1, 1)
                    if (imgData && imgData.data) {
                        return Qt.rgba(imgData.data[0]/255, imgData.data[1]/255, imgData.data[2]/255, imgData.data[3]/255)
                    }
                } catch (e) {}
                return Qt.rgba(0, 0, 0, 1)
            }
        }
    }
    
    // Color Picker Tooltip
    Rectangle {
        id: colorPickerTooltip
        visible: root.showColorPicker
        x: Math.min(Math.max(root.colorPickerPos.x + 12, 5), root.width - width - 5)
        y: Math.min(Math.max(root.colorPickerPos.y + 12, 5), root.height - height - 5)
        width: 140
        height: 72
        color: "#1e1e1e"
        border.color: "#555"
        border.width: 1
        radius: 6
        z: 100
        
        // Smooth appear/disappear animation
        opacity: root.showColorPicker ? 1 : 0
        scale: root.showColorPicker ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            // Color swatch
            Rectangle {
                width: 40
                height: 40
                radius: 4
                
                // Checkerboard for alpha
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var size = 5
                        ctx.fillStyle = "#444"
                        ctx.fillRect(0, 0, width, height)
                        ctx.fillStyle = "#666"
                        for (var yy = 0; yy < height; yy += size * 2) {
                            for (var xx = 0; xx < width; xx += size * 2) {
                                ctx.fillRect(xx, yy, size, size)
                                ctx.fillRect(xx + size, yy + size, size, size)
                            }
                        }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: colorGrabber.getPixelColor(root.pickedPixelX, root.pickedPixelY)
                    border.color: "#666"
                    border.width: 1
                }
            }
            
            // Info column
            Column {
                spacing: 2
                Layout.fillWidth: true
                
                Text {
                    text: root.pickedPixelX + ", " + root.pickedPixelY
                    color: root.textDim
                    font.pixelSize: 10
                    font.family: "monospace"
                }
                
                Text {
                    property color c: colorGrabber.getPixelColor(root.pickedPixelX, root.pickedPixelY)
                    text: Math.round(c.r * 255) + " " + Math.round(c.g * 255) + " " + Math.round(c.b * 255)
                    color: root.textColor
                    font.pixelSize: 11
                    font.family: "monospace"
                }
                
                Text {
                    property color c: colorGrabber.getPixelColor(root.pickedPixelX, root.pickedPixelY)
                    property string hex: "#" + Math.round(c.r * 255).toString(16).padStart(2, '0') + Math.round(c.g * 255).toString(16).padStart(2, '0') + Math.round(c.b * 255).toString(16).padStart(2, '0')
                    text: hex.toUpperCase()
                    color: root.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "monospace"
                }
            }
        }
    }
    
    // TOP TOOLBAR
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        color: root.panelBg
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8
            
            // LEFT SIDE: Texture info
            Text {
                text: textureProvider && textureProvider.is_loaded ?
                      textureProvider.texture_width + " × " + textureProvider.texture_height : "No texture"
                color: root.textColor
                font.pixelSize: 13
                font.family: "monospace"
            }
            
            // Format badge
            Rectangle {
                visible: textureProvider && textureProvider.is_loaded
                color: "#3c3c3c"
                radius: 4
                width: formatText.width + 12
                height: 22
                
                Text {
                    id: formatText
                    anchors.centerIn: parent
                    text: textureProvider ? textureProvider.format_name : ""
                    color: root.textColor
                    font.pixelSize: 11
                    font.family: "monospace"
                }
            }
            
            // Mipmap selector
            RowLayout {
                visible: textureProvider && textureProvider.mipmap_count > 1
                spacing: 4
                
                Text {
                    text: "Mip:"
                    color: root.textDim
                    font.pixelSize: 11
                }
                
                Rectangle {
                    id: mipDownBtn
                    width: 28
                    height: 24
                    radius: 4
                    color: mipDownMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: mipDownMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: root.textColor
                        font.pixelSize: 10
                    }
                    
                    MouseArea {
                        id: mipDownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (textureProvider && textureProvider.current_mipmap > 0) {
                                textureProvider.set_mipmap(textureProvider.current_mipmap - 1)
                            }
                        }
                    }
                }
                
                Text {
                    text: (textureProvider ? (textureProvider.current_mipmap + 1) : 0) + "/" + (textureProvider ? textureProvider.mipmap_count : 0)
                    color: root.textColor
                    font.pixelSize: 11
                    font.family: "monospace"
                }
                
                Rectangle {
                    id: mipUpBtn
                    width: 28
                    height: 24
                    radius: 4
                    color: mipUpMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: mipUpMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: root.textColor
                        font.pixelSize: 10
                    }
                    
                    MouseArea {
                        id: mipUpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (textureProvider && textureProvider.current_mipmap < textureProvider.mipmap_count - 1) {
                                textureProvider.set_mipmap(textureProvider.current_mipmap + 1)
                            }
                        }
                    }
                }
            }
            
            // SPACER - pushes everything after to the right
            Item { Layout.fillWidth: true }
            
            // RIGHT SIDE: ZOOM CONTROLS
            RowLayout {
                spacing: 4
                
                // Zoom Out Button
                Rectangle {
                    id: zoomOutBtn
                    width: 32
                    height: 28
                    radius: 4
                    color: zoomOutMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: zoomOutMouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        color: root.textColor
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: zoomOutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.zoomOut()
                    }
                }
                
                // Zoom Percentage
                Rectangle {
                    id: zoomResetBtn
                    width: 60
                    height: 28
                    radius: 4
                    color: zoomResetMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: zoomResetMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.zoom * 100) + "%"
                        color: root.textColor
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                    
                    MouseArea {
                        id: zoomResetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetZoom()
                    }
                }
                
                // Zoom In Button
                Rectangle {
                    id: zoomInBtn
                    width: 32
                    height: 28
                    radius: 4
                    color: zoomInMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    // Smooth hover animation
                    scale: zoomInMouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animDurationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.animDurationFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: root.textColor
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: zoomInMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.zoomIn()
                    }
                }
                
                // Separator
                Rectangle { width: 1; height: 20; color: "#4a4a4a" }
                
                // Fit Button
                Rectangle {
                    width: 32
                    height: 28
                    radius: 4
                    color: fitMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⊡"
                        color: root.textColor
                        font.pixelSize: 16
                    }
                    
                    MouseArea {
                        id: fitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fitToView()
                    }
                }
                
                // 1:1 Button
                Rectangle {
                    width: 36
                    height: 28
                    radius: 4
                    color: actualMouse.containsMouse ? root.buttonHover : root.buttonBg
                    
                    Text {
                        anchors.centerIn: parent
                        text: "1:1"
                        color: root.textColor
                        font.pixelSize: 11
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: actualMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetZoom()
                    }
                }
            }
        }
    }
    
    // BOTTOM INFO BAR
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        color: root.panelBg
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16
            
            // File name
            Text {
                visible: textureProvider && textureProvider.current_texture !== ""
                text: {
                    if (textureProvider && textureProvider.current_texture) {
                        var path = textureProvider.current_texture.toString()
                        return path.split('/').pop() || ""
                    }
                    return ""
                }
                color: root.textColor
                font.pixelSize: 11
                elide: Text.ElideMiddle
                Layout.maximumWidth: 200
            }
            
            // Separator
            Rectangle {
                visible: textureProvider && textureProvider.is_loaded
                width: 1
                height: 16
                color: "#4a4a4a"
            }
            
            // Mipmap info
            Text {
                visible: textureProvider && textureProvider.mipmap_count > 1
                text: "Mip " + (textureProvider ? (textureProvider.current_mipmap + 1) + "/" + textureProvider.mipmap_count : "")
                color: root.textDim
                font.pixelSize: 11
            }
            
            // Alpha badge
            Rectangle {
                visible: textureProvider && textureProvider.has_alpha
                color: "#2d4a2d"
                radius: 3
                width: alphaText.width + 8
                height: 18
                
                Text {
                    id: alphaText
                    anchors.centerIn: parent
                    text: "Alpha"
                    color: "#7cb87c"
                    font.pixelSize: 10
                }
            }
            
            // Animated badge
            Rectangle {
                visible: textureProvider && textureProvider.is_animated
                color: "#4a3d2d"
                radius: 3
                width: animText.width + 8
                height: 18
                
                Text {
                    id: animText
                    anchors.centerIn: parent
                    text: "Animated"
                    color: "#d4a857"
                    font.pixelSize: 10
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Color picker hint
            Text {
                text: "Right-click for color picker"
                color: root.textDim
                font.pixelSize: 10
                opacity: 0.6
            }
            
            // Zoom percentage
            Text {
                text: Math.round(root.zoom * 100) + "%"
                color: root.textDim
                font.pixelSize: 11
                font.family: "monospace"
            }
        }
    }
    
    // PLACEHOLDER when no texture
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: !textureProvider || !textureProvider.is_loaded
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "📷"
            font.pixelSize: 48
            opacity: 0.3
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No texture loaded"
            color: root.textDim
            font.pixelSize: 16
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Open a VMT file or drag & drop a VTF here"
            color: root.textDim
            font.pixelSize: 12
            opacity: 0.7
        }
    }
    
    // Drop area
    DropArea {
        anchors.fill: parent
        onDropped: function(drop) {
            if (drop.hasUrls) {
                var url = drop.urls[0].toString()
                if (url.endsWith(".vtf")) {
                    textureProvider.load_texture(root.urlToLocalPath(url))
                }
            }
        }
    }
}
