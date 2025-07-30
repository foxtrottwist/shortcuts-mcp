# Shortcuts MCP

A TypeScript MCP server that lets Claude execute your macOS Shortcuts through the native `shortcuts` CLI. No AppleScript complexity, no workarounds—just direct integration with the automation tools you already use.

## Why This Exists

If you're like me, you've probably built a collection of shortcuts that handle everything from quick notes to complex workflows. The problem? Using them from Claude meant either manually running them or building complicated integrations. This server bridges that gap by connecting Claude directly to your shortcuts through macOS's built-in command-line interface.

## What You Get

- **Direct CLI Integration**: Uses the native `shortcuts` command that ships with macOS—no additional layers or complexity
- **App Integration**: Works with any app that supports Shortcuts, from Calendar and Messages to specialized workflow tools
- **Smart Timeout Handling**: Interactive shortcuts automatically launch in background mode so Claude's interface never hangs
- **Complete Integration**: Browse available shortcuts, execute with input, and open shortcuts in the editor for modification
- **Cross-Device Capabilities**: Since shortcuts sync across Apple devices, Claude can trigger automations that affect your entire ecosystem

## Installation

### Option 1: Desktop Extension (.dxt) - Recommended

1. Download the latest `.dxt` file from [Releases](https://github.com/foxtrottwist/shortcuts-mcp/releases)
2. Open Claude Desktop
3. Go to Settings → Extensions
4. Click "Install Extension" and select the downloaded `.dxt` file
5. Restart Claude Desktop

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
      "args": ["/absolute/path/to/shortcuts-mcp/dist/index.js"]
    }
  }
}
```

## How to Use It

### Basic Automation

```
Claude, run my "Add Today's Date To Clipboard" shortcut
```

The shortcut presents a menu to choose from multiple date formats (ISO, readable, custom), then adds your selection to the clipboard.

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

## Timeout Behavior

### Interactive Shortcuts

Shortcuts requiring user interaction (file pickers, menus, prompts) automatically launch in background mode after a 5-second timeout to prevent Claude's interface from hanging:

```
Claude, run my "Choose Files" shortcut
```

**Result**: After 5 seconds, the shortcut opens in the Shortcuts app for you to interact with directly.

### Customizable Timeout

For longer-running processing shortcuts, specify a custom timeout:

```
Claude, run my "Video Converter" shortcut with 30 seconds timeout
```

### Silent Shortcuts

Shortcuts that complete successfully but provide no text output (clipboard operations, system settings) also trigger the timeout behavior and launch in background mode.

## Building Shortcuts for Claude

### Claude-Optimized Shortcuts

For the smoothest Claude integration, consider building specialized shortcuts that:

- **Return clear text output** instead of just showing UI notifications
- **Minimize interactive prompts** for automated workflows
- **Provide structured data** that Claude can easily parse and use

### Examples of Claude-Optimized Shortcuts

**Instead of**: "Add Note" (opens Notes app UI)  
**Build**: "Add Note to Claude" (saves note and returns confirmation text)

**Instead of**: "Weather" (shows weather widget)  
**Build**: "Get Weather Text" (returns weather as formatted text)

**Instead of**: "File Organizer" (interactive file picker)  
**Build**: "Organize Desktop Files" (processes specific folder, returns summary)

This approach maximizes automation potential while maintaining the flexibility to use any existing shortcut through the background launch system.

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

- **"Add Today's Date To Clipboard"**: Quick date insertion with format menu (ISO, readable, custom formats)
- **"New Quick Note"**: Capture thoughts with automatic tagging and cross-device sync
- **"Add Meeting Assignment To Calendar"**: Parse meeting details and create calendar events

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

### Debugging

Check shortcut execution directly:

```bash
shortcuts list
shortcuts run "My Shortcut"
```

## Compatibility

- **macOS**: 12+ (Monterey and later)
- **Shortcuts**: Works with all shortcut types and cross-device sync
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

- Website: [lawrencehon.com](https://lawrencehon.com)
- Email: hello@foxtrottwist.com
- MCP Projects: [lawrencehon.com/mcp](https://lawrencehon.com/mcp)

---

_Part of the [Model Context Protocol](https://modelcontextprotocol.io) ecosystem - enabling AI assistants to interact with external tools and data sources._
