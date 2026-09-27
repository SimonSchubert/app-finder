// App Finder as its own Quickshell process.
//
//   quickshell -p /usr/share/app-finder/shell.qml
//
// The window opens at startup and closing it ends the process -- a window
// that is gone with a process still running is how an app becomes a battery
// bug. The one exception is an install still going, which Panel waits for.
import QtQuick
import Quickshell

ShellRoot {
  Panel {
    onQuit: Qt.quit()
  }
}
