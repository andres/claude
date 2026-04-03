# pfang.site Server Setup — Session Summary

**Date:** 2026-03-26
**Server:** paglafang (ssh paglafang), Ubuntu
**Domain:** pfang.site
**IP:** 192.124.249.6

## Stack

- **OpenFang Agent OS** v0.5.1 — installed at `/home/pfang/.openfang/`
- **Caddy** — reverse proxy + automatic Let's Encrypt TLS
- **Default model:** anthropic/claude-haiku-4-5-20251001
- **API listen:** 0.0.0.0:4200

## Configuration Files

### OpenFang config: `/home/pfang/.openfang/config.toml`

```toml
api_listen = "0.0.0.0:4200"

[default_model]
provider = "anthropic"
model = "claude-haiku-4-5-20251001"
api_key_env = "ANTHROPIC_API_KEY"

[memory]
decay_rate = 0.05

[routing]
simple_model = "claude-haiku-4-5-20251001"
medium_model = "claude-sonnet-4-6"
complex_model = "claude-opus-4-6"
simple_threshold = 100
complex_threshold = 500
```

### Caddyfile: `/etc/caddy/Caddyfile`

```
pfang.site {
    basic_auth * {
        pfang $2a$14$...
    }
    reverse_proxy 127.0.0.1:4200 {
        header_down Content-Security-Policy "...connect-src 'self' ws://pfang.site wss://pfang.site ws://localhost:* ws://127.0.0.1:* wss://localhost:* wss://127.0.0.1:*..."
    }
}
```

Key: Caddy overrides the upstream CSP `Content-Security-Policy` header to add `ws://pfang.site` and `wss://pfang.site` to `connect-src`, so WebSocket connections work through the reverse proxy.

### Systemd service: `/etc/systemd/system/openfang.service`

```ini
[Unit]
Description=OpenFang Agent OS
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pfang
Group=pfang
WorkingDirectory=/home/pfang
ExecStart=/home/pfang/.openfang/bin/openfang start
EnvironmentFile=/home/pfang/.openfang/.env
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enabled and starts on boot.

## Issues Fixed

### 1. Redirect loop ("pfang.site redirected you too many times")

**Cause:** Original Caddyfile had two blocks — `yourdomain.com` (placeholder with the actual reverse_proxy) and `pfang.site` (with only `redir https://pfang.site{uri} permanent`). The pfang.site block redirected to itself infinitely.

**Fix:** Replaced entire Caddyfile with a single `pfang.site` block containing basicauth + reverse_proxy to 127.0.0.1:4200.

### 2. OpenFang daemon not running

**Cause:** Only `openfang chat` was running interactively on a terminal. The API server (`openfang start`) wasn't launched.

**Fix:** Ran `openfang start` and created a systemd service for persistence.

### 3. WebSocket CSP blocking (dashboard hangs with spinner)

**Cause:** OpenFang's built-in CSP header only allows WebSocket connections to `localhost` and `127.0.0.1`. When accessed via `pfang.site`, the browser blocks the WebSocket connection, causing the dashboard to hang.

**Fix:** Added `header_down Content-Security-Policy` in the Caddy reverse_proxy block to override the upstream header, adding `ws://pfang.site wss://pfang.site` to `connect-src`.

### 4. Chrome caching 301 permanent redirect

**Cause:** The original `redir ... permanent` (301) got cached by Chrome. Clearing cookies, hard reload, clearing HSTS, and DevTools cache clear did not flush it.

**Fix:** `chrome://settings/content/all` → search `pfang` → delete the pfang.site entry. This is the only reliable way to clear a cached 301 in Chrome.

## Agents on the server

- `assistant` (persisted, restored on daemon start)
- `General Assistant` and `Code Helper` (spawned at runtime, crashed due to heartbeat timeout after inactivity — auto-recovery)

## Notes

- Ollama, vLLM, LMStudio, Lemonade are configured as local providers but not installed/running (warnings in logs, harmless)
- Basicauth user: `pfang`
- ANTHROPIC_API_KEY is stored in `/home/pfang/.openfang/.env`
- Chat session history survives daemon restarts (stored on disk), but the web UI may take a moment to load and restore previous sessions
