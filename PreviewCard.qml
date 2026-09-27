// A screenshot you can tap, with its name across the bottom.
//
//     PreviewCard {
//       width: 280
//       source: app.thumb; title: app.name; subtitle: app.author
//       initials: app.initials; accent: app.accent; key: app.id
//       onTapped: root.show(app.id)
//     }
//
// 16:9 by default; a phone
// screenshot passes `ratio` (height over width) and is cropped from the top,
// where an app keeps its title and its controls. While the picture is
// on its way -- or when there is none -- the card is the app's own hue with
// its monogram large in the middle, so a slow network draws a row of colour
// rather than a row of holes, and nothing jumps when the image lands.
//
// Given `sources` -- more than one screenshot -- it shows each in turn and
// crossfades between them while `cycling` is true. The next one is decoded
// behind the one on show and only faded in once it is ready, so a slow
// network holds the current picture rather than flashing the monogram.

import QtQuick
import Quickshell.Widgets
import "Hues.js" as Hues

Item {
  id: root

  Tokens { id: tokens }

  property string source: ""
  // Several pictures to show in turn; `source` when there is only one.
  property var sources: []
  property bool cycling: false
  property int cycleInterval: 4000
  // Where this card starts in the cycle, so a row of them does not change
  // all at once.
  property int cycleDelay: 0
  property string title: ""
  property string subtitle: ""
  property string trailing: ""
  property string initials: ""
  property string accent: ""
  property string key: ""
  // Decode no wider than this: a 1600px hero at full size is 5.7 MB of
  // texture for a picture 360 points wide.
  property int decodeWidth: 0
  // Height over width.
  property real ratio: 9 / 16
  // A hairline round the edge. A phone screenshot is usually the same dark
  // as the sheet it sits on, and without one the card has no edge at all.
  property bool outlined: false

  signal tapped()

  readonly property var pictures: root.sources && root.sources.length ? root.sources
    : (root.source !== "" ? [root.source] : [])
  property int shown: 0
  // Which of the two layers is on top. The other is where the next picture
  // decodes.
  property bool frontIsA: true
  readonly property Image front: root.frontIsA ? layerA : layerB
  readonly property Image back: root.frontIsA ? layerB : layerA
  readonly property bool loaded: layerA.status === Image.Ready || layerB.status === Image.Ready

  onPicturesChanged: {
    root.shown = 0
    root.frontIsA = true
    layerB.source = ""
    layerA.source = root.pictures.length ? root.pictures[0] : ""
  }

  // True while a new picture fades in: the one it replaces stays fully drawn
  // under it until then, so the fade never shows the card's colour through.
  property bool fading: false

  function swap() {
    root.frontIsA = !root.frontIsA
    root.fading = true
    fadeDone.restart()
  }

  function advance() {
    if (root.pictures.length < 2) return
    root.shown = (root.shown + 1) % root.pictures.length
    root.back.source = root.pictures[root.shown]
    if (root.back.status === Image.Ready) root.swap()
  }

  Timer { id: fadeDone; interval: 700; onTriggered: root.fading = false }

  Timer {
    id: cycle
    running: root.cycling && root.visible && root.pictures.length > 1 && root.loaded && !touch.lit
    interval: root.cycleInterval + root.cycleDelay
    repeat: true
    onTriggered: { interval = root.cycleInterval; root.advance() }
  }
  readonly property color hue: Hues.of(root.accent, root.key || root.initials)

  implicitWidth: tokens.space(280)
  implicitHeight: Math.round(root.width * root.ratio)

  scale: touch.lit ? 0.98 : 1
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

  ClippingRectangle {
    anchors.fill: parent
    radius: Math.round(tokens.radiusCard * 1.5)
    color: tokens.alpha(root.hue, 0.18)
    contentUnderBorder: true
    border.width: root.outlined ? 1 : 0
    border.color: tokens.alpha(tokens.sheetForeground, 0.16)

    Rectangle {
      anchors.fill: parent
      visible: !root.loaded
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0; color: tokens.alpha(root.hue, 0.32) }
        GradientStop { position: 1; color: tokens.alpha(root.hue, 0.08) }
      }

      Monogram {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.title !== "" ? -tokens.space(10) : 0
        size: Math.round(root.height * 0.36)
        initials: root.initials
        accent: root.accent
        key: root.key
      }
    }

    component Layer: Image {
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      verticalAlignment: Image.AlignTop
      asynchronous: true
      cache: true
      sourceSize.width: root.decodeWidth
      property bool isA: false
      readonly property bool onTop: root.frontIsA === isA
      z: onTop ? 1 : 0
      opacity: status !== Image.Ready ? 0 : onTop || root.fading ? 1 : 0
      // Only the one arriving animates; the one leaving holds under it and is
      // dropped once it is covered.
      Behavior on opacity {
        enabled: onTop
        NumberAnimation { duration: 700; easing.type: Easing.InOutQuad }
      }
      // Decoded after advance() asked for it: now it can come forward.
      onStatusChanged: if (status === Image.Ready && !onTop
                           && source.toString() === String(root.pictures[root.shown]))
                         root.swap()
    }

    Layer { id: layerA; isA: true; source: root.pictures.length ? root.pictures[0] : "" }
    Layer { id: layerB }

    // Black and not a theme role, for the reason Tokens.scrim() gives: its job
    // is to darken whatever the screenshot has under the name.
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: parent.height * 0.55
      visible: root.title !== "" && root.loaded
      gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.72) }
      }
    }

    Column {
      anchors.left: parent.left
      anchors.right: tail.left
      anchors.bottom: parent.bottom
      anchors.margins: tokens.space(12)
      spacing: 0
      visible: root.title !== ""

      Text {
        width: parent.width
        text: root.title
        elide: Text.ElideRight
        font.family: tokens.studioFontFamily
        font.pixelSize: tokens.phoneAppText
        font.weight: Font.DemiBold
        color: root.loaded ? "white" : tokens.sheetForeground
      }

      Text {
        width: parent.width
        visible: root.subtitle !== ""
        text: root.subtitle
        elide: Text.ElideRight
        font.family: tokens.fontFamily
        font.pixelSize: tokens.fontCaption
        font.weight: tokens.textWeight
        color: root.loaded ? Qt.rgba(1, 1, 1, 0.75) : tokens.sheetDim
      }
    }

    Text {
      id: tail
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: tokens.space(12)
      visible: root.trailing !== "" && root.title !== ""
      text: root.trailing
      font.family: tokens.fontFamily
      font.pixelSize: tokens.fontCaption
      font.weight: tokens.textWeight
      color: root.loaded ? Qt.rgba(1, 1, 1, 0.8) : tokens.sheetDim
    }
  }

  TouchArea {
    id: touch
    anchors.fill: parent
    onTapped: root.tapped()
  }
}
