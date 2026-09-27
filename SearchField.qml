import QtQuick

// The search box: a glyph, the text, and a clear button once there is text.
// Focus only when pressed, so a phone's keyboard comes up because somebody
// asked for it.
Item {
  id: root

  Tokens { id: tokens }

  property string placeholder: ""
  property string glyph: ""
  property string clearGlyph: ""

  property alias text: input.text
  readonly property bool active: input.activeFocus

  function takeFocus() { input.forceActiveFocus() }
  function release() { input.focus = false }
  function clear() { input.text = "" }

  implicitHeight: tokens.tapSlot

  Card {
    anchors.fill: parent
    border.width: 1
    border.color: input.activeFocus ? tokens.accent : "transparent"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.takeFocus()
  }

  Glyph {
    id: mark
    anchors.left: parent.left
    anchors.leftMargin: tokens.space(12)
    anchors.verticalCenter: parent.verticalCenter
    visible: root.glyph !== ""
    text: root.glyph
    color: tokens.sheetDim
  }

  Button {
    id: clear
    anchors.right: parent.right
    anchors.rightMargin: tokens.space(2)
    anchors.verticalCenter: parent.verticalCenter
    visible: root.clearGlyph !== "" && input.text !== ""
    width: visible ? implicitWidth : 0
    glyph: root.clearGlyph
    tone: "dim"
    onTapped: root.clear()
  }

  TextInput {
    id: input
    anchors.left: mark.right
    anchors.leftMargin: root.glyph !== "" ? tokens.space(10) : tokens.space(12)
    anchors.right: clear.left
    anchors.rightMargin: tokens.space(6)
    anchors.verticalCenter: parent.verticalCenter
    font.family: tokens.fontFamily
    font.pixelSize: tokens.fontSize
    color: tokens.sheetForeground
    selectionColor: tokens.alpha(tokens.accent, 0.35)
    selectedTextColor: tokens.sheetForeground
    clip: true
    selectByMouse: true
    inputMethodHints: Qt.ImhNoPredictiveText
    Keys.onEscapePressed: (event) => { event.accepted = false; root.release() }
  }

  Label {
    anchors.fill: input
    verticalAlignment: Text.AlignVCenter
    visible: input.text === "" && !input.activeFocus
    text: root.placeholder
    tone: "dim"
  }
}
