// One app's page: its screenshots, what it is, how it fared on a phone, and
// the button that installs it.
//
// The button is the page's one control and it changes shape rather than
// being joined by others: Install, then a bar filling as the install goes
// through its steps, then Open and Remove side by side. Remove asks twice --
// a thumb resting on the wrong half of a two-button row is how an app
// disappears -- and then turns back after three seconds.

pragma ComponentBehavior: Bound

import QtQuick
import "Hues.js" as Hues
import "Catalog.js" as Catalog
import "Glyphs.js" as Glyphs

Item {
  id: root

  Tokens { id: tokens }

  property var app: null
  property bool installed: false
  property var job: null

  signal back()
  signal install()
  signal remove()
  signal open()
  signal retry()
  signal source()

  readonly property var fit: root.app ? root.app.fit : null
  readonly property var shots: root.app && root.app.phoneShots ? root.app.phoneShots : []
  readonly property string rating: Catalog.rating(root.app)
  readonly property bool busy: !!root.job && root.job.state !== "error"
  readonly property bool failed: !!root.job && root.job.state === "error"
  readonly property int side: tokens.space(20)

  property bool confirming: false
  onAppChanged: {
    root.confirming = false
    flick.contentY = 0
    gallery.positionViewAtBeginning()
  }

  Timer {
    id: unconfirm
    interval: 3000
    onTriggered: root.confirming = false
  }

  Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: body.height + tokens.space(32)
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    Column {
      id: body
      width: flick.width
      topPadding: tokens.space(12)
      spacing: tokens.space(18)

      // The hero: what the phone test run saw, as a row of phone screens
      // you can swipe.
      ListView {
        id: gallery
        visible: root.shots.length > 0
        width: parent.width
        readonly property int shotWidth: Math.round(Math.min(width * 0.52, tokens.space(200)))
        height: visible ? Math.round(shotWidth * Catalog.SHOT_RATIO) : 0
        orientation: ListView.Horizontal
        spacing: tokens.space(12)
        leftMargin: tokens.space(20) + tokens.space(48)
        rightMargin: tokens.space(20)
        boundsBehavior: Flickable.StopAtBounds
        model: root.shots

        delegate: PreviewCard {
          required property string modelData
          width: gallery.shotWidth
          ratio: Catalog.SHOT_RATIO
          outlined: true
          source: modelData
          decodeWidth: 540
          initials: root.app ? (root.app.initials || Hues.initials(root.app.name)) : ""
          accent: root.app ? root.app.accent : ""
          key: root.app ? root.app.id : ""
        }
      }

      // Room for the back button when there is no screen under it.
      Item {
        visible: root.shots.length === 0
        width: 1
        height: visible ? tokens.space(48) : 0
      }

      // Name, and where it comes from.
      Row {
        x: root.side
        width: parent.width - 2 * root.side
        spacing: tokens.space(14)

        Monogram {
          id: mark
          size: tokens.space(56)
          source: root.app ? root.app.icon || "" : ""
          initials: root.app ? (root.app.initials || Hues.initials(root.app.name)) : ""
          accent: root.app ? root.app.accent : ""
          key: root.app ? root.app.id : ""
        }

        Column {
          width: parent.width - mark.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: tokens.space(2)

          Text {
            width: parent.width
            text: root.app ? root.app.name : ""
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: tokens.studioFontFamily
            font.pixelSize: tokens.space(22)
            font.weight: Font.Medium
            color: tokens.sheetForeground
          }

          Text {
            width: parent.width
            text: root.app ? "AUR" + (root.app.version ? " · " + root.app.version : "") : ""
            elide: Text.ElideRight
            font.family: tokens.fontFamily
            font.pixelSize: tokens.fontCaption
            font.weight: tokens.textWeight
            color: tokens.sheetDim
          }
        }
      }

      // The button, in whichever of its shapes.
      Column {
        x: root.side
        width: parent.width - 2 * root.side
        spacing: tokens.space(8)

        Item {
          width: parent.width
          height: tokens.space(48)

          // Install, or Try again.
          Rectangle {
            anchors.fill: parent
            visible: !root.busy && !root.installed
            radius: height / 2
            color: installTouch.lit ? Qt.darker(tokens.accent, 1.15) : tokens.accent

            Row {
              anchors.centerIn: parent
              spacing: tokens.space(6)

              Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: root.failed ? Glyphs.REFRESH : Glyphs.DOWNLOAD
                color: tokens.onAccent
                optical: true
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.failed ? "Try again" : "Install"
                font.family: tokens.studioFontFamily
                font.pixelSize: tokens.phoneAppText
                font.weight: Font.DemiBold
                color: tokens.onAccent
              }
            }

            TouchArea {
              id: installTouch
              anchors.fill: parent
              onTapped: root.failed ? root.retry() : root.install()
            }
          }

          // Working: a bar that fills as the steps come in.
          Rectangle {
            id: track
            anchors.fill: parent
            visible: root.busy
            radius: height / 2
            color: tokens.alpha(tokens.accent, 0.14)
            clip: true

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Math.max(parent.height, parent.width * (root.job ? root.job.progress || 0 : 0))
              radius: parent.radius
              color: tokens.alpha(tokens.accent, 0.4)
              Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            }

            Text {
              anchors.centerIn: parent
              text: root.job ? root.job.text : ""
              font.family: tokens.studioFontFamily
              font.pixelSize: tokens.phoneAppText
              font.weight: Font.DemiBold
              color: tokens.sheetForeground
            }
          }

          // Installed: Open, and Remove beside it.
          Row {
            anchors.fill: parent
            visible: !root.busy && root.installed
            spacing: tokens.space(10)

            Rectangle {
              width: (parent.width - parent.spacing) * 0.58
              height: parent.height
              radius: height / 2
              color: openTouch.lit ? Qt.darker(tokens.accent, 1.15) : tokens.accent

              Row {
                anchors.centerIn: parent
                spacing: tokens.space(6)

                Glyph {
                  anchors.verticalCenter: parent.verticalCenter
                  text: Glyphs.OPEN
                  color: tokens.onAccent
                  optical: true
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Open"
                  font.family: tokens.studioFontFamily
                  font.pixelSize: tokens.phoneAppText
                  font.weight: Font.DemiBold
                  color: tokens.onAccent
                }
              }

              TouchArea {
                id: openTouch
                anchors.fill: parent
                onTapped: root.open()
              }
            }

            Rectangle {
              width: (parent.width - parent.spacing) * 0.42
              height: parent.height
              radius: height / 2
              color: root.confirming ? tokens.alpha(tokens.urgent, removeTouch.lit ? 0.3 : 0.18)
                : removeTouch.lit ? tokens.sheetPressed : tokens.alpha(tokens.sheetForeground, 0.08)

              Text {
                anchors.centerIn: parent
                width: parent.width - tokens.space(16)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.confirming ? "Tap to confirm" : "Remove"
                font.family: tokens.studioFontFamily
                font.pixelSize: tokens.phoneAppText
                font.weight: Font.DemiBold
                color: root.confirming ? tokens.urgent : tokens.sheetForeground
              }

              TouchArea {
                id: removeTouch
                anchors.fill: parent
                onTapped: {
                  if (root.confirming) {
                    root.confirming = false
                    unconfirm.stop()
                    root.remove()
                  } else {
                    root.confirming = true
                    unconfirm.restart()
                  }
                }
              }
            }
          }
        }

        Label {
          width: parent.width
          visible: root.failed
          text: root.job ? root.job.error : ""
          tone: "urgent"
          role: "caption"
          wrapMode: Text.WordWrap
          elide: Text.ElideNone
        }

        // yay would say this before it builds; App Finder answers its
        // questions for it, so it has to say it here instead.
        Label {
          width: parent.width
          visible: !root.installed && !root.failed
          text: "Built from the AUR on this device, from a recipe anyone can publish. Installing asks for your password."
          tone: "dim"
          role: "caption"
          wrapMode: Text.WordWrap
          elide: Text.ElideNone
        }
      }

      // How it fared on a phone.
      Card {
        x: tokens.space(12)
        width: parent.width - 2 * x
        height: fitColumn.height + 2 * tokens.space(16)

        Column {
          id: fitColumn
          x: tokens.space(16)
          y: tokens.space(16)
          width: parent.width - 2 * x
          spacing: tokens.space(10)

          Row {
            width: parent.width
            spacing: tokens.space(12)

            Glyph {
              id: fitGlyph
              anchors.verticalCenter: parent.verticalCenter
              text: root.rating === "perfect" || root.rating === "usable" ? Glyphs.PHONE_OK
                : root.rating === "desktop only" ? Glyphs.DESKTOP
                : root.rating === "" ? Glyphs.MAGNIFY
                : Glyphs.ALERT
              fontSize: tokens.iconSizeLarge
              color: root.rating === "perfect" ? Hues.of("lime")
                : root.rating === "usable" ? Hues.of("cyan")
                : tokens.sheetDim
              optical: true
            }

            Column {
              width: parent.width - fitGlyph.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter

              Text {
                width: parent.width
                text: Catalog.summary(root.app)
                wrapMode: Text.WordWrap
                font.family: tokens.fontFamily
                font.pixelSize: tokens.fontSize
                font.weight: tokens.textWeight
                color: tokens.sheetForeground
              }

              Text {
                width: parent.width
                visible: !!root.fit
                text: "Tested on a phone-sized screen."
                font.family: tokens.fontFamily
                font.pixelSize: tokens.fontCaption
                font.weight: tokens.textWeight
                color: tokens.sheetDim
              }
            }
          }

          Repeater {
            model: root.fit ? root.fit.notes.slice(0, 4) : []

            delegate: Row {
              id: note
              required property string modelData
              width: fitColumn.width
              spacing: tokens.space(8)

              Rectangle {
                y: Math.round(noteText.font.pixelSize * 0.6)
                width: tokens.space(4)
                height: width
                radius: width / 2
                color: tokens.sheetDim
              }

              Text {
                id: noteText
                width: parent.width - tokens.space(12)
                text: note.modelData
                wrapMode: Text.WordWrap
                font.family: tokens.fontFamily
                font.pixelSize: tokens.fontCaption
                font.weight: tokens.textWeight
                color: tokens.sheetDim
              }
            }
          }

          Text {
            width: parent.width
            visible: text !== ""
            text: root.fit ? root.fit.summary || "" : ""
            wrapMode: Text.WordWrap
            lineHeight: 1.1
            font.family: tokens.fontFamily
            font.pixelSize: tokens.fontCaption
            font.weight: tokens.textWeight
            color: tokens.sheetDim
          }
        }
      }

      Text {
        x: root.side
        width: parent.width - 2 * root.side
        text: root.app ? root.app.description : ""
        wrapMode: Text.WordWrap
        lineHeight: 1.15
        font.family: tokens.fontFamily
        font.pixelSize: tokens.fontSize
        font.weight: tokens.textWeight
        color: tokens.sheetForeground
      }

      // The small print.
      Column {
        id: facts
        x: root.side
        width: parent.width - 2 * root.side

        Repeater {
          model: !root.app ? [] : [
            ["Version", root.app.version],
            ["Package", root.app.pkg],
            ["Source", Catalog.source(root.app.aurUrl)]
          ].filter(function (r) { return r[1] !== "" && r[1] !== undefined })

          delegate: Item {
            id: fact
            required property var modelData
            readonly property bool link: modelData[0] === "Source"
            width: facts.width
            height: tokens.space(36)

            Rectangle {
              anchors.top: parent.top
              width: parent.width
              height: 1
              color: tokens.alpha(tokens.sheetForeground, 0.08)
            }

            Text {
              id: key
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: fact.modelData[0]
              font.family: tokens.fontFamily
              font.pixelSize: tokens.fontCaption
              font.weight: tokens.textWeight
              color: tokens.sheetDim
            }

            Text {
              anchors.right: parent.right
              anchors.left: key.right
              anchors.leftMargin: tokens.space(16)
              anchors.verticalCenter: parent.verticalCenter
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideMiddle
              text: String(fact.modelData[1])
              font.family: tokens.fontFamily
              font.pixelSize: tokens.fontCaption
              font.weight: tokens.textWeight
              color: fact.link ? tokens.accent : tokens.sheetForeground
            }

            // The AUR page: the recipe it is built from, and its comments.
            TouchArea {
              anchors.fill: parent
              interactive: fact.link
              onTapped: root.source()
            }
          }
        }
      }
    }
  }

  // Back, over the hero. On the hero's own dark scrim rather than on the
  // sheet: it has to read on whatever the screenshot is.
  Rectangle {
    x: tokens.space(20)
    y: tokens.space(16)
    width: tokens.space(40)
    height: width
    radius: width / 2
    color: backTouch.lit ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0, 0, 0, 0.42)
    opacity: flick.contentY > tokens.space(120) ? 0 : 1
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Glyph {
      anchors.centerIn: parent
      text: Glyphs.BACK
      fontSize: tokens.iconSizeLarge
      color: "white"
      optical: true
    }

    TouchArea {
      id: backTouch
      anchors.fill: parent
      anchors.margins: -tokens.space(4)
      onTapped: root.back()
    }
  }
}
