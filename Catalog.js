.pragma library

// What App Finder does with the list: order it, filter it, and say in words
// what the phone test run found. Plain functions over the array Panel.qml
// holds, so the screens only bind.

// Best first. An app nobody has rated sits between the ones that work and
// the ones that do not: not knowing is better than knowing it is bad.
var RANK = { "perfect": 0, "usable": 1, "": 2, "desktop only": 3, "not usable": 4, "broken": 5 }

function rating(app) {
  return app && app.fit ? String(app.fit.rating || "") : ""
}

function rank(app) {
  var r = RANK[rating(app)]
  return r === undefined ? 2 : r
}

// Worth showing without asking: it works, or nobody knows yet.
function fits(app) { return rank(app) <= 2 }

// Ours first, in the order the data repo's recommended.json gives them; then
// the tested rest, best fit first.
function sorted(apps) {
  var out = (apps || []).slice()
  out.sort(function (a, b) {
    if (!!a.recommended !== !!b.recommended) return a.recommended ? -1 : 1
    if (a.recommended) return (a.rank || 0) - (b.rank || 0)
    var d = rank(a) - rank(b)
    if (d) return d
    return String(a.name).toLowerCase() < String(b.name).toLowerCase() ? -1 : 1
  })
  return out
}

// The carousel: the recommended ones when the data repo names any -- the row
// is headed "Recommended", so nothing else belongs in it -- and otherwise the
// ones that work, with a phone screenshot to show.
function featured(apps, max) {
  var out = [], limit = max || 12, i, a
  for (i = 0; i < apps.length; i++) {
    a = apps[i]
    if (a.recommended && a.phoneShots && a.phoneShots.length) out.push(a)
  }
  if (out.length) return out
  for (i = 0; i < apps.length && out.length < limit; i++) {
    a = apps[i]
    if (rank(a) <= 1 && a.phoneShots && a.phoneShots.length) out.push(a)
  }
  return out
}

function hasRecommended(apps) {
  for (var i = 0; i < (apps || []).length; i++) if (apps[i].recommended) return true
  return false
}

// A phone screenshot's height over its width: the phone's window, 356x728
// logical less its border. A shot cropped under a leftover notification is
// shorter, and the card crops it from the top.
var SHOT_RATIO = 1456 / 712

function matches(app, words) {
  var hay = (app.name + " " + app.pkg + " " + app.description).toLowerCase()
  for (var i = 0; i < words.length; i++) if (hay.indexOf(words[i]) < 0) return false
  return true
}

// The shelves, in the order the chips show them. The data repo files every
// app on one or more of them, by key.
var CATEGORIES = [
  { key: "games", label: "Games" },
  { key: "productivity", label: "Productivity" },
  { key: "media", label: "Media" },
  { key: "internet", label: "Internet" },
  { key: "graphics", label: "Graphics" },
  { key: "tools", label: "Tools" },
  { key: "education", label: "Education" },
  { key: "development", label: "Development" }
]

function inCategory(app, key) {
  return !key || (app.categories || []).indexOf(key) >= 0
}

function categoryLabel(key) {
  for (var i = 0; i < CATEGORIES.length; i++) if (CATEGORIES[i].key === key) return CATEGORIES[i].label
  return ""
}

// The shelves at least one of these apps is on: a chip that led to an empty
// list would be a dead end.
function categories(apps) {
  return CATEGORIES.filter(function (c) {
    for (var i = 0; i < (apps || []).length; i++) if (inCategory(apps[i], c.key)) return true
    return false
  })
}

// { apps, hidden }: what the list shows, and how many that do not fit a phone
// it is holding back. A search holds nothing back -- somebody who typed the
// name wants that app, whatever it scored.
function filter(apps, query, showUnfit, category) {
  var words = String(query || "").toLowerCase().split(/\s+/).filter(function (w) { return w !== "" })
  var out = [], hidden = 0
  for (var i = 0; i < apps.length; i++) {
    var a = apps[i]
    if (!inCategory(a, category)) continue
    if (words.length && !matches(a, words)) continue
    if (!words.length && !showUnfit && !fits(a)) { hidden++; continue }
    out.push(a)
  }
  return { apps: out, hidden: hidden }
}

// ----------------------------------------------------------------- words

// The badge: a word or two, and whether it is good news.
function badge(app) {
  if (app && app.recommended) return { text: "Recommended", tone: "good" }
  switch (rating(app)) {
  case "perfect": return { text: "Great fit", tone: "good" }
  case "usable": return { text: "Works", tone: "ok" }
  case "desktop only": return { text: "Desktop", tone: "dim" }
  case "not usable": return { text: "Poor fit", tone: "dim" }
  case "broken": return { text: "Broken", tone: "dim" }
  }
  return null
}

// The sentence on an app's page.
function summary(app) {
  switch (rating(app)) {
  case "perfect": return "Works well on a phone."
  case "usable": return "Works on a phone, with some rough edges."
  case "desktop only": return "Made for a desktop, not for a phone."
  case "not usable": return "Hard to use on a phone."
  case "broken": return "Did not start when it was tested."
  }
  return "Not tested on a phone yet."
}

// "3 min ago", "5 h ago", "2 days ago", from seconds since the epoch.
function ago(seconds, now) {
  if (!seconds) return ""
  var s = Math.max(0, Math.round(now / 1000 - seconds))
  if (s < 90) return "just now"
  if (s < 3600) return Math.round(s / 60) + " min ago"
  if (s < 86400 * 2) return Math.round(s / 3600) + " h ago"
  return Math.round(s / 86400) + " days ago"
}

// "aur.archlinux.org/packages/foo" for the facts table.
function source(url) {
  return String(url || "").replace(/^https?:\/\//, "").replace(/\.git$/, "")
}
