// One app in the list: its monogram, its name and one line of
// what it does, and on the right the one thing most worth knowing -- that it
// is installing, that it is installed, or how well it fits a phone.

import QtQuick
import "Hues.js" as Hues
import "Catalog.js" as Catalog
import "Glyphs.js" as Glyphs

Item {
  id: root

  Tokens { id: tokens }

  property var app: ({})
  property bool installed: false
  property var job: null

  signal tapped()

  readonly property var badge: Catalog.badge(root.app)
  readonly property bool busy: !!root.job && root.job.state !== "error"

  // A card with an edge of its own, for the desktop's grid; a bare row that
  // lights up under the finger, for the phone's list.
  property bool card: false
  // The app whose page is open beside the grid.
  property bool selected: false

  implicitHeight: tokens.space(68)

  Card {
    anchors.fill: parent
    visible: root.card
    border.width: root.selected ? 1 : 0
    border.color: tokens.accent
    color: root.selected ? Qt.tint(tokens.sheetCard, tokens.alpha(tokens.accent, 0.1)) : tokens.sheetCard
  }

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: root.card ? 0 : tokens.space(2)
    anchors.bottomMargin: root.card ? 0 : tokens.space(2)
    radius: tokens.radiusCard
    color: touch.lit ? tokens.sheetPressed : tokens.alpha(tokens.sheetForeground, 0.04)
    visible: touch.lit || (root.card && touch.containsMouse)
  }

  Monogram {
    id: mark
    anchors.left: parent.left
    anchors.leftMargin: tokens.space(14)
    anchors.verticalCenter: parent.verticalCenter
    size: tokens.space(44)
    source: root.app.icon || ""
    initials: root.app.initials || Hues.initials(root.app.name)
    accent: root.app.accent || ""
    key: root.app.id || ""
  }

  // A Row so that the one visible child is the whole width: a Row skips
  // what is not visible, and only one of these ever is.
  Row {
    id: tail
    anchors.right: parent.right
    anchors.rightMargin: tokens.space(14)
    anchors.verticalCenter: parent.verticalCenter

    Text {
      visible: root.busy
      text: root.job ? root.job.text : ""
      font.family: tokens.fontFamily
      font.pixelSize: tokens.fontCaption
      font.weight: tokens.textWeight
      color: tokens.accent
    }

    Row {
      visible: !root.busy && root.installed
      spacing: tokens.space(2)

      Glyph {
        anchors.verticalCenter: parent.verticalCenter
        text: Glyphs.CHECK
        fontSize: tokens.fontCaption
        color: tokens.sheetDim
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Installed"
        font.family: tokens.fontFamily
        font.pixelSize: tokens.fontCaption
        font.weight: tokens.textWeight
        color: tokens.sheetDim
      }
    }

    Chip {
      visible: !root.busy && !root.installed && !!root.badge
      text: root.badge ? root.badge.text : ""
      tint: !root.badge ? tokens.sheetForeground
        : root.badge.tone === "good" ? Hues.of("lime")
        : root.badge.tone === "ok" ? Hues.of("cyan")
        : tokens.sheetDim
    }

  }

  Column {
    anchors.left: mark.right
    anchors.leftMargin: tokens.space(14)
    anchors.right: tail.left
    anchors.rightMargin: tokens.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: tokens.space(1)

    Text {
      width: parent.width
      text: root.app.name || ""
      elide: Text.ElideRight
      font.family: tokens.fontFamily
      font.pixelSize: tokens.fontSize
      font.weight: tokens.textWeight
      color: tokens.sheetForeground
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: root.app.description || ""
      elide: Text.ElideRight
      maximumLineCount: 1
      font.family: tokens.fontFamily
      font.pixelSize: tokens.fontCaption
      font.weight: tokens.textWeight
      color: tokens.sheetDim
    }
  }

  TouchArea {
    id: touch
    anchors.fill: parent
    onTapped: root.tapped()
  }
}
