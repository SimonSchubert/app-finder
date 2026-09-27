import QtQuick

// One Nerd Font glyph (Glyphs.js), centred in a square slot so a column of
// them lines up.
Text {
  id: root

  Tokens { id: tokens }

  property int fontSize: tokens.fontSize
  // Kept for the call sites that ask for it; the square slot already centres.
  property bool optical: false

  width: Math.round(root.fontSize * 1.3)
  height: width
  font.family: "JetBrainsMono Nerd Font"
  font.pixelSize: root.fontSize
  color: tokens.sheetForeground
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
