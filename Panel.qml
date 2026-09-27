pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "Hues.js" as Hues
import "Catalog.js" as Catalog
import "Glyphs.js" as Glyphs

// App Finder: apps from the AUR, and how each one did when it was tried on a
// phone-sized screen.
//
// The top of Browse is a row of phone screenshots of the ones that work;
// below it every app is a row with its icon, or a two-letter monogram when
// the test run had none. An app that does not fit a phone is not hidden from
// a search, but the list keeps them folded away at the end.
//
// One window, and the process ends with it: shell.qml runs this as its own
// Quickshell process. The list, the pictures and the installs are
// libexec/app-finder-helper's; this runs it and keeps the answers.
Item {
  id: root

  Tokens { id: tokens }

  property string page: "browse"      // browse | installed
  property string detailId: ""
  property string query: ""
  property bool showUnfit: false
  property real now: Date.now()

  // A window closed with an install still going hides, and the process ends
  // once the install has: killing yay half-way leaves a half-built package.
  property bool closing: false
  signal quit()

  // ------------------------------------------------------------ the list

  property var apps: []
  property bool loading: false
  property string error: ""
  property bool offline: false
  property real fetchedAt: 0

  // pkg -> installed, as a finished job left it, until the next catalogue
  // (which asks pacman) says so itself.
  property var overrides: ({})

  function isInstalled(id) {
    if (root.overrides[id] !== undefined) return root.overrides[id]
    var app = root.byId[id]
    return !!app && app.installed === true
  }

  readonly property var sorted: Catalog.sorted(root.apps)
  readonly property var byId: {
    var out = {}
    for (var i = 0; i < root.sorted.length; i++) out[root.sorted[i].id] = root.sorted[i]
    return out
  }
  readonly property var featured: Catalog.featured(root.sorted, 12)
  readonly property var filtered: Catalog.filter(root.sorted, root.query, root.showUnfit)
  readonly property bool browsing: root.query === ""

  readonly property var installedApps: {
    var out = []
    for (var i = 0; i < root.sorted.length; i++)
      if (root.isInstalled(root.sorted[i].id)) out.push(root.sorted[i])
    return out
  }

  readonly property var detailApp: root.byId[root.detailId] || null

  // The search field lives in the list's header, a component of its own, so
  // its id is not reachable from here; it hands itself over instead.
  property var searchField: null

  function show(id) {
    root.detailId = id
    if (root.searchField) root.searchField.release()
  }

  function openApp(id) {
    var app = root.byId[id]
    if (!app) return
    var desktop = String(app.desktop || "").replace(/\.desktop$/, "")
    var entry = (desktop !== "" ? DesktopEntries.byId(desktop) : null) || DesktopEntries.heuristicLookup(app.pkg)
    if (entry) entry.execute()
  }

  function openSource(id) {
    var app = root.byId[id]
    if (app && app.aurUrl) Quickshell.execDetached(["xdg-open", app.aurUrl])
  }

  // Back: the page first, then the search, then the tab. Never the window.
  function back() {
    if (root.detailId !== "") root.detailId = ""
    else if (root.query !== "") { if (root.searchField) root.searchField.clear() }
    else if (root.page !== "browse") root.page = "browse"
  }

  function present() {
    root.closing = false
    root.now = Date.now()
    appWindow.visible = true
    root.refresh(false)
  }

  Component.onCompleted: root.present()

  // ------------------------------------------------------------ the helper

  // Next to this file in a checkout, in /usr/lib when packaged.
  readonly property string helper: {
    var env = Quickshell.env("APP_FINDER_HELPER")
    return env ? env : String(Qt.resolvedUrl("libexec/app-finder-helper")).replace(/^file:\/\//, "")
  }

  function helperCommand(args) {
    return ["sh", "-c",
      "h=$1; shift; [ -x \"$h\" ] || h=/usr/lib/app-finder/app-finder-helper; exec \"$h\" \"$@\"",
      "sh", root.helper].concat(args)
  }

  property bool refreshQueued: false
  property bool refreshForce: false

  function refresh(force) {
    if (catalog.running) {
      root.refreshQueued = true
      root.refreshForce = root.refreshForce || !!force
      return
    }
    root.loading = true
    catalog.command = root.helperCommand(["catalog"].concat(force ? ["--refresh"] : []))
    catalog.running = true
  }

  // The last document taken, so an unchanged list -- which is most opens --
  // does not hand the list a new array and throw its scroll away.
  property string lastText: ""

  function take(text) {
    if (text === root.lastText && root.error === "") return
    var doc
    try { doc = JSON.parse(text) } catch (e) {
      root.error = "The list of apps could not be read."
      return
    }
    if (!doc.ok) {
      root.error = doc.error || "The list of apps could not be reached."
      return
    }
    var apps = doc.apps || []
    for (var i = 0; i < apps.length; i++) {
      apps[i].initials = Hues.initials(apps[i].name)
      apps[i].accent = ""
    }
    root.lastText = text
    root.error = ""
    root.offline = doc.offline === true
    root.fetchedAt = doc.fetchedAt || 0
    root.overrides = ({})
    root.apps = apps
    // Pictures the new document names and the disk does not have yet. Cheap
    // when there are none, so after every change rather than once a session:
    // a re-tested app's screens arrive with its rating.
    if (!root.offline && !thumbs.running) thumbs.running = true
  }

  Process {
    id: catalog
    stdout: StdioCollector { onStreamFinished: root.take(text) }
    stderr: SplitParser { onRead: line => console.warn("app-finder:", line) }
    onExited: (exitCode) => {
      root.loading = false
      if (exitCode !== 0 && root.apps.length === 0 && root.error === "")
        root.error = "The list of apps could not be loaded."
      // Later: a Process is not restarted from inside its own exit.
      if (root.refreshQueued) {
        var force = root.refreshForce
        root.refreshQueued = false
        root.refreshForce = false
        Qt.callLater(root.refresh, force)
      }
    }
  }

  // The pictures then come off the disk. Not read back in straight away -- a
  // new array under the list would jump it to the top under a thumb that is
  // scrolling it -- but the next catalogue swaps the URLs for file:// ones.
  Process {
    id: thumbs
    command: root.helperCommand(["thumbs"])
  }

  // ------------------------------------------------------------ jobs

  // id -> { action: "install"|"remove", state: "queued"|"running"|"error",
  //         step, text, progress, error }. Replaced whole on every change so
  // bindings on it re-run. A job that succeeds is dropped. One at a time, in
  // the order asked: pacman holds a lock, and a second install would fail on
  // it.
  property var jobs: ({})
  property var queue: []
  property string current: ""
  readonly property bool working: root.current !== "" || root.queue.length > 0

  function setJob(id, patch) {
    var next = {}
    for (var k in root.jobs) next[k] = root.jobs[k]
    if (patch === null) delete next[id]
    else {
      var job = {}
      var old = next[id] || {}
      for (var a in old) job[a] = old[a]
      for (var b in patch) job[b] = patch[b]
      next[id] = job
    }
    root.jobs = next
  }

  function enqueue(action, id) {
    var job = root.jobs[id]
    if (job && (job.state === "queued" || job.state === "running")) return
    root.setJob(id, { action: action, state: "queued", step: "", error: "",
                      text: "Waiting…", progress: 0.05 })
    root.queue = root.queue.concat([{ action: action, id: id }])
    root.next()
  }

  function install(id) { root.dismiss(id); root.enqueue("install", id) }
  function remove(id) { root.enqueue("remove", id) }
  function dismiss(id) {
    var job = root.jobs[id]
    if (job && job.state === "error") root.setJob(id, null)
  }

  function next() {
    if (jobProcess.running || root.queue.length === 0) return
    var head = root.queue[0]
    root.queue = root.queue.slice(1)
    root.current = head.id
    root.setJob(head.id, { state: "running", text: head.action === "install" ? "Starting…" : "Removing…",
                           progress: 0.08 })
    jobProcess.action = head.action
    jobProcess.command = root.helperCommand([head.action, head.id])
    jobProcess.running = true
  }

  function handle(line) {
    var ev
    try { ev = JSON.parse(line) } catch (e) { return }
    var id = root.current
    if (ev.done) {
      if (ev.ok) {
        root.setJob(id, null)
        var o = {}
        for (var k in root.overrides) o[k] = root.overrides[k]
        o[id] = jobProcess.action === "install"
        root.overrides = o
      } else {
        root.setJob(id, { state: "error", error: ev.error || "Something went wrong." })
      }
      return
    }
    // yay does not print its stages in one order -- it reads the recipe,
    // installs what the build needs, then builds -- so a step that would move
    // the bar backwards is not news.
    var job = root.jobs[id]
    if (job && (ev.progress || 0) < (job.progress || 0)) return
    root.setJob(id, { step: ev.step || "", text: ev.text || "", progress: ev.progress || 0 })
  }

  Process {
    id: jobProcess
    property string action: ""
    stdout: SplitParser { onRead: line => root.handle(line) }
    stderr: SplitParser { onRead: line => console.warn("app-finder:", line) }
    onExited: (exitCode) => {
      var id = root.current
      var left = root.jobs[id]
      // Died without saying done.
      if (left && left.state === "running")
        root.setJob(id, { state: "error",
                          error: exitCode === 127 ? "The App Finder helper is missing." : "It stopped before it finished." })
      root.current = ""
      // pacman is the one that knows what is installed now.
      Qt.callLater(root.refresh, false)
      Qt.callLater(root.next)
    }
  }

  onWorkingChanged: if (!root.working && root.closing) root.quit()

  // ------------------------------------------------------------ outside

  // `app-finder` a second time: bring this window back rather than start
  // another process (bin/app-finder asks here first).
  IpcHandler {
    target: "app-finder"

    function show(): string { root.present(); return "ok" }

    function state(): string {
      return "visible=" + (appWindow.visible ? 1 : 0)
        + " page=" + root.page
        + " detail=" + (root.detailId === "" ? "-" : root.detailId)
        + " query=" + (root.query === "" ? "-" : root.query)
        + " apps=" + root.apps.length
        + " listed=" + root.filtered.apps.length
        + " folded=" + root.filtered.hidden
        + " featured=" + root.featured.length
        + " installed=" + root.installedApps.length
        + " loading=" + (root.loading ? 1 : 0)
        + " offline=" + (root.offline ? 1 : 0)
        + " current=" + (root.current === "" ? "-" : root.current)
        + " layout=" + (root.compact ? "phone" : root.split ? "split" : "desktop")
        + " size=" + stage.width + "x" + stage.height
        + " searchFocus=" + (root.searchField && root.searchField.active ? 1 : 0)
        + " focusItem=" + String(stage.Window.activeFocusItem).split("(")[0]
        + " error=" + (root.error === "" ? "-" : root.error)
    }

    function jobs(): string { return JSON.stringify(root.jobs) }
    function open(id: string): string { root.show(id); return root.detailApp ? root.detailApp.name : "unknown" }
    function page(name: string): string { root.detailId = ""; root.page = name; return root.page }
    function type(text: string): string { if (root.searchField) root.searchField.text = text; return String(root.filtered.apps.length) }
    function back(): string { root.back(); return "ok" }
    function refresh(): string { root.refresh(true); return "refreshing" }
    function install(id: string): string { root.install(id); return "queued" }
    function remove(id: string): string { root.remove(id); return "queued" }
    function glyphs(): string { return Glyphs.listing() }
  }

  // ------------------------------------------------------------ the window

  // Laid out from the window's own width, not from what it runs on: a phone
  // app below 720 -- a list, pages that slide over it -- and above it a
  // desktop app, with a rail, a grid of cards, and from 1100 the app's page
  // beside the grid instead of over it.
  readonly property bool compact: stage.width < 720
  readonly property bool split: stage.width >= 1100
  readonly property int railWidth: 220
  readonly property int paneWidth: 440

  FloatingWindow {
    id: appWindow
    visible: false
    title: "App Finder"
    color: tokens.sheetOpaque
    implicitWidth: 1180
    implicitHeight: 820
    minimumSize: Qt.size(340, 480)

    // Closed by the window manager: the end of the app, once nothing is
    // being installed.
    onVisibleChanged: if (!visible) {
      root.closing = true
      if (!root.working) root.quit()
    }

    FocusScope {
      id: stage
      anchors.fill: parent
      focus: true

      Keys.onEscapePressed: root.back()
      // "/" to search, from anywhere a field is not already taking the key.
      Keys.onPressed: function (event) {
        if (event.text === "/" && root.searchField && root.page === "browse") {
          root.detailId = root.split ? root.detailId : ""
          root.searchField.takeFocus()
          event.accepted = true
        }
      }

      // ---------------------------------------------------------- the rail

      Rectangle {
        id: rail
        visible: !root.compact
        width: visible ? root.railWidth : 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: tokens.sheetCard

        Column {
          anchors.fill: parent
          anchors.margins: tokens.space(12)
          spacing: tokens.space(4)

          Label {
            x: tokens.space(8)
            height: tokens.space(52)
            verticalAlignment: Text.AlignVCenter
            text: "App Finder"
            font.pixelSize: tokens.space(22)
            font.weight: Font.Medium
          }

          Repeater {
            model: [
              { key: "browse", label: "Browse", glyph: Glyphs.MAGNIFY, count: root.apps.length },
              { key: "installed", label: "Installed", glyph: Glyphs.DOWNLOAD, count: root.installedApps.length }
            ]

            delegate: Rectangle {
              id: navItem
              required property var modelData
              readonly property bool selected: root.page === modelData.key
              width: parent.width
              height: tokens.space(40)
              radius: tokens.radiusCard
              color: navItem.selected ? tokens.alpha(tokens.accent, 0.14)
                : navTouch.lit ? tokens.sheetPressed
                : navTouch.containsMouse ? tokens.alpha(tokens.sheetForeground, 0.05)
                : "transparent"

              Row {
                anchors.left: parent.left
                anchors.leftMargin: tokens.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: tokens.space(8)

                Glyph {
                  anchors.verticalCenter: parent.verticalCenter
                  text: navItem.modelData.glyph
                  color: navItem.selected ? tokens.accent : tokens.sheetDim
                }

                Label {
                  anchors.verticalCenter: parent.verticalCenter
                  text: navItem.modelData.label
                  color: navItem.selected ? tokens.accent : tokens.sheetForeground
                }
              }

              Label {
                anchors.right: parent.right
                anchors.rightMargin: tokens.space(12)
                anchors.verticalCenter: parent.verticalCenter
                visible: navItem.modelData.count > 0
                text: navItem.modelData.count
                role: "caption"
                tone: "dim"
              }

              TouchArea {
                id: navTouch
                anchors.fill: parent
                onTapped: {
                  if (!root.split) root.detailId = ""
                  root.page = navItem.modelData.key
                }
              }
            }
          }
        }

        // Offline, at the foot of the rail rather than over the grid.
        Label {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: tokens.space(20)
          visible: root.offline
          wrapMode: Text.WordWrap
          elide: Text.ElideNone
          role: "caption"
          tone: "dim"
          text: "Offline · updated " + Catalog.ago(root.fetchedAt, root.now)
        }
      }

      // ---------------------------------------------------------- the list

      Item {
        id: main
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: rail.right
        anchors.right: root.split && root.detailApp ? pane.left : parent.right

        // The desktop's search and heading, above the grid.
        Item {
          id: topBar
          visible: !root.compact
          width: parent.width
          height: visible ? tokens.space(72) : 0

          Label {
            anchors.left: parent.left
            anchors.leftMargin: tokens.space(24)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.page === "installed"
            text: "Installed"
            font.pixelSize: tokens.space(22)
            font.weight: Font.Medium
          }

          Loader {
            anchors.left: parent.left
            anchors.leftMargin: tokens.space(18)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - tokens.space(36), tokens.space(520))
            active: !root.compact && root.page === "browse"
            visible: active
            sourceComponent: searchComponent
          }
        }

        Component {
          id: searchComponent

          SearchField {
            id: field
            glyph: Glyphs.MAGNIFY
            clearGlyph: Glyphs.CLOSE
            placeholder: root.apps.length > 0 ? "Search " + root.apps.length + " apps" : "Search apps"
            onTextChanged: root.query = text
            Component.onCompleted: {
              text = root.query
              root.searchField = field
            }
            Component.onDestruction: if (root.searchField === field) root.searchField = null
          }
        }

        GridView {
          id: list
          anchors.top: topBar.bottom
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: root.compact ? 0 : tokens.space(12)
          anchors.rightMargin: root.compact ? 0 : tokens.space(12)
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          // One column on a phone, which is a list; as many 320-wide cards as
          // fit on a desktop.
          readonly property int columns: root.compact ? 1 : Math.max(1, Math.floor(width / tokens.space(320)))
          cellWidth: Math.floor(width / columns)
          cellHeight: root.compact ? tokens.space(68) : tokens.space(84)

          // Opening the page beside the grid takes a column away, and the
          // reflow would leave the scroll wherever it lands. Keep the app
          // whose page is open in view instead.
          function reveal() {
            var values = root.page === "browse" ? root.filtered.apps : root.installedApps
            for (var i = 0; i < values.length; i++)
              if (values[i].id === root.detailId) { list.positionViewAtIndex(i, GridView.Contain); return }
          }
          onColumnsChanged: if (root.detailId !== "") Qt.callLater(list.reveal)

          // A ScriptModel and not the array itself. A view given a new model
          // makes item 0 current and gives it focus, and every keystroke in
          // the search makes a new array -- so the field in the header would
          // lose focus after each character. This one stays put and has items
          // inserted and removed instead.
          model: ScriptModel {
            values: root.page === "browse" ? root.filtered.apps : root.installedApps
          }
          cacheBuffer: tokens.space(600)
          // No current item either: a current item is an item with focus.
          currentIndex: -1
          keyNavigationEnabled: false

          header: Column {
            width: list.width
            spacing: 0

            // A view holds its first item still when the header above it
            // grows, so the carousel arriving would scroll the title, the
            // search and the carousel itself off the top. Nobody is reading
            // the list while the header is still settling.
            onHeightChanged: if (!list.moving && !list.dragging) list.positionViewAtBeginning()

            // The phone's title and tabs; the desktop has its rail.
            Item {
              visible: root.compact
              width: parent.width
              height: visible ? tokens.tapSlot + tokens.space(12) : 0

              Label {
                anchors.left: parent.left
                anchors.leftMargin: tokens.phoneSide
                anchors.verticalCenter: parent.verticalCenter
                text: "App Finder"
                font.pixelSize: tokens.phoneTitle
                font.weight: Font.Medium
              }

              Row {
                anchors.right: parent.right
                anchors.rightMargin: tokens.space(8)
                anchors.verticalCenter: parent.verticalCenter

                Button {
                  text: "Browse"
                  tone: root.page === "browse" ? "ink" : "dim"
                  onTapped: root.page = "browse"
                }

                Button {
                  text: root.installedApps.length > 0 ? "Installed · " + root.installedApps.length : "Installed"
                  tone: root.page === "installed" ? "ink" : "dim"
                  onTapped: root.page = "installed"
                }
              }
            }

            Loader {
              x: tokens.space(12)
              width: parent.width - 2 * x
              active: root.compact && root.page === "browse"
              visible: active
              sourceComponent: searchComponent
            }

            // Offline, or the list could not be reached at all.
            Item {
              width: parent.width
              height: visible ? tokens.space(34) : 0
              visible: root.compact && (root.offline || (root.error !== "" && root.apps.length > 0))

              Row {
                anchors.left: parent.left
                anchors.leftMargin: tokens.phoneSide
                anchors.verticalCenter: parent.verticalCenter
                spacing: tokens.space(6)

                Glyph {
                  anchors.verticalCenter: parent.verticalCenter
                  text: Glyphs.OFFLINE
                  fontSize: tokens.fontCaption
                  color: tokens.sheetDim
                }

                Label {
                  anchors.verticalCenter: parent.verticalCenter
                  role: "caption"
                  tone: "dim"
                  text: "Offline · updated " + Catalog.ago(root.fetchedAt, root.now)
                }
              }
            }

            // ------------------------------------------------ the carousel

            Column {
              width: parent.width
              visible: root.page === "browse" && root.browsing && root.featured.length > 0
              topPadding: root.compact ? tokens.space(18) : 0
              spacing: tokens.space(10)

              Text {
                visible: !root.compact
                x: tokens.space(12)
                text: "Works well on a phone"
                font.family: tokens.studioFontFamily
                font.pixelSize: tokens.phoneAppText
                font.weight: Font.DemiBold
                color: tokens.sheetForeground
              }

              ListView {
                id: carousel
                width: parent.width
                // Two and a bit phones across on a phone: the next one peeking
                // in says the row swipes. No bigger than a phone's worth on a
                // desktop window, where more of them fit.
                readonly property int cardWidth: Math.min(tokens.space(170), Math.round((width - tokens.space(12)) * 0.4))
                readonly property int cardHeight: Math.round(cardWidth * Catalog.SHOT_RATIO)
                height: cardHeight + tokens.space(50)
                orientation: ListView.Horizontal
                spacing: tokens.space(12)
                leftMargin: root.compact ? tokens.space(16) : tokens.space(12)
                rightMargin: leftMargin
                boundsBehavior: Flickable.StopAtBounds
                model: root.featured
                // A list that changes under the row starts it over rather
                // than keeping an offset into the old one.
                // positionViewAtBeginning() would put the first card on the
                // edge, inside leftMargin.
                onModelChanged: Qt.callLater(function () { carousel.contentX = carousel.originX - carousel.leftMargin })

                // A mouse wheel scrolls the page, not the row: a desktop row
                // that ate the wheel would stop the page under the pointer.
                WheelHandler {
                  acceptedDevices: PointerDevice.Mouse
                  onWheel: (event) => {
                    list.contentY = Math.max(list.originY, Math.min(list.contentY - event.angleDelta.y,
                      list.originY + list.contentHeight - list.height))
                  }
                }

                delegate: Column {
                  id: phoneCard
                  required property var modelData
                  required property int index
                  width: carousel.cardWidth
                  spacing: tokens.space(8)

                  // Every screen the test run took, in turn, while the row is
                  // what is on show; a card a beat behind the one before it.
                  PreviewCard {
                    width: parent.width
                    ratio: Catalog.SHOT_RATIO
                    outlined: true
                    sources: phoneCard.modelData.phoneShots || []
                    cycling: appWindow.visible && (root.split || root.detailId === "") && root.page === "browse" && root.browsing
                    cycleDelay: phoneCard.index * 900
                    decodeWidth: 540
                    initials: phoneCard.modelData.initials
                    accent: phoneCard.modelData.accent
                    key: phoneCard.modelData.id
                    onTapped: root.show(phoneCard.modelData.id)
                  }

                  Column {
                    width: parent.width

                    Text {
                      width: parent.width
                      text: phoneCard.modelData.name
                      elide: Text.ElideRight
                      font.family: tokens.fontFamily
                      font.pixelSize: tokens.fontSize
                      font.weight: tokens.textWeight
                      color: tokens.sheetForeground
                    }

                    Text {
                      width: parent.width
                      text: phoneCard.modelData.description
                      elide: Text.ElideRight
                      font.family: tokens.fontFamily
                      font.pixelSize: tokens.fontCaption
                      font.weight: tokens.textWeight
                      color: tokens.sheetDim
                    }
                  }
                }
              }
            }

            // ------------------------------------------------ the list title

            Item {
              width: parent.width
              height: tokens.space(40)
              visible: list.count > 0 && (root.compact || root.page === "browse")

              Text {
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? tokens.phoneSide : tokens.space(12)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: tokens.space(6)
                text: root.page === "installed" ? "Installed"
                  : root.query !== "" ? (list.count === 1 ? "1 app" : list.count + " apps")
                  : "All apps"
                font.family: tokens.studioFontFamily
                font.pixelSize: tokens.phoneAppText
                font.weight: Font.DemiBold
                color: tokens.sheetForeground
              }
            }
          }

          delegate: Item {
            id: cell
            required property var modelData
            width: list.cellWidth
            height: list.cellHeight

            AppRow {
              anchors.fill: parent
              anchors.margins: root.compact ? 0 : tokens.space(6)
              card: !root.compact
              app: cell.modelData
              installed: root.isInstalled(cell.modelData.id)
              job: root.jobs[cell.modelData.id] || null
              selected: !root.compact && root.detailId === cell.modelData.id
              onTapped: root.show(cell.modelData.id)
            }
          }

          // The ones that do not fit a phone, folded away.
          footer: Item {
            width: list.width
            height: fold.visible ? tokens.space(72) : tokens.space(24)

            Button {
              id: fold
              anchors.centerIn: parent
              visible: root.page === "browse" && root.query === ""
                && (root.filtered.hidden > 0 || root.showUnfit)
              tone: "dim"
              glyph: root.showUnfit ? Glyphs.LESS : Glyphs.MORE
              text: root.showUnfit ? "Hide the ones made for a desktop"
                : root.filtered.hidden + " more made for a desktop"
              onTapped: root.showUnfit = !root.showUnfit
            }
          }
        }

        // ---------------------------------------------- empty, loading, error

        Column {
          anchors.centerIn: parent
          width: Math.min(parent.width - 2 * tokens.phoneSide, tokens.space(420))
          spacing: tokens.space(12)
          visible: list.count === 0 && !(root.loading && root.apps.length === 0)

          Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.error !== "" && root.apps.length === 0 ? Glyphs.OFFLINE
              : root.page === "installed" ? Glyphs.DOWNLOAD : Glyphs.MAGNIFY
            fontSize: tokens.space(36)
            color: tokens.sheetDim
          }

          Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            tone: "dim"
            text: root.error !== "" && root.apps.length === 0 ? root.error
              : root.page === "installed" ? "None of these apps are installed yet."
              : "No apps match “" + root.query + "”."
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.error !== "" && root.apps.length === 0
            glyph: Glyphs.REFRESH
            text: "Try again"
            onTapped: root.refresh(true)
          }
        }

        // Skeleton rows while the first list is on its way.
        Column {
          id: skeleton
          y: root.compact ? tokens.space(170) : topBar.height + tokens.space(12)
          x: root.compact ? 0 : tokens.space(12)
          width: parent.width - 2 * x
          visible: root.loading && root.apps.length === 0 && root.page === "browse"

          SequentialAnimation on opacity {
            running: skeleton.visible
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.45; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 1; duration: 700; easing.type: Easing.InOutSine }
          }

          Repeater {
            model: 6
            delegate: Item {
              width: skeleton.width
              height: tokens.space(68)

              Rectangle {
                id: ghost
                x: tokens.space(14)
                anchors.verticalCenter: parent.verticalCenter
                width: tokens.space(44)
                height: width
                radius: tokens.radiusCard
                color: tokens.alpha(tokens.sheetForeground, 0.08)
              }

              Column {
                anchors.left: ghost.right
                anchors.leftMargin: tokens.space(14)
                anchors.verticalCenter: parent.verticalCenter
                spacing: tokens.space(8)

                Rectangle {
                  width: tokens.space(140)
                  height: tokens.space(10)
                  radius: height / 2
                  color: tokens.alpha(tokens.sheetForeground, 0.1)
                }

                Rectangle {
                  width: tokens.space(200)
                  height: tokens.space(8)
                  radius: height / 2
                  color: tokens.alpha(tokens.sheetForeground, 0.06)
                }
              }
            }
          }
        }
      }

      // ---------------------------------------------------------- an app

      // Beside the grid on a wide window. On a narrower one, over the list
      // rather than instead of it, so back lands on the row it left from with
      // the list where it was -- across the whole window on a phone, and
      // beside the rail, its content held to a readable width, on a desktop.
      Rectangle {
        id: pane
        width: root.split ? root.paneWidth : parent.width - rail.width
        height: parent.height
        color: tokens.sheetOpaque
        x: root.detailApp ? parent.width - width : parent.width
        visible: x < parent.width
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // The seam between the grid and the page, when they sit side by side.
        Rectangle {
          visible: root.split
          width: 1
          height: parent.height
          color: tokens.alpha(tokens.sheetForeground, 0.1)
        }

        // Kept after the page closes, so the slide out still has something on it.
        property var shown: null
        Connections {
          target: root
          function onDetailAppChanged() { if (root.detailApp) pane.shown = root.detailApp }
        }

        Detail {
          width: Math.min(parent.width, tokens.space(760))
          height: parent.height
          anchors.horizontalCenter: parent.horizontalCenter
          app: pane.shown
          installed: !!pane.shown && root.isInstalled(pane.shown.id)
          job: pane.shown ? (root.jobs[pane.shown.id] || null) : null
          closeGlyph: root.split
          onBack: root.detailId = ""
          onInstall: root.install(pane.shown.id)
          onRetry: root.install(pane.shown.id)
          onRemove: root.remove(pane.shown.id)
          onOpen: root.openApp(pane.shown.id)
          onSource: root.openSource(pane.shown.id)
        }
      }
    }
  }
}
