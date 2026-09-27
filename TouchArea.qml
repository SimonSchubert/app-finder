import QtQuick

// A tap target: `lit` while a finger or the mouse is down on it, `tapped`
// when it lifts inside. A drag that turns into a scroll is not a tap -- the
// Flickable under it steals the press, and nothing fires.
MouseArea {
  id: root

  property bool interactive: true
  readonly property bool lit: root.interactive && root.pressed

  signal tapped()

  enabled: root.interactive
  cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
  onClicked: root.tapped()
}
