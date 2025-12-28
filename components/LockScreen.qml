import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: lockScreenRoot
    
    required property var screen
    property string currentWallpaper: ""
    property var sharedData: null
    
    screen: lockScreenRoot.screen
    
    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: screen ? screen.height : 1080
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qslockscreen"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.lockScreenVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: (sharedData && sharedData.lockScreenVisible) ? -1 : 0
    
    // Solid background to hide all windows
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        visible: (sharedData && sharedData.lockScreenVisible) || false
        z: -100
    }
    
    visible: (sharedData && sharedData.lockScreenVisible) || false
    color: "transparent"
    
    margins {
        left: 0
        top: 0
        right: 0
        bottom: 0
    }
    
    // Blurred wallpaper background
    Item {
        id: backgroundContainer
        anchors.fill: parent
        visible: lockScreenRoot.visible
        
        // Modern multi-pass blur effect
        // First pass - large scale blur
        Repeater {
            model: 20
            Image {
                id: blurLayer1
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (index - 9.5) * 10
                anchors.verticalCenterOffset: (index - 9.5) * 10
                width: parent.width * (1.0 + (index - 9.5) * 0.1)
                height: parent.height * (1.0 + (index - 9.5) * 0.1)
                source: currentWallpaper || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                
                // Refined Gaussian distribution
                property real gaussianWeight: Math.exp(-((index - 9.5) * (index - 9.5)) / 18.0)
                opacity: gaussianWeight * 0.1
                z: -index
                
                layer.enabled: true
                layer.smooth: true
            }
        }
        
        // Second pass - medium scale blur for smoothness
        Repeater {
            model: 12
            Image {
                id: blurLayer2
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (index - 5.5) * 6
                anchors.verticalCenterOffset: (index - 5.5) * 6
                width: parent.width * (1.0 + (index - 5.5) * 0.06)
                height: parent.height * (1.0 + (index - 5.5) * 0.06)
                source: currentWallpaper || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                
                property real gaussianWeight: Math.exp(-((index - 5.5) * (index - 5.5)) / 8.0)
                opacity: gaussianWeight * 0.12
                z: -index - 25
                
                layer.enabled: true
                layer.smooth: true
            }
        }
        
        // Third pass - fine detail blur
        Repeater {
            model: 8
            Image {
                id: blurLayer3
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (index - 3.5) * 3
                anchors.verticalCenterOffset: (index - 3.5) * 3
                width: parent.width * (1.0 + (index - 3.5) * 0.03)
                height: parent.height * (1.0 + (index - 3.5) * 0.03)
                source: currentWallpaper || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                
                property real gaussianWeight: Math.exp(-((index - 3.5) * (index - 3.5)) / 4.0)
                opacity: gaussianWeight * 0.15
                z: -index - 40
                
                layer.enabled: true
                layer.smooth: true
            }
        }
        
        // Base wallpaper with smooth blending
        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: currentWallpaper || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 0.25
            
            layer.enabled: true
            layer.smooth: true
        }
        
        // Dark overlay for better contrast and to hide windows
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
        }
        
        // Subtle vignette effect
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "#000000" }
            }
            opacity: 0.2
        }
        
        // Fallback if no wallpaper
        Rectangle {
            anchors.fill: parent
            color: "#0a0a0a"
            visible: !currentWallpaper || currentWallpaper === ""
            z: -1
        }
    }
    
    // Lock screen content
    Item {
        id: lockContent
        anchors.fill: parent
        visible: lockScreenRoot.visible
        
        // Clock display - hh:mm format
        Row {
            id: clockRow
            anchors.top: parent.top
            anchors.topMargin: 200
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            
            // Hours display
            Text {
                id: hoursDisplay
                text: "00"
                font.pixelSize: 160
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
            }
            
            // Colon separator
            Text {
                text: ":"
                font.pixelSize: 160
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
            }
            
            // Minutes display
            Text {
                id: minutesDisplay
                text: "00"
                font.pixelSize: 160
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
            }
        }
        
        // Timer to update clock
        Timer {
            id: lockScreenClockTimer
            interval: 1000
            repeat: true
            running: lockScreenRoot.visible
            onTriggered: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                var hStr = h < 10 ? "0" + h : h.toString()
                var mStr = m < 10 ? "0" + m : m.toString()
                hoursDisplay.text = hStr
                minutesDisplay.text = mStr
            }
            Component.onCompleted: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                var hStr = h < 10 ? "0" + h : h.toString()
                var mStr = m < 10 ? "0" + m : m.toString()
                hoursDisplay.text = hStr
                minutesDisplay.text = mStr
            }
        }
        
        // Password input - moved lower
        Column {
            id: passwordColumn
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 180
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            width: Math.min(500, parent.width * 0.35)
            
            // Password input field with lock icon
            Rectangle {
                id: passwordInputContainer
                width: parent.width
                height: 65
                radius: 0
                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                border.color: passwordField.activeFocus ? 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a")
                border.width: 2
                
                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuart
                    }
                }
                
                // Lock icon inside the button
                Text {
                    id: lockIcon
                    text: "󰌾"
                    font.pixelSize: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: passwordField.activeFocus ? 
                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                        ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#888888")
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                
                TextField {
                    id: passwordField
                    anchors.left: lockIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    echoMode: TextField.Password
                    font.pixelSize: 16
                    font.family: "JetBrains Mono"
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    background: Rectangle {
                        color: "transparent"
                    }
                    placeholderText: "Password"
                    placeholderTextColor: "#666666"
                    
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            verifyPassword()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            // Don't allow escape to close lock screen
                            event.accepted = true
                        }
                    }
                    
                    onTextChanged: {
                        errorText.visible = false
                    }
                }
            }
            
            // Error message
            Text {
                id: errorText
                text: "Incorrect password"
                color: "#ff4444"
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false
            }
            
        }
    }
    
    // Password verification process
    property var passwordProcess: null
    property bool isVerifying: false
    
    // Lock screen password - loaded from file
    property string lockPassword: "Marzec"
    property string passwordFilePath: ""
    
    // Load password from file
    function loadPassword() {
        // Get home directory
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$HOME\" > /tmp/quickshell_home_lockscreen 2>/dev/null || echo \"\" > /tmp/quickshell_home_lockscreen']; running: true }", lockScreenRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: lockScreenRoot.readHomePathForPassword() }", lockScreenRoot)
    }
    
    function readHomePathForPassword() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_home_lockscreen")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var home = xhr.responseText.trim()
                if (home && home.length > 0) {
                    passwordFilePath = home + "/.config/sharpshell/lock-password.txt"
                } else {
                    passwordFilePath = "/tmp/sharpshell/lock-password.txt"
                }
                // Load password from file
                var passwordXhr = new XMLHttpRequest()
                passwordXhr.open("GET", "file://" + passwordFilePath)
                passwordXhr.onreadystatechange = function() {
                    if (passwordXhr.readyState === XMLHttpRequest.DONE) {
                        if (passwordXhr.status === 200 || passwordXhr.status === 0) {
                            var savedPassword = passwordXhr.responseText.trim()
                            if (savedPassword && savedPassword.length > 0) {
                                lockPassword = savedPassword
                            }
                        }
                    }
                }
                passwordXhr.send()
            }
        }
        xhr.send()
    }
    
    Component.onCompleted: {
        loadPassword()
    }
    
    function verifyPassword() {
        if (isVerifying || !passwordField.text) {
            return
        }
        
        isVerifying = true
        errorText.visible = false
        
        var password = passwordField.text
        passwordField.text = ""  // Clear password field immediately
        
        // Simple password check - will be replaced with configurable password later
        Qt.callLater(function() {
            if (password === lockPassword) {
                lockScreenRoot.unlockScreen()
            } else {
                lockScreenRoot.passwordIncorrect()
            }
        })
    }
    
    function unlockScreen() {
        isVerifying = false
        
        // Hide lock screen
        if (sharedData) {
            sharedData.lockScreenVisible = false
        }
        
        // Clear password field
        passwordField.text = ""
        passwordField.focus = false
    }
    
    function passwordIncorrect() {
        isVerifying = false
        errorText.visible = true
        passwordField.focus = true
        
        // Shake animation
        passwordInputContainer.x = 0
        var shakeAnimation = Qt.createQmlObject(`
            import QtQuick;
            SequentialAnimation {
                id: shakeAnim
                running: true
                NumberAnimation {
                    target: passwordInputContainer
                    property: "x"
                    from: 0
                    to: -10
                    duration: 50
                }
                NumberAnimation {
                    target: passwordInputContainer
                    property: "x"
                    from: -10
                    to: 10
                    duration: 50
                }
                NumberAnimation {
                    target: passwordInputContainer
                    property: "x"
                    from: 10
                    to: -10
                    duration: 50
                }
                NumberAnimation {
                    target: passwordInputContainer
                    property: "x"
                    from: -10
                    to: 0
                    duration: 50
                }
            }
        `, lockScreenRoot)
    }
    
    // Auto-focus password field when lock screen becomes visible
    onVisibleChanged: {
        if (visible) {
            loadPassword()  // Reload password when lock screen becomes visible
            Qt.callLater(function() {
                passwordField.forceActiveFocus()
                passwordField.text = ""
                errorText.visible = false
            })
        }
    }
    
    // Prevent closing with Escape
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
        }
    }
}

