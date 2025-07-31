# Shortcuts MCP

A TypeScript MCP server that lets Claude execute your macOS Shortcuts through the native `shortcuts` CLI. No AppleScript complexity, no workarounds—just direct integration with the automation tools you already use.

## Why This Exists

If you're like me, you've probably built a collection of shortcuts that handle everything from quick notes to complex workflows. The problem? Using them from Claude meant either manually running them or building complicated integrations. This server bridges that gap by connecting Claude directly to your shortcuts through macOS's built-in command-line interface.

## What You Get

- **Direct CLI Integration**: Uses the native `shortcuts` command that ships with macOS—no additional layers or complexity
- **App Integration**: Works with any app that supports Shortcuts, from Calendar and Messages to specialized workflow tools
- **Smart Timeout Handling**: Long-running shortcuts timeout gracefully so Claude's interface never hangs
- **Complete Integration**: Browse available shortcuts, execute with input, and open shortcuts in the editor for modification
- **Cross-Device Capabilities**: Since shortcuts sync across Apple devices, Claude can trigger automations that affect your entire ecosystem

## Installation

### Option 1: Desktop Extension (.dxt) - Recommended

1. Download the latest `.dxt` file from [Releases](https://github.com/foxtrottwist/shortcuts-mcp/releases)
2. Double-click the .dxt file or drag it onto Claude Desktop
3. Click "Install" in the Claude Desktop UI
4. Restart Claude Desktop

### Option 2: Manual Installation

Clone and build locally for development:

```bash
git clone https://github.com/foxtrottwist/shortcuts-mcp.git
cd shortcuts-mcp
npm install
npm run build
```

Add to Claude Desktop configuration:

```json
{
  "mcpServers": {
    "shortcuts-mcp": {
      "command": "node",
      "args": ["/absolute/path/to/shortcuts-mcp/dist/server.js"]
    }
  }
}
```

## How to Use It

### Automated Shortcuts

```
Claude, run my "Get Weather Text" shortcut
```

Shortcuts that run automatically and return text output work perfectly through Claude.

### Finding the Right Shortcut

```
What shortcuts do I have available for text processing?
```

Claude can browse your complete shortcuts library and suggest the best options for specific tasks.

```
I need to process some data from a CSV file. What shortcuts could help?
```

### Cross-Device Workflows

Since Shortcuts sync across Apple devices, Claude can trigger automations that work across your entire ecosystem:

```
Run my "Save Research Notes" shortcut
```

This might save notes to iCloud, add reminders to your iPhone, or trigger notifications on your Apple Watch—all from a single Claude request.

## Interactive Shortcuts Limitation

**Important**: Shortcuts requiring user interaction (file pickers, menus, prompts) **cannot display UI elements** when run through MCP servers due to security restrictions. This is a limitation of the MCP server execution context, not this specific implementation.

### What Works

- ✅ Automated shortcuts that run without user input
- ✅ Shortcuts that return text output
- ✅ Background processing shortcuts
- ✅ Clipboard operations and system automation

### What Doesn't Work

- ❌ File picker dialogs
- ❌ Interactive menus and prompts
- ❌ UI-based user input
- ❌ Shortcuts requiring visual confirmation

### Interactive Shortcut Behavior

When Claude attempts to run an interactive shortcut:

```
Claude, run my "Choose Files" shortcut
```

**Result**: `Shortcut "Choose Files" timed out after 5 seconds. Interactive shortcuts requiring user input cannot display UI when run through MCP servers. Please run interactive shortcuts manually in the Shortcuts app.`

## Timeout Behavior

### Customizable Timeout

For longer-running processing shortcuts, specify a custom timeout:

```
Claude, run my "Video Converter" shortcut with 30 seconds timeout
```

### Silent Shortcuts

Shortcuts that complete successfully but provide no text output will show a confirmation message:

```
Shortcut "My Shortcut" completed successfully (no text output - check clipboard or other apps for results).
```

## Building Shortcuts for Claude

### Claude-Optimized Shortcuts

For the best Claude integration, build shortcuts that:

- **Return clear text output** instead of relying on UI notifications
- **Work without user interaction** for full automation
- **Provide structured data** that Claude can easily parse and use
- **Handle errors gracefully** with informative text responses

### Examples of Claude-Optimized Shortcuts

**Instead of**: "Add Note" (opens Notes app UI)  
**Build**: "Add Note to Claude" (saves note and returns confirmation text)

**Instead of**: "Weather" (shows weather widget)  
**Build**: "Get Weather Text" (returns weather as formatted text)

**Instead of**: "File Organizer" (interactive file picker)  
**Build**: "Organize Desktop Files" (processes specific folder, returns summary)

**Instead of**: "Choose Image" (file picker dialog)  
**Build**: "Process Latest Screenshot" (works with most recent screenshot automatically)

This approach maximizes automation potential while avoiding the interactive shortcut limitations.

## How It Works

### Architecture

```
Claude ←→ MCP Server ←→ shortcuts CLI ←→ Shortcuts App ←→ Other Devices/Clipboard/Filesystem
```

**Data Flow**:

- **Claude** sends requests through the Model Context Protocol
- **MCP Server** translates requests to native macOS `shortcuts` commands
- **shortcuts CLI** executes commands and communicates with the Shortcuts app
- **Shortcuts App** runs your automations and can sync results across devices
- **Other Devices/Clipboard/Filesystem** receive results via iCloud sync, local clipboard, or file operations

### MCP Integration

1. **Resource**: `Available Shortcuts` - Browse your complete shortcuts library in Claude's context menu
2. **Tools**:
   - `run_shortcut` - Execute shortcuts with optional input and configurable timeout
   - `view_shortcut` - Open shortcuts in the Shortcuts app editor for modification
3. **Prompt**: `Recommend a Shortcut` - AI-powered analysis to suggest the best shortcut for your task

### Security

All user input is properly escaped using single-quote shell escaping. No AppleScript interpretation layer reduces the attack surface, and the native CLI provides an official, maintained interface.

## Real-World Examples

### Text Processing

- **"Add To Clipboard"**: Enhanced clipboard management with formatting options
- **"Word Definition Prompt"**: Quick dictionary lookup with formatted results

### Productivity

- **"Get Current Date"**: Return today's date in various formats (automated version)
- **"New Quick Note"**: Capture thoughts with automatic tagging and cross-device sync
- **"Create Calendar Event"**: Parse text and create calendar events with confirmation

### Development Workflows

- **"Extract Text from Image"**: OCR processing for code snippets or documentation
- **"Convert File To iCalendar"**: Transform data into calendar-compatible formats
- **"Make Rich Text From Markdown"**: Format conversion for documentation

## Development

### Prerequisites

- Node.js 22+
- macOS with Shortcuts app
- TypeScript knowledge for contributions

### Setup

```bash
# Clone repository
git clone https://github.com/foxtrottwist/shortcuts-mcp.git
cd shortcuts-mcp

# Install dependencies
npm install

# Development mode with hot reload
npm run dev

# Build for production
npm run build

# Build .dxt extension
npm run build:dxt
```

### Project Structure

```
src/
├── server.ts              # MCP server configuration
├── shortcuts.ts           # Core shortcuts CLI wrapper
└── shortcuts.test.ts      # Comprehensive test suite
```

### Core Functions

```typescript
// Execute any shortcuts CLI command
await execShortcuts("list");
await execShortcuts("run", shellEscape("My Shortcut"), '<<< "input"');

// High-level shortcuts operations
await listShortcuts(); // Get all available shortcuts
await runShortcut("Shortcut Name", "input"); // Execute with input
await viewShortcut("Shortcut Name"); // Open in editor
```

### Testing

Comprehensive test suite covering shell escaping edge cases, command construction accuracy, error handling scenarios, and all core functions with mocked CLI:

```bash
npm run test        # Run test suite
npm run lint        # Linting and type checking
npm run format      # Code formatting
```

## Troubleshooting

### Common Issues

**"Command not found: shortcuts"**

Ensure you're running macOS 12+ with Shortcuts app installed. The `shortcuts` CLI is included with recent macOS versions.

**"Permission denied"**

Grant necessary permissions to Terminal/Claude Desktop in System Preferences → Privacy & Security.

**"Shortcut not found"**

Check shortcut name matches exactly (case-sensitive). Use the `Available Shortcuts` resource to see all available shortcuts.

**"Shortcut timed out"**

This means the shortcut either requires user interaction or completed without returning text output. Interactive shortcuts cannot display UI when run through MCP servers and should be run manually in the Shortcuts app. For shortcuts that completed silently, check the Shortcuts app, clipboard, or other applications for results.

### Debugging

Check shortcut execution directly:

```bash
shortcuts list
shortcuts run "My Shortcut"
```

## Compatibility

- **macOS**: 12+ (Monterey and later)
- **Shortcuts**: Works with automated shortcuts; interactive shortcuts have UI limitations
- **Claude Desktop**: Compatible with MCP protocol
- **Node.js**: 22+ recommended

## What's Next

- [x] .dxt build process and automated GitHub releases
- [ ] Enhanced debugging and logging (command tracing, timing, verbose output)
- [ ] Workflow chaining capabilities
- [ ] Performance monitoring and analytics

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes with tests
4. Run the test suite: `npm run test`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

**Law Horne**

- Website: [lawrencehorne.com](https://lawrencehorne.com)
- Email: hello@foxtrottwist.com
- MCP Projects: [lawrencehorne.com/mcp](https://lawrencehorne.com/mcp)

---

_Part of the [Model Context Protocol](https://modelcontextprotocol.io) ecosystem - enabling AI assistants to interact with external tools and data sources._
