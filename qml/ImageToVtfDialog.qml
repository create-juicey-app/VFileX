import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import com.VFileX 1.0

Dialog {
    id: root
    
    required property VFileXApp app
    required property var urlToLocalPath
    required property var themeRoot
    
    signal conversionComplete(int successCount, int totalCount)
    
    modal: true
    anchors.centerIn: parent
    width: 750
    height: 550
    padding: 0
    
    Overlay.modal: Rectangle { color: themeRoot.overlayBg }
    
    property var selectedImages: []
    property string outputDirectory: ""
    property bool generateMipmaps: true
    property bool isNormalMap: false
    property bool isConverting: false
    property int convertProgress: 0
    property int convertTotal: 0
    
    property bool clampTexture: false
    property bool noLod: false
    property bool pointSample: false
    property bool trilinear: false
    property bool noCompression: false
    property bool alphaTest: false
    property int resizeMode: 0
    property int customWidth: 512
    property int customHeight: 512
    
    Keys.onEscapePressed: close()
    
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
    
    background: Rectangle {
        color: themeRoot.dialogBg
        border.color: themeRoot.dialogBorder
        radius: themeRoot.dialogRadius
    }
    
    header: Item { height: 0 }
    footer: Item { height: 0 }
    
    // File dialog for adding images
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
            root.selectedImages = root.selectedImages.concat(paths)
        }
    }
    
    Timer {
        id: conversionTimer
        interval: 10
        repeat: true
        running: false
        
        property int successCount: 0
        property string baseDir: ""
        
        onTriggered: {
            if (root.convertProgress >= root.selectedImages.length) {
                stop()
                root.isConverting = false
                root.conversionComplete(successCount, root.selectedImages.length)
                if (successCount === root.selectedImages.length) {
                    root.selectedImages = []
                }
                return
            }
            
            var inputPath = root.selectedImages[root.convertProgress]
            var fileName = inputPath.split("/").pop().split("\\").pop()
            var baseName = fileName.replace(/\.[^/.]+$/, "")
            var outputPath = baseDir + "/" + baseName + ".vtf"
            
            var res = root.app.import_image_to_vtf(
                inputPath, outputPath,
                root.generateMipmaps, root.isNormalMap,
                root.clampTexture, root.noLod,
                root.resizeMode, root.customWidth, root.customHeight
            )
            
            if (!res.startsWith("ERR:")) {
                successCount++
            }
            
            root.convertProgress++
        }
    }
    
    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8
                    
                    ThemedIcon {
                        width: 18
                        height: 18
                        source: "qrc:/media/export.svg"
                        sourceSize: Qt.size(18, 18)
                        themeRoot: root.themeRoot
                    }
                    
                    Text {
                        text: "Image to VTF Converter"
                        color: themeRoot.textColor
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: vtfCloseBtn.containsMouse ? themeRoot.buttonHover : "transparent"
                        
                        scale: vtfCloseBtn.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                        Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                        
                        ThemedIcon {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            source: "qrc:/media/close.svg"
                            sourceSize: Qt.size(12, 12)
                            themeRoot: root.themeRoot
                        }
                        
                        MouseArea {
                            id: vtfCloseBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: themeRoot.panelBorder
                }
            }
            
            // Main content
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                spacing: 16
                
                // LEFT - Options
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.15)
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text {
                                text: "OUTPUT FOLDER"
                                color: themeRoot.textDim
                                font.pixelSize: 10
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                color: themeRoot.inputBg
                                border.color: themeRoot.inputBorder
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (!root.outputDirectory) return "Select folder..."
                                            var parts = root.outputDirectory.split("/")
                                            return ".../" + parts.slice(-2).join("/")
                                        }
                                        color: root.outputDirectory ? themeRoot.textColor : themeRoot.textDim
                                        font.pixelSize: 11
                                        elide: Text.ElideLeft
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    ThemedIcon {
                                        width: 14
                                        height: 14
                                        source: "qrc:/media/folder.svg"
                                        sourceSize: Qt.size(14, 14)
                                        themeRoot: root.themeRoot
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var path = root.app.browse_folder_native("Select Output Folder")
                                        if (path.length > 0) {
                                            root.outputDirectory = path
                                        }
                                    }
                                }
                            }
                        }
                        
                        Rectangle { Layout.fillWidth: true; height: 1; color: themeRoot.panelBorder }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            
                            Text {
                                text: "RESIZE"
                                color: themeRoot.textDim
                                font.pixelSize: 10
                                font.bold: true
                            }
                            
                            ComboBox {
                                id: resizeModeCombo
                                Layout.fillWidth: true
                                model: ["Auto (Power of 2)", "Keep Original", "Custom Size"]
                                currentIndex: root.resizeMode
                                onCurrentIndexChanged: root.resizeMode = currentIndex
                                
                                background: Rectangle {
                                    implicitHeight: 28
                                    color: themeRoot.inputBg
                                    border.color: themeRoot.inputBorder
                                    radius: 4
                                }
                                
                                contentItem: Text {
                                    leftPadding: 8
                                    text: resizeModeCombo.displayText
                                    color: themeRoot.textColor
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                visible: root.resizeMode === 2
                                spacing: 8
                                
                                TextField {
                                    Layout.fillWidth: true
                                    text: root.customWidth.toString()
                                    color: themeRoot.textColor
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 4096 }
                                    onTextChanged: {
                                        var val = parseInt(text)
                                        if (!isNaN(val) && val > 0) root.customWidth = val
                                    }
                                    background: Rectangle {
                                        implicitHeight: 26
                                        color: themeRoot.inputBg
                                        border.color: themeRoot.inputBorder
                                        radius: 4
                                    }
                                }
                                
                                ThemedIcon { width: 16; height: 16; source: "qrc:/media/multiply.svg"; sourceSize: Qt.size(14, 14); themeRoot: root.themeRoot }
                                
                                TextField {
                                    Layout.fillWidth: true
                                    text: root.customHeight.toString()
                                    color: themeRoot.textColor
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 4096 }
                                    onTextChanged: {
                                        var val = parseInt(text)
                                        if (!isNaN(val) && val > 0) root.customHeight = val
                                    }
                                    background: Rectangle {
                                        implicitHeight: 26
                                        color: themeRoot.inputBg
                                        border.color: themeRoot.inputBorder
                                        radius: 4
                                    }
                                }
                            }
                        }
                        
                        Rectangle { Layout.fillWidth: true; height: 1; color: themeRoot.panelBorder }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            
                            Text {
                                text: "TEXTURE FLAGS"
                                color: themeRoot.textDim
                                font.pixelSize: 10
                                font.bold: true
                            }
                            
                            component VtfCheckBox: CheckBox {
                                id: vtfCheck
                                property string label: ""
                                
                                contentItem: Text {
                                    leftPadding: vtfCheck.indicator.width + 6
                                    text: vtfCheck.label
                                    color: themeRoot.textColor
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                indicator: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: vtfCheck.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    border.color: vtfCheck.checked ? themeRoot.accent : themeRoot.inputBorder
                                    color: vtfCheck.checked ? themeRoot.accent : "transparent"
                                    
                                    ThemedIcon {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        source: "qrc:/media/check.svg"
                                        sourceSize: Qt.size(10, 10)
                                        themeRoot: root.themeRoot
                                        visible: vtfCheck.checked
                                    }
                                }
                            }
                            
                            VtfCheckBox { label: "Generate Mipmaps"; checked: root.generateMipmaps; onCheckedChanged: root.generateMipmaps = checked }
                            VtfCheckBox { label: "Normal Map"; checked: root.isNormalMap; onCheckedChanged: root.isNormalMap = checked }
                            VtfCheckBox { label: "Clamp (No Tiling)"; checked: root.clampTexture; onCheckedChanged: root.clampTexture = checked }
                            VtfCheckBox { label: "No LOD"; checked: root.noLod; onCheckedChanged: root.noLod = checked }
                            VtfCheckBox { label: "Point Sample"; checked: root.pointSample; onCheckedChanged: root.pointSample = checked }
                            VtfCheckBox { label: "Trilinear"; checked: root.trilinear; onCheckedChanged: root.trilinear = checked }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
                
                // RIGHT - File list
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: "IMAGES (" + root.selectedImages.length + ")"
                            color: themeRoot.textDim
                            font.pixelSize: 10
                            font.bold: true
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            id: vtfAddBtn
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 26
                            color: vtfAddBtnMouse.containsMouse ? themeRoot.accentHover : themeRoot.accent
                            radius: 4
                            
                            scale: vtfAddBtnMouse.pressed ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                            Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                ThemedIcon { width: 12; height: 12; source: "qrc:/media/plus.svg"; sourceSize: Qt.size(12, 12); themeRoot: root.themeRoot }
                                Text { text: "Add"; color: "white"; font.pixelSize: 11; font.bold: true }
                            }
                            
                            MouseArea {
                                id: vtfAddBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addImageDialog.open()
                            }
                        }
                        
                        Rectangle {
                            id: vtfClearBtn
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 26
                            visible: root.selectedImages.length > 0
                            color: vtfClearBtnMouse.containsMouse ? themeRoot.dangerHover : themeRoot.dangerColor
                            radius: 4
                            
                            scale: vtfClearBtnMouse.pressed ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                            Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                            
                            Text { anchors.centerIn: parent; text: "Clear"; color: "white"; font.pixelSize: 11; font.bold: true }
                            
                            MouseArea {
                                id: vtfClearBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedImages = []
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: themeRoot.inputBg
                        border.color: vtfDropArea.containsDrag ? themeRoot.accent : themeRoot.inputBorder
                        border.width: vtfDropArea.containsDrag ? 2 : 1
                        radius: 6
                        
                        MouseArea {
                            anchors.fill: parent
                            visible: root.selectedImages.length === 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addImageDialog.open()
                        }
                        
                        DropArea {
                            id: vtfDropArea
                            anchors.fill: parent
                            keys: ["text/uri-list"]
                            
                            onDropped: (drop) => {
                                var paths = []
                                for (var i = 0; i < drop.urls.length; i++) {
                                    var path = root.urlToLocalPath(drop.urls[i])
                                    var lower = path.toLowerCase()
                                    if (lower.endsWith(".png") || lower.endsWith(".jpg") || 
                                        lower.endsWith(".jpeg") || lower.endsWith(".bmp") ||
                                        lower.endsWith(".tga") || lower.endsWith(".gif")) {
                                        paths.push(path)
                                    }
                                }
                                if (paths.length > 0) {
                                    root.selectedImages = root.selectedImages.concat(paths)
                                }
                            }
                        }
                        
                        Column {
                            anchors.centerIn: parent
                            visible: root.selectedImages.length === 0
                            spacing: 12
                            
                            ThemedIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 40; height: 40
                                source: "qrc:/media/image.svg"
                                sourceSize: Qt.size(40, 40)
                                themeRoot: root.themeRoot
                                opacity: 0.5
                            }
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Click to add images\nor drag & drop"
                                color: themeRoot.textDim
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "PNG, JPG, BMP, TGA, GIF"
                                color: themeRoot.textDim
                                font.pixelSize: 10
                                opacity: 0.7
                            }
                        }
                        
                        ListView {
                            id: vtfImageList
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true
                            visible: root.selectedImages.length > 0
                            model: root.selectedImages
                            spacing: 2
                            
                            delegate: Rectangle {
                                width: vtfImageList.width
                                height: 36
                                color: vtfItemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                                radius: 4
                                
                                MouseArea { id: vtfItemMouse; anchors.fill: parent; hoverEnabled: true }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 8
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        color: themeRoot.buttonBg
                                        radius: 4
                                        
                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            source: "file://" + modelData
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.split("/").pop().split("\\").pop()
                                            color: themeRoot.textColor
                                            font.pixelSize: 11
                                            elide: Text.ElideMiddle
                                        }
                                        
                                        RowLayout {
                                            property string info: root.app.get_image_info(modelData)
                                            spacing: 4
                                            
                                            Text {
                                                text: {
                                                    if (parent.info.startsWith("ERR:")) return ""
                                                    var parts = parent.info.split("|")
                                                    return parts[0]
                                                }
                                                color: themeRoot.textDim
                                                font.pixelSize: 9
                                            }
                                            ThemedIcon { width: 12; height: 12; source: "qrc:/media/multiply.svg"; sourceSize: Qt.size(12, 12); themeRoot: root.themeRoot }
                                            Text {
                                                text: {
                                                    if (parent.info.startsWith("ERR:")) return ""
                                                    var parts = parent.info.split("|")
                                                    return parts[1] + " px"
                                                }
                                                color: themeRoot.textDim
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: vtfRemoveBtn.containsMouse ? themeRoot.dangerColor : "transparent"
                                        visible: vtfItemMouse.containsMouse
                                        
                                        ThemedIcon {
                                            anchors.centerIn: parent
                                            width: 10; height: 10
                                            source: "qrc:/media/close.svg"
                                            sourceSize: Qt.size(10, 10)
                                            themeRoot: root.themeRoot
                                        }
                                        
                                        MouseArea {
                                            id: vtfRemoveBtn
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var newList = root.selectedImages.slice()
                                                newList.splice(index, 1)
                                                root.selectedImages = newList
                                            }
                                        }
                                    }
                                }
                            }
                            
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        visible: root.isConverting
                        color: themeRoot.inputBg
                        border.color: themeRoot.inputBorder
                        radius: 4
                        
                        Rectangle {
                            width: parent.width * (root.convertTotal > 0 ? root.convertProgress / root.convertTotal : 0)
                            height: parent.height
                            color: themeRoot.accent
                            radius: 4
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.convertProgress + " / " + root.convertTotal
                            color: themeRoot.textColor
                            font.pixelSize: 10
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            id: vtfCancelBtn
                            width: 90
                            height: 32
                            color: vtfCancelBtnMouse.containsMouse ? themeRoot.buttonHover : themeRoot.buttonBg
                            radius: 4
                            
                            scale: vtfCancelBtnMouse.pressed ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                            Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                            
                            Text { anchors.centerIn: parent; text: "Cancel"; color: themeRoot.textColor; font.pixelSize: 13 }
                            
                            MouseArea {
                                id: vtfCancelBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                        
                        Rectangle {
                            id: vtfConvertBtn
                            width: 130
                            height: 32
                            property bool btnEnabled: root.selectedImages.length > 0 && (root.outputDirectory.length > 0 || root.app.materials_root.length > 0) && !root.isConverting
                            color: !btnEnabled ? themeRoot.buttonBg : (vtfConvertBtnMouse.containsMouse ? themeRoot.accentHover : themeRoot.accent)
                            radius: 4
                            opacity: btnEnabled ? 1.0 : 0.5
                            
                            scale: vtfConvertBtnMouse.pressed && btnEnabled ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: themeRoot.animDurationFast; easing.type: themeRoot.animEasing } }
                            Behavior on color { ColorAnimation { duration: themeRoot.animDurationFast } }
                            Behavior on opacity { NumberAnimation { duration: themeRoot.animDurationFast } }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                ThemedIcon { width: 14; height: 14; source: "qrc:/media/download.svg"; sourceSize: Qt.size(14, 14); themeRoot: root.themeRoot; visible: !root.isConverting }
                                Text { text: root.isConverting ? "Converting..." : "Convert to VTF"; color: "white"; font.pixelSize: 13; font.bold: true }
                            }
                            
                            MouseArea {
                                id: vtfConvertBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: vtfConvertBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: vtfConvertBtn.btnEnabled
                                
                                onClicked: {
                                    root.convertProgress = 0
                                    root.convertTotal = root.selectedImages.length
                                    var baseDir = (root.outputDirectory && root.outputDirectory.length > 0) ? root.outputDirectory : root.app.materials_root
                                    
                                    if (!baseDir || baseDir.length === 0) {
                                        return
                                    }
                                    
                                    // Normalize and ensure materials subfolder
                                    baseDir = baseDir.replace(/[\\\/]+$/, "")
                                    var lower = baseDir.toLowerCase()
                                    if (!lower.endsWith("/materials") && !lower.endsWith("\\materials")) {
                                        baseDir = baseDir + "/materials"
                                    }
                                    
                                    // Try to create directory
                                    if (root.app.mkdir) root.app.mkdir(baseDir)
                                    else if (root.app.create_directory) root.app.create_directory(baseDir)
                                    
                                    conversionTimer.baseDir = baseDir
                                    conversionTimer.successCount = 0
                                    root.isConverting = true
                                    conversionTimer.start()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Loading Overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
            visible: root.isConverting
            radius: themeRoot.dialogRadius
            
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
                        themeRoot: root.themeRoot
                        
                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.isConverting
                        }
                    }
                }
                
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Converting Images..."
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.convertProgress + " / " + root.convertTotal
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 13
                    }
                }
            }
            
            // Block clicks while converting
            MouseArea { anchors.fill: parent; preventStealing: true }
        }
    }
    
    onOpened: {
        if (outputDirectory.length === 0 && app.materials_root.length > 0) {
            outputDirectory = app.materials_root
        }
    }
}
