# Farever Disable Profanity Filter

An HLX mod for Farever that lets you disable the client-side profanity filter used for chat messages and speech bubbles.

Character-name validation is intentionally unchanged.

## Installation

1. Install [HLX Core](https://github.com/hlx-framework/hlx-core).
2. Install the Farever ImGui plugin required by HLX mods with settings menus.
3. Download the latest build artifact. Install the ZIP with Vortex, or extract it directly into the Farever game directory; the archive already contains `hlx/mods/disable-profanity-filter/`.
4. Start Farever and press `F9` to open the settings menu.

The settings hotkey can be changed from inside the menu.

## Building (developers)

Install Haxe 4.3.7, HLX Runtime, and `hl-imgui`, then run:

```sh
haxe compile.hxml
```

The compiled mod is written to `build/disable-profanity-filter/disable-profanity-filter.hl`.

