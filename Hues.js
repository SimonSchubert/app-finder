.pragma library

// Six hues for the monograms of apps without an icon, picked by the app's id
// so the same app gets the same one every time. What keeps them from fighting
// the theme is how they are used: Monogram draws the hue at low alpha over the
// sheet and tints its letters toward the sheet's own ink.
//
// Mid-saturation on purpose. Six loud hues down a list read as a sweet shop.

var TABLE = {
  cyan:   "#56b6c2",
  rose:   "#e06c8c",
  lime:   "#98c379",
  coral:  "#e5886a",
  amber:  "#e5c07b",
  violet: "#b48ead"
}

var NAMES = ["cyan", "rose", "lime", "coral", "amber", "violet"]

// No name: a hue from the id, the same one every time.
function forKey(key) {
  var s = String(key || ""), h = 0
  for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0
  return NAMES[Math.abs(h) % NAMES.length]
}

function of(name, key) {
  return TABLE[String(name || "").toLowerCase()] || TABLE[forKey(key)]
}

// Two letters for something with only a name: its first two words' first
// letters, or the first letter alone.
function initials(name) {
  var words = String(name || "").replace(/[^A-Za-z0-9 ]+/g, " ").trim().split(/\s+/)
  if (!words.length || words[0] === "") return "?"
  var out = words[0].charAt(0) + (words.length > 1 ? words[1].charAt(0) : "")
  return out.toUpperCase()
}
