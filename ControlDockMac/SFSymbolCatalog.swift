//
//  SFSymbolCatalog.swift
//  ControlDockMac
//
//  A curated, categorised list of SF Symbol names for the picker. SF Symbols
//  cannot be enumerated at runtime, so this is a hand-maintained selection of
//  commonly useful, broadly available symbols.
//

import Foundation

enum SFSymbolCatalog {

    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let symbols: [String]
    }

    /// Flat list of every symbol across all categories (deduplicated, ordered).
    static let all: [String] = {
        var seen = Set<String>()
        var result: [String] = []
        for category in categories {
            for symbol in category.symbols where !seen.contains(symbol) {
                seen.insert(symbol)
                result.append(symbol)
            }
        }
        return result
    }()

    /// Returns symbols whose name contains the query (case-insensitive).
    static func search(_ query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.contains(trimmed) }
    }

    static let categories: [Category] = [
        Category(name: "Häufig", symbols: [
            "bolt.fill", "star.fill", "heart.fill", "flame.fill", "power", "command",
            "play.fill", "pause.fill", "stop.fill", "forward.fill", "backward.fill",
            "house.fill", "gearshape.fill", "bell.fill", "tag.fill", "flag.fill",
            "checkmark.circle.fill", "xmark.circle.fill", "plus.circle.fill", "minus.circle.fill",
            "questionmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill"
        ]),
        Category(name: "Steuerung & System", symbols: [
            "power", "powerplug.fill", "powersleep", "restart", "sleep", "lock.fill",
            "lock.open.fill", "lock.rotation", "key.fill", "touchid", "faceid",
            "moon.fill", "moon.stars.fill", "sun.max.fill", "sunrise.fill", "sunset.fill",
            "display", "display.2", "menubar.rectangle", "dock.rectangle", "macwindow",
            "slider.horizontal.3", "switch.2", "gauge", "gauge.high", "speedometer",
            "battery.100", "battery.25", "battery.0", "bolt.badge.clock.fill"
        ]),
        Category(name: "Medien", symbols: [
            "play.fill", "pause.fill", "stop.fill", "playpause.fill", "forward.fill",
            "backward.fill", "forward.end.fill", "backward.end.fill", "shuffle", "repeat",
            "speaker.fill", "speaker.wave.1.fill", "speaker.wave.2.fill", "speaker.wave.3.fill",
            "speaker.slash.fill", "music.note", "music.note.list", "music.mic", "guitars.fill",
            "headphones", "hifispeaker.fill", "tv.fill", "film.fill", "video.fill",
            "camera.fill", "camera.aperture", "photo.fill", "photo.on.rectangle", "mic.fill",
            "mic.slash.fill", "waveform", "waveform.path", "airplayvideo", "airplayaudio"
        ]),
        Category(name: "Kommunikation", symbols: [
            "envelope.fill", "envelope.open.fill", "paperplane.fill", "message.fill",
            "bubble.left.fill", "bubble.right.fill", "phone.fill", "phone.down.fill",
            "video.fill", "bell.fill", "bell.slash.fill", "megaphone.fill", "quote.bubble.fill",
            "at", "person.crop.circle.fill", "person.2.fill", "person.3.fill",
            "bubble.left.and.bubble.right.fill"
        ]),
        Category(name: "Pfeile & Navigation", symbols: [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right", "arrow.up.arrow.down",
            "arrow.clockwise", "arrow.counterclockwise", "arrow.triangle.2.circlepath",
            "arrow.uturn.left", "arrow.uturn.right", "arrow.up.right", "arrow.down.left",
            "chevron.up", "chevron.down", "chevron.left", "chevron.right", "chevron.right.2",
            "arrowshape.turn.up.right.fill", "arrow.up.forward.app.fill", "location.fill",
            "location.north.fill", "map.fill", "mappin", "mappin.circle.fill", "scope",
            "arrow.up.left.and.arrow.down.right", "arrow.down.right.and.arrow.up.left"
        ]),
        Category(name: "Bearbeiten & Text", symbols: [
            "pencil", "pencil.circle.fill", "square.and.pencil", "highlighter", "scissors",
            "doc.on.doc.fill", "doc.on.clipboard.fill", "clipboard.fill", "trash.fill",
            "bin.xmark.fill", "textformat", "bold", "italic", "underline", "text.alignleft",
            "text.aligncenter", "text.alignright", "list.bullet", "list.number",
            "magnifyingglass", "magnifyingglass.circle.fill", "plus.magnifyingglass",
            "minus.magnifyingglass", "wand.and.stars", "paintbrush.fill", "paintpalette.fill",
            "eyedropper", "ruler.fill", "crop"
        ]),
        Category(name: "Dateien & Ordner", symbols: [
            "folder.fill", "folder.badge.plus", "folder.badge.gearshape", "tray.fill",
            "tray.full.fill", "tray.and.arrow.down.fill", "tray.and.arrow.up.fill",
            "doc.fill", "doc.text.fill", "doc.richtext.fill", "doc.zipper", "archivebox.fill",
            "externaldrive.fill", "internaldrive.fill", "opticaldiscdrive.fill", "sdcard.fill",
            "square.and.arrow.up.fill", "square.and.arrow.down.fill", "icloud.fill",
            "icloud.and.arrow.up.fill", "icloud.and.arrow.down.fill", "books.vertical.fill"
        ]),
        Category(name: "Geräte & Technik", symbols: [
            "desktopcomputer", "laptopcomputer", "macbook", "macpro.gen3.fill", "macmini.fill",
            "display", "keyboard", "keyboard.fill", "computermouse.fill", "magicmouse.fill",
            "iphone", "ipad", "applewatch", "airpods", "airpodspro", "homepod.fill",
            "appletv.fill", "printer.fill", "scanner.fill", "tv.fill", "gamecontroller.fill",
            "cpu.fill", "memorychip.fill", "server.rack", "wifi", "wifi.router.fill",
            "antenna.radiowaves.left.and.right", "dot.radiowaves.left.and.right", "network",
            "cable.connector", "bonjour"
        ]),
        Category(name: "Wetter & Natur", symbols: [
            "sun.max.fill", "sun.min.fill", "cloud.fill", "cloud.rain.fill", "cloud.bolt.fill",
            "cloud.snow.fill", "cloud.fog.fill", "wind", "tornado", "hurricane", "snowflake",
            "drop.fill", "flame.fill", "leaf.fill", "tree.fill", "mountain.2.fill",
            "globe.americas.fill", "globe.europe.africa.fill", "moon.fill", "sparkles", "rainbow"
        ]),
        Category(name: "Transport", symbols: [
            "car.fill", "bus.fill", "tram.fill", "bicycle", "scooter", "airplane",
            "ferry.fill", "sailboat.fill", "fuelpump.fill", "bolt.car.fill", "parkingsign",
            "road.lanes", "figure.walk", "figure.run", "tortoise.fill", "hare.fill"
        ]),
        Category(name: "Personen & Aktivität", symbols: [
            "person.fill", "person.crop.circle.fill", "person.2.fill", "person.3.fill",
            "person.badge.plus", "person.badge.minus", "figure.walk", "figure.run",
            "figure.wave", "hand.raised.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill",
            "hand.tap.fill", "hands.clap.fill", "brain.head.profile", "eye.fill", "ear.fill"
        ]),
        Category(name: "Symbole & Formen", symbols: [
            "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill",
            "seal.fill", "shield.fill", "checkmark.shield.fill", "rosette", "crown.fill",
            "star.circle.fill", "heart.circle.fill", "bolt.circle.fill", "sparkle",
            "burst.fill", "circle.grid.2x2.fill", "square.grid.2x2.fill", "square.grid.3x3.fill",
            "rectangle.3.group.fill", "circle.hexagongrid.fill", "infinity", "number",
            "percent", "plus", "minus", "multiply", "divide", "equal", "function"
        ]),
        Category(name: "Werkzeuge & Objekte", symbols: [
            "hammer.fill", "wrench.fill", "wrench.and.screwdriver.fill", "screwdriver.fill",
            "gear", "gearshape.2.fill", "terminal.fill", "chevron.left.forwardslash.chevron.right",
            "ladybug.fill", "cube.fill", "shippingbox.fill", "bag.fill", "cart.fill",
            "creditcard.fill", "banknote.fill", "giftcard.fill", "calendar", "clock.fill",
            "alarm.fill", "timer", "stopwatch.fill", "hourglass", "lightbulb.fill",
            "bolt.fill", "fanblades.fill", "thermometer.medium", "humidity.fill",
            "lifepreserver.fill", "cross.case.fill", "pills.fill", "bandage.fill"
        ])
    ]
}
