import QtQuick
import qs

// The colours, type and sizes every screen is drawn with, by role.
//
// The active Omarchy theme's, read from its colors.toml (Theme.qml), so App
// Finder matches the desktop and the phone it runs on and follows a theme
// switch. Without one -- a Quickshell desktop that is not Omarchy -- it follows
// the desktop's light or dark preference with a palette of its own.
QtObject {
  id: root

  readonly property bool themed: Theme.loaded

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
  function space(px) { return Math.round(px) }
  function luminance(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }

  readonly property bool dark: root.themed
    ? (Theme.mode !== "" ? Theme.mode !== "light"
      // Empty for the moment a switch takes to read the new file.
      : Theme.background === "" || root.luminance(Qt.color(Theme.background)) < 0.5)
    : Qt.styleHints.colorScheme !== Qt.ColorScheme.Light

  // ------------------------------------------------------------ colour

  readonly property color sheetOpaque: root.themed ? Theme.background : (dark ? "#1e1e2e" : "#fafafa")
  readonly property color sheetForeground: root.themed ? Theme.foreground : (dark ? "#e6e6ef" : "#1f1f28")
  readonly property color sheetDim: alpha(sheetForeground, 0.55)
  readonly property color sheetPressed: alpha(sheetForeground, 0.1)
  readonly property color sheetCard: Qt.tint(sheetOpaque, alpha(sheetForeground, dark ? 0.06 : 0.04))
  readonly property color accent: root.themed && Theme.accent !== "" ? Theme.accent : (dark ? "#89b4fa" : "#1e66f5")
  readonly property color urgent: root.themed && Theme.red !== "" ? Theme.red : (dark ? "#f38ba8" : "#d20f39")
  // Text on a filled accent button.
  readonly property color onAccent: root.luminance(accent) > 0.6 ? "#111111" : "#ffffff"

  // ------------------------------------------------------------ size

  readonly property int tapSlot: 44
  readonly property int radiusCard: 10
  readonly property int phoneSide: 24

  // ------------------------------------------------------------ type

  // Omarchy draws everything in the fontconfig alias `omarchy font set`
  // writes, which is what "monospace" resolves to there.
  readonly property string fontFamily: root.themed ? "monospace" : Qt.application.font.family
  readonly property string studioFontFamily: fontFamily
  readonly property int textWeight: Font.Normal
  readonly property int fontSize: 15
  readonly property int fontCaption: 12
  readonly property int fontDisplay: 26
  readonly property int iconSizeLarge: 20
  readonly property int phoneTitle: 27
  readonly property int phoneAppText: 17
}
