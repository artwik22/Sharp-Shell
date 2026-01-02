import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData
    
    screen: edgeDetector.screen
    
    anchors { 
        right: true
        top: true
    }
    margins { 
        right: 0
        top: (screen && screen.height) ? (screen.height - 270) / 2 : 0
    }
    implicitWidth: 1  // Minimalna szerokość tylko do wykrywania hover
    implicitHeight: 270  // Tylko wysokość volume slidera (wyśrodkowany)
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector"
    exclusiveZone: 0
    
    color: "transparent"
    visible: true
    
    // Niewidoczny obszar wykrywający hover - tylko wąski pasek przy krawędzi
    MouseArea {
        id: edgeMouseArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 10  // Tylko 10px przy prawej krawędzi
        height: 270  // Tylko wysokość volume slidera
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Nie przechwytuj kliknięć
        propagateComposedEvents: true  // Pozwól na propagację zdarzeń myszy
        enabled: true
        
        onEntered: {
            console.log("RightEdgeDetector: Mouse entered, containsMouse:", containsMouse)
            if (sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
                console.log("RightEdgeDetector: Set volumeVisible to true")
            }
        }
        
        onExited: {
            console.log("RightEdgeDetector: Mouse exited, containsMouse:", containsMouse)
            // Oznacz, że myszka opuściła detektor
            if (sharedData) {
                sharedData.volumeEdgeHovered = false
                console.log("RightEdgeDetector: Set volumeEdgeHovered to false")
                // Timer zamykania zostanie uruchomiony w VolumeSlider
            }
        }
        
        onHoveredChanged: {
            console.log("RightEdgeDetector: Hovered changed to", containsMouse)
            if (containsMouse && sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
        
        onPositionChanged: function(mouse) {
            // Upewnij się, że slider jest widoczny gdy myszka jest nad detektorem
            if (containsMouse && sharedData) {
                if (!sharedData.volumeVisible) {
                    console.log("RightEdgeDetector: Mouse moved over detector, showing slider")
                    sharedData.volumeVisible = true
                }
                sharedData.volumeEdgeHovered = true
            }
        }
    }
}

