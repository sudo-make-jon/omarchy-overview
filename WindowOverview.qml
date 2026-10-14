import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons

Item {
  id: root

  property bool opened: false
  property bool focusPrimed: false
  property var selectedToplevel: null
  readonly property var allToplevels: ToplevelManager.toplevels.values
  readonly property var visibleToplevels: root.filteredToplevels()

  Timer {
    id: focusPrimeTimer
    interval: 75
    repeat: false
    onTriggered: root.focusPrimed = true
  }

  function filteredToplevels() {
    var result = []
    var windows = root.allToplevels || []
    for (var i = 0; i < windows.length; i++) {
      var window = windows[i]
      if (!window || window.parent || window.minimized) continue
      if (!window.title && !window.appId) continue
      result.push(window)
    }
    return result
  }

  function windowsForScreen(targetScreen) {
    var result = []
    var windows = root.visibleToplevels
    for (var i = 0; i < windows.length; i++) {
      var screens = windows[i].screens || []
      for (var j = 0; j < screens.length; j++) {
        if (screens[j] === targetScreen) {
          result.push(windows[i])
          break
        }
      }
    }
    return result
  }

  function open(payloadJson) {
    var windows = root.visibleToplevels
    if (windows.length === 0) {
      root.close()
      return
    }
    var active = ToplevelManager.activeToplevel
    root.selectedToplevel = windows.indexOf(active) >= 0 ? active : windows[0]
    root.focusPrimed = false
    root.opened = true
    focusPrimeTimer.restart()
  }

  function close() {
    focusPrimeTimer.stop()
    root.focusPrimed = false
    root.opened = false
    root.selectedToplevel = null
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function moveSelection(offset) {
    var windows = root.visibleToplevels
    if (windows.length === 0) return
    var index = windows.indexOf(root.selectedToplevel)
    if (index < 0) index = 0
    else index = (index + offset + windows.length) % windows.length
    root.selectedToplevel = windows[index]
  }

  function activateSelection() {
    if (!root.selectedToplevel) return
    var target = root.selectedToplevel
    root.close()
    target.activate()
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: overlay
        required property var modelData
        screen: modelData
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "jonathan-window-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        // Prime keyboard focus after the shortcut; permanent Exclusive focus
        // can prevent pointer events from reaching the overview surface.
        WlrLayershell.keyboardFocus: {
          if (modelData !== Quickshell.screens[0] || !root.opened)
            return WlrKeyboardFocus.None
          return root.focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive
        }

        Item {
          id: canvas
          anchors.fill: parent
          focus: overlay.modelData === Quickshell.screens[0]

          Rectangle {
            anchors.fill: parent
            color: "#d9000000"
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.close()
          }

          Column {
            id: content
            anchors.centerIn: parent
            width: Math.min(parent.width - 96, 1440)
            spacing: 24

            Text {
              width: parent.width
              text: "Overview"
              color: "white"
              font.family: Style.font.family
              font.pixelSize: 28
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
            }

            Grid {
              id: windowGrid
              anchors.horizontalCenter: parent.horizontalCenter
              columns: Math.max(1, Math.min(4, Math.ceil(Math.sqrt(windowRepeater.count))))
              spacing: 20

              Repeater {
                id: windowRepeater
                model: root.windowsForScreen(overlay.modelData)

                delegate: Item {
                  id: tile
                  required property var modelData
                  readonly property var toplevel: modelData
                  readonly property bool selected: root.selectedToplevel === tile.toplevel
                  width: Math.min(350, (content.width - (windowGrid.columns - 1) * windowGrid.spacing) / windowGrid.columns)
                  height: width * 0.68 + 38

                  Rectangle {
                    id: previewFrame
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: parent.height - 38
                    radius: 12
                    color: "#292929"
                    clip: true
                    border.width: tile.selected ? 3 : 1
                    border.color: tile.selected ? "#ffffff" : "#66ffffff"

                    Text {
                      anchors.centerIn: parent
                      visible: !preview.hasContent
                      text: tile.toplevel.appId || "Window"
                      color: "#dddddd"
                      font.family: Style.font.family
                      font.pixelSize: 16
                      elide: Text.ElideRight
                    }

                    ScreencopyView {
                      id: preview
                      anchors.fill: parent
                      captureSource: tile.toplevel
                      live: true
                      constraintSize: Qt.size(previewFrame.width, previewFrame.height)
                      visible: hasContent
                    }
                  }

                  Text {
                    anchors { top: previewFrame.bottom; left: parent.left; right: parent.right; topMargin: 8 }
                    text: tile.toplevel.title || tile.toplevel.appId || "Window"
                    color: "white"
                    font.family: Style.font.family
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedToplevel = tile.toplevel
                    onClicked: {
                      root.selectedToplevel = tile.toplevel
                      root.activateSelection()
                    }
                  }
                }
              }
            }

            Text {
              width: parent.width
              text: "←  →  ↑  ↓  Navigate     Enter  Open     Esc  Close"
              color: "#cccccc"
              font.family: Style.font.family
              font.pixelSize: 14
              horizontalAlignment: Text.AlignHCenter
            }
          }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              root.close()
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.activateSelection()
              event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
              root.moveSelection(1)
              event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
              root.moveSelection(-1)
              event.accepted = true
            } else if (event.key === Qt.Key_Tab) {
              root.moveSelection(event.modifiers & Qt.ShiftModifier ? -1 : 1)
              event.accepted = true
            }
          }
        }
      }
    }
  }
}
