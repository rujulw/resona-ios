# resona ios roadmap

## Product Direction

resona ios is the mobile companion to the resona desktop player. the goal is a native iOS experience that feels continuous with the desktop — same library, same design language, same playback model — without compromising for platform defaults.

the client is local-first in resilience terms: it degrades gracefully when the mac mini is unreachable, but it is not a standalone player. the mac mini is the library source and streaming origin.

## Milestone 1: Foundation

- establish repo structure, docs, and gitignore
- define source model, module layout, and concurrency contract
- capture architecture and design decisions before code lands
- port reusable design-language code from resona desktop where applicable
- confirm server API contracts against the companion resona repo

## Milestone 2: Server Connection

- implement `ServerSession` with base URL management, health check, and retry
- implement `ServerDiscovery` via `NWBrowser` for `_resona._tcp`
- implement manual IP/port fallback in Settings
- expose connection state to UI (connected / discovering / offline)
- validate against a live resona mac mini instance

## Milestone 3: Library Layer

- implement `RemoteLibrary` — fetch `/library`, decode JSON, cache with `SwiftData`
- implement `LocalLibrary` — index on-device audio files
- implement `LibraryStore` — merge both into unified track/album/artist/playlist arrays
- expose search and sort on the merged library surface
- handle mixed-source track lists without branching in view code

## Milestone 4: Playback Engine

- implement `PlaybackEngine` with `AVPlayer` for both local and stream sources
- implement `QueueManager` — ordered list, auto-advance, shuffle, repeat
- implement `NowPlayingBridge` — `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`
- implement `PlaybackSession` — position persistence across launches
- validate byte-range seeking against resona server on device before calling streaming done
- configure `AVAudioSession` for background playback

## Milestone 5: UI Shell

- implement `AppRoot` with tab bar (Home | Library | Search | Settings)
- implement `MiniPlayer` persistent bottom bar
- implement `FullPlayer` sheet with artwork, transport, queue panel
- implement `Home` — recents, playlists, albums rows
- implement `Library` — Tracks | Albums | Artists | Playlists tabs
- implement `Search` — cross-entity, client-side scored
- implement `Settings` — server discovery, manual IP, local library roots

## Milestone 6: Lock Screen and CarPlay

- validate lock screen and control center via `MPNowPlayingInfoCenter` on device
- implement CarPlay template hierarchy (`CPTemplateApplicationScene`)
- verify headphone transport controls route correctly through `MPRemoteCommandCenter`
- test against both AirPlay and wired audio output

## Deferred Scope

- Spotify import / listening history (desktop-only feature for now)
- analytics surfaces (top tracks, top artists, time windows)
- timbre audio intelligence (deferred to desktop milestone 6)
- offline pinning / local cache of streamed tracks
- gapless playback, crossfade, equalizer
- iPad layout
- widget extension

## Dependencies and Open Questions

- byte-range streaming must be confirmed against the resona server — `AVPlayer` sends `Range:` headers and breaks on servers that don't honor them
- CarPlay requires entitlement approval and either a vehicle, CarPlay simulator, or MFi hardware for meaningful testing
- local library indexing scope: Music app tracks (requires `NSAppleMusicUsageDescription`), imported files, Files app picks — confirm which are in v1
- track identity across sources: local hash vs server UUID must never be conflated; confirm the merge key used in `LibraryStore` when the same track exists in both libraries
