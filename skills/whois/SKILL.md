---
name: whois
description: Look up WHOIS registration information for a domain name via datacom.mn. Use when the user wants to know who owns a domain, when it was registered, or its expiry date.
argument-hint: <domain.tld>
---

# WHOIS Lookup — datacom.mn

Look up domain registration details using Datacom Mongolia's WHOIS service.

## Instructions

Given the domain "$ARGUMENTS", look up its WHOIS information.

### Step 1: Run the WHOIS query

```bash
curl -s -X POST "https://datacom.mn/whois" \
  -H "Accept: text/x-component" \
  -H "Content-Type: text/plain;charset=UTF-8" \
  -H "Next-Action: cffab30bfe61084fc501c41680d6d802e3269b58" \
  --data "[\"$ARGUMENTS\"]"
```

### Step 2: Parse the response

The response is in RSC (React Server Components) text format. The WHOIS data is on the line starting with `2:T` — the content after the first comma contains the WHOIS text with `<br />` as line breaks.

Strip all HTML tags (`<br />`, etc.) and extract the clean WHOIS information.

### Step 3: Present results

Display the WHOIS data cleanly, highlighting these key fields:

- **Domain Name**
- **Creation Date**
- **Registry Expiry Date**
- **Registrar**
- **Domain Status**
- **Name Servers**
- **Registrant Name** / **Registrant Organization** (if available)

Format dates in a human-readable way (e.g. "April 10, 2000" instead of "2000-04-10T00:00:00Z").

### Error handling

- If the response contains `"digest"` instead of WHOIS data, the API action ID may have changed. Inform the user that datacom.mn may have redeployed and the plugin needs updating.
- If no WHOIS data is returned, the domain is likely not registered — inform the user accordingly.

### Important notes

- The `Next-Action` header ID is tied to datacom.mn's current deployment and may change if they redeploy
- This works for any TLD that datacom.mn supports WHOIS lookups for
- The user must provide the full domain including TLD (e.g. `google.mn`, not just `google`)
