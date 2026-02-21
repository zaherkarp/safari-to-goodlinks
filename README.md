# Safari Tab Group -> GoodLinks (CLI)

Save all tabs from a Safari Tab Group into GoodLinks with deterministic "smart" tags.

## Requirements

- macOS with Safari and GoodLinks installed
- Terminal permissions:
  - Privacy & Security -> Accessibility: enable for your runner (Terminal / iTerm / Script Editor)
  - Privacy & Security -> Automation: allow Terminal to control Safari (prompt appears on first run)

## Install

Clone repo, then:

```bash
chmod +x bin/stg2gl
```

## Usage

**Save a named Tab Group (script selects it):**

```bash
./bin/stg2gl --group "Work"
```

**Add a base tag for the whole batch:**

```bash
./bin/stg2gl --group "Work" --base-tag "inbox"
```

**Dry run (prints URLs and tags, does not save):**

```bash
./bin/stg2gl --group "Work" --dry-run
```

**Huge batches (slower throttle):**

```bash
./bin/stg2gl --group "Research" --throttle 120
```

**No Tab Group selection (uses current front Safari window tabs):**

```bash
./bin/stg2gl --mode active --base-tag "quick-harvest"
```

**Limit for testing:**

```bash
./bin/stg2gl --group "Work" --max 10
```

## Tagging Logic

Rules live in `config/rules.json`:

- Always adds: `tg/<group-name>`
- Adds domain tags based on substring match of host
- Adds keyword tags based on regex search in title/url
- Customize `domain_tags` and `keyword_tags` to taste

## Parameters

| Parameter | Meaning |
|---|---|
| `--group "Name"` | Tab Group name (exact or partial match) |
| `--mode select` | Select group by name via Accessibility (default) |
| `--mode active` | Don't select group, just use current Safari front window |
| `--rules file.json` | Use a different tagging rules file |
| `--base-tag tag` | Add a tag to everything (repeatable) |
| `--throttle ms` | Delay per save to avoid drops on big batches |
| `--dry-run` | Print what would happen, don't save |
| `--max N` | Process only first N tabs |

## Security Permissions

On first run you'll get prompts, but you can also pre-enable:

1. **Accessibility**
   System Settings -> Privacy & Security -> Accessibility
   Enable: **Terminal** (or iTerm / Script Editor, whichever runs the script)

2. **Automation**
   The first time Terminal tries to control Safari, macOS will prompt:
   - Allow Terminal to control **Safari**
   - Allow Terminal to control **System Events** (for UI scripting)

## Notes

Safari Tab Groups are not directly scriptable in AppleScript. This repo uses Accessibility GUI scripting to select by name in Safari's sidebar.

## Smart Tagging Upgrades

Extend `config/rules.json` to add more tagging rules:

- Add domain buckets: `*.gov` -> `gov`, `*.edu` -> `edu`, `arxiv.org` -> `papers`
- Add keyword patterns for tutorials, videos, RFCs, changelogs, etc.
- See `examples/rules.json` for an extended example with more rules
