---
name: shortcuts-mcp
description: >
  Use when the user wants to run, discover, or manage macOS Shortcuts. This includes
  executing shortcuts by name with optional input, viewing shortcuts in the editor,
  browsing available shortcuts, checking usage statistics, recording what shortcuts
  are used for, and getting shortcut recommendations for specific tasks.
---

# shortcuts-mcp

MCP server for macOS Shortcuts automation. Executes shortcuts via AppleScript, tracks usage patterns, and maintains purpose annotations so shortcut intent persists across sessions.

## Tools

### run_shortcut

Execute a macOS Shortcut by name with optional input.

**Parameters:**

- `name` (required) — Shortcut name. Case-insensitive: the server resolves names against the shortcuts list and uses the canonical form.
- `input` (optional) — String input to pass to the shortcut.
- `purpose` (optional) — Brief phrase describing why this shortcut is being run (e.g. "check weather forecast"). Recorded as an annotation for future reference.

**Behavior:**

- Resolves shortcut names case-insensitively. If the provided name doesn't match exactly but matches after case folding, the response includes `[Resolved "input" -> "Canonical"]`.
- Executes via AppleScript (`Shortcuts Events`), which handles interactive shortcuts (file pickers, dialogs, location services).
- Records execution metrics (duration, success/failure) to daily logs.
- If `purpose` is provided and execution succeeds, the purpose is stored in the user profile annotations (deduped, max 8 per shortcut).

**Error patterns:**

- Permission error (1743): User needs to grant automation access in System Settings > Privacy & Security > Automation.
- "User canceled": The shortcut showed a dialog that was dismissed.
- "missing value": Shortcut completed but produced no output.

### shortcuts_usage

Access shortcut usage history, execution patterns, and user preferences.

**Parameters:**

- `action` — `"read"` to load resources, `"update"` to save profile data.
- `data` (optional) — Profile data to merge on update. Supports `annotations`, `context`, and `preferences`.
- `resources` (optional) — Array of `"profile"`, `"shortcuts"`, `"statistics"` to embed in the response.

**Data structure for updates:**

```json
{
  "annotations": { "Shortcut Name": { "purposes": ["brief description"] } },
  "context": { "current-projects": ["project"], "focus-areas": ["area"] },
  "preferences": {
    "favorite-shortcuts": ["name"],
    "workflow-patterns": { "pattern": ["shortcut1", "shortcut2"] }
  }
}
```

### view_shortcut

Open a macOS Shortcut in the Shortcuts editor for viewing or editing.

**Parameters:**

- `name` (required) — The shortcut name to open.

## Resources

### shortcuts://available

JSON map of all available shortcuts. Each entry includes the shortcut's system identifier and any purpose annotations from the user profile.

```json
{
  "Morning Summary": {
    "id": "ABC-123",
    "purposes": ["check weather and news"]
  },
  "Set Timer": { "id": "DEF-456" }
}
```

### context://system/current

Current system time, timezone, and day of week. Embedded automatically with `run_shortcut` responses.

### context://user/profile

User preferences, workflow patterns, and shortcut annotations.

### statistics://generated

AI-generated execution statistics: success rates, timing analysis, per-shortcut performance.

## Purpose Tracking

Shortcut names often don't describe what they do. Purpose annotations solve this:

1. When calling `run_shortcut`, include a `purpose` parameter with a brief phrase.
2. Purposes are normalized (lowercase, trimmed, whitespace-collapsed) and deduped before storage.
3. Each shortcut stores up to 8 purposes (oldest evicted first).
4. Purposes appear in the `shortcuts://available` resource, enriching the shortcuts list.

## Name Resolution

The server resolves shortcut names case-insensitively:

- Exact match is preferred (no resolution note).
- Case-insensitive fallback compares lowercased names.
- If no match is found, the original name is passed through to AppleScript (which has its own fuzzy matching).

## Notes

- **macOS only** — Requires Node 22+ and macOS Shortcuts app.
- **Interactive shortcuts** can't show UI through MCP. Use `view_shortcut` to open them in the editor when user interaction is needed.
- **Data storage** lives at `~/.shortcuts-mcp/` — profile, cache, execution logs, and statistics.
- **Shortcuts cache** refreshes every 24 hours. Delete `~/.shortcuts-mcp/shortcuts-cache.txt` to force a refresh.
