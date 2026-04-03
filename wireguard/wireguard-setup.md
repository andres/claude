# WireGuard Tunnel: Office Ollama <-> Digital Ocean OpenFang

## Overview

```
┌─────────────────────┐          WireGuard tunnel          ┌─────────────────────┐
│   Office Machine    │◄──────────────────────────────────►│  Digital Ocean (DO)  │
│                     │         10.0.0.2 <-> 10.0.0.1      │                     │
│  Ollama :11434      │                                     │  OpenFang           │
│  WireGuard peer     │                                     │  WireGuard peer     │
└─────────────────────┘                                     └─────────────────────┘

Office machine initiates outbound connection to DO.
No NAT port forwarding needed on the office side.
```

---

## Step 1: Install WireGuard on both machines

Run on **both** machines:

```bash
sudo apt update && sudo apt install -y wireguard
```

---

## Step 2: Generate keys on both machines

### On the DO machine:

```bash
umask 077
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

Note the public key:

```bash
sudo cat /etc/wireguard/public.key
```

### On the Office machine:

```bash
umask 077
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

Note the public key:

```bash
sudo cat /etc/wireguard/public.key
```

---

## Step 3: Configure the DO machine

```bash
sudo nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <PASTE DO PRIVATE KEY>

[Peer]
# Office machine
PublicKey = <PASTE OFFICE PUBLIC KEY>
AllowedIPs = 10.0.0.2/32
```

To get the private key:

```bash
sudo cat /etc/wireguard/private.key
```

### Open the firewall on DO

```bash
# UFW (common on DO droplets)
sudo ufw allow 51820/udp
```

Also allow it in the Digital Ocean dashboard firewall if you have one configured (Networking > Firewalls): add an inbound rule for **UDP port 51820**.

---

## Step 4: Configure the Office machine

```bash
sudo nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <PASTE OFFICE PRIVATE KEY>

[Peer]
# DO machine
PublicKey = <PASTE DO PUBLIC KEY>
Endpoint = <DO PUBLIC IP>:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
```

Replace `<DO PUBLIC IP>` with the actual public IP of your Digital Ocean droplet.

`PersistentKeepalive = 25` keeps the tunnel alive through NAT so the DO machine can always reach back.

---

## Step 5: Start WireGuard on both machines

Run on **both** machines:

```bash
# Start the tunnel
sudo wg-quick up wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0
```

---

## Step 6: Verify the connection

### From the DO machine:

```bash
# Check tunnel status
sudo wg show

# Ping the office machine
ping 10.0.0.2

# Test Ollama
curl http://10.0.0.2:11434/api/tags
```

### From the Office machine:

```bash
# Check tunnel status
sudo wg show

# Ping DO
ping 10.0.0.1
```

---

## Step 7: Configure OpenFang

In your OpenFang configuration, set the Ollama endpoint to:

```
http://10.0.0.2:11434
```

---

## Step 8: Make sure Ollama accepts connections

If Ollama on the office machine is running in Docker, make sure it binds to `0.0.0.0`:

```bash
docker run -d --name ollama -p 11434:11434 ollama/ollama
```

If Ollama is running as a native service, set:

```bash
sudo systemctl edit ollama
```

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

Then restart: `sudo systemctl restart ollama`

---

## Troubleshooting

```bash
# Check WireGuard status and handshake
sudo wg show

# If "latest handshake" shows a recent time, the tunnel is working
# If there is no handshake, check:
#   - DO firewall allows UDP 51820 inbound
#   - Public keys are correct (swapped between peers)
#   - DO public IP is correct in the office config

# Restart the tunnel
sudo wg-quick down wg0 && sudo wg-quick up wg0

# Check logs
sudo journalctl -u wg-quick@wg0 -f
```

## Security notes

- Only traffic to/from `10.0.0.1` and `10.0.0.2` flows through the tunnel (`AllowedIPs` is scoped tight)
- Ollama is only reachable via the WireGuard IP, not from the public internet
- No NAT port forwarding is needed on the office router
- WireGuard uses modern cryptography (Curve25519, ChaCha20, Poly1305)
