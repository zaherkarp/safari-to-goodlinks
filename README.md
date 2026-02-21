# Safari Tab Group -> GoodLinks / Local Storage (CLI)

Save every tab in a Safari Tab Group — with smart auto-tagging — to [GoodLinks](https://goodlinks.app) or to a **local file** (JSON, SQLite, Markdown) that never touches the cloud.

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
   --output ?
       |
       ├── goodlinks  ->  goodlinks://x-callback-url/save  (syncs to iCloud)
       ├── json       ->  local .json file                  (no cloud)
       ├── sqlite     ->  local .db file                    (no cloud)
       └── markdown   ->  local .md file                    (no cloud)
```

## Requirements

| Requirement | Why |
|---|---|
| macOS | AppleScript + Accessibility APIs are macOS-only |
| Safari | The scripts control Safari directly |
| Python 3 | Pre-installed on macOS since Catalina. Used for JSON handling and tagging logic |
| [GoodLinks](https://goodlinks.app) | Only needed if using `--output goodlinks` (the default) |

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

### Save to GoodLinks (default, syncs to iCloud)

```bash
./bin/stg2gl --group "Work"
```

### Save to a local JSON file (no cloud)

```bash
./bin/stg2gl --group "Work" --output json
```

Creates `./stg2gl_bookmarks.json`. New runs append to the same file. Each item:

```json
{
  "url": "https://github.com/myorg/myrepo",
  "title": "GitHub - myorg/myrepo",
  "tags": ["tg/work", "dev"],
  "saved_at": "2026-02-21T17:30:00+00:00"
}
```

### Save to a local SQLite database (no cloud)

```bash
./bin/stg2gl --group "Work" --output sqlite
```

Creates `./stg2gl_bookmarks.db` with a `bookmarks` table. Duplicate URLs are silently skipped (UNIQUE constraint). Query it with any SQLite tool:

```bash
sqlite3 stg2gl_bookmarks.db "SELECT title, tags FROM bookmarks WHERE tags LIKE '%dev%'"
```

### Save to a local Markdown file (no cloud)

```bash
./bin/stg2gl --group "Work" --output markdown
```

Appends a dated section to `./stg2gl_bookmarks.md`:

```markdown
## 2026-02-21 17:30 — Work

- [GitHub - myorg/myrepo](https://github.com/myorg/myrepo) `tg/work` `dev`
- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110) `tg/work` `rfc` `docs`
```

Works with Obsidian, any text editor, or version control.

### Custom output file path

```bash
./bin/stg2gl --group "Work" --output sqlite --output-file ~/bookmarks.db
./bin/stg2gl --group "Work" --output json --output-file ~/Desktop/tabs.json
```

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
./bin/stg2gl --mode active --output json --base-tag "quick-harvest"
```

In `active` mode, `--group` is not required. The script reads whatever tabs are in Safari's front window right now.

### Slow down for large GoodLinks batches

```bash
./bin/stg2gl --group "Research" --throttle 200
```

`--throttle` sets the delay in milliseconds between each GoodLinks save. Default is 50ms (from `rules.json`). Increase if GoodLinks drops items. Not needed for local output modes.

### Limit tab count (for testing)

```bash
./bin/stg2gl --group "Work" --max 5
```

## All parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--group "Name"` | Yes (in `select` mode) | — | Tab Group name. Partial match, case-insensitive |
| `--mode select\|active` | No | `select` | `select`: click group in sidebar first. `active`: use current front window as-is |
| `--output target` | No | `goodlinks` | Where to save: `goodlinks`, `json`, `sqlite`, or `markdown` |
| `--output-file path` | No | auto | File path for local output (default: `./stg2gl_bookmarks.{json,db,md}`) |
| `--rules path/to/file.json` | No | `config/rules.json` | Path to a tagging rules file |
| `--base-tag tag` | No | — | Extra tag added to every item. Repeatable |
| `--dry-run` | No | off | Print what would be saved; do not save anywhere |
| `--throttle ms` | No | from `rules.json` (50) | Milliseconds to wait between each GoodLinks save |
| `--dedupe` | No | on | Skip duplicate URLs within the same run |
| `--max N` | No | — | Only process the first N tabs |

You can also set a default rules file path via the `RULES_FILE` environment variable:

```bash
export RULES_FILE=~/my-custom-rules.json
./bin/stg2gl --group "Work"
```

## Output modes compared

| | `goodlinks` | `json` | `sqlite` | `markdown` |
|---|---|---|---|---|
| **Cloud sync** | iCloud (via GoodLinks) | None | None | None |
| **Data stays on disk** | No | Yes | Yes | Yes |
| **Needs GoodLinks installed** | Yes | No | No | No |
| **Queryable** | In GoodLinks app | `jq`, Python | SQL (`sqlite3`) | Text search |
| **Dedup across runs** | GoodLinks handles it | Manual | Automatic (UNIQUE) | Manual |
| **Importable to** | — | GoodLinks, buku, Raindrop | Any SQLite tool | Obsidian, nb |
| **Human-readable** | Via app | With `jq` | With `sqlite3` | Directly |

**Recommendation:** Use `--output json` or `--output sqlite` if you want your bookmarks to stay entirely local. You can always import the JSON into GoodLinks later if you decide to.

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

This tool reads your browser tabs and saves them. Where that data ends up depends on which `--output` mode you use.

### Choose your output mode based on sensitivity

| Concern | Use this |
|---|---|
| Tabs contain sensitive/internal URLs | `--output json` or `--output sqlite` (local only) |
| You want iCloud sync across devices | `--output goodlinks` (default) |
| You want to review before saving anywhere | `--dry-run` first, always |

### Accessibility permission is broad

In `--mode select`, the tool requires **macOS Accessibility permission for your Terminal app**. This permission allows the Terminal to control the UI of **any application on your Mac** — not just Safari. It persists after the script exits. Any other script or command you run from the same Terminal also inherits this power.

- Only grant Accessibility to terminal apps you trust.
- Review the scripts in `scripts/` before running to confirm they only interact with Safari.
- If you only need `--mode active`, you do **not** need Accessibility permission at all.

### `--output goodlinks`: URLs are synced to iCloud

Every URL saved via GoodLinks is stored in GoodLinks and **uploaded to Apple's iCloud servers**. If your tabs contain sensitive URLs — internal company tools, admin panels, healthcare portals, financial dashboards, or URLs with authentication tokens in query strings — those URLs will be synced to the cloud.

**To avoid this entirely**, use `--output json`, `--output sqlite`, or `--output markdown`. These write only to local files on your disk.

### There is no undo (GoodLinks mode)

Saved items go to GoodLinks immediately. There is no batch undo — you would need to delete them one by one inside GoodLinks. **Always `--dry-run` first**, especially on large Tab Groups:

```bash
# Review what would be saved
./bin/stg2gl --group "Research" --dry-run

# Then save for real only after reviewing
./bin/stg2gl --group "Research"
```

Local output modes (json, sqlite, markdown) are easier to undo — just delete the file or remove the last entries.

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

The tool itself makes no network calls — all processing is local. The only external data flow is through GoodLinks' own iCloud sync, and only when using `--output goodlinks`.

### `--dry-run` output contains browsing history

If your terminal session is logged or recorded (e.g. iTerm2 session logs, `script` command, screen recording), the dry-run output — which includes all tab URLs and titles — will appear in those logs.

## Notes

- Safari Tab Groups are **not directly scriptable** in AppleScript. This tool uses macOS Accessibility GUI scripting to click the matching group in Safari's sidebar. This means `--mode select` requires Accessibility permission and may break if Apple changes Safari's sidebar UI in a future macOS update.
- `--mode active` does **not** require Accessibility permission — it only reads tabs from the front window.
- The `save_to_goodlinks.applescript` in `scripts/` is a standalone utility. You can use it independently: `osascript scripts/save_to_goodlinks.applescript "https://example.com" "tag1 tag2"`
- **Similar tools:** [buku](https://github.com/jarun/buku) (CLI bookmark manager, SQLite-backed, local-first) and [nb](https://github.com/xwmx/nb) (CLI note/bookmark tool, Markdown + Git) take a local-first approach to bookmark storage. If you outgrow this tool's local output modes, either is a good next step.
