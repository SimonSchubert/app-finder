# App Finder

Apps from the [AUR](https://aur.archlinux.org), and how each one did when it
was tried on a phone-sized screen. Browse the ones that fit a phone, see their
screenshots and what went wrong on the rest, and install or remove them.

App Finder is a [Quickshell](https://quickshell.org) app that runs as its own
process. It needs neither Omarchy nor Omarchy Mobile, but it was made for a
phone running them.

## Install

From the [AUR](https://aur.archlinux.org/packages/app-finder):

```sh
yay -S app-finder
```

## What it lists

Every AUR package the phone test run built and tried. Each one has:
- a rating: great fit, works, desktop only, poor fit or broken
- the run's notes
- up to three phone screenshots, and an icon cut from the first one

Anything that doesn't fit a phone is folded away at the end of the list, and a
search always finds it.

The recommended apps' screenshots are drawn in every theme Omarchy ships, and
App Finder shows the ones in the theme the phone is in
(`~/.local/state/omarchy/current/theme.name`), switching with it. Under any
other theme, or without Omarchy, it shows the app's plain screenshots.

Chips under the search narrow Browse to one category: Games, Productivity,
Media, Internet, Graphics, Tools, Education or Development. Each app's
categories come with the list; a chip shows only when some app is in its
category.

The list and pictures come from
[SimonSchubert/mobile-market-data](https://github.com/SimonSchubert/mobile-market-data)
(`aur/apps.json`, `aur/shots`, `aur/icons`). App Finder fetches them at most
hourly and caches them in `~/.cache/app-finder`, so a re-tested app shows up
without a new release. To read a different copy, put its URL in
`~/.config/app-finder/data-url` or set `APP_FINDER_DATA`.

## Installing apps

Install is the standard AUR install: `yay -S` builds the package on the
device, as you. yay needs root several times in one install: for the build's
dependencies, to mark them, and for the package itself. App Finder has it use
`app-finder-sudo` for those steps, which runs pacman through App Finder's own
polkit action (`auth_admin_keep`). The session's polkit agent asks for your
password once, and the later steps of that install reuse it. App Finder
answers yay's own questions for you (no diff or edit menus), so only install
what you trust. Remove runs `pacman -Rns` the same way.

App Finder only installs or removes a package that is on its list.

### Needs

- `quickshell`, `ttf-jetbrains-mono-nerd`, `curl`, `jq`, `polkit`
- `yay` (with `git` and `base-devel`) to install anything
- a polkit authentication agent in the session. Without one, an install stops
  with "It needs your password, and nothing on this session could ask for it."

## Running it

```sh
app-finder                                  # installed from the package
quickshell -p /path/to/checkout/shell.qml   # from a checkout
```

Launching it a second time brings back the running window. Closing the window
ends the process, but if an install is still going it waits for that to finish
first.

For scripting and tests, it has an IPC target:
`quickshell ipc -p /usr/share/app-finder/shell.qml call app-finder state`
(also `show`, `open <pkg>`, `page browse|installed`, `type <text>`, `back`,
`refresh`, `install <pkg>`, `remove <pkg>`, `jobs`).

## Layout

| Path | What |
|---|---|
| `shell.qml`, `Panel.qml` | The window: Browse and Installed, search, the carousel |
| `Detail.qml`, `AppRow.qml`, `PreviewCard.qml`, `Monogram.qml`, `Chip.qml` | An app's page, a row, a screenshot card, an icon, a badge |
| `Tokens.qml`, `Label.qml`, `Glyph.qml`, `Button.qml`, `SearchField.qml`, `TouchArea.qml`, `Card.qml` | The small UI kit it is drawn with |
| `Catalog.js`, `Glyphs.js`, `Hues.js` | Sorting and wording, the Nerd Font glyphs, monogram colours |
| `libexec/app-finder-helper` | The list, the pictures, install and remove, as JSON |
| `libexec/app-finder-sudo`, `libexec/app-finder-pacman`, `polkit/` | Root for yay: pacman through one polkit action, so an install asks once |
| `bin/app-finder` | The launcher |
| `packaging/` | The AUR PKGBUILD, and `release.sh`, which builds the tarball it pins |

## Releasing

```sh
git tag v1.0.0 && git push --tags
packaging/release.sh 1.0.0        # dist/app-finder-1.0.0.tar.gz, sha256 into PKGBUILD
gh release create v1.0.0 dist/app-finder-1.0.0.tar.gz
```

Then copy `packaging/PKGBUILD` to the AUR repo and run
`makepkg --printsrcinfo > .SRCINFO`.

## License

MIT
