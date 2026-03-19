# Focus Timer — Project Overview

## What it is

A Pomodoro-style focus timer that lives in the macOS menu bar. Features a 3D particle sphere visualization that fills with white dots as you focus, giving a visual sense of accumulated deep work.

## Platforms

| Platform | Status | Description |
|----------|--------|-------------|
| macOS | Built | Menu bar widget + detachable floating window |
| iOS | Planned | Full app with particle sphere, synced with Mac |
| watchOS | Planned | Timer widget, synced with Mac and iPhone |

## Core Features

### Timer
- Focus and break sessions with configurable durations
- Play/pause/skip controls
- Auto-start breaks and work sessions (optional)
- Session and break counters (orange/green)

### Particle Sphere
- 800 particles distributed via Fibonacci sphere (golden spiral)
- 85% surface particles, 15% interior for depth
- Particles reveal progressively as the timer counts down
- Slow Y-axis rotation with subtle X-axis wobble
- Depth-based opacity and size (back particles dimmer/smaller)
- Fade-in effect for each particle as it appears

### Theme System
- `TimerThemeView` protocol for swappable visualizations
- Particle theme is the first implementation
- Architecture ready for future themes (sand timer, aurora, ink, etc.)

### Views
- **Menu bar dropdown** — full timer with particle sphere, countdown, controls, sessions list, settings
- **Floating widget** — minimal, resizable, particle-only view with hover controls. Designed to stay open during focus sessions
- **Sessions list** — history of completed focus sessions
- **Settings** — focus/break durations, sound, notifications, auto-start toggles

## Syncing (Planned)

### Mechanism
- **iCloud/CloudKit** for cross-device sync
- SwiftData model container backed by CloudKit

### What syncs
- Timer state (sync "end time" rather than "remaining seconds")
- Completed sessions history
- User preferences (durations, toggles)

### Notifications
- When a session ends, notification fires on **all devices** (Mac, iPhone, Apple Watch)
- Uses `UNUserNotificationCenter` locally, CloudKit push for remote devices

## Tech Stack

- **SwiftUI** — all views and the particle Canvas renderer
- **SwiftData** — session history persistence
- **AppKit** — menu bar (`NSStatusItem`), panels (`NSPanel`)
- **UserDefaults** — preferences storage (will migrate to CloudKit)
- **CoreGraphics** — particle projection math

## Architecture

```
FocusTimer/
├── App/                    # App entry, menu bar controller
├── Models/                 # TimerPhase, TimerState, FocusSession, UserPreferences
├── ViewModels/             # TimerViewModel, SessionHistoryViewModel
├── Views/
│   ├── Timer/              # PopoverView, FloatingView, Controls, Countdown
│   ├── Themes/             # TimerThemeView protocol
│   │   └── Particle/       # ParticleSystem, ParticleThemeView
│   ├── Sessions/           # Session list and row views
│   ├── Settings/           # Settings view, TickSlider
│   └── Shared/             # FloatingPanel, BottomBar
├── Services/               # NotificationService, SoundService
├── Utilities/              # Constants, Color+Theme, TimeFormatting
└── docs/                   # This folder
```
