// A short word in a pill: a filter you can tap, or a badge you only read.
//
//     Chip { text: "Productivity"; interactive: true
//                    selected: root.category === text; onTapped: root.category = text }
//     Chip { text: "Great fit"; tint: tokens.accent }
//
// One shape for both, told apart by `interactive`: a filter is tall enough to
// aim a thumb at and a badge is sized to sit on a line of type.

import QtQuick

Item {
  id: root

  Tokens { id: tokens }

  property string text: ""
  property string glyph: ""

  // The chip's one colour. The sheet's ink by default, which makes a plain
  // grey filter; a badge passes a hue.
  property color tint: tokens.sheetForeground

  // Filled with the tint, letters in the sheet's colour: the filter that is on.
  property bool selected: false

  property bool interactive: false

  signal tapped()

  readonly property int pad: root.interactive ? tokens.space(14) : tokens.space(8)

  implicitHeight: root.interactive ? tokens.space(34) : tokens.space(22)
  implicitWidth: content.implicitWidth + 2 * root.pad

  // A hue pulled a quarter of the way toward the sheet's ink, which holds
  // its contrast on a light theme; the sheet's own ink tinted by itself is
  // itself, so a plain chip needs no case of its own.
  readonly property color ink: root.selected ? tokens.sheetOpaque
    : Qt.tint(root.tint, tokens.alpha(tokens.sheetForeground, 0.25))

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.selected ? root.tint
      : tokens.alpha(root.tint, touch.lit ? 0.26 : root.interactive ? 0.1 : 0.15)
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: tokens.space(4)

    Glyph {
      visible: root.glyph !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      fontSize: root.interactive ? tokens.fontSize : tokens.fontCaption
      color: root.ink
      optical: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      font.family: tokens.fontFamily
      font.pixelSize: root.interactive ? tokens.fontSize : tokens.fontCaption
      font.weight: tokens.textWeight
      color: root.ink
    }
  }

  // Taller than it looks: a 34px pill is a comfortable thing to see and a
  // mean thing to aim at, so the target reaches out to the tap slot.
  TouchArea {
    id: touch
    anchors.fill: parent
    anchors.topMargin: -Math.max(0, (tokens.tapSlot - root.height) / 2)
    anchors.bottomMargin: anchors.topMargin
    interactive: root.interactive
    onTapped: root.tapped()
  }
}
