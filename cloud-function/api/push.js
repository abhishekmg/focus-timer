import http2 from "node:http2";
import crypto from "node:crypto";

// APNs requires HTTP/2 — Node's built-in http2 module handles this
// Use sandbox for development builds from Xcode, production for App Store builds
const APNS_HOST = "https://api.sandbox.push.apple.com";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "POST only" });
  }

  // Validate environment
  const { APNS_KEY_BASE64, APNS_KEY_ID, APNS_TEAM_ID, APNS_TOPIC, AUTH_SECRET } = process.env;
  if (!APNS_KEY_BASE64 || !APNS_KEY_ID || !APNS_TEAM_ID || !APNS_TOPIC || !AUTH_SECRET) {
    return res.status(500).json({ error: "server misconfigured — missing environment variables" });
  }

  // Authenticate
  const authHeader = req.headers["authorization"];
  if (authHeader !== `Bearer ${AUTH_SECRET}`) {
    return res.status(401).json({ error: "unauthorized" });
  }

  const { pushToken, contentState, event } = req.body;

  if (!pushToken || !contentState || !event) {
    return res.status(400).json({ error: "missing pushToken, contentState, or event" });
  }

  const jwt = createAPNsJWT();

  const payload = {
    aps: {
      timestamp: Math.floor(Date.now() / 1000),
      event,
      "content-state": contentState,
    },
  };

  if (event === "end") {
    payload.aps["dismissal-date"] = Math.floor(Date.now() / 1000) + 10;
  }

  try {
    const result = await sendAPNs(pushToken, jwt, payload);
    if (result.status === 200) {
      return res.status(200).json({ ok: true });
    } else {
      return res.status(502).json({ error: "apns_failed", status: result.status, body: result.body });
    }
  } catch (err) {
    return res.status(500).json({ error: "apns_error", message: err.message });
  }
}

// --- Send via HTTP/2 ---

function sendAPNs(pushToken, jwt, payload) {
  return new Promise((resolve, reject) => {
    let settled = false;
    const settle = (fn, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      fn(value);
    };

    const client = http2.connect(APNS_HOST);

    const timeout = setTimeout(() => {
      client.close();
      settle(reject, new Error("APNs request timed out after 10s"));
    }, 10000);

    client.on("error", (err) => {
      client.close();
      settle(reject, err);
    });

    const headers = {
      ":method": "POST",
      ":path": `/3/device/${pushToken}`,
      authorization: `bearer ${jwt}`,
      "apns-topic": process.env.APNS_TOPIC,
      "apns-push-type": "liveactivity",
      "apns-priority": "10",
    };

    const req = client.request(headers);

    req.on("error", (err) => {
      client.close();
      settle(reject, err);
    });

    let data = "";
    req.on("response", (responseHeaders) => {
      const status = responseHeaders[":status"];
      req.on("data", (chunk) => (data += chunk));
      req.on("end", () => {
        client.close();
        settle(resolve, { status, body: data });
      });
    });

    req.write(JSON.stringify(payload));
    req.end();
  });
}

// --- APNs JWT (ES256) ---

function createAPNsJWT() {
  const header = {
    alg: "ES256",
    kid: process.env.APNS_KEY_ID,
  };

  const claims = {
    iss: process.env.APNS_TEAM_ID,
    iat: Math.floor(Date.now() / 1000),
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedClaims = base64url(JSON.stringify(claims));
  const signingInput = `${encodedHeader}.${encodedClaims}`;

  // Decode the .p8 key from base64 env var
  const keyPem = Buffer.from(process.env.APNS_KEY_BASE64, "base64").toString("utf8");

  const sign = crypto.createSign("SHA256");
  sign.update(signingInput);
  // Sign returns DER, we need raw r||s for ES256
  const derSig = sign.sign(keyPem);
  const rawSig = derToRaw(derSig);
  const encodedSig = base64url(rawSig);

  return `${signingInput}.${encodedSig}`;
}

function base64url(input) {
  const buf = typeof input === "string" ? Buffer.from(input) : input;
  return buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function derToRaw(der) {
  // DER: 0x30 <len> 0x02 <rLen> <r> 0x02 <sLen> <s>
  let offset = 2;
  if (der[1] & 0x80) offset += der[1] & 0x7f;

  offset++; // 0x02
  const rLen = der[offset++];
  let r = der.slice(offset, offset + rLen);
  offset += rLen;

  offset++; // 0x02
  const sLen = der[offset++];
  let s = der.slice(offset, offset + sLen);

  if (r.length > 32) r = r.slice(r.length - 32);
  if (s.length > 32) s = s.slice(s.length - 32);

  const raw = Buffer.alloc(64);
  r.copy(raw, 32 - r.length);
  s.copy(raw, 64 - s.length);
  return raw;
}
