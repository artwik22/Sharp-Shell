import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: notificationPanelRoot
    
    anchors {
        right: true
        top: true
    }
    
    implicitWidth: 400
    implicitHeight: 0  // Dynamic height based on notifications
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotifications"
    exclusiveZone: 0
    
    property var sharedData: null
    
    visible: true
    color: "transparent"
    
    margins {
        right: 20
        top: 20
    }
    
    // List of notifications
    property var notifications: []
    property int maxNotifications: 5
    property int notificationTimeout: 5000  // 5 seconds
    
    // Model for notifications
    ListModel {
        id: notificationsModel
    }
    
    property string notificationFile: "/tmp/quickshell_notifications.json"
    property int lastNotificationId: 0
    property string projectPath: ""
    
    // Timer to monitor notifications file
    Timer {
        id: notificationMonitorTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: checkNotifications()
    }
    
    // Start notification monitor script on component creation
    Component.onCompleted: {
        // Initialize notification file
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \\\"[]\\\" > " + notificationFile + "']; running: true }", notificationPanelRoot)
        // Get project path
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_notif_path 2>/dev/null || pwd > /tmp/quickshell_notif_path']; running: true }", notificationPanelRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: notificationPanelRoot.readProjectPath() }", notificationPanelRoot)
        // Test notification after a delay
        Qt.createQmlObject("import QtQuick; Timer { interval: 2000; running: true; repeat: false; onTriggered: { notificationPanelRoot.addNotification('Test', 'NotificationPanel is working!', 'SharpShell', '') } }", notificationPanelRoot)
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_notif_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                    // Stop mako completely to prevent it from showing notifications
                    // Stop systemd service, disable it, dismiss all notifications, and kill process forcefully
                    Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'systemctl --user stop mako.service 2>/dev/null || true; systemctl --user disable mako.service 2>/dev/null || true; makoctl dismiss-all 2>/dev/null || true; pkill -9 mako 2>/dev/null || true; killall mako 2>/dev/null || true']; running: true }", notificationPanelRoot)
                    // Keep mako stopped - check and kill it every 1 second aggressively
                    Qt.createQmlObject("import QtQuick; Timer { interval: 1000; repeat: true; running: true; onTriggered: { Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: [\\'sh\\', \\'-c\\', \\'systemctl --user stop mako.service 2>/dev/null || true; pkill -9 mako 2>/dev/null || true; killall mako 2>/dev/null || true\\']; running: true }', notificationPanelRoot) } }", notificationPanelRoot)
                    // Start the notification server script
                    var scriptPath = projectPath + "/scripts/notification-server.sh"
                    Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'pkill -f notification-server.sh; nohup " + scriptPath + " > /dev/null 2>&1 &']; running: true }", notificationPanelRoot)
                }
            }
        }
        xhr.send()
    }
    
    function checkNotifications() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + notificationFile)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var content = xhr.responseText.trim()
                        if (content && content.length > 0) {
                            var json = JSON.parse(content)
                            if (Array.isArray(json) && json.length > 0) {
                                // Check for new notifications
                                for (var i = 0; i < json.length; i++) {
                                    var notif = json[i]
                                    if (notif.id && notif.id > lastNotificationId) {
                                        addNotification(
                                            notif.title || "",
                                            notif.body || "",
                                            notif.appName || "Unknown",
                                            notif.icon || ""
                                        )
                                        lastNotificationId = notif.id
                                    }
                                }
                            }
                        }
                    } catch (e) {
                        console.log("Error parsing notifications:", e)
                    }
                }
            }
        }
        xhr.send()
    }
    
    // Function to add notification
    function addNotification(title, body, appName, icon) {
        var notification = {
            id: Date.now(),
            title: title || "Notification",
            body: body || "",
            appName: appName || "Unknown",
            icon: icon || "",
            timestamp: new Date()
        }
        
        notifications.unshift(notification)
        
        // Limit number of notifications
        if (notifications.length > maxNotifications) {
            notifications = notifications.slice(0, maxNotifications)
        }
        
        updateNotificationsModel()
        
        // Auto-remove after timeout
        Qt.createQmlObject("import QtQuick; Timer { interval: " + notificationTimeout + "; running: true; repeat: false; onTriggered: { notificationPanelRoot.removeNotification(" + notification.id + ") } }", notificationPanelRoot)
    }
    
    function removeNotification(id) {
        for (var i = 0; i < notifications.length; i++) {
            if (notifications[i].id === id) {
                notifications.splice(i, 1)
                break
            }
        }
        updateNotificationsModel()
    }
    
    function updateNotificationsModel() {
        notificationsModel.clear()
        for (var i = 0; i < notifications.length; i++) {
            notificationsModel.append(notifications[i])
        }
    }
    
    // Column to stack notifications
    Column {
        id: notificationsColumn
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width
        spacing: 12
        
        Repeater {
            model: notificationsModel
            
            Item {
                width: notificationsColumn.width
                height: notificationCard.height
                
                // Shadow
                Rectangle {
                    anchors.fill: notificationCard
                    anchors.topMargin: 3
                    anchors.leftMargin: 3
                    color: "#000000"
                    opacity: 0.15
                    z: 0
                }
                
                Rectangle {
                    id: notificationCard
                    width: parent.width
                    height: Math.max(80, contentColumn.height + 24)
                    radius: 0
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                    border.color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                    border.width: 1
                    z: 1
                    
                    opacity: 1.0
                    scale: 1.0
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    // Slide in animation
                    property real slideOffset: 0
                    
                    Component.onCompleted: {
                        slideOffset = width
                        Qt.createQmlObject("import QtQuick; Timer { interval: 50; running: true; repeat: false; onTriggered: { notificationCard.slideOffset = 0 } }", notificationCard)
                    }
                    
                    Behavior on slideOffset {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    x: slideOffset
                    
                    RowLayout {
                        id: contentRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        
                        // Icon (if available)
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            Layout.alignment: Qt.AlignTop
                            radius: 0
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                            visible: model.icon && model.icon !== ""
                            
                            Text {
                                anchors.centerIn: parent
                                text: model.icon || "󰍡"
                                font.pixelSize: 24
                                font.family: "JetBrains Mono Nerd Font"
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                            }
                        }
                        
                        // Content
                        Column {
                            id: contentColumn
                            Layout.fillWidth: true
                            spacing: 6
                            
                            // App name
                            Text {
                                text: model.appName || "Notification"
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                            }
                            
                            // Title
                            Text {
                                text: model.title || ""
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                width: contentColumn.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            
                            // Body
                            Text {
                                text: model.body || ""
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.2) : "#cccccc"
                                width: contentColumn.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: model.body && model.body !== ""
                            }
                        }
                        
                        // Close button
                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignTop
                            radius: 0
                            color: closeArea.containsMouse ? 
                                ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                "transparent"
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                            
                            Text {
                                text: "󰅖"
                                font.pixelSize: 12
                                font.family: "JetBrains Mono Nerd Font"
                                color: closeArea.containsMouse ? 
                                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                    ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa")
                                anchors.centerIn: parent
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    notificationPanelRoot.removeNotification(model.id)
                                }
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Clicking notification could open the app or dismiss it
                            notificationPanelRoot.removeNotification(model.id)
                        }
                    }
                }
            }
        }
    }
}

