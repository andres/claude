# Mirth Connect + PostgreSQL (Docker)

## Prerequisites

- Docker and Docker Compose installed
- AWS CLI installed

---

## 1. Start the containers

```bash
docker compose up -d
```

Wait ~60 seconds for Mirth Connect to fully initialize.

---

## 2. Download the Administrator Launcher

```bash
aws s3 cp s3://downloads.mirthcorp.com/connect-client-launcher/mirth-administrator-launcher-latest-unix.sh . --no-sign-request
```

---

## 3. Install the Administrator Launcher

```bash
chmod +x mirth-administrator-launcher-latest-unix.sh
sudo ./mirth-administrator-launcher-latest-unix.sh
```

Follow the on-screen installer prompts.

---

## 4. Launch the Administrator client

After installation, launch the Mirth Administrator from your applications menu or run:

```bash
/opt/mirth-administrator-launcher/launcher
```

---

## 5. Connect to the server

In the Administrator Launcher, enter the following and click **Launch**:

| Field    | Value                   |
|----------|-------------------------|
| Address  | `https://localhost:8443` |

---

## 6. Log in

| Field    | Value   |
|----------|---------|
| Username | `admin` |
| Password | `admin` |

You will be prompted to change the password on first login.

---

## Ports

| Port   | Protocol | Purpose                          |
|--------|----------|----------------------------------|
| `8080` | HTTP     | Browser download page            |
| `8443` | HTTPS    | Administrator Launcher (client)  |
| `8081` | HTTP     | FHIR channel: JSON → FHIR R4     |
| `8082` | HTTP     | FHIR channel: FHIR R4 → JSON     |

---

## Stop the containers

```bash
docker compose down
```

To also remove all data volumes:

```bash
docker compose down -v
```

---

## FHIR R4 Integration

This stack embeds [HAPI FHIR 7.6.0](https://hapifhir.io/) (Apache 2.0) into the Mirth Docker image at build time. Two Mirth channels provide bidirectional JSON ↔ FHIR R4 transformation over HTTP.

### Build the custom image

The first `docker compose up` (or an explicit `docker compose build`) will run a Maven multi-stage build to download all HAPI FHIR JARs:

```bash
docker compose build --no-cache
docker compose up -d
```

Verify the JARs are present inside the container:

```bash
docker exec mirth-connect ls /opt/connect/custom-lib/ | grep hapi
```

---

### One-time Mirth Administrator setup (per fresh data volume)

These steps configure the classloader so Mirth can find the HAPI FHIR classes.

#### 1. Create a Library Resource

1. Log in at `https://localhost:8443`
2. Go to **Settings > Resources > New Directory Resource**
3. Set the path to `/opt/connect/custom-lib`
4. Enable **Load Parent First** — this is critical; without it you will get "does not contain valid HAPI-FHIR annotations" errors
5. Enable **Include Subdirectories**
6. Click **Reload Resource**

#### 2. Import the channel XML files

- **Channels > Import Channel** → `channels/json-to-fhir-channel.xml`
- **Channels > Import Channel** → `channels/fhir-to-json-channel.xml`

#### 3. Assign the Library Resource to each channel

For each imported channel:

1. Open the channel
2. Go to the **Summary** tab
3. Click **Set Libraries**
4. Check the custom-lib resource you created
5. **Save** and **Deploy**

---

### Internal JSON schema

```json
{
  "mrn": "MRN-2024-001",
  "firstName": "Jane",
  "lastName": "Smith",
  "dob": "1985-03-15",
  "gender": "female",
  "phone": "555-867-5309",
  "address": {
    "line": "123 Elm Street",
    "city": "Springfield",
    "state": "IL",
    "postalCode": "62701"
  }
}
```

---

### Verification (curl tests)

**JSON → FHIR R4** (port 8081):

```bash
curl -s -X POST http://localhost:8081/fhir/patient \
  -H "Content-Type: application/json" \
  -d '{
    "mrn": "MRN-001",
    "firstName": "Jane",
    "lastName": "Smith",
    "dob": "1985-03-15",
    "gender": "female",
    "phone": "555-1234",
    "address": {
      "line": "123 Elm St",
      "city": "Springfield",
      "state": "IL",
      "postalCode": "62701"
    }
  }' | python3 -m json.tool
```

**FHIR R4 → JSON** (port 8082):

```bash
curl -s -X POST http://localhost:8082/fhir/patient \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "identifier": [{"system": "http://example.org/fhir/mrn", "value": "MRN-001"}],
    "name": [{"use": "official", "family": "Smith", "given": ["Jane"]}],
    "gender": "female",
    "birthDate": "1985-03-15"
  }' | python3 -m json.tool
```

---

### Known pitfalls

| Symptom | Fix |
|---|---|
| "does not contain valid HAPI-FHIR annotations" | Enable **Load Parent First** on the Library Resource |
| `[JavaPackage] is not a function` | Assign the Library Resource to the channel in **Summary > Set Libraries** |
| Slow first message (~2 s) | Normal — `FhirContext.forR4Cached()` initialises once then reuses the singleton |
| Java Strings break `JSON.stringify` | Wrap all `.get*()` return values with `String()` in Rhino JavaScript |
| `setBirthDate(Date)` type error | Use `setBirthDateElement(new DateType("YYYY-MM-DD"))` instead |
