pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active Omarchy theme's palette, for every Tokens to draw from: the
// colors.toml Omarchy writes into ~/.local/state/omarchy/current/theme, the
// same file its shell reads. Without Omarchy -- or before a theme was ever
// chosen -- it has none, and Tokens falls back to its own light and dark
// palettes.
//
// Watched, and read again whenever App Finder's window comes forward: a theme
// switch can replace the file rather than write into it, and a watch on the
// old one would then never fire.
Singleton {
  id: root

  readonly property string path: {
    var state = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    return state + "/omarchy/current/theme/colors.toml"
  }

  property bool loaded: false
  property string mode: ""
  property string background: ""
  property string foreground: ""
  property string accent: ""
  property string muted: ""
  property string red: ""
  property string lighterBackground: ""

  function parse(text) {
    var found = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]*)"/)
      if (m) found[m[1]] = m[2]
    }
    // Older themes carry only the terminal's sixteen: 0 and 7 are background
    // and foreground there, 4 the accent, 1 red, 8 muted -- the same fallbacks
    // Omarchy's own Color.qml takes.
    root.background = found.background || found.color0 || ""
    root.foreground = found.foreground || found.color7 || ""
    root.accent = found.accent || found.color4 || ""
    root.muted = found.muted || found.color8 || ""
    root.red = found.red || found.color1 || ""
    root.lighterBackground = found.lighter_background || ""
    root.mode = found.mode || ""
    root.loaded = root.background !== "" && root.foreground !== ""
  }

  function reload() { colors.reload() }

  property FileView colors: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: root.parse(text())
    onLoadFailed: root.parse("")
    onFileChanged: reload()
  }
}
