# resona ios design

## Product Summary

resona ios should feel like the desktop player in your hand. not a "mobile version" — the same product, adapted for the form factor. dark, audio-native, controlled. it should not look like a default Apple music app template.

## UX Principles

- source transparency — the user should never need to care whether a track is local or streamed
- playback state legible at a glance from the mini player at all times
- shallow navigation — tab bar at root, one push level within each tab, sheet for the full player
- no discovery feed, no algorithmic suggestions, no content noise
- lock screen and CarPlay are first-class playback surfaces, not bolted-on afterthoughts
- degradation should be quiet — offline state communicated simply, no error wall blocking the UI

## Design Language

Mirrors resona desktop exactly. Deviation from the desktop design language requires explicit justification.

### Palette

| Role | Value |
|---|---|
| Background | `#121212` |
| Playback surface | `#0e0e0e` |
| Primary text | `#f2f2f2` |
| Secondary text | `#8f8f8f` |
| Muted | `#a5a5a5`, `#6f6f6f` |
| Active/selected | white at 10% opacity overlay |
| Press state | white at 5–6% opacity |
| Borders | white at 5–10% opacity |

No system blue anywhere. Interactive elements use white-tinted states, not `Color.accentColor`.

### Radii

| Context | Radius |
|---|---|
| List rows, nav items | 4pt |
| Cards (artwork + label) | 8pt |
| Artist avatars | circular |
| Sheets and modals | system sheet radius |

### Typography

| Role | Size | Weight | Tracking | Color |
|---|---|---|---|---|
| Section labels | 11pt | regular | 0.08em | `#8f8f8f`, lowercase |
| Primary content | 14pt | medium | default | `#f2f2f2` |
| Secondary/meta | 12pt | regular | default | `#8f8f8f` |

No system blue. No dynamic type scaling unless explicitly added later.

### Motion

- iOS spring animations for sheet presentation and row selection
- vinyl art: rotation animation while playing, pause on stop
- state transitions: ~150ms, purposeful — not every element animates
- mini player: spring-in on track change, not a fade

## Primary Surfaces

### Mini Player

Persistent at the bottom of every tab. Tapping opens the full player sheet.

- shows: artwork thumbnail, track title, artist, play/pause
- no skip controls — those live in the full player
- press state: white 6% overlay on the whole bar
- should not overlap tab bar — sits above it

### Full Player

Sheet, presented from any tab.

- large artwork (square, 8pt radius)
- vinyl rotation animation while playing
- transport: previous, play/pause, next — spaced clearly
- seek bar with elapsed / remaining
- queue panel toggle (numbered setlist style, matching desktop)
- source indicator for streamed vs local (subtle, secondary text weight)

### Library

Tab bar surface. Four tabs within: Tracks | Albums | Artists | Playlists.

- tracks: scrollable table, inline search, header-driven sort
- albums: grid of artwork cards (8pt radius)
- artists: list with circular avatars
- playlists: list with artwork thumbnails

### Home

Recent activity, playlists, albums — horizontal scroll rows. Not a feed. Dense, not card-heavy.

### Settings

- server: discovered server hostname + manual IP/port entry
- local library: folder roots for on-device indexing
- no account, no profile, no social

## Anti-Patterns

These are prohibited regardless of how common they are in iOS music app designs:

- white or light-mode default background
- `Color.accentColor` (system blue) on any interactive element
- `List` with default grouped style and inset cell backgrounds
- rounded rectangle cards as the primary layout primitive
- animation on every element load
- hamburger menu or slide-out drawer navigation
- generic hero header with a centered h1 and gradient

## Platform Conventions

Use system conventions where they are invisible to the user (sheet presentation, safe area insets, haptics). Override them where they conflict with the design language (colors, typography, row styling). Don't fight the system — shape it.

## Accepted Decisions

### 2026-05-26 — SwiftUI only, no UIKit except AVKit wrappers

UIKit is only permitted when `AVKit` demands a `UIViewController` wrapper (e.g. `AVPlayerViewController`). All layout, navigation, and animation is SwiftUI. Rationale: Swift 6 and SwiftUI concurrency model make mixing UIKit and `@Observable` unnecessarily complex without a clear return.

### 2026-05-26 — No third-party UI frameworks

No UIKit wrappers, no Lottie, no custom navigation libraries. SwiftUI spring animations cover the motion needs. Keeping the dependency surface minimal is a deliberate tradeoff against animation expressiveness for now.
