---
name: shortcuts-cli
description: "DEPRECATED — macOS Shortcuts capability has been absorbed into the Switchboard plugin. Use the switchboard-usage skill instead (run_shortcut, view_shortcut, shortcuts_usage MCP tools, plus the `switchboard shortcuts` CLI). Do not trigger this skill; if a request mentions running, listing, or viewing macOS Shortcuts, defer to switchboard-usage."
---

# Shortcuts (deprecated)

This skill has been folded into the Switchboard plugin. The shortcuts-mcp
plugin is on track for retirement once the absorb is verified end-to-end.

For anything Shortcuts-related — running, listing, viewing, discovering, or
recording purpose annotations — use the **switchboard-usage** skill. The same
tool names (`run_shortcut`, `view_shortcut`, `shortcuts_usage`) are now
exposed by the `switchboard` MCP server, and the CLI fallback is
`switchboard shortcuts <run|list|view>`.

Signing `.shortcut` files (`shortcuts sign`) is still done with Apple's
system CLI — switchboard doesn't wrap that yet.
