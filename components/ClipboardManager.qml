import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardManagerRoot
    
    anchors { 
        left: true
        bottom: true
    }
    
    implicitWidth: 320
    implicitHeight: 400
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsclipboard"
    WlrLayershell.keyboardFocus: clipboardVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    
    property var sharedData: null
    property bool clipboardVisible: false
    
    onClipboardVisibleChanged: {
        console.log("ClipboardManager clipboardVisible changed to:", clipboardVisible)
        if (clipboardVisible) {
            // Odśwież historię i sprawdź aktualny schowek przy otwieraniu
            console.log("Opening clipboard manager, current history length:", clipboardHistory ? clipboardHistory.length : 0)
            // Najpierw załaduj historię z pliku
            loadClipboardHistory()
            // Potem po chwili zaktualizuj model (żeby dać czas na załadowanie)
            Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: { console.log('After load, history length:', clipboardManagerRoot.clipboardHistory ? clipboardManagerRoot.clipboardHistory.length : 0); clipboardManagerRoot.updateHistoryModel(); } }", clipboardManagerRoot)
        }
    }
    
    // Kontrola widoczności - widoczne tylko gdy otwarte lub animuje się
    visible: clipboardVisible
    color: "transparent"
    
    // Slide animation - przesuwamy przez margins.left (obok SidePanel na dole)
    property int slideOffset: clipboardVisible ? 0 : -(implicitWidth + 36)
    
    margins {
        left: slideOffset + 36  // Przylega bezpośrednio do SidePanel (36px szerokość)
        bottom: 8  // Na dole, obok przycisku
    }
    
    // Animacja slideOffset dla slide in/out
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart
        }
    }
    
    property var clipboardHistory: []
    property string clipboardHistoryFile: "/tmp/quickshell_clipboard_history.json"
    
    // Model historii - musi być na poziomie głównym
    ListModel {
        id: clipboardHistoryModel
    }
    
    // Timer do monitorowania schowka - działa zawsze w tle
    Timer {
        id: clipboardMonitorTimer
        interval: 1000  // Sprawdzaj co 1 sekundę
        running: true  // Zawsze działa w tle
        repeat: true
        onTriggered: checkClipboard()
    }
    
    // Timer do zapisywania historii
    Timer {
        id: saveHistoryTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: saveClipboardHistory()
    }
    
    function checkClipboard() {
        // W Wayland używamy wl-clipboard do odczytu
        // Spróbuj najpierw wl-paste, potem xclip jako fallback
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '(wl-paste 2>/dev/null || xclip -selection clipboard -o 2>/dev/null || echo \"\") > /tmp/quickshell_clipboard_current']; running: true }", clipboardManagerRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: clipboardManagerRoot.readClipboard() }", clipboardManagerRoot)
    }
    
    function readClipboard() {
        // Ignoruj nowe elementy jeśli właśnie wyczyszczono historię
        if (clearingHistory) {
            console.log("Ignoring clipboard content - history was just cleared")
            return
        }
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_clipboard_current")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var content = xhr.responseText.trim()
                console.log("Read clipboard content, length:", content.length, "first 50 chars:", content.substring(0, 50))
                if (content && content.length > 0) {
                    // Sprawdź czy to nowa wartość - porównaj z pierwszym elementem
                    var isNew = true
                    if (clipboardHistory.length > 0) {
                        // Sprawdź czy pierwszy element jest taki sam
                        if (clipboardHistory[0] === content) {
                            isNew = false
                            console.log("Clipboard content is the same as first item in history, skipping")
                        } else {
                            // Sprawdź czy nie ma tego samego w całej historii (żeby uniknąć duplikatów)
                            for (var i = 0; i < clipboardHistory.length; i++) {
                                if (clipboardHistory[i] === content) {
                                    // Usuń duplikat z obecnej pozycji
                                    clipboardHistory.splice(i, 1)
                                    break
                                }
                            }
                        }
                    }
                    
                    if (isNew) {
                        console.log("New clipboard content detected, adding to history. Current history length:", clipboardHistory.length)
                        // Dodaj na początek listy
                        clipboardHistory.unshift(content)
                        // Ogranicz do 50 elementów
                        if (clipboardHistory.length > 50) {
                            clipboardHistory = clipboardHistory.slice(0, 50)
                        }
                        console.log("History after adding, length:", clipboardHistory.length, "first 3 items:", clipboardHistory.slice(0, 3).map(function(x) { return x.substring(0, 30) }))
                        // Zapisz historię
                        saveHistoryTimer.restart()
                        // Odśwież model
                        updateHistoryModel()
                    }
                } else {
                    console.log("Clipboard content is empty")
                }
            }
        }
        xhr.send()
    }
    
    function updateHistoryModel() {
        console.log("updateHistoryModel: clipboardHistory length:", clipboardHistory ? clipboardHistory.length : 0)
        clipboardHistoryModel.clear()
        if (clipboardHistory && clipboardHistory.length > 0) {
            for (var i = 0; i < clipboardHistory.length; i++) {
                var item = clipboardHistory[i]
                if (item && typeof item === 'string' && item.length > 0) {
                    clipboardHistoryModel.append({ text: item })
                    console.log("updateHistoryModel: Added item", i, ":", item.substring(0, 50))
                } else {
                    console.log("updateHistoryModel: Skipping invalid item at index", i, "type:", typeof item, "value:", item)
                }
            }
        } else {
            console.log("updateHistoryModel: clipboardHistory is empty or null")
        }
        console.log("History model updated, count:", clipboardHistoryModel.count)
    }
    
    function loadClipboardHistory() {
        console.log("loadClipboardHistory: Loading from", clipboardHistoryFile)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + clipboardHistoryFile)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var content = xhr.responseText.trim()
                        console.log("loadClipboardHistory: File content length:", content.length)
                        if (content && content.length > 0) {
                            var json = JSON.parse(content)
                            if (Array.isArray(json) && json.length > 0) {
                                clipboardHistory = json
                                console.log("Loaded clipboard history, count:", clipboardHistory.length, "first 5 items:", clipboardHistory.slice(0, 5).map(function(x) { return x.substring(0, 30) }))
                                // Zaktualizuj model po załadowaniu
                                if (clipboardVisible) {
                                    updateHistoryModel()
                                }
                            } else {
                                console.log("loadClipboardHistory: Parsed content is not an array or is empty:", typeof json, "length:", json ? json.length : 0)
                                if (!clipboardHistory || clipboardHistory.length === 0) {
                                    clipboardHistory = []
                                }
                            }
                        } else {
                            console.log("Clipboard history file is empty")
                            if (!clipboardHistory || clipboardHistory.length === 0) {
                                clipboardHistory = []
                            }
                        }
                    } catch (e) {
                        console.log("Error parsing clipboard history:", e, "content:", xhr.responseText.substring(0, 100))
                        if (!clipboardHistory || clipboardHistory.length === 0) {
                            clipboardHistory = []
                        }
                    }
                } else {
                    console.log("Clipboard history file not found or not accessible, status:", xhr.status)
                    if (!clipboardHistory || clipboardHistory.length === 0) {
                        clipboardHistory = []
                    }
                }
            }
        }
        xhr.send()
    }
    
    function saveClipboardHistory() {
        // Nie zapisuj historii jeśli została wyczyszczona
        if (historyCleared) {
            console.log("saveClipboardHistory: History was cleared, not saving to file")
            return
        }
        if (!clipboardHistory || clipboardHistory.length === 0) {
            console.log("saveClipboardHistory: clipboardHistory is empty, skipping save")
            return
        }
        try {
            console.log("saveClipboardHistory: Saving", clipboardHistory.length, "items:", clipboardHistory.slice(0, 5).map(function(x) { return x.substring(0, 30) }))
            var json = JSON.stringify(clipboardHistory)
            if (!json) {
                console.log("saveClipboardHistory: JSON.stringify returned empty")
                return
            }
            // Escape properly for shell - użyj printf zamiast echo dla bezpieczeństwa
            var escapedJson = json.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`')
            Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "printf \\"%s\\" \\"' + escapedJson + '\\" > ' + clipboardHistoryFile + '"]; running: true }', clipboardManagerRoot)
            console.log("saveClipboardHistory: Saved", clipboardHistory.length, "items to file")
        } catch (e) {
            console.log("saveClipboardHistory error:", e)
        }
    }
    
    function copyToClipboard(text) {
        // Kopiuj do schowka używając wl-copy
        var escapedText = text.replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`')
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "echo -n \\"' + escapedText + '\\" | wl-copy"]; running: true }', clipboardManagerRoot)
        // Zamknij okno po skopiowaniu
        clipboardManagerRoot.clipboardVisible = false
    }
    
    // Flaga zapobiegająca dodawaniu elementów zaraz po wyczyszczeniu
    property bool clearingHistory: false
    // Flaga zapobiegająca zapisywaniu historii do pliku (po wyczyszczeniu)
    property bool historyCleared: false
    
    function clearClipboardHistory() {
        clearingHistory = true
        historyCleared = true
        clipboardHistory = []
        clipboardHistoryModel.clear()
        // Zatrzymaj timer zapisywania, żeby nie zapisał pustej historii
        saveHistoryTimer.stop()
        // Zatrzymaj timer monitorujący schowek, żeby nie dodawał elementów z powrotem
        clipboardMonitorTimer.stop()
        // Usuń plik z historią zamiast zapisywać pustą tablicę - użyj sync, żeby upewnić się że plik jest usunięty
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "rm -f ' + clipboardHistoryFile + ' && sync"]; running: true }', clipboardManagerRoot)
        console.log("Clipboard history cleared and file removed permanently")
        // Zignoruj nowe elementy przez 5 sekund po wyczyszczeniu, potem wznowij monitorowanie
        // Ale nie zapisuj historii do pliku - użytkownik musi ręcznie wyczyścić historię
        Qt.createQmlObject("import QtQuick; Timer { interval: 5000; running: true; repeat: false; onTriggered: { clipboardManagerRoot.clearingHistory = false; clipboardManagerRoot.clipboardMonitorTimer.start() } }", clipboardManagerRoot)
    }
    
    Component.onCompleted: {
        console.log("ClipboardManager Component.onCompleted")
        console.log("clipboardHistoryModel exists:", clipboardHistoryModel !== undefined)
        console.log("clipboardHistoryModel initial count:", clipboardHistoryModel.count)
        // Zainicjalizuj pustą historię jeśli nie istnieje
        if (!clipboardHistory || clipboardHistory.length === 0) {
            clipboardHistory = []
        }
        // Najpierw załaduj historię z pliku
        loadClipboardHistory()
        // Sprawdź aktualny schowek po chwili
        Qt.createQmlObject("import QtQuick; Timer { interval: 1000; running: true; repeat: false; onTriggered: clipboardManagerRoot.checkClipboard() }", clipboardManagerRoot)
    }
    
    Item {
        id: clipboardContainer
        anchors.fill: parent
        opacity: clipboardVisible ? 1.0 : 0.0
        scale: clipboardVisible ? 1.0 : 0.95
        enabled: clipboardVisible
        
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
        
        // Tło
        Rectangle {
            anchors.fill: parent
            radius: 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
            border.color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
            border.width: 1
            
            // Cień
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.leftMargin: 3
                color: "#000000"
                opacity: 0.2
                z: -1
            }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Nagłówek
            Row {
                width: parent.width
                spacing: 10
                
                Text {
                    text: "󰨸"
                    font.pixelSize: 20
                    font.family: "JetBrains Mono Nerd Font"
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Clipboard History"
                    font.pixelSize: 18
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item { width: parent.width - 200; height: 1 }
                
                // Przycisk zamknięcia
                Rectangle {
                    width: 24
                    height: 24
                    radius: 0
                    color: closeArea.containsMouse ? 
                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    Text {
                        text: "󰅖"
                        font.pixelSize: 14
                        font.family: "JetBrains Mono Nerd Font"
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        anchors.centerIn: parent
                    }
                    
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: clipboardManagerRoot.clipboardVisible = false
                    }
                }
            }
            
            // Lista historii
            Flickable {
                id: historyFlickable
                width: parent.width
                height: parent.height - 60 - 60  // Odejmij wysokość nagłówka i przycisku z większym odstępem
                clip: true
                contentWidth: width
                contentHeight: historyColumn.height
                
                Column {
                    id: historyColumn
                    width: historyFlickable.width
                    spacing: 6
                    
                    Repeater {
                        id: clipboardRepeater
                        model: clipboardHistoryModel
                        
                        onItemAdded: {
                            console.log("Repeater item added at index:", index, "model count:", clipboardHistoryModel.count)
                        }
                        
                        onCountChanged: {
                            console.log("Repeater count changed to:", count, "model count:", clipboardHistoryModel.count)
                        }
                        
                        Rectangle {
                            width: historyColumn.width
                            height: Math.max(40, itemText.implicitHeight + 16)
                            radius: 0
                            color: itemArea.containsMouse ? 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") : 
                                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                
                                Text {
                                    id: itemText
                                    Layout.fillWidth: true
                                    text: {
                                        var txt = modelData ? (modelData.text || modelData || "No text") : "No modelData"
                                        return txt.length > 100 ? txt.substring(0, 100) + "..." : txt
                                    }
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    text: "󰆍"
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono Nerd Font"
                                    color: itemArea.containsMouse ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                        ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa")
                                    Layout.alignment: Qt.AlignVCenter
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    var txt = modelData ? (modelData.text || modelData) : ""
                                    if (txt) {
                                        copyToClipboard(txt)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Pusta lista
                    Text {
                        width: parent.width
                        visible: clipboardHistoryModel.count === 0
                        text: "No clipboard history"
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                        color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        anchors.topMargin: 20
                    }
                }
            }
            
            // Odstęp przed przyciskiem
            Item {
                width: parent.width
                height: 20
            }
            
            // Przycisk usuwania historii
            Rectangle {
                width: parent.width
                height: 36
                radius: 0
                color: clearButtonArea.containsMouse ? 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                
                property real buttonScale: clearButtonArea.pressed ? 0.95 : (clearButtonArea.containsMouse ? 1.02 : 1.0)
                
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuart
                    }
                }
                
                Behavior on buttonScale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuart
                    }
                }
                
                scale: buttonScale
                
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: "󰆼"
                        font.pixelSize: 14
                        font.family: "JetBrains Mono Nerd Font"
                        color: clearButtonArea.containsMouse ? 
                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                    
                    Text {
                        text: "Clear History"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        font.weight: Font.Medium
                        color: clearButtonArea.containsMouse ? 
                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }
                
                MouseArea {
                    id: clearButtonArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        clearClipboardHistory()
                    }
                }
            }
        }
        
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape && clipboardManagerRoot.clipboardVisible) {
                clipboardManagerRoot.clipboardVisible = false
                event.accepted = true
            }
        }
        
        focus: clipboardManagerRoot.clipboardVisible
    }
}

