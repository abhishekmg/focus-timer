# FocusTimer Push — Vercel Serverless Function

Forwards timer state changes to the iOS Dynamic Island via APNs.

## Setup

1. **Apple Developer Portal** — create an APNs Auth Key:
   - Go to Certificates, Identifiers & Profiles > Keys
   - Create a new key with "Apple Push Notifications service (APNs)" enabled
   - Download the .p8 file, note the Key ID

2. **Base64 encode the .p8 key:**
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
   ```

3. **Deploy to Vercel:**
   ```bash
   cd cloud-function
   npx vercel --prod
   ```

4. **Set environment variables** in Vercel dashboard (Settings > Environment Variables):
   - `APNS_KEY_BASE64` — the base64 string from step 2
   - `APNS_KEY_ID` — from step 1
   - `APNS_TEAM_ID` — from Apple Developer > Membership
   - `APNS_TOPIC` — `com.timelessventures.focustimer.ios.push-type.liveactivity`
   - `AUTH_SECRET` — generate with `openssl rand -hex 32`

5. **Update the app** — set your Vercel URL in `PushService.swift`:
   ```
   https://your-project.vercel.app/api/push
   ```

## Endpoint

`POST /api/push`

```json
{
  "pushToken": "hex-encoded-device-token",
  "contentState": { "phase": "work", "timerState": "paused", ... },
  "event": "update"
}
```

## Development

```bash
cd cloud-function
npx vercel dev
```

For sandbox APNs (development builds), uncomment the sandbox URL in `api/push.js`.
