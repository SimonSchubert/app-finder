// An app's mark: its icon when the test run cut one from a screenshot, and
// two letters on a tile of its hue while that loads or when there is none.
//
//     Monogram { initials: app.initials; key: app.id }
//     Monogram { source: app.icon; initials: app.initials; key: app.id }
//
// The icons are the top of a phone screenshot of the app, corners already
// rounded in, so a list of them needs no clipping.
//
// Tinted rather than filled: a solid tile per row is a column of coloured
// squares, and the eye still has to go to the name. At 20% the hue tells rows
// apart without shouting over the text beside it.

import QtQuick
import "Hues.js" as Hues

Rectangle {
  id: root

  Tokens { id: tokens }

  property string initials: ""
  property string accent: ""
  // What the hue falls back on when `accent` is not one of the six: the id.
  property string key: ""
  property int size: tokens.space(44)
  property string source: ""

  readonly property bool pictured: picture.status === Image.Ready

  readonly property color hue: Hues.of(root.accent, root.key || root.initials)

  implicitWidth: root.size
  implicitHeight: root.size
  // The theme's corner, grown with the tile: a 64px tile with an 8px corner
  // looks square, and one with a 32px corner is a circle, which is an avatar.
  radius: Math.min(root.size * 0.32, Math.round(tokens.radiusCard * root.size / tokens.space(36)))
  color: root.pictured ? "transparent" : tokens.alpha(root.hue, 0.2)
  border.width: 1
  border.color: root.pictured ? tokens.alpha(tokens.sheetForeground, 0.14) : tokens.alpha(root.hue, 0.32)

  Image {
    id: picture
    anchors.fill: parent
    source: root.source
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: root.size * 3
    visible: root.pictured
    z: -1
  }

  Text {
    visible: !root.pictured
    anchors.centerIn: parent
    text: String(root.initials || "?").slice(0, 2).toUpperCase()
    font.family: tokens.studioFontFamily
    font.pixelSize: Math.round(root.size * (text.length > 1 ? 0.36 : 0.44))
    font.weight: Font.Bold
    font.letterSpacing: -root.size * 0.01
    // Toward the sheet's ink, so the letters hold their contrast on a light
    // theme where the bare hue would wash out.
    color: Qt.tint(root.hue, tokens.alpha(tokens.sheetForeground, 0.3))
  }
}
