import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Dialog {
    id: root
    
    required property VFileXApp app
    required property var urlToLocalPath
    
    signal conversionComplete(int successCount, int totalCount)
    
    modal: true
    anchors.centerIn: parent
    width: 750
    height: 550
    padding: 0
    
    Overlay.modal: Rectangle { color: Theme.overlayBg }
    
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
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animDurationNormal; easing.type: Theme.animEasing }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.animDurationNormal; easing.type: Theme.animEasingBounce }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animDurationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: Theme.animDurationFast; easing.type: Easing.InCubic }
        }
    }
    
    background: Rectangle {
        color: Theme.panelBg
        border.color: Theme.panelBorder
        radius: 8
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
    
    contentItem: ColumnLayout {
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
                
                Image {
                    width: 18
                    height: 18
                    source: "qrc:/media/export.svg"
                    sourceSize: Qt.size(18, 18)
                }
                
                Text {
                    text: "Image to VTF Converter"
                    color: Theme.textColor
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: vtfCloseBtn.containsMouse ? Theme.buttonHover : "transparent"
                    
                    scale: vtfCloseBtn.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    
                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: "qrc:/media/close.svg"
                        sourceSize: Qt.size(12, 12)
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
                color: Theme.panelBorder
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
                            color: Theme.textDim
                            font.pixelSize: 10
                            font.bold: true
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: Theme.inputBg
                            border.color: Theme.inputBorder
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
                                    color: root.outputDirectory ? Theme.textColor : Theme.textDim
                                    font.pixelSize: 11
                                    elide: Text.ElideLeft
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                Image {
                                    width: 14
                                    height: 14
                                    source: "qrc:/media/folder.svg"
                                    sourceSize: Qt.size(14, 14)
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
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Text {
                            text: "RESIZE"
                            color: Theme.textDim
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
                                color: Theme.inputBg
                                border.color: Theme.inputBorder
                                radius: 4
                            }
                            
                            contentItem: Text {
                                leftPadding: 8
                                text: resizeModeCombo.displayText
                                color: Theme.textColor
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
                                color: Theme.textColor
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                validator: IntValidator { bottom: 1; top: 4096 }
                                onTextChanged: {
                                    var val = parseInt(text)
                                    if (!isNaN(val) && val > 0) root.customWidth = val
                                }
                                background: Rectangle {
                                    implicitHeight: 26
                                    color: Theme.inputBg
                                    border.color: Theme.inputBorder
                                    radius: 4
                                }
                            }
                            
                            Image { width: 16; height: 16; source: "qrc:/media/multiply.svg"; sourceSize: Qt.size(14, 14) }
                            
                            TextField {
                                Layout.fillWidth: true
                                text: root.customHeight.toString()
                                color: Theme.textColor
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                validator: IntValidator { bottom: 1; top: 4096 }
                                onTextChanged: {
                                    var val = parseInt(text)
                                    if (!isNaN(val) && val > 0) root.customHeight = val
                                }
                                background: Rectangle {
                                    implicitHeight: 26
                                    color: Theme.inputBg
                                    border.color: Theme.inputBorder
                                    radius: 4
                                }
                            }
                        }
                    }
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Text {
                            text: "TEXTURE FLAGS"
                            color: Theme.textDim
                            font.pixelSize: 10
                            font.bold: true
                        }
                        
                        component VtfCheckBox: CheckBox {
                            id: vtfCheck
                            property string label: ""
                            
                            contentItem: Text {
                                leftPadding: vtfCheck.indicator.width + 6
                                text: vtfCheck.label
                                color: Theme.textColor
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            indicator: Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                x: vtfCheck.leftPadding
                                y: parent.height / 2 - height / 2
                                radius: 3
                                border.color: vtfCheck.checked ? Theme.accent : Theme.inputBorder
                                color: vtfCheck.checked ? Theme.accent : "transparent"
                                
                                Image {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    source: "qrc:/media/check.svg"
                                    sourceSize: Qt.size(10, 10)
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
                        color: Theme.textDim
                        font.pixelSize: 10
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        id: vtfAddBtn
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 26
                        color: vtfAddBtnMouse.containsMouse ? Theme.accentHover : Theme.accent
                        radius: 4
                        
                        scale: vtfAddBtnMouse.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Image { width: 12; height: 12; source: "qrc:/media/plus.svg"; sourceSize: Qt.size(12, 12) }
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
                        color: vtfClearBtnMouse.containsMouse ? "#c0392b" : "#e74c3c"
                        radius: 4
                        
                        scale: vtfClearBtnMouse.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        
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
                    color: Theme.inputBg
                    border.color: vtfDropArea.containsDrag ? Theme.accent : Theme.inputBorder
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
                        
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40; height: 40
                            source: "qrc:/media/image.svg"
                            sourceSize: Qt.size(40, 40)
                            opacity: 0.5
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Click to add images\nor drag & drop"
                            color: Theme.textDim
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "PNG, JPG, BMP, TGA, GIF"
                            color: Theme.textDim
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
                                    color: Theme.buttonBg
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
                                        color: Theme.textColor
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
                                            color: Theme.textDim
                                            font.pixelSize: 9
                                        }
                                        Image { width: 12; height: 12; source: "qrc:/media/multiply.svg"; sourceSize: Qt.size(12, 12) }
                                        Text {
                                            text: {
                                                if (parent.info.startsWith("ERR:")) return ""
                                                var parts = parent.info.split("|")
                                                return parts[1] + " px"
                                            }
                                            color: Theme.textDim
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: vtfRemoveBtn.containsMouse ? "#e74c3c" : "transparent"
                                    visible: vtfItemMouse.containsMouse
                                    
                                    Image {
                                        anchors.centerIn: parent
                                        width: 10; height: 10
                                        source: "qrc:/media/close.svg"
                                        sourceSize: Qt.size(10, 10)
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
                    color: Theme.inputBg
                    border.color: Theme.inputBorder
                    radius: 4
                    
                    Rectangle {
                        width: parent.width * (root.convertTotal > 0 ? root.convertProgress / root.convertTotal : 0)
                        height: parent.height
                        color: Theme.accent
                        radius: 4
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.convertProgress + " / " + root.convertTotal
                        color: Theme.textColor
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
                        color: vtfCancelBtnMouse.containsMouse ? Theme.buttonHover : Theme.buttonBg
                        radius: 4
                        
                        scale: vtfCancelBtnMouse.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        
                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.textColor; font.pixelSize: 13 }
                        
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
                        color: !btnEnabled ? Theme.buttonBg : (vtfConvertBtnMouse.containsMouse ? Theme.accentHover : Theme.accent)
                        radius: 4
                        opacity: btnEnabled ? 1.0 : 0.5
                        
                        scale: vtfConvertBtnMouse.pressed && btnEnabled ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Image { width: 14; height: 14; source: "qrc:/media/download.svg"; sourceSize: Qt.size(14, 14); visible: !root.isConverting }
                            Text { text: root.isConverting ? "Converting..." : "Convert to VTF"; color: "white"; font.pixelSize: 13; font.bold: true }
                        }
                        
                        MouseArea {
                            id: vtfConvertBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: vtfConvertBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: vtfConvertBtn.btnEnabled
                            
                            onClicked: {
                                // Urgent care is such a dying art~
                                root.isConverting = true
                                root.convertProgress = 0
                                root.convertTotal = root.selectedImages.length
                                var baseDir = (root.outputDirectory && root.outputDirectory.length > 0) ? root.outputDirectory : root.app.materials_root
                                if (!baseDir || baseDir.length === 0) {
                                    // No output directory available, cancel conversion
                                    root.isConverting = false
                                    return
                                }
                                // Ensure we're writing into a materials folder
                                baseDir = baseDir.replace(/[\\\/]+$/, "")
                                var lower = baseDir.toLowerCase()
                                if (!lower.endsWith("/materials") && !lower.endsWith("\\materials")) {
                                    baseDir = baseDir + "/materials"
                                }
                                // Create directory if backend supports it (best-effort)
                                if (root.app.mkdir) root.app.mkdir(baseDir)
                                else if (root.app.create_directory) root.app.create_directory(baseDir)
                                else if (root.app.create_dir) root.app.create_dir(baseDir)
                                else if (root.app.create_folder) root.app.create_folder(baseDir)
                                var successCount = 0
                                // I broke that yesterday lmaoo
                                if (root.app.batch_import_images_to_vtf) {
                                    var result = root.app.batch_import_images_to_vtf(root.selectedImages, baseDir, root.generateMipmaps, root.isNormalMap, root.clampTexture, root.noLod, root.resizeMode, root.customWidth, root.customHeight)
                                    successCount = result
                                    root.convertProgress = root.selectedImages.length
                                } else {
                                    // If batch call isn't available (older backends), fall back
                                    for (var i = 0; i < root.selectedImages.length; i++) {
                                        var inputPath = root.selectedImages[i]
                                        var fileName = inputPath.split("/").pop().split("\\").pop()
                                        var baseName = fileName.replace(/\.[^/.]+$/, "")
                                        var outputPath = baseDir + "/" + baseName + ".vtf"
                                        var res = root.app.import_image_to_vtf(
                                            inputPath, outputPath,
                                            root.generateMipmaps, root.isNormalMap,
                                            root.clampTexture, root.noLod,
                                            root.resizeMode, root.customWidth, root.customHeight
                                        )
                                        if (!res.startsWith("ERR:")) successCount++
                                        root.convertProgress = i + 1
                                    }
                                }
                                root.isConverting = false
                                root.conversionComplete(successCount, root.selectedImages.length)
                                if (successCount === root.selectedImages.length) {
                                    root.selectedImages = []
                                }
                                var successCount = 0
                                for (var i = 0; i < root.selectedImages.length; i++) {
                                    var inputPath = root.selectedImages[i]
                                    var fileName = inputPath.split("/").pop().split("\\").pop()
                                    var baseName = fileName.replace(/\.[^/.]+$/, "")
                            
                                    // Determine base output directory: user-selected or app's default materials root
                                    var baseDir = (root.outputDirectory && root.outputDirectory.length > 0) ? root.outputDirectory : root.app.materials_root
                                    if (!baseDir) baseDir = root.outputDirectory // fallback to whatever is set
                            
                                    // Normalize and ensure we output into a "materials" subfolder
                                    baseDir = baseDir.replace(/[\\\/]+$/, "") // remove trailing slash
                                    var lower = baseDir.toLowerCase()
                                    if (!lower.endsWith("/materials") && !lower.endsWith("\\materials")) {
                                        baseDir = baseDir + "/materials"
                                    }
                            
                                    // Try to create the materials dir if the app exposes a helper
                                    if (root.app.mkdir) root.app.mkdir(baseDir)
                                    else if (root.app.create_directory) root.app.create_directory(baseDir)
                                    else if (root.app.create_dir) root.app.create_dir(baseDir)
                                    else if (root.app.create_folder) root.app.create_folder(baseDir)
                            
                                    var outputPath = baseDir + "/" + baseName + ".vtf"
                            
                                    var result = root.app.import_image_to_vtf(
                                        inputPath, outputPath, 
                                        root.generateMipmaps, root.isNormalMap,
                                        root.clampTexture, root.noLod,
                                        root.resizeMode, root.customWidth, root.customHeight
                                    )
                            
                                    if (!result.startsWith("ERR:")) successCount++
                                    root.convertProgress = i + 1
                                }
                            
                                root.isConverting = false
                                root.conversionComplete(successCount, root.selectedImages.length)
                            
                                if (successCount === root.selectedImages.length) {
                                    root.selectedImages = []
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    onOpened: {
        if (outputDirectory.length === 0 && app.materials_root.length > 0) {
            outputDirectory = app.materials_root
        }
    }
}
