import QtQuick

// A flat text or glyph button, a thumb's width at least.
Item {
  id: root

  Tokens { id: tokens }

  property string glyph: ""
  property string text: ""
  property string tone: "ink"       // ink | dim
  property bool enabled: true

  signal tapped()

  readonly property bool pressed: touch.lit

  implicitWidth: Math.max(tokens.tapSlot, content.implicitWidth + tokens.space(20))
  implicitHeight: tokens.tapSlot

  readonly property color ink: touch.lit ? tokens.sheetForeground
    : !root.enabled ? tokens.alpha(tokens.sheetForeground, 0.35)
    : root.tone === "dim" ? tokens.sheetDim
    : tokens.sheetForeground

  Accessible.role: Accessible.Button
  Accessible.name: root.text

  Rectangle {
    anchors.fill: parent
    anchors.margins: tokens.space(4)
    radius: tokens.radiusCard
    color: tokens.sheetPressed
    visible: touch.lit
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: (root.glyph !== "" && root.text !== "") ? tokens.space(6) : 0

    Glyph {
      visible: root.glyph !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      fontSize: tokens.iconSizeLarge
      color: root.ink
    }

    Label {
      visible: root.text !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: root.ink
    }
  }

  TouchArea {
    id: touch
    anchors.fill: parent
    interactive: root.enabled
    onTapped: root.tapped()
  }
}
