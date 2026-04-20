---
name: shortcuts-cli
description: "Run, list, view, and sign macOS Shortcuts. Use when the user wants to trigger a Shortcut, discover available Shortcuts, open one in the editor, or sign .shortcut files for distribution. Triggers on: 'run a shortcut', 'trigger a shortcut', 'shortcuts list', 'what shortcuts do I have', 'automate with a shortcut', 'does a shortcut exist for this', 'call a shortcut from a script', 'sign a shortcut', 'open shortcut in editor'."
---

# Shortcuts

Run and manage macOS Shortcuts. Prefer the MCP tools when available — they use AppleScript and handle Location types, permissions, and execution history automatically. Fall back to the `shortcuts` CLI for discovery and signing.

## Execution — prefer MCP tools

When the shortcuts-mcp MCP server is connected, use these tools instead of the CLI:

- **`run_shortcut(name, input?, purpose?)`** — executes via AppleScript; handles Location types correctly; always pass `purpose` to build annotations
- **`view_shortcut(name)`** — opens in Shortcuts.app editor
- **`shortcuts_usage(action, resources?)`** — load `resources: ["shortcuts"]` to discover available shortcuts with purpose annotations before running

**Worked example — run Get Current Weather via MCP:**

```
run_shortcut(name: "Get Current Weather", input: "Indianapolis, IN", purpose: "check local weather forecast")
```

**Discover shortcuts before running:**

```
shortcuts_usage(action: "read", resources: ["shortcuts"])
```

## Discovery and signing — use the CLI

The MCP doesn't expose `--show-identifiers` or signing. Use the `shortcuts` CLI for these:

```bash
# List all shortcuts with stable UUIDs
shortcuts list --show-identifiers

# List shortcuts in a folder
shortcuts list --folder-name "Shannon"

# Sign a .shortcut file for distribution
shortcuts sign --input PATH --output PATH [--mode anyone|people-who-know-me]
```

## Known shortcuts (with UUIDs)

- Get Current Weather — `D238F651-1CCA-4083-A263-1D493C80CCFD`
- Speak Aloud — `ECAA6D54-8048-47DD-A1EE-736752463B40`
- Start Screen Saver — `040660C0-1F6F-4CB7-91D2-64309152FB89`

## CLI fallback — when MCP is unavailable

```bash
# Pipe text input
echo "Good morning, Law" | shortcuts run "Speak Aloud" --input-path -

# Fire and forget
shortcuts run "Start Screen Saver"

# Capture output to file (never /dev/stdout — crashes)
echo "Hello" | shortcuts run "Speak Aloud" --input-path - --output-path /tmp/out.txt
```

## Constraints

- Always prefer MCP `run_shortcut` over CLI `shortcuts run` — AppleScript handles Location types; the CLI cannot convert Text to Location
- Never use `--output-path /dev/stdout` with the CLI — crashes with NSInvalidArgumentException
- CLI `shortcuts view` opens Shortcuts.app GUI — it prints nothing to stdout
- Error 1743 from MCP means automation permissions are needed: System Settings → Privacy & Security → Automation
- After CLI `shortcuts run`, verify: `$?` is 0; if output file written, check `[ -s /tmp/out.txt ]`
