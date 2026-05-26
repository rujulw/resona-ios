# resona ios

native iOS client for resona. streams from a mac mini running the resona desktop app over local wifi, or plays local files on-device. both sources present a unified library and playback experience.

the iOS client is designed to feel continuous with the desktop: same design language, same library structure, same playback model — adapted for mobile without compromise.

## Vision

resona ios emphasizes:

- source-transparent playback — local and streamed tracks share one queue, one player, one UI
- network resilience — bonjour discovery with manual IP fallback, clean offline degradation
- lock screen and CarPlay as first-class surfaces, not afterthoughts
- a design that mirrors the desktop exactly: dark, audio-native, no platform-default styling

## Current Implementation Status

Implemented:

- none yet — initial foundation

Not implemented yet:

- server discovery (Bonjour + manual IP fallback)
- remote library fetch and local cache
- local file library (on-device)
- `PlaybackEngine` with `AVPlayer` (local + stream)
- UI shell: tab bar, mini player, full player
- lock screen / control center integration (`MPNowPlayingInfoCenter`)
- CarPlay support

## Documentation

- [Architecture](docs/architecture.md): system boundaries, module layout, and source model
- [Roadmap](docs/roadmap.md): phased milestones from foundation to CarPlay
- [Design Log](docs/design.md): accepted decisions and UX principles
- [Bug Log](docs/bug-log.md): fix history and verification

## Tech Stack

- Swift 6, SwiftUI, iOS 17+
- `AVFoundation` / `AVPlayer` — local and HTTP streaming playback
- `Network.framework` + Bonjour/mDNS — server discovery
- `MediaPlayer` — lock screen, control center, CarPlay
- `SwiftData` — local library index cache

## Project Structure

```text
resona-ios/
├── Sources/
│   ├── Server/       — ServerSession, discovery, health
│   ├── Library/      — LibraryStore, RemoteLibrary, LocalLibrary
│   ├── Playback/     — PlaybackEngine, QueueManager, NowPlayingBridge
│   └── UI/           — views, components, navigation
├── Tests/
├── docs/
└── README.md
```

## Quick Start

```bash
# build for simulator
xcodebuild -scheme ResonaIOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# run tests
xcodebuild -scheme ResonaIOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

## Known Gaps

- byte-range streaming must be verified against the resona server before seeking is claimed done
- Bonjour discovery fails on some VPN and enterprise router configurations — manual IP fallback is required
- local track identity (path hash) and remote track identity (server UUID) must never be assumed globally unique across sources

## Development Workflow

1. all feature branches cut from `development`, never from `main`
2. companion server contracts live in `/Users/rujulw/dev/resona` — check there for API shapes before implementing client-side calls
3. byte-range seeking must be tested on real hardware or a correctly configured simulator before calling streaming done
4. lock screen and CarPlay surfaces require device testing — simulator coverage is incomplete
