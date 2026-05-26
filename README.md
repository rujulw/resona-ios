# resona ios

native iOS music player for local FLAC and MP3 libraries. plays files already on your iPhone via AVFoundation. mac mini streaming comes later — v1 is fully local and offline-capable.

the iOS client mirrors the resona desktop exactly: same design language, same library model, same playback architecture — adapted for mobile without compromise.

## Vision

resona ios emphasizes:

- local-first playback — FLAC and MP3 from your iPhone's Files app, no server required
- design continuity with the desktop — dark, audio-native, no platform defaults
- lock screen and headphone controls as first-class surfaces
- a clean extension point for mac mini streaming when the time comes

## Current Implementation Status

Implemented:

- none yet — initial foundation

Not implemented yet:

- xcode project and app skeleton
- local file indexer (FLAC + MP3 via AVFoundation)
- `PlaybackEngine` with `AVPlayer`
- `QueueManager`, shuffle, repeat
- lock screen / headphone controls (`MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`)
- UI shell: tab bar, mini player, full player, vinyl rotation
- library views: tracks table, albums grid, artists list
- settings: add library folders, scan status
- mac mini streaming (deferred — future branch)

## Documentation

- [Architecture](docs/architecture.md): system boundaries, module layout, and source model
- [Roadmap](docs/roadmap.md): phased milestones from local player to mac mini streaming
- [Design Log](docs/design.md): accepted decisions and UX principles
- [Bug Log](docs/bug-log.md): fix history and verification

## Tech Stack

- Swift 6, SwiftUI, iOS 17+
- `AVFoundation` / `AVPlayer` — FLAC and MP3 playback (streaming deferred)
- `CryptoKit` — SHA256 track identity, matching resona desktop's stable_identifier
- `MediaPlayer` — lock screen, headphone controls, CarPlay (later)
- `SwiftData` — local library index, security-scoped bookmark persistence

## Project Structure

```text
resona-ios/
├── Sources/
│   ├── Library/      — LibraryIndexer, LibraryStore, SwiftData models
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

- lock screen artwork requires device testing — simulator rendering is incomplete
- security-scoped bookmarks must be re-validated on app launch; stale bookmarks need graceful handling in the indexer
- FLAC metadata via AVFoundation covers Vorbis comments — edge cases with malformed tags fall back the same way as the resona desktop (filename stem, parent folder)

## Development Workflow

1. all feature branches cut from `development`, never from `main`
2. resona desktop data model shapes live in `/Users/rujulw/dev/resona/server/src/library/models.rs` — check there when adding fields to Track or Album
3. physical device needed for meaningful lock screen and audio session testing
4. mac mini streaming deferred to `feat/stream-source` — do not add network code to this codebase until local playback is solid
