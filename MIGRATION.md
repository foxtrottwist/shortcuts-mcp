# Migration Guide: TypeScript to Swift

This guide helps you migrate from the TypeScript version of shortcuts-mcp to the new Swift implementation.

## Overview

The Swift version (`v4.0.0+`) maintains full backward compatibility with the TypeScript version (`v3.x`) while adding new features for programmatic shortcut generation, templates, and signing. Both versions can coexist in your configuration.

## Compatibility Matrix

| Feature | TypeScript | Swift |
|---------|-----------|-------|
| `run_shortcut` | ✅ | ✅ |
| `list_shortcuts` | ✅ | ✅ |
| `view_shortcut` | ✅ | ✅ |
| `shortcuts_usage` | ✅ | ✅ |
| `create_shortcut` | ❌ | ✅ |
| `list_templates` | ❌ | ✅ |
| Templates (API, text, file) | ❌ | ✅ |
| Action catalog | ❌ | ✅ |
| Signing & import | ❌ | ✅ |
| Import questions | ❌ | ✅ |

## Installation & Deployment

### Option 1: Use MCP Bundle (Recommended)

No migration needed - the .mcpb bundle is the same installation method for both versions. Simply download the latest release and install.

### Option 2: Build from Source

#### Switching from TypeScript to Swift

If currently using TypeScript from source:

```bash
# Current TypeScript setup
cd shortcuts-mcp
npm run build
```

To switch to Swift:

```bash
# Build Swift version
cd shortcuts-mcp/swift
swift build -c release
```

Update your MCP client configuration:

```json
{
  "mcpServers": {
    "shortcuts-mcp": {
      "command": "/absolute/path/to/shortcuts-mcp/swift/.build/release/shortcuts-mcp"
    }
  }
}
```

#### Coexisting Installations

You can run both versions simultaneously with different names:

```json
{
  "mcpServers": {
    "shortcuts-mcp-ts": {
      "command": "node",
      "args": ["/path/to/shortcuts-mcp/dist/server.js"]
    },
    "shortcuts-mcp": {
      "command": "/path/to/shortcuts-mcp/swift/.build/release/shortcuts-mcp"
    }
  }
}
```

## API Differences

### Tool Parameters

All existing tools work identically:

```typescript
// TypeScript
{
  "name": "run_shortcut",
  "shortcutName": "Get Weather",
  "input": "optional input"
}

// Swift - identical
{
  "name": "run_shortcut",
  "name": "Get Weather",
  "input": "optional input"
}
```

### New Tools (Swift Only)

#### `create_shortcut` - Create .shortcut Files

```json
{
  "name": "create_shortcut",
  "action_definition": {
    "name": "my-shortcut",
    "actions": [
      {
        "identifier": "is.workflow.actions.gettext",
        "parameters": {
          "WFTextActionText": "Hello World"
        }
      }
    ]
  }
}
```

#### `list_templates` - Discover Templates

```json
{
  "name": "list_templates",
  "action_definition": {
    "verbose": false
  }
}
```

### Resource Differences

Resources are compatible. Return values are identical:

```json
// Both versions return the same structure
{
  "shortcuts://available": "Shortcut 1\nShortcut 2\n..."
}
```

New resources in Swift version (don't break existing clients):

```json
{
  "actions://catalog": "Action catalog (progressive disclosure)"
}
```

### Prompt Differences

Prompts are identical and can be used with either version:

```json
{
  "name": "Recommend a Shortcut",
  "arguments": {
    "task_description": "What I want to do",
    "context": "Additional context"
  }
}
```

## Breaking Changes

**There are no breaking changes.** The Swift version maintains 100% API compatibility with the TypeScript version for all existing tools and resources.

All changes are additive (new tools, resources, templates).

## New Features Guide

### Creating Shortcuts Programmatically

The new `create_shortcut` tool in the Swift version enables AI assistants to generate complete .shortcut files:

```json
{
  "name": "create_shortcut",
  "action_definition": {
    "name": "weather-check",
    "template": "api-request",
    "templateParams": {
      "url": "https://api.weather.gov/points/40.7128,-74.0060",
      "method": "GET",
      "jsonPath": "properties.periods.0.shortForecast"
    },
    "autoImport": true,
    "sign": true
  }
}
```

### Using Templates

Pre-built templates reduce token usage and improve reliability:

```bash
# Available templates:
# - api-request: HTTP requests with JSON parsing
# - text-pipeline: Text transformations (case, split, combine, replace)
# - file-download: Download and save files to disk
```

Example: Text processing pipeline

```json
{
  "name": "create_shortcut",
  "action_definition": {
    "name": "cleanup-text",
    "template": "text-pipeline",
    "templateParams": {
      "inputText": "User provided text",
      "operations": "[
        {\"type\": \"uppercase\"},
        {\"type\": \"replace\", \"find\": \"OLD\", \"replace\": \"NEW\"},
        {\"type\": \"split\", \"separator\": \"spaces\"}
      ]"
    }
  }
}
```

### Action Catalog

Browse available actions via progressive disclosure:

```json
// Level 1: Categories
{
  "uri": "actions://catalog"
}
// Returns: {categories: [{name: "text", action_count: 6}, ...]}

// Level 2: Actions in category
{
  "uri": "actions://catalog/text"
}
// Returns: {actions: [{name: "replace-text", id: "is.workflow.actions.text.replace"}, ...]}

// Level 3: Full parameter schema
{
  "uri": "actions://catalog/text/replace-text"
}
// Returns: {parameters: [{name: "find", type: "string", required: true}, ...]}
```

### Signing & Auto-Import

Generated shortcuts can be automatically signed and imported:

```json
{
  "name": "create_shortcut",
  "action_definition": {
    "name": "api-shortcut",
    "actions": [...],
    "sign": true,
    "signingMode": "anyone",  // or "peopleWhoKnowMe"
    "autoImport": true        // Automatically open in Shortcuts app
  }
}
```

Response includes:

```json
{
  "filePath": "/path/to/api-shortcut.shortcut",
  "signedFilePath": "/path/to/api-shortcut-signed.shortcut",
  "imported": true,
  "importError": null
}
```

### Import Questions

Prompts users for secrets when importing:

```json
{
  "name": "create_shortcut",
  "action_definition": {
    "name": "api-shortcut",
    "importQuestions": [
      {
        "actionIndex": 0,
        "parameterKey": "WFAPIKey",
        "category": "API Key",
        "text": "Enter your API key"
      }
    ]
  }
}
```

When importing, the user will be prompted: "Enter your API key"

## Performance Considerations

### TypeScript vs Swift

**TypeScript (v3.x)**:
- Node.js runtime required
- Good for command-line integration
- ~50ms warmup per request

**Swift (v4.0+)**:
- Native binary, faster startup
- ~5-10ms per request
- Lower memory footprint
- Better for high-frequency operations

### Caching

Both versions cache shortcuts list for 24 hours. To refresh:

```json
{
  "name": "list_shortcuts",
  "action_definition": {
    "refresh": true
  }
}
```

## Troubleshooting Migration

### "Unknown tool" errors

If you see "Unknown tool: create_shortcut", you're using the TypeScript version. Either:
1. Update to the Swift version, or
2. Use only TypeScript-compatible tools (run_shortcut, list_shortcuts, view_shortcut, shortcuts_usage)

### "Cannot find shortcuts CLI"

Both versions require the `shortcuts` CLI to be available. Verify:

```bash
which shortcuts
shortcuts list --show-identifiers
```

If not found, update macOS or install the Shortcuts command-line tool.

### Signing failures

The `sign` parameter requires the `shortcuts sign` CLI command. Verify:

```bash
shortcuts sign --help
```

If not available, upgrade to macOS 12.4+ which includes shortcut signing support.

### Shortcut compatibility

Not all shortcut features are available via programmatic generation. Limitations include:

- **Interactive elements**: Limited to built-in UI actions (notifications, alerts, menus)
- **Advanced actions**: Some less common actions may not be supported yet
- **Conditional logic**: If/Then/Else requires action definitions with control flow markers

Workaround: Create complex shortcuts manually in the Shortcuts app and use `run_shortcut` to execute them.

## Updating LLM Prompts

If you're using custom LLM prompts with the shortcuts-mcp, update them to mention new capabilities:

**Before**:
```
Available: run_shortcut, list_shortcuts, view_shortcut, shortcuts_usage
```

**After** (if using Swift):
```
Available: run_shortcut, list_shortcuts, view_shortcut, shortcuts_usage, create_shortcut, list_templates

New features:
- create_shortcut: Generate .shortcut files from actions or templates
- list_templates: Discover pre-built templates (api-request, text-pipeline, file-download)
- Action catalog: Browse all available actions at actions://catalog
```

## Rollback Plan

If you need to revert to TypeScript:

1. Update MCP configuration to use the TypeScript version again
2. Restart your MCP client
3. No data migration needed (profiles and preferences are compatible)

## Testing the Migration

### 1. Verify compatibility

```bash
# Test existing tools
# Should work identically between versions

# Test run_shortcut
"Run my existing shortcut"

# Test list_shortcuts
"What shortcuts do I have?"

# Test view_shortcut
"Open my shortcut for editing"

# Test shortcuts_usage
"What's my usage history?"
```

### 2. Test new features (Swift only)

```bash
# Test create_shortcut
"Create a shortcut that fetches weather data"

# Test templates
"Create a shortcut using the api-request template"

# Test action catalog
"What actions are available?"

# Test signing
"Create and sign a shortcut for sharing"
```

### 3. Verify resources

```bash
# Test resources work identically
"Read my shortcuts list"
"What's my current system state?"
"Show my execution statistics"
```

## Version Identification

To determine which version you're using:

```bash
# Check if create_shortcut is available
# (Swift only feature)

# Or check the server info
# Response includes version number and server name
```

## FAQ

**Q: Will my existing LLM prompts work with Swift?**
A: Yes, all existing tools and resources are fully compatible. New tools won't be used unless the LLM is instructed to use them.

**Q: Do I need to migrate? Can I keep using TypeScript?**
A: Both versions are maintained. TypeScript remains stable at v3.x. Choose Swift if you need programmatic shortcut generation or better performance.

**Q: Can I run both versions simultaneously?**
A: Yes, with different configuration names. They don't conflict since they're separate processes.

**Q: Will my user profiles/preferences transfer?**
A: Yes, both versions store data in `~/.shortcuts-mcp/`. Profiles are compatible between versions.

**Q: What about custom shortcuts I've created?**
A: Your existing shortcuts in the macOS Shortcuts app are unaffected. Both versions can execute them via `run_shortcut`.

**Q: Is the Swift version production-ready?**
A: Yes, v4.0+ is production-ready with full test coverage (401+ tests) and is the recommended version for new installations.

## Next Steps

1. **If staying on TypeScript**: No action needed. Continue using v3.x.
2. **If migrating to Swift**:
   - Build from source with `swift build -c release` in the `swift/` directory
   - Update your MCP client configuration
   - Test with your LLM client
3. **If using both**: Configure both with different names in your MCP configuration

## Support

For issues with the migration:
1. Check the [main README](README.md) for updated tool/resource documentation
2. Review test files for usage examples: `swift/Tests/ShortcutsMCPTests/`
3. File an issue with version details and reproduction steps

## Version History

- **v4.0.0+**: Swift implementation with shortcut generation
- **v3.x**: TypeScript implementation (stable, maintained)

See [CHANGELOG](CHANGELOG.md) for detailed changes.
