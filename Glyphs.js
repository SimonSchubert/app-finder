.pragma library

// Every glyph App Finder draws, by its md- name, checked against the cmap and
// post table of the JetBrainsMono Nerd Font it renders with.

var MAGNIFY  = "󰍉"   // U+F0349  md-magnify
var CLOSE    = "󰅖"   // U+F0156  md-close
var BACK     = "󰁍"   // U+F004D  md-arrow_left
var DOWNLOAD = "󰇚"   // U+F01DA  md-download
var REMOVE   = "󰩺"   // U+F0A7A  md-trash_can_outline
var OPEN     = "󰏌"   // U+F03CC  md-open_in_new
var CHECK    = "󰄬"   // U+F012C  md-check
var ALERT    = "󰗖"   // U+F05D6  md-alert_circle_outline
var OFFLINE  = "󰅤"   // U+F0164  md-cloud_off_outline
var REFRESH  = "󰑐"   // U+F0450  md-refresh
var MORE     = "󰅀"   // U+F0140  md-chevron_down
var LESS     = "󰅃"   // U+F0143  md-chevron_up
var PHONE_OK = "󱟽"   // U+F17FD  md-cellphone_check
var DESKTOP  = "󰍹"   // U+F0379  md-monitor

var TABLE = [
  ["md-magnify", "U+F0349", MAGNIFY],
  ["md-close", "U+F0156", CLOSE],
  ["md-arrow_left", "U+F004D", BACK],
  ["md-download", "U+F01DA", DOWNLOAD],
  ["md-trash_can_outline", "U+F0A7A", REMOVE],
  ["md-open_in_new", "U+F03CC", OPEN],
  ["md-check", "U+F012C", CHECK],
  ["md-alert_circle_outline", "U+F05D6", ALERT],
  ["md-cloud_off_outline", "U+F0164", OFFLINE],
  ["md-refresh", "U+F0450", REFRESH],
  ["md-chevron_down", "U+F0140", MORE],
  ["md-chevron_up", "U+F0143", LESS],
  ["md-cellphone_check", "U+F17FD", PHONE_OK],
  ["md-monitor", "U+F0379", DESKTOP]
]

function listing() {
  var out = []
  for (var i = 0; i < TABLE.length; i++)
    out.push(TABLE[i][0] + "\t" + TABLE[i][1] + "\t" + TABLE[i][2])
  return out.join("\n")
}
