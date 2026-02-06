# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

**Development:**

- `pnpm start` - Run server with tsx
- `pnpm dev` - Run with fastmcp dev mode (hot reload)
- `pnpm inspect` - Inspect MCP server with fastmcp CLI
- `pnpm test` - Run vitest suite
- `pnpm lint` - Run prettier check + eslint + typecheck
- `pnpm format` - Auto-fix with prettier + eslint

**Building:**

- `pnpm build` - Compile TypeScript to `dist/`
- `pnpm build:mcpb` - Build .mcpb bundle for Claude Desktop

**Debugging Shortcuts:**

```bash
# Test CLI discovery
shortcuts list --show-identifiers

# Test AppleScript execution
osascript -e 'tell application "Shortcuts Events" to run the shortcut named "My Shortcut"'
```

## Architecture Overview

TypeScript MCP server using a **hybrid execution model** to interact with macOS Shortcuts:

```
Claude <-> FastMCP Server <-> [AppleScript + CLI] <-> Shortcuts App
```

### Key Design Decisions

1. **AppleScript for Execution** (`osascript` via "Shortcuts Events"):
   - Reliable permission context for interactive shortcuts
   - Handles file pickers, dialogs, location services
   - More forgiving with shortcut name resolution

2. **CLI for Discovery** (`shortcuts list`):
   - Fast enumeration of available shortcuts
   - Subject to Apple CLI bugs (name resolution issues)

3. **Double-Layer Security**:
   - `shellEscape()` - Wraps in single quotes, prevents shell injection
   - `escapeAppleScriptString()` - Doubles backslashes, escapes quotes
   - Never execute unescaped user input

### Source Layout

```
src/
├── server.ts            # FastMCP server setup, tool/resource/prompt registration
├── shortcuts.ts         # Core execution (AppleScript via child_process.exec)
├── shortcuts-usage.ts   # User profile, execution tracking, shortcuts cache (~/.shortcuts-mcp/)
├── sampling.ts          # MCP sampling for AI-generated statistics
├── helpers.ts           # Security escaping, utilities, type guards
├── logger.ts            # Pino logger (stderr, async, ISO timestamps)
├── helpers.test.ts      # Tests co-located with source
├── shortcuts.test.ts
└── shortcuts-usage.test.ts
```

### Key Dependencies

- **fastmcp** - MCP SDK (tool/resource/prompt registration, stdio transport)
- **pino** - Structured JSON logging to stderr
- **zod** - Schema validation for tool parameters
- **@fastify/deepmerge** - Deep merging for profile updates

## Common Patterns

### Error Handling

1. **Permission Errors (1743)**: Guide user to System Settings -> Privacy & Security -> Automation
2. **Apple CLI Bugs**: Try exact case-sensitive name from `shortcuts list`; AppleScript is more forgiving than CLI
3. **Interactive Shortcuts**: Open in editor when UI is needed; "User canceled" = dialog dismissed; "missing value" = no output

### Code Style

- **ESLint**: Flat config with typescript-eslint + perfectionist (alphabetical sorting) + prettier
- **ES Modules**: `.js` extensions required in imports (Node ESM resolution)
- **Alphabetical sorting enforced**: Use `// eslint-disable-next-line perfectionist/sort-object-types` for logical ordering exceptions
- **Pre-commit hooks** (lefthook): prettier, eslint, typecheck, and tests run in parallel

### Testing

- **Framework**: Vitest (no custom config)
- **Co-located**: `*.test.ts` files alongside source
- **Mocking**: `vi.mock()` at top level, `vi.clearAllMocks()` in `beforeEach`

### Adding New Features

1. Add tool/resource/prompt in `src/server.ts`
2. Create supporting module in `src/` if needed
3. Add tests as `src/<module>.test.ts`
4. Update `manifest.json` if adding tools
5. **Always run `pnpm test` before committing**

### Data Storage

- **Location**: `~/.shortcuts-mcp/`
- `user-profile.json` - Preferences, projects, focus areas
- `shortcuts-cache.txt` - 24hr cached shortcuts list with timestamp
- `statistics.json` - AI-generated stats (via MCP sampling, refreshed every 24hrs)
- `executions/YYYY-MM-DD.json` - Daily execution logs

## Key Constraints

- **macOS only** (darwin) - Node 22+ required
- **Interactive shortcuts**: Can't show UI in MCP context (open in editor instead)
- **Apple CLI reliability**: Name resolution bugs require workarounds
- **Execution timing**: AppleScript can be slow for complex shortcuts

## CI/CD

- **Semantic release** on `main` branch: conventional commits -> CHANGELOG -> GitHub release with .mcpb asset
- `manifest.json` version is auto-synced from `package.json` during release
- **Release-triggering prefixes**: `feat:` (minor), `fix:` (patch), `feat!:`/`fix!:` (major)
- **Non-releasing prefixes**: `chore:`, `style:`, `docs:`, `refactor:`, `test:` — use these for build/CI-only changes
