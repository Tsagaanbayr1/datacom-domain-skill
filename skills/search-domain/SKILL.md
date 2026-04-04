---
name: search-domain
description: Check domain name availability across multiple TLDs (.mn, .io, .biz, .cc, .asia, etc.) via datacom.mn. Use when the user wants to check if a domain is available, find a domain name, or register a domain.
argument-hint: <domain-name>
---

# Domain Availability Search — datacom.mn

Check if a domain name is available for registration using Datacom Mongolia's API.

## Instructions

Given the domain name "$ARGUMENTS", check its availability across all supported TLDs.

### Step 1: Clean the domain name

Strip any TLD the user may have included and lowercase it. The domain name (without TLD) must be at least 3 characters.

Run this to extract the clean name:

```bash
NAME=$(echo '$ARGUMENTS' | sed 's/\.\(mn\|ub\.mn\|org\.mn\|io\|biz\|info\|name\|mobi\|tv\|cc\|asia\)$//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
echo "Searching for: $NAME"
```

### Step 2: Check availability

Using the cleaned `NAME` from step 1, run this curl command:

```bash
curl -s -X POST "https://datacom.mn/search" \
  -H "Accept: text/x-component" \
  -H "Content-Type: text/plain;charset=UTF-8" \
  -H "Next-Action: 7fbf051aa44b56885a01afc8132a8c62f2878646" \
  --data "[[\"${NAME}.mn\",\"${NAME}.ub.mn\",\"${NAME}.org.mn\",\"${NAME}.io\",\"${NAME}.biz\",\"${NAME}.info\",\"${NAME}.name\",\"${NAME}.mobi\",\"${NAME}.tv\",\"${NAME}.cc\",\"${NAME}.asia\"]]"
```

### Step 3: Parse the response

The response is in RSC (React Server Components) text format. The line starting with `1:` contains a JSON array of results.

Each object in the array has:
- `tld` — the extension (e.g. `"mn"`, `"io"`)
- `domain` — full domain (e.g. `"example.mn"`)
- `status` — either `"available"` or `"unavailable"`

### Step 4: Present results

Show results as a clean table:

| Domain | Status | Register |
|--------|--------|----------|
| example.mn | Available | [Register](https://manage.datacom.mn/cart.php?a=add&domain=register&sld=example&tld=.mn) |
| example.io | Taken | — |

- Use "Available" for available domains and "Taken" for unavailable ones
- Only show the Register link for available domains
- The registration URL format is: `https://manage.datacom.mn/cart.php?a=add&domain=register&sld=NAME&tld=.TLD`

### Step 5: Summary

After the table, provide a brief summary:
- How many domains are available out of total checked
- Mention that registration can be done at datacom.mn

### Error handling

- If the response line `1:` contains `"digest"` instead of domain results, the API action ID may have changed. Inform the user that datacom.mn may have redeployed and the plugin needs updating.
- If the domain name is less than 3 characters, tell the user the minimum length requirement.

### Important notes

- Domain names must be at least 3 characters
- The `Next-Action` header ID is tied to datacom.mn's current deployment and may change if they redeploy
- Available TLDs: .mn, .ub.mn, .org.mn, .io, .biz, .info, .name, .mobi, .tv, .cc, .asia
