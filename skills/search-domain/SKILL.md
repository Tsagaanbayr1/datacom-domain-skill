---
name: search-domain
description: Check domain name availability across multiple TLDs (.mn, .io, .biz, .cc, .asia, etc.) via datacom.mn. Use when the user wants to check if a domain is available, find a domain name, or register a domain.
argument-hint: <domain-name>
---

# Domain Availability Search — datacom.mn

Check if a domain name is available for registration using Datacom Mongolia's API.

## Instructions

Given the domain name "$ARGUMENTS", check its availability across all supported TLDs.

### Step 1: Clean the name and check availability

Run this as **one** command, copied exactly. The argument is read through a quoted
heredoc, so the shell never expands or runs anything in it. Surrounding spaces are
trimmed, and only a name made of 3–63 letters, digits and hyphens (no spaces
inside) is ever sent to datacom.mn.

If the argument spans more than one line, do not run anything: ask the user for a
single domain name instead. Never paste the argument anywhere else in the command.

```bash
RAW=$(cat <<'DATACOM_ARG'
$ARGUMENTS
DATACOM_ARG
)
NAME=$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]')
NAME=${NAME#"${NAME%%[![:space:]]*}"}; NAME=${NAME%"${NAME##*[![:space:]]}"}
NAME=${NAME#http://}; NAME=${NAME#https://}; NAME=${NAME#www.}
for tld in ub.mn org.mn mn io biz info name mobi tv cc asia; do NAME=${NAME%".$tld"}; done
if [[ $NAME =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]]; then
  echo "Searching for: $NAME"
  curl -s -X POST "https://datacom.mn/search" \
    -H "Accept: text/x-component" \
    -H "Content-Type: text/plain;charset=UTF-8" \
    -H "Next-Action: 7fbf051aa44b56885a01afc8132a8c62f2878646" \
    --data "[[\"${NAME}.mn\",\"${NAME}.ub.mn\",\"${NAME}.org.mn\",\"${NAME}.io\",\"${NAME}.biz\",\"${NAME}.info\",\"${NAME}.name\",\"${NAME}.mobi\",\"${NAME}.tv\",\"${NAME}.cc\",\"${NAME}.asia\"]]"
else
  echo "INVALID_NAME: use 3-63 letters, digits or hyphens, without spaces or a leading/trailing hyphen." >&2
fi
```

If it prints `INVALID_NAME`, tell the user the name is not valid (at least 3
characters; letters, digits and hyphens only) and stop.

### Step 2: Parse the response

The response is in RSC (React Server Components) text format. The line starting with `1:` contains a JSON array of results.

Each object in the array has:
- `tld` — the extension (e.g. `"mn"`, `"io"`)
- `domain` — full domain (e.g. `"example.mn"`)
- `status` — either `"available"` or `"unavailable"`

### Step 3: Present results

Show results as a clean table:

| Domain | Status | Register |
|--------|--------|----------|
| example.mn | Available | [Register](https://manage.datacom.mn/cart.php?a=add&domain=register&sld=example&tld=.mn) |
| example.io | Taken | — |

- Use "Available" for available domains and "Taken" for unavailable ones
- Only show the Register link for available domains
- The registration URL format is: `https://manage.datacom.mn/cart.php?a=add&domain=register&sld=NAME&tld=.TLD`

### Step 4: Summary

After the table, provide a brief summary:
- How many domains are available out of total checked
- Mention that registration can be done at datacom.mn

### Error handling

- If the response line `1:` contains `"digest"` instead of domain results, the API action ID may have changed. Inform the user that datacom.mn may have redeployed and the plugin needs updating.
- If the domain name is less than 3 characters or contains anything other than letters, digits and hyphens, the command prints `INVALID_NAME` and sends nothing; tell the user the requirement.

### Important notes

- Domain names must be at least 3 characters
- The `Next-Action` header ID is tied to datacom.mn's current deployment and may change if they redeploy
- Available TLDs: .mn, .ub.mn, .org.mn, .io, .biz, .info, .name, .mobi, .tv, .cc, .asia
