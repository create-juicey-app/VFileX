import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import com.VFileX 1.0
import "ThemeColors.js" as Theme

Dialog {
    id: root
    
    required property VFileXApp app
    
    signal gameSelected(string gameName, string gamePath)
    signal skipped()
    
    modal: true
    anchors.centerIn: parent
    width: 500
    padding: 0
    closePolicy: Popup.NoAutoClose
    
    Overlay.modal: Rectangle { color: Theme.overlayBg }
    
    Keys.onEscapePressed: if (!isLoadingVPKs && selectedIndex >= 0) close()
    Keys.onReturnPressed: if (!isLoadingVPKs && selectedIndex >= 0) doSelectGame()
    Keys.onEnterPressed: if (!isLoadingVPKs && selectedIndex >= 0) doSelectGame()
    Keys.onUpPressed: if (selectedIndex > 0) selectedIndex--
    Keys.onDownPressed: if (selectedIndex < detectedGames.length - 1) selectedIndex++
    
    function doSelectGame() {
        if (selectedIndex >= 0 && selectedIndex < detectedGames.length) {
            gameSelected(detectedGames[selectedIndex].name, detectedGames[selectedIndex].path)
        }
    }
    
    onOpened: gameListView.forceActiveFocus()
    
    // Smooth enter/exit animations
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animDurationSlow; easing.type: Theme.animEasing }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.animDurationSlow; easing.type: Theme.animEasingBounce }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animDurationNormal; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: Theme.animDurationNormal; easing.type: Easing.InCubic }
        }
    }
    
    property var detectedGames: []
    property int selectedIndex: -1
    property bool isLoadingVPKs: false
    property string loadingMessage: ""
    
    // Connect to VPK loading signals
    Connections {
        target: root.app
        function onVpk_loading_started() {
            root.isLoadingVPKs = true
            root.loadingMessage = "Loading game archives..."
        }
        function onVpk_loading_progress(message) {
            root.loadingMessage = message
        }
        function onVpk_loading_finished(count) {
            root.isLoadingVPKs = false
            root.loadingMessage = ""
            if (count > 0) {
                root.app.complete_first_run()
                root.close()
            }
        }
    }
    
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
        color: Theme.panelBg
        radius: 12
    }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.accent
            radius: 12
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: parent.color
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome to VFileX!"
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
                text: root.detectedGames.length > 0 
                    ? "We found these Source games installed. Select one to use its textures:"
                    : "No Source games detected. You can browse for a materials folder manually."
                font.pixelSize: 13
                color: Theme.textColor
                wrapMode: Text.WordWrap
            }
            
            // Game list
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: Theme.inputBg
                border.color: gameListView.activeFocus ? Theme.accent : Theme.inputBorder
                radius: 6
                visible: root.detectedGames.length > 0
                
                ListView {
                    id: gameListView
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: root.detectedGames
                    spacing: 4
                    focus: true
                    activeFocusOnTab: true
                    keyNavigationEnabled: true
                    currentIndex: root.selectedIndex
                    
                    Keys.onReturnPressed: root.doSelectGame()
                    Keys.onEnterPressed: root.doSelectGame()
                    Keys.onUpPressed: if (root.selectedIndex > 0) root.selectedIndex--
                    Keys.onDownPressed: if (root.selectedIndex < root.detectedGames.length - 1) root.selectedIndex++
                    
                    onCurrentIndexChanged: root.selectedIndex = currentIndex
                    
                    delegate: Rectangle {
                        id: gameItemRect
                        width: gameListView.width
                        height: 52
                        color: root.selectedIndex === index ? Theme.accent : 
                               (gameMouseArea.containsMouse ? Theme.buttonHover : "transparent")
                        radius: 6
                        
                        scale: gameMouseArea.pressed ? 0.97 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            
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
                                
                                Image {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    source: "qrc:/media/gamepad.svg"
                                    sourceSize: Qt.size(24, 24)
                                    visible: gameIcon.status !== Image.Ready
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: root.selectedIndex === index ? "white" : Theme.textColor
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.path
                                    font.pixelSize: 10
                                    color: root.selectedIndex === index ? Qt.rgba(1,1,1,0.7) : Theme.textDim
                                    elide: Text.ElideMiddle
                                }
                            }
                            
                            Image {
                                Layout.alignment: Qt.AlignVCenter
                                width: 18
                                height: 18
                                visible: root.selectedIndex === index
                                source: "qrc:/media/check.svg"
                                sourceSize: Qt.size(18, 18)
                            }
                        }
                        
                        MouseArea {
                            id: gameMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedIndex = index
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
            
            // Browse manually
            Rectangle {
                id: browseManuallyBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: browseMouseArea.containsMouse ? Theme.buttonHover : Theme.inputBg
                border.color: Theme.inputBorder
                radius: 6
                
                scale: browseMouseArea.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        color: "transparent"
                        
                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: "qrc:/media/folder.svg"
                            sourceSize: Qt.size(24, 24)
                        }
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Browse for materials folder manually..."
                        font.pixelSize: 14
                        color: Theme.textColor
                    }
                }
                
                MouseArea {
                    id: browseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var path = root.app.browse_folder_native("Select Materials Folder")
                        if (path.length > 0) {
                            root.app.set_materials_root_path(path)
                            manualPathField.text = path
                            root.selectedIndex = -1
                        }
                    }
                }
            }
            
            // Path display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: manualPathField.implicitHeight + 16
                color: Theme.inputBg
                border.color: Theme.inputBorder
                radius: 6
                visible: manualPathField.text.length > 0
                
                TextField {
                    id: manualPathField
                    anchors.fill: parent
                    anchors.margins: 4
                    background: null
                    color: Theme.textColor
                    font.pixelSize: 11
                    readOnly: true
                    text: root.selectedIndex >= 0 && root.detectedGames.length > 0
                        ? root.detectedGames[root.selectedIndex].path
                        : ""
                }
            }
        }
        
        // Footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Qt.darker(Theme.panelBg, 1.1)
            
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
                        root.app.complete_first_run()
                        root.skipped()
                        root.close()
                    }
                    
                    scale: pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: Theme.textDim
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 32
                        color: skipButton.hovered ? Theme.buttonHover : "transparent"
                        radius: 4
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }
                }
                
                Button {
                    id: continueButton
                    text: root.isLoadingVPKs ? "Loading..." : "Continue"
                    enabled: !root.isLoadingVPKs && (root.selectedIndex >= 0 || manualPathField.text.length > 0)
                    onClicked: {
                        if (root.selectedIndex >= 0 && root.detectedGames.length > 0) {
                            var game = root.detectedGames[root.selectedIndex]
                            root.app.select_game(game.name)
                        } else {
                            root.app.complete_first_run()
                            root.close()
                        }
                    }
                    
                    scale: pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Theme.animEasing } }
                    
                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent
                        
                        Item {
                            width: 16
                            height: 16
                            visible: root.isLoadingVPKs
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Canvas {
                                anchors.fill: parent
                                property real angle: 0
                                
                                NumberAnimation on angle {
                                    from: 0
                                    to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                    running: root.isLoadingVPKs
                                }
                                
                                onAngleChanged: requestPaint()
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = "white"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    var startAngle = (angle - 90) * Math.PI / 180
                                    var endAngle = (angle + 90) * Math.PI / 180
                                    ctx.arc(width/2, height/2, 6, startAngle, endAngle)
                                    ctx.stroke()
                                }
                            }
                        }
                        
                        Text {
                            text: continueButton.text
                            font.pixelSize: 13
                            font.bold: true
                            color: continueButton.enabled ? "white" : Theme.textDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 32
                        color: continueButton.enabled 
                            ? (continueButton.hovered ? Theme.accentHover : Theme.accent)
                            : Theme.buttonBg
                        radius: 4
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }
                }
            }
            
            Text {
                visible: root.isLoadingVPKs && root.loadingMessage.length > 0
                Layout.fillWidth: true
                text: root.loadingMessage
                color: Theme.textDim
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
