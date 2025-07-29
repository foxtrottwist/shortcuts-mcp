# Shortcuts MCP

A TypeScript MCP server that enables Claude to execute macOS Shortcuts through the native `shortcuts` CLI, providing seamless automation and cross-device capabilities.

## Features

- **Native CLI Integration**: Direct `shortcuts` command execution (no AppleScript complexity)
- **App Integration**: Automate common tasks like calendar events, messages, reminders, and workflows with apps that provide Shortcuts support or callback URL APIs
- **AI-Enhanced Workflows**: Let Claude recommend optimal shortcuts for specific tasks
- **Secure Execution**: Proper shell escaping and error handling
- **Rich Integration**: Browse your available shortcuts, execute with input, and view in editor

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

## Usage Examples

### Basic Automation

```
Claude, run my "Add Todays Date To Clipboard" shortcut
```

```
Claude, run my "Add Todays Date To Clipboard" shortcut
```

_Shortcut presents a menu to choose from multiple date formats (ISO, readable, custom)_

### Workflow Discovery

```
What shortcuts do I have available for text processing?
```

```
I need to process some data from a CSV file. What shortcuts could help?
```

### Cross-Device Capabilities

Since Shortcuts sync across Apple devices, Claude can trigger automations that work across your entire ecosystem:

```
Run my "Add To Clipboard" shortcut to copy this data
```

**Real Cross-Device Examples:**

- Execute Mac shortcuts that sync results to iOS Clipboard
- Trigger shortcuts that create Reminders accessible on all devices
- Run workflows that save files to iCloud for cross-device access
- Start shortcuts that send notifications to iPhone/Apple Watch

**macOS Tahoe 26 Beta - Advanced AI Workflows:**

```
Run my "Research Assistant" shortcut to analyze this document using Apple Intelligence
```

- Process documents with on-device Apple Intelligence models
- Generate summaries that automatically sync across devices
- Create AI-powered content that saves to shared iCloud folders

## Common Shortcuts Examples

### Text Processing

- **"Add To Clipboard"**: Enhanced clipboard management with formatting options

### Productivity

- **"Add Todays Date To Clipboard"**: Quick date insertion with format menu (ISO, readable, custom formats)
- **"File Organizer"**: Programmatic file management and sorting
- **"Quick Note"**: Capture thoughts with automatic tagging and cross-device sync

### AI-Enhanced (macOS Tahoe 26 Beta Only)

- **"macOS Agent Task"**: Leverage Shortcuts' "Use Model" action for complex workflows
- **"Research Assistant"**: Automated research and data collection
- **"Content Generator"**: AI-powered content creation pipelines

> **Note**: The "Use Model" action is currently only available in macOS Tahoe 26 beta. This feature allows shortcuts to directly interface with Apple Intelligence (on-device, Private Cloud Compute, or ChatGPT) for advanced AI-powered automation workflows.

## How It Works

### Architecture

```
Claude ←→ MCP Server ←→ shortcuts CLI ←→ Shortcuts App ←→ Other Devices
```

1. **Resource**: `Available Shortcuts` - Claude can browse your shortcuts library
2. **Tools**:
   - `run_shortcut` - Execute shortcuts with optional input
   - `view_shortcut` - Open shortcuts in the editor
3. **Prompts**: `recommend-shortcut` - AI-powered workflow suggestions

### Security

- All user input is properly escaped using single-quote shell escaping
- No AppleScript interpretation layer reduces attack surface
- Native CLI provides official, maintained interface

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

# Run tests
npm run test

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
└── shortcuts.test.ts      # Comprehensive test suite (collocated)
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

Comprehensive test suite covering:

- Shell escaping edge cases (quotes, special characters)
- Command construction accuracy
- Error handling scenarios
- All core functions with mocked CLI

```bash
npm run test        # Run test suite
npm run lint        # Linting and type checking
npm run format      # Code formatting
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes with tests
4. Run the test suite: `npm run test`
5. Submit a pull request

## Troubleshooting

### Common Issues

**"Command not found: shortcuts"**

- Ensure you're running macOS 12+ with Shortcuts app installed
- The `shortcuts` CLI is included with recent macOS versions

**"Permission denied"**

- Grant necessary permissions to Terminal/Claude Desktop in System Preferences → Privacy & Security

**"Shortcut not found"**

- Check shortcut name matches exactly (case-sensitive)
- Use `list` resource to see all available shortcuts

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

## Roadmap

- [x] .dxt build process and automated GitHub releases
- [ ] Enhanced workflow chaining capabilities
- [ ] Enhanced debugging and logging (command tracing, timing, verbose output)
- [ ] Performance monitoring and analytics
- [ ] Integration with more Apple ecosystem services

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

**Law Horne**

- Website: [lawrencehon.com](https://lawrencehon.com)
- Email: hello@foxtrottwist.com
- MCP Projects: [lawrencehon.com/mcp](https://lawrencehon.com/mcp)

---

_Part of the [Model Context Protocol](https://modelcontextprotocol.io) ecosystem - enabling AI assistants to interact with external tools and data sources._
