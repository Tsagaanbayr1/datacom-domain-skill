# Datacom Domain Search — Claude Code Plugin

Search domain name availability and look up WHOIS info via [datacom.mn](https://datacom.mn), Mongolia's domain registrar.

## Install

In Claude Code, run:

```
/plugin marketplace add Tsagaanbayr1/datacom-domain-skill
/plugin install datacom@datacom-domain-skill
/reload-plugins
```

## Skills

| Skill | Usage | Description |
|-------|-------|-------------|
| `/datacom:search-domain` | `/datacom:search-domain mybusiness` | Check availability across 11 TLDs |
| `/datacom:whois` | `/datacom:whois datacom.mn` | WHOIS registration lookup |

## Examples

```
/datacom:search-domain coolshop
/datacom:whois google.mn
```

## Supported TLDs

`.mn` `.ub.mn` `.org.mn` `.io` `.biz` `.info` `.name` `.mobi` `.tv` `.cc` `.asia`

## How It Works

This plugin teaches Claude how to call datacom.mn's API via curl. No dependencies, no build step, no MCP server — just markdown skills.

- **search-domain**: Sends a POST to `datacom.mn/search` and parses the RSC response to show a table of available/unavailable domains with registration links.
- **whois**: Sends a POST to `datacom.mn/whois` and parses the WHOIS text data for clean display.

## Note

This plugin calls datacom.mn's Next.js Server Actions directly via curl. The `Next-Action` header IDs are tied to their current deployment and may need updating if they redeploy their site. If you get errors, please [open an issue](https://github.com/Tsagaanbayr1/datacom-domain-skill/issues).

## License

MIT
