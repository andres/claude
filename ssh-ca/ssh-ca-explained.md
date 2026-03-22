# SSH Certificate Authority — How It All Works

## The Players

There are **three roles** in this system. They can live on the same machine or different ones.

| Role | What it is | Your setup |
|------|-----------|------------|
| **CA (Certificate Authority)** | The trusted signer. Holds the master key pair that signs everyone's keys. | `~/ssh-ca-lab/ca/` on your main workstation |
| **Client** | The machine you SSH *from*. Holds your personal key pair + the signed certificate. | `~/.ssh/` on your workstation (or any machine you want to SSH from) |
| **Server** | The machine you SSH *into*. Trusts the CA's public key and checks certificates. | `10.9.21.27` (oldie) |

---

## The Keys — What Is What

### CA Key Pair (`~/ssh-ca-lab/ca/`)

```
ca_key       → CA private key (SECRET — the crown jewel, never leaves this machine)
ca_key.pub   → CA public key (SAFE to share — goes to every server)
```

This is the **stamp of authority**. The CA private key signs other people's keys. The CA public key is installed on servers so they can verify those signatures.

Think of it like a notary's seal. The notary has the seal (private key). Everyone knows what the seal looks like (public key). If a document has the seal on it, you trust it.

### Your Personal Key Pair (`~/.ssh/`)

```
andres_ed       → Your private key (SECRET — stays with you, proves you are you)
andres_ed.pub   → Your public key (SAFE to share — this is what the CA signs)
```

This is **your identity**. You generated it, and the private key never leaves your machine(s). The public key is what you hand to the CA to get signed.

### Your Certificate (`~/.ssh/`)

```
andres_ed-cert.pub → Your signed certificate (SAFE to share — it's your "badge")
```

This is what the CA produces when it signs your public key. It contains:

- Your public key
- Your identity (`andres@paglayan.com`)
- What usernames you're allowed to log in as (`andres`, `root`)
- When it expires (or `forever` in your case)
- The CA's signature proving all of the above is legit

---

## What Lives Where

```
YOUR WORKSTATION (CA + Client)          SERVER (oldie / 10.9.21.27)
─────────────────────────────           ───────────────────────────

~/ssh-ca-lab/ca/                        /etc/ssh/
  ca_key          ← NEVER leaves here    ca_key.pub        ← copy of CA public key
  ca_key.pub                              sshd_config       ← trusts the CA

~/.ssh/                                 /etc/ssh/auth_principals/
  andres_ed       ← your private key      andres            ← file listing: andres, root
  andres_ed.pub   ← your public key       root              ← file listing: root
  andres_ed-cert.pub ← signed cert
  config          ← Host oldie entry
```

### On a SECOND client machine (e.g., laptop)

```
~/.ssh/
  andres_ed           ← copy of your private key
  andres_ed.pub       ← copy of your public key
  andres_ed-cert.pub  ← copy of your signed cert
  config              ← Host oldie entry
```

No CA key needed. The client just needs the key pair + cert.

---

## The Process — Step by Step

### One-Time Setup

#### Step 1: Create the CA (on your workstation)

```
You run: ssh-keygen → produces ca_key + ca_key.pub

This happens ONCE. The CA key pair is the root of trust.
```

#### Step 2: Tell the server to trust the CA

```
You copy ca_key.pub → server:/etc/ssh/ca_key.pub
You edit sshd_config → TrustedUserCAKeys /etc/ssh/ca_key.pub

This tells the server: "If someone shows up with a certificate
signed by this CA, believe them."
```

#### Step 3: Define who can log in as whom (on the server)

```
You create /etc/ssh/auth_principals/andres containing:
  andres
  root

This tells the server: "If a certificate has principal 'andres'
or 'root', allow login to the 'andres' account."
```

### Signing (whenever you need a new cert)

#### Step 4: Sign your public key with the CA

```
          ┌──────────────┐
          │  CA Machine   │
          │               │
INPUT  →  │  ca_key       │  ← CA private key (does the signing)
INPUT  →  │  andres_ed.pub│  ← your public key (what gets signed)
          │               │
OUTPUT ←  │  andres_ed-cert.pub  ← THE CERTIFICATE
          └──────────────┘

The certificate = your public key + metadata + CA's signature

Metadata baked in:
  - Identity: "andres@paglayan.com"
  - Principals: andres, root  (what usernames you can use)
  - Validity: forever (or a time window like 8 hours)
```

### Connection (every time you SSH)

#### Step 5: What happens when you type `ssh oldie`

```
CLIENT (your machine)                    SERVER (oldie)
────────────────────                     ──────────────

1. SSH reads ~/.ssh/config
   → finds Host oldie
   → uses ~/.ssh/andres_ed
   → auto-discovers andres_ed-cert.pub

2. Sends the certificate ──────────────→ 3. Receives certificate

                                         4. Checks: "Is this signed by
                                            a CA I trust?"
                                            → reads /etc/ssh/ca_key.pub
                                            → verifies the signature
                                            ✓ YES, signature is valid

                                         5. Checks: "Is this cert expired?"
                                            → reads validity period
                                            ✓ NO, still valid

                                         6. Checks: "Can this cert's principals
                                            log in as 'andres'?"
                                            → reads /etc/ssh/auth_principals/andres
                                            → cert has principal "andres"
                                            ✓ YES, principal matches

                                         7. Challenges the client to prove
                                            they hold the private key
                                            (crypto challenge-response)

8. Signs the challenge with
   andres_ed (private key) ────────────→ 9. Verifies signature matches
                                            the public key in the cert
                                            ✓ YES, client has the real key

                                        10. ACCESS GRANTED
```

---

## The Trust Chain

```
ca_key (private)
  │
  │ signs
  ▼
andres_ed-cert.pub (certificate)
  │
  │ contains
  ▼
andres_ed.pub (your public key) + metadata + CA signature
  │
  │ verified against
  ▼
ca_key.pub (on server) ← "Do I trust who signed this?"


If ANY link breaks, access is denied:
  ✗ Cert not signed by trusted CA     → rejected at step 4
  ✗ Cert expired                       → rejected at step 5
  ✗ Principal not in auth_principals   → rejected at step 6
  ✗ Client doesn't have private key    → rejected at step 9
```

---

## Analogy: The Airport

| SSH Concept | Airport Equivalent |
|---|---|
| **CA private key** (`ca_key`) | The government's passport-printing machine |
| **CA public key** (`ca_key.pub`) | The passport verification database at border control |
| **Your private key** (`andres_ed`) | Your face / biometrics (only you have it) |
| **Your public key** (`andres_ed.pub`) | Your photo (representation of your identity) |
| **Your certificate** (`andres_ed-cert.pub`) | Your passport (photo + stamps + government signature) |
| **Principals** (`andres`, `root`) | Visa stamps — which countries (usernames) you can enter |
| **auth_principals file** | The immigration rulebook — which visa types are accepted |
| **Server** | The country you're entering |
| **sshd** | Border control agent |

You can copy your passport (cert + keys) to carry in multiple bags (multiple client machines).
But only the government (CA) can issue new passports.
And each country (server) decides independently which passports to accept.

---

## Adding a New Server

Repeat steps 2 and 3 on the new server. No new certs or keys needed:

1. Copy `ca_key.pub` to the new server's `/etc/ssh/ca_key.pub`
2. Add `TrustedUserCAKeys /etc/ssh/ca_key.pub` to sshd_config
3. Create `/etc/ssh/auth_principals/<username>` with allowed principals
4. Restart sshd

Your existing cert works on every server that trusts your CA.

## Adding a New Client Machine

Copy your key pair + cert. No CA key needed:

1. Copy `andres_ed`, `andres_ed.pub`, `andres_ed-cert.pub` to `~/.ssh/`
2. Set permissions (`chmod 600` on private key)
3. Add the Host entry to `~/.ssh/config`

## Adding a New User

Sign their public key with the CA:

1. They generate their own key pair and send you their `.pub` file
2. You sign it: `ssh-keygen -s ~/ssh-ca-lab/ca/ca_key -I "them" -n principal -V ... their.pub`
3. Send them back the `-cert.pub` file
4. Ensure the server's auth_principals files include their principal
