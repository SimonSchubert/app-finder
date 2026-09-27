import QtQuick

// Text in one of three roles and three tones, so screens never pick sizes.
Text {
  id: root

  Tokens { id: tokens }

  property string role: "body"      // body | caption | headline
  property string tone: "ink"       // ink | dim | urgent

  font.family: tokens.fontFamily
  font.pixelSize: root.role === "headline" ? tokens.fontDisplay
    : root.role === "caption" ? tokens.fontCaption
    : tokens.fontSize
  font.weight: tokens.textWeight
  color: root.tone === "dim" ? tokens.sheetDim
    : root.tone === "urgent" ? tokens.urgent
    : tokens.sheetForeground

  elide: Text.ElideRight
}
