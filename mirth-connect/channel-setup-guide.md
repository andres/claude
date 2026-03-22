# Mirth Connect — FHIR R4 Channel Setup Guide

---

## Prerequisites

Before creating channels:

1. Log in at `https://localhost:8443`
2. Go to **Settings > Resources > New Directory Resource**
   - Path: `/opt/connect/custom-lib`
   - Enable **Load Parent First**
   - Enable **Include Subdirectories**
   - Click **Reload Resource**

---

## Channel 1 — JSON to FHIR R4

### Summary Tab
| Field | Value |
|---|---|
| Channel Name | `JSON to FHIR R4` |
| Description | Accepts internal JSON on port 8081, returns FHIR R4 Patient |

Click **Set Libraries** → check the custom-lib resource.

---

### Source Tab — Connector Settings
| Field | Value |
|---|---|
| Connector Type | HTTP Listener |
| Port | `8081` |
| Context Path | `/fhir/patient` |
| Response Content Type | `application/fhir+json` |
| Response Status Code | `${channelMap.get('responseStatusCode')}` |

---

### Source Tab — Transformer
Add step: **JavaScript**

```javascript
importPackage(Packages.ca.uhn.fhir.context);
importPackage(Packages.org.hl7.fhir.r4.model);

var input = JSON.parse(connectorMessage.getRawData());

var ctx = FhirContext.forR4Cached();
var parser = ctx.newJsonParser();
parser.setPrettyPrint(true);

var patient = new Patient();

patient.addIdentifier()
    .setSystem('http://example.org/fhir/mrn')
    .setValue(input.mrn || '');

patient.addName()
    .setUse(HumanName.NameUse.OFFICIAL)
    .setFamily(input.lastName || '')
    .addGiven(input.firstName || '');

var genderMap = {
    'male':   Enumerations.AdministrativeGender.MALE,
    'female': Enumerations.AdministrativeGender.FEMALE,
    'other':  Enumerations.AdministrativeGender.OTHER
};
patient.setGender(
    genderMap[String(input.gender).toLowerCase()] ||
    Enumerations.AdministrativeGender.UNKNOWN
);

if (input.dob) patient.setBirthDateElement(new DateType(String(input.dob)));

if (input.phone) {
    patient.addTelecom()
        .setSystem(ContactPoint.ContactPointSystem.PHONE)
        .setUse(ContactPoint.ContactPointUse.HOME)
        .setValue(String(input.phone));
}

if (input.address) {
    var addr = patient.addAddress();
    addr.setUse(Address.AddressUse.HOME);
    if (input.address.line)       addr.addLine(String(input.address.line));
    if (input.address.city)       addr.setCity(String(input.address.city));
    if (input.address.state)      addr.setState(String(input.address.state));
    if (input.address.postalCode) addr.setPostalCode(String(input.address.postalCode));
}

channelMap.put('responseContentType', 'application/fhir+json');
channelMap.put('responseStatusCode', '200');
return parser.encodeResourceToString(patient);
```

---

### Destinations Tab
| Field | Value |
|---|---|
| Connector Type | JavaScript Writer |
| Script | `return;` |

---

### Final Steps
- Click **Save**
- Click **Deploy**

---
---

## Channel 2 — FHIR R4 to JSON

### Summary Tab
| Field | Value |
|---|---|
| Channel Name | `FHIR R4 to JSON` |
| Description | Accepts FHIR R4 Patient on port 8082, returns internal JSON |

Click **Set Libraries** → check the custom-lib resource.

---

### Source Tab — Connector Settings
| Field | Value |
|---|---|
| Connector Type | HTTP Listener |
| Port | `8082` |
| Context Path | `/fhir/patient` |
| Response Content Type | `application/json` |
| Response Status Code | `${channelMap.get('responseStatusCode')}` |

---

### Source Tab — Transformer
Add step: **JavaScript**

```javascript
importPackage(Packages.ca.uhn.fhir.context);
importPackage(Packages.org.hl7.fhir.r4.model);

var ctx = FhirContext.forR4Cached();
var patient = ctx.newJsonParser()
    .parseResource(Patient, connectorMessage.getRawData());

// MRN
var mrn = '';
var ids = patient.getIdentifier();
for (var i = 0; i < ids.size(); i++) {
    if (String(ids.get(i).getSystem()).indexOf('mrn') !== -1) {
        mrn = String(ids.get(i).getValue());
        break;
    }
}
if (!mrn && ids.size() > 0) mrn = String(ids.get(0).getValue());

// Name
var firstName = '', lastName = '';
var names = patient.getName();
for (var n = 0; n < names.size(); n++) {
    var hn = names.get(n);
    lastName = String(hn.getFamily() || '');
    if (hn.getGiven().size() > 0)
        firstName = String(hn.getGiven().get(0).getValue());
    if (hn.getUse() == HumanName.NameUse.OFFICIAL) break;
}

// Gender
var gender = patient.getGender()
    ? String(patient.getGender().toCode()) : 'unknown';

// DOB
var dob = patient.getBirthDateElement()
    ? String(patient.getBirthDateElement().getValueAsString()) : '';

// Phone
var phone = '';
var tc = patient.getTelecom();
for (var t = 0; t < tc.size(); t++) {
    if (tc.get(t).getSystem() == ContactPoint.ContactPointSystem.PHONE) {
        phone = String(tc.get(t).getValue());
        break;
    }
}

// Address
var addressObj = {};
var addrs = patient.getAddress();
if (addrs.size() > 0) {
    var a = addrs.get(0);
    addressObj = {
        line:       a.getLine().size() > 0
                        ? String(a.getLine().get(0).getValue()) : '',
        city:       String(a.getCity()       || ''),
        state:      String(a.getState()      || ''),
        postalCode: String(a.getPostalCode() || '')
    };
}

channelMap.put('responseContentType', 'application/json');
channelMap.put('responseStatusCode', '200');
return JSON.stringify({
    mrn:       mrn,
    firstName: firstName,
    lastName:  lastName,
    dob:       dob,
    gender:    gender,
    phone:     phone,
    address:   addressObj
}, null, 2);
```

---

### Destinations Tab
| Field | Value |
|---|---|
| Connector Type | JavaScript Writer |
| Script | `return;` |

---

### Final Steps
- Click **Save**
- Click **Deploy**

---
---

## Verification

### Test Channel 1 — JSON → FHIR R4
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

### Test Channel 2 — FHIR R4 → JSON
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

## Known Pitfalls

| Symptom | Fix |
|---|---|
| "does not contain valid HAPI-FHIR annotations" | Enable **Load Parent First** on the Library Resource |
| `[JavaPackage] is not a function` | Assign the Library Resource in **Summary > Set Libraries** |
| Slow first message (~2 s) | Normal — FHIR context initialises once then reuses singleton |
| Java Strings break `JSON.stringify` | Wrap all `.get*()` returns with `String()` |
| `setBirthDate(Date)` type error | Use `setBirthDateElement(new DateType("YYYY-MM-DD"))` |
