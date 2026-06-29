<div align="center">

# ControlDock

**Turn your iPhone or iPad into a wireless control surface for your Mac.**

Build a personal grid of buttons that launch apps, run shell commands, press
keyboard shortcuts or open URLs — all triggered from your iOS device over the
local network. Think of it as a configurable, software-only stream deck.

</div>

---

## Overview

ControlDock is two native SwiftUI apps that talk to each other over your local
Wi-Fi network:

| App | Platform | Role |
| --- | --- | --- |
| **ControlDock** | iOS / iPadOS | The **client** — shows the button grid and sends presses. |
| **ControlDockMac** | macOS | The **server** — hosts the buttons, executes the actions. |

The Mac advertises itself via **Bonjour**, the iOS app discovers it
automatically, you pair once with a PIN, and every button you tap on the phone
runs its action on the Mac.

```
┌──────────────────┐        Bonjour (_controldock._tcp)        ┌──────────────────┐
│   iPhone / iPad   │  ───  discover • pair (PIN) • press  ───▶ │       Mac         │
│  ControlDock app  │                                           │ ControlDockMac    │
│  (button grid)    │  ◀───  deck layout • action results  ───  │ (action executor) │
└──────────────────┘            length-prefixed JSON            └──────────────────┘
```

## Features

- **Four action types** for every button:
  - 🚀 **Launch app** — by name, bundle identifier, or full path
  - 💻 **Shell command** — runs in a login `zsh` shell
  - ⌨️ **Keystroke** — key combos (`cmd+shift+4`) *and* media / hardware keys
    (volume, brightness, playback, keyboard backlight)
  - 🔗 **Open URL** — opens links in the default browser
- **Visual deck editor** on the Mac — title, SF Symbol icon, color, action, and
  a one-tap **Test** button for each entry.
- **Automatic discovery** over Bonjour — no IP addresses to type in.
- **PIN pairing** so only your own devices can drive your Mac.
- **Adaptive grid layout** on iOS that fills the screen on both iPhone and iPad.
- **Live activity log** and connected-device list on the Mac.
- **In-app help** on both platforms.
- **100% local** — nothing leaves your network; there is no cloud, no account,
  no telemetry.

## Requirements

- **macOS 15** or later (ControlDockMac)
- **iOS / iPadOS 26** or later (ControlDock)
- **Xcode 16** or later with a Swift 5 toolchain
- Both devices on the **same local network**

## Getting started

The repository contains two independent Xcode projects:

```
ControlDock.xcodeproj      # iOS / iPadOS client
ControlDockMac.xcodeproj   # macOS server
```

### 1. Run the Mac server

1. Open `ControlDockMac.xcodeproj` in Xcode.
2. Select the **ControlDockMac** scheme and run it (⌘R).
3. The app starts a server named after your Mac and shows a **pairing PIN**.
4. The first time you use a **Keystroke** button, grant ControlDock
   **Accessibility** permission when prompted
   (System Settings → Privacy & Security → Accessibility). This is required for
   macOS to allow synthetic key events.

### 2. Run the iOS client

1. Open `ControlDock.xcodeproj` in Xcode.
2. Select the **ControlDock** scheme and a device or simulator, then run (⌘R).
3. Allow **Local Network** access when prompted.
4. Pick your Mac from the discovered list and enter the PIN shown on the Mac.

> **Code signing:** to run on a physical iPhone or iPad, set your own
> development team and a unique bundle identifier in the target's
> *Signing & Capabilities* tab.

### 3. Build your deck

On the Mac, add buttons in the editor, give each one a title, icon, color and
action, and use **Test** to verify it. Changes are pushed to connected devices
instantly.

## How it works

- **Discovery & transport** — the Mac advertises a `_controldock._tcp` Bonjour
  service; the iOS app browses for it and opens a TCP connection via Apple's
  `Network` framework.
- **Wire protocol** — messages are length-prefixed JSON frames (a 4-byte
  big-endian length header followed by the payload). The protocol is defined
  once in `ControlProtocol.swift`, a file kept identical in both targets.
- **Pairing** — the client sends a `hello` with its name and the PIN; the server
  accepts only if the protocol version matches and the PIN is correct.
- **Execution** — a `press` message carries the button's UUID; the Mac looks up
  the button and runs its action off the main thread, then reports success or
  failure back to the client.

## Security & privacy

- All communication stays on your **local network** — there is no internet
  component, account, or analytics.
- **Shell command** and **keystroke** buttons run with the privileges of the
  logged-in macOS user. Only pair devices you trust, and keep PIN pairing
  enabled.
- The pairing PIN is generated on the Mac and can be regenerated at any time.

## Project structure

```
ControlDock/            # iOS client sources
  ControlProtocol.swift #   shared wire protocol (mirror of the Mac copy)
  DeckClient.swift      #   Bonjour discovery + connection
  DeckView.swift        #   the button grid
  ...
ControlDockMac/         # macOS server sources
  ControlProtocol.swift #   shared wire protocol (mirror of the iOS copy)
  DeckServer.swift      #   Bonjour service + connection handling
  ActionExecutor.swift  #   runs apps / shell / URLs
  KeystrokeSimulator.swift  # synthesizes key & media events
  ConfigView.swift      #   the deck editor
  ...
```

## Roadmap ideas

- Multiple decks / pages
- Button import & export
- Encrypted transport

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.
