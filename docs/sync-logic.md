# Sync Logic

## Overview

FocusTimer syncs timer state between macOS and iOS in real time. There are two sync channels:

1. **iCloud KV Store** — syncs state when both apps are in the foreground
2. **APNs Push via Vercel** — updates the iOS Dynamic Island when the iOS app is backgrounded

## Architecture

```
macOS App                         iOS App
    |                                |
    |--- iCloud KV Store ---------->|  (foreground sync)
    |                                |
    |--- Vercel Function ---> APNs ->|  Dynamic Island
    |                                |  (background sync)
```

## Channel 1: iCloud KV Store (Foreground Sync)

**Service:** `SyncService.swift`

Uses `NSUbiquitousKeyValueStore` to publish and observe timer state changes across devices. Each device has a stable UUID (`focustimer_device_id`) to filter out its own changes.

### Published Keys

| Key | Type | Description |
|-----|------|-------------|
| `sync_timerState` | String | `"running"`, `"paused"`, or `"idle"` |
| `sync_endTime` | Double | Unix timestamp when timer expires (running state) |
| `sync_pausedRemaining` | Double | Seconds remaining (paused state) |
| `sync_phase` | String | `"work"` or `"rest"` |
| `sync_taskName` | String | Current task label |
| `sync_deviceID` | String | UUID of the device that wrote the state |
| `sync_liveActivityPushToken` | String | APNs push token for the iOS Live Activity |

### Flow

1. Device A changes timer state (start/pause/resume/skip/reset)
2. Device A writes to KV store via `publishRunning()`, `publishPaused()`, or `publishIdle()`
3. Device B receives `didChangeExternallyNotification`
4. Device B's `handleRemoteChange()` updates local state
5. `TimerViewModel.handleRemoteSync()` applies the state (starts/stops engine, updates UI)

### Limitation

`didChangeExternallyNotification` is only delivered when the app is in the foreground. If the iOS app is backgrounded (Dynamic Island visible), it won't receive KV store changes. This is why Channel 2 exists.

## Channel 2: APNs Push via Vercel (Dynamic Island Sync)

**Services:** `LiveActivityService.swift`, `PushService.swift`, `cloud-function/api/push.js`

Updates the Dynamic Island when the iOS app is suspended. This is the only way to update a Live Activity from an external event — Apple does not allow background code execution for this purpose.

### How the Push Token Gets Stored

1. iOS starts a Live Activity with `pushType: .token`
2. `LiveActivityService` observes `activity.pushTokenUpdates` (async stream)
3. When a token arrives, it's hex-encoded and passed via `onPushTokenUpdate` callback
4. `TimerViewModel` stores it in iCloud KV store via `syncService.storePushToken()`
5. macOS can now read this token via `syncService.readPushToken()`

### How macOS Pushes to the Dynamic Island

1. User pauses/resumes/skips/resets timer on macOS
2. `TimerViewModel` calls `pushService.pushUpdate()` or `pushService.pushEnd()`
3. `PushService` sends a POST to the Vercel function with:
   - `pushToken` — the iOS Live Activity token from KV store
   - `contentState` — the new state (phase, timerState, endTime, progress, remainingSeconds)
   - `event` — `"update"` or `"end"`
4. Vercel function creates an APNs JWT using the .p8 auth key
5. Vercel function sends an HTTP/2 request to APNs
6. APNs delivers the payload directly to the Dynamic Island (no app code runs)

### APNs Payload Format

```json
{
  "aps": {
    "timestamp": 1711500000,
    "event": "update",
    "content-state": {
      "phase": "work",
      "timerState": "paused",
      "endTime": 764000000.0,
      "progress": 0.3,
      "remainingSeconds": 1050
    }
  }
}
```

For ending the activity:
```json
{
  "aps": {
    "timestamp": 1711500000,
    "event": "end",
    "dismissal-date": 1711500010,
    "content-state": { ... }
  }
}
```

### Vercel Function

**Location:** `cloud-function/api/push.js`

A single serverless function that:
- Authenticates requests with a shared secret (`AUTH_SECRET`)
- Creates an ES256 JWT for APNs using the .p8 key
- Sends the push via HTTP/2 to APNs

**Environment variables** (set in Vercel dashboard):
- `APNS_KEY_BASE64` — Base64-encoded .p8 APNs auth key
- `APNS_KEY_ID` — Key ID from Apple Developer
- `APNS_TEAM_ID` — Team ID from Apple Developer
- `APNS_TOPIC` — `com.timelessventures.focustimer.ios.push-type.liveactivity`
- `AUTH_SECRET` — Shared secret for request authentication

**APNs environment:** Uses sandbox (`api.sandbox.push.apple.com`) for development builds. Switch to `api.push.apple.com` for production/App Store builds.

## Dynamic Island Timer Display

The Dynamic Island countdown runs locally on-device using SwiftUI's `Text(timerInterval:countsDown:)`. This means:

- **Running:** The island receives an `endTime` once and counts down automatically. No per-second updates needed.
- **Paused:** The island shows a static time with dimmed opacity.
- **Resume:** A new `endTime` is pushed, and the countdown restarts.

This is why the push only fires on **state changes** (pause, resume, skip, reset), not every second. A typical 25-minute session uses ~4 push calls.

## State Change Summary

| Action | KV Store | Push to Dynamic Island |
|--------|----------|----------------------|
| Start | `publishRunning()` | `pushUpdate("running")` |
| Pause | `publishPaused()` | `pushUpdate("paused")` |
| Resume | `publishRunning()` | `pushUpdate("running")` |
| Skip | `publishIdle()` | `pushEnd()` |
| Revert | `publishIdle()` | `pushEnd()` |
| Reset | `publishIdle()` | `pushEnd()` |
| Timer finishes | `publishIdle()` | `pushEnd()` |

macOS sends both KV store updates (for foreground iOS sync) and push notifications (for Dynamic Island sync) on every state change. iOS only uses KV store + direct `LiveActivityService` calls since it updates the Dynamic Island locally.

## Conflict Resolution

### Source of Truth: Last Local Action Wins

When two devices have conflicting timer state, the device where the user most recently took an action is the source of truth.

**The problem:** When macOS starts a timer, `start()` calls `syncService.fetchCurrentState()` to check if another device has a running timer. If it finds one, it joins it. But if the user just reset the timer locally (e.g. changed duration from 25m to 1m), the KV store might still have stale state from iOS that hasn't been overwritten yet. Without protection, macOS would join the stale iOS timer instead of starting the fresh local one.

**The fix:** A `localActionOverride` flag in `TimerViewModel`:

1. `reset()`, `skip()`, `revert()` set `localActionOverride = true`
2. `start()` checks the flag — if set, it skips the remote timer check and starts fresh
3. The flag resets to `false` after `start()` runs

This means:
- **Reset then play** = starts a fresh local timer (local action wins)
- **App launch then play** = joins remote timer if one exists (normal sync)
- **Remote sync notification** = always applied (handled by `handleRemoteSync`)

### Live Activity Deduplication

Multiple Live Activities can accumulate if `startActivity()` is called without ending old ones. This causes ghost activities with stale push tokens, flickering, and unresponsive Dynamic Islands.

**Prevention:**

1. `LiveActivityService.startActivity()` calls `endAllActivities()` first — iterates `Activity<FocusTimerAttributes>.activities` and ends every one before creating a new activity
2. `handleRemoteSync()` uses `updateActivity()` instead of `startActivity()` — the push channel handles creating the Dynamic Island, KV store sync only updates app state
3. `updateActivity()` adopts orphaned activities — if `currentActivity` is nil (e.g. after app relaunch), it checks `Activity<FocusTimerAttributes>.activities` for an existing activity and reuses it

### Dual Channel Coordination

Two channels update the Dynamic Island independently:
- **APNs push** (from macOS via Vercel) — updates the Dynamic Island directly, even when the iOS app is suspended
- **KV store sync** (via `handleRemoteSync`) — updates the app's in-memory state and calls `updateActivity()`

To prevent conflicts:
- `handleRemoteSync()` never calls `startActivity()` — only `updateActivity()`, which is safe to call multiple times with the same state
- If both channels deliver the same update, the second one is a harmless no-op
- Push is the primary channel for Dynamic Island; KV store is the primary channel for foreground app state
