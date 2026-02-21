# Safari Tab Group -> GoodLinks (CLI)

Save every tab in a Safari Tab Group to [GoodLinks](https://goodlinks.app) — each bookmark automatically tagged based on deterministic rules you control.

No AI, no network calls, no dependencies beyond macOS + Python 3 (pre-installed on macOS).

## How it works

```
Safari Tab Group
       |
       v
[select_tab_group.applescript]   <- clicks the named group in Safari's sidebar
       |
       v
[export_tabs.applescript]        <- reads every tab's title + URL as JSON
       |
       v
[stg2gl tagging engine]         <- applies rules from config/rules.json
       |
       v
  goodlinks://x-callback-url/save?...   <- opens one GoodLinks save URL per tab
```

## Requirements

| Requirement | Why |
|---|---|
| macOS | AppleScript + Accessibility APIs are macOS-only |
| Safari | The scripts control Safari directly |
| [GoodLinks](https://goodlinks.app) | Receives bookmarks via its `goodlinks://` URL scheme |
| Python 3 | Pre-installed on macOS since Catalina. Used for JSON handling and tagging logic |

## Setup

### 1. Clone

```bash
git clone https://github.com/YOUR_USER/safari-to-goodlinks.git
cd safari-to-goodlinks
```

### 2. Grant macOS permissions

The first time you run the tool, macOS will prompt for two permissions. You can also pre-enable them:

**Accessibility** (required for Tab Group selection in `--mode select`):

> System Settings -> Privacy & Security -> Accessibility
> Toggle ON: **Terminal** (or iTerm / Script Editor — whichever app runs the script)

**Automation** (required for all modes):

> On first run, macOS will prompt:
> - "Terminal wants to control Safari" -> **Allow**
> - "Terminal wants to control System Events" -> **Allow**

If you deny either prompt by mistake, re-enable in:
> System Settings -> Privacy & Security -> Automation -> Terminal

### 3. Verify

```bash
./bin/stg2gl --help
```

You should see the full usage text. If you get `permission denied`, run:

```bash
chmod +x bin/stg2gl
```

## Usage

### Save a Tab Group by name

```bash
./bin/stg2gl --group "Work"
```

This will:
1. Open Safari and click the "Work" Tab Group in the sidebar
2. Read every tab's title and URL
3. Apply tagging rules from `config/rules.json`
4. Open a `goodlinks://` save URL for each tab (GoodLinks saves it instantly)

### Preview before saving (dry run)

```bash
./bin/stg2gl --group "Work" --dry-run
```

Example output:

```
[DRY] 'GitHub - myorg/myrepo' -> https://github.com/myorg/myrepo
      tags: tg/work dev
[DRY] 'RFC 9110: HTTP Semantics' -> https://www.rfc-editor.org/rfc/rfc9110
      tags: tg/work rfc docs
[DRY] 'Google Docs - Project Plan' -> https://docs.google.com/document/d/abc123
      tags: tg/work docs
Done. total=3 saved=3 skipped=0
```

### Add extra tags to every item

```bash
./bin/stg2gl --group "Work" --base-tag "inbox"
./bin/stg2gl --group "Work" --base-tag "inbox" --base-tag "2024-q1"
```

`--base-tag` is repeatable. Each tag is added to every saved item.

### Use current window tabs (skip Tab Group selection)

```bash
./bin/stg2gl --mode active --base-tag "quick-harvest"
```

In `active` mode, `--group` is not required. The script reads whatever tabs are in Safari's front window right now.

### Slow down for large batches

```bash
./bin/stg2gl --group "Research" --throttle 200
```

`--throttle` sets the delay in milliseconds between each save. Default is 50ms (from `rules.json`). Increase if GoodLinks drops items on very large batches.

### Limit tab count (for testing)

```bash
./bin/stg2gl --group "Work" --max 5
```

## All parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--group "Name"` | Yes (in `select` mode) | — | Tab Group name. Partial match, case-insensitive |
| `--mode select\|active` | No | `select` | `select`: click group in sidebar first. `active`: use current front window as-is |
| `--rules path/to/file.json` | No | `config/rules.json` | Path to a tagging rules file |
| `--base-tag tag` | No | — | Extra tag added to every item. Repeatable |
| `--dry-run` | No | off | Print what would be saved; do not open GoodLinks URLs |
| `--throttle ms` | No | from `rules.json` (50) | Milliseconds to wait between each save |
| `--dedupe` | No | on | Skip duplicate URLs within the same run |
| `--max N` | No | — | Only process the first N tabs |

You can also set a default rules file path via the `RULES_FILE` environment variable:

```bash
export RULES_FILE=~/my-custom-rules.json
./bin/stg2gl --group "Work"
```

## Tagging rules (`config/rules.json`)

All tagging is deterministic — no AI, no network lookups. Rules are applied in order:

### File format

```jsonc
{
  // Milliseconds to wait between saves (default if --throttle not passed)
  "throttle_ms": 50,

  // Template for the auto-added group tag. {group} is replaced with the group name.
  // e.g. group "Work" -> tag "tg/work"
  "group_tag_format": "tg/{group}",

  // Group name used when --mode active (no real group name available)
  "active_mode_group_name": "active",

  // URLs starting with any of these prefixes are silently skipped.
  // Includes non-HTTP schemes that are never useful as bookmarks.
  "skip_url_prefixes": [
    "about:",
    "file:",
    "safari-extension:",
    "javascript:",
    "data:",
    "mailto:",
    "tel:"
  ],

  // URLs matching any of these regexes are silently skipped
  "skip_url_regex": [
    "^(https?://)?localhost[:/]"
  ],

  // Substring match against the tab's hostname.
  // If the key appears anywhere in the hostname, the tags are added.
  // e.g. "github.com" matches "github.com" and "gist.github.com"
  "domain_tags": {
    "github.com": ["dev"],
    "docs.google.com": ["docs"]
  },

  // Regex match against title and/or URL.
  // "pattern": regex (case-insensitive)
  // "fields":  which fields to search — ["title"], ["url"], or ["title", "url"]
  // "tags":    tags to add if the pattern matches
  "keyword_tags": [
    {
      "pattern": "\\brfc\\b",
      "fields": ["title", "url"],
      "tags": ["rfc"]
    }
  ]
}
```

### How tags are applied (in order)

1. **Group tag** — always added: `tg/<group-name>` (lowercased, spaces become dashes)
2. **Base tags** — from `--base-tag` flags
3. **Domain tags** — if any `domain_tags` key is a substring of the tab's hostname
4. **Keyword tags** — if any `keyword_tags` pattern regex-matches the specified fields

All tags are lowercased and deduplicated. Spaces in tags become dashes.

### Domain matching details

Domain matching is **substring-based on the hostname**. The key does not support wildcards or globs.

| Key in `domain_tags` | Matches hostname | Does NOT match |
|---|---|---|
| `"github.com"` | `github.com`, `gist.github.com` | `mygithub.company.com` |
| `".gov"` | `cms.gov`, `whitehouse.gov`, `data.gov` | `govtrack.us` |
| `"bitbucket"` | `bitbucket.org`, `bitbucket.company.com` | — |

## File structure

```
safari-to-goodlinks/
├── bin/
│   └── stg2gl                          # Main CLI (bash). Start here.
├── scripts/
│   ├── select_tab_group.applescript    # Clicks a Tab Group in Safari's sidebar
│   ├── export_tabs.applescript         # Reads front window tabs as JSON
│   └── save_to_goodlinks.applescript   # Standalone: save one URL to GoodLinks
├── config/
│   └── rules.json                      # Your active tagging rules
├── examples/
│   └── rules.json                      # Extended example with more rules
└── README.md
```

## Troubleshooting

### "Could not find a Tab Group matching: ..."

- The group name is matched **case-insensitively** as a **substring** of sidebar items. Make sure the name you pass is close enough.
- Safari's sidebar must be accessible. If you recently changed Tab Group names, close and reopen Safari.

### Tabs are skipped unexpectedly

- Run with `--dry-run` to see which tabs are processed and which are skipped.
- Check `skip_url_prefixes` and `skip_url_regex` in your `rules.json` — these define which URLs are silently dropped.

### GoodLinks doesn't save some items

- Increase `--throttle` (e.g. `--throttle 200`). On large batches, the URL scheme handler can drop requests if they arrive too fast.
- Verify GoodLinks is installed and responds to `goodlinks://` URLs by running: `open "goodlinks://x-callback-url/save?quick=1&url=https%3A%2F%2Fexample.com"`

### "permission denied" running stg2gl

```bash
chmod +x bin/stg2gl
```

### macOS blocks Accessibility or Automation

Re-enable in System Settings -> Privacy & Security. You may need to remove and re-add Terminal from the Accessibility list if permissions get stuck.

## Privacy and security considerations

This tool reads your browser tabs and sends each URL to GoodLinks. Understand the following before running it.

### Accessibility permission is broad

In `--mode select`, the tool requires **macOS Accessibility permission for your Terminal app**. This permission allows the Terminal to control the UI of **any application on your Mac** — not just Safari. It persists after the script exits. Any other script or command you run from the same Terminal also inherits this power.

- Only grant Accessibility to terminal apps you trust.
- Review the scripts in `scripts/` before running to confirm they only interact with Safari.
- If you only need `--mode active`, you do **not** need Accessibility permission at all.

### URLs are synced to iCloud via GoodLinks

Every URL saved by this tool is stored in GoodLinks and **uploaded to Apple's iCloud servers**. If your tabs contain sensitive URLs — internal company tools, admin panels, healthcare portals, financial dashboards, or URLs with authentication tokens in query strings — those URLs will be synced to the cloud.

### There is no undo

Saved items go to GoodLinks immediately. There is no batch undo — you would need to delete them one by one inside GoodLinks. **Always `--dry-run` first**, especially on large Tab Groups:

```bash
# Review what would be saved
./bin/stg2gl --group "Research" --dry-run

# Then save for real only after reviewing
./bin/stg2gl --group "Research"
```

### Group name matching is partial

`--group "work"` matches the **first** sidebar element containing "work" (case-insensitive). If you have groups named "Work" and "Homework", it may match either one depending on sidebar order. Use the most specific name you can, or use `--dry-run` to verify.

### Sensitive URL filtering

The `skip_url_prefixes` and `skip_url_regex` fields in `rules.json` control which URLs are silently dropped. The defaults block non-HTTP schemes (`javascript:`, `data:`, `mailto:`, `tel:`, etc.) and localhost URLs. Add patterns for your own internal domains:

```json
{
  "skip_url_prefixes": [
    "https://internal.company.com",
    "https://admin."
  ],
  "skip_url_regex": [
    "[?&](token|key|secret|password|auth)="
  ]
}
```

### No data leaves your machine (except through GoodLinks)

The tool itself makes no network calls — all processing is local. The only external data flow is through GoodLinks' own iCloud sync.

### `--dry-run` output contains browsing history

If your terminal session is logged or recorded (e.g. iTerm2 session logs, `script` command, screen recording), the dry-run output — which includes all tab URLs and titles — will appear in those logs.

## Notes

- Safari Tab Groups are **not directly scriptable** in AppleScript. This tool uses macOS Accessibility GUI scripting to click the matching group in Safari's sidebar. This means `--mode select` requires Accessibility permission and may break if Apple changes Safari's sidebar UI in a future macOS update.
- `--mode active` does **not** require Accessibility permission — it only reads tabs from the front window.
- The `save_to_goodlinks.applescript` in `scripts/` is a standalone utility. You can use it independently: `osascript scripts/save_to_goodlinks.applescript "https://example.com" "tag1 tag2"`
