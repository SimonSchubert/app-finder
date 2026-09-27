import QtQuick

// The colours, type and sizes every screen is drawn with, by role.
//
// App Finder runs as its own Quickshell process, so there is no shell theme to
// borrow: it follows the desktop's light or dark preference instead, with a
// palette of its own.
QtObject {
  id: root

  readonly property bool dark: Qt.styleHints.colorScheme !== Qt.ColorScheme.Light

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
  function space(px) { return Math.round(px) }

  // ------------------------------------------------------------ colour

  readonly property color sheetOpaque: dark ? "#1e1e2e" : "#fafafa"
  readonly property color sheetForeground: dark ? "#e6e6ef" : "#1f1f28"
  readonly property color sheetDim: alpha(sheetForeground, 0.55)
  readonly property color sheetPressed: alpha(sheetForeground, 0.1)
  readonly property color sheetCard: Qt.tint(sheetOpaque, alpha(sheetForeground, dark ? 0.06 : 0.04))
  readonly property color accent: dark ? "#89b4fa" : "#1e66f5"
  readonly property color urgent: dark ? "#f38ba8" : "#d20f39"
  // Text on a filled accent button.
  readonly property color onAccent: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.6
    ? "#111111" : "#ffffff"

  // ------------------------------------------------------------ size

  readonly property int tapSlot: 44
  readonly property int radiusCard: 10
  readonly property int phoneSide: 24

  // ------------------------------------------------------------ type

  readonly property string fontFamily: Qt.application.font.family
  readonly property string studioFontFamily: fontFamily
  readonly property int textWeight: Font.Normal
  readonly property int fontSize: 15
  readonly property int fontCaption: 12
  readonly property int fontDisplay: 26
  readonly property int iconSizeLarge: 20
  readonly property int phoneTitle: 27
  readonly property int phoneAppText: 17
}
