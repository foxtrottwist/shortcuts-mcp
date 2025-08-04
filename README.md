# Shortcuts MCP

A TypeScript MCP server that connects Claude to your macOS Shortcuts library. Interactive workflows with file pickers, dialogs, and prompts work through AppleScript integration, while CLI handles discovery and management.

## Why This Exists

Your shortcuts collection handles everything from quick utilities to complex workflows, but using them from Claude meant workarounds or manual execution. This server bridges that gap with AppleScript integration that handles all shortcut types reliably.

## What You Get

- **Interactive Support**: File pickers, dialogs, and prompts work normally through AppleScript execution
- **Hybrid Integration**: AppleScript for compatibility + CLI for discovery and management
- **Permission Handling**: Location services, system integrations work with proper permission context
- **All Shortcut Types**: Interactive workflows and automation both work reliably
- **Cross-Device Sync**: Shortcuts sync across Apple devices for ecosystem-wide automation
- **Reliable Execution**: No more hanging on permission requests or interactive elements

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

### Interactive Workflows

```
Claude, run my "Photo Organizer" shortcut
```

File pickers and dialogs appear normally for user interaction. All shortcut types work including location-based and permission-requiring workflows.

### Finding the Right Shortcut

```
What shortcuts do I have for file processing?
```

Claude can browse your complete shortcuts library and suggest options for specific tasks.

### Examples That Work

```
Claude, run my "Get Weather" shortcut
Claude, run "Create QR Code"
Claude, execute my "File Organizer"
```

Both automated and interactive shortcuts work reliably through AppleScript execution.

## Interactive Shortcuts - Full Support ✅

**AppleScript integration enables complete interactive shortcut support.** File pickers, dialogs, prompts, and menus all work normally for user interaction.

### What Works

- ✅ **Interactive workflows** with file pickers, dialogs, and forms
- ✅ **Location-based shortcuts** with proper permission handling
- ✅ **Automated processes** that run without user input
- ✅ **System integrations** (Calendar, Messages, Notes)
- ✅ **Cross-device workflows** via iCloud sync

### How It Works

When running interactive shortcuts:

```
Claude, run my "Create Contact" shortcut
```

**Result**: Forms and dialogs appear normally. You can fill out contact information, select files, or interact with any UI elements as if running the shortcut manually.

**Error Handling**:

- **"User canceled"**: Dialog was dismissed or timed out
- **"missing value"**: Interaction completed but returned no data
- **Successful completion**: Normal data output from interaction

## Architecture Improvements

### Hybrid Execution Model

```
Claude ←→ MCP Server ←→ [AppleScript Execution + CLI Discovery] ←→ Shortcuts App ←→ Apple Ecosystem
```

**AppleScript Execution**: Reliable permission context for all shortcut types
**CLI Discovery**: Fast listing and identification of available shortcuts
**Permission Awareness**: Graceful handling of location services and system permissions

### Reliability Enhancements

- **Permission Context**: AppleScript runs through "Shortcuts Events" with proper user permissions
- **Apple CLI Bug Handling**: Name resolution differences detected and managed
- **Comprehensive Logging**: Timing, debugging, permission detection for troubleshooting
- **Error Recovery**: User-friendly guidance for permission issues and execution failures

## Building Shortcuts for Claude

### All Shortcut Types Work

AppleScript integration supports interactive and automated shortcuts. Build shortcuts that take advantage of this:

- **Interactive workflows** with file selection and user input
- **Automated processes** for background execution
- **Hybrid approaches** combining interaction with automation
- **Cross-device integration** across your Apple ecosystem

### Design Approaches

**Interactive**: "Photo Editor" → File picker for images, processing menu, save results
**Automated**: "Daily Backup" → Runs automatically, returns status summary
**Hybrid**: "Custom Report" → User selects data source, automatic processing
**Cross-Device**: "Meeting Prep" → Interactive setup, automatic notifications across devices

### For Best Claude Integration

While all shortcuts work, some integrate better with Claude workflows:

- **Return clear text output** that Claude can understand and act on
- **Provide completion messages** rather than silent operations
- **Include error handling** with informative responses
- **Design for both modes** when possible (interactive + automated)

**Examples**:

- **File Processing**: "Organize Files" → Returns summary with file counts and locations
- **Weather**: "Get Weather Report" → Returns structured weather data as text
- **System Tasks**: "Deploy Project" → Returns deployment status and any issues
- **Cross-Device**: "Create Event" → Returns confirmation with calendar integration details

### Real-World Interactive Examples

- **"Choose Files for Upload"**: File picker dialog for document selection
- **"Custom QR Generator"**: Input form for text/URL entry with format options
- **"Photo Processing Menu"**: Image picker followed by processing options menu
- **"Contact Creator"**: Multi-field form for complete contact information entry
- **"Project Template Selector"**: Menu-driven workflow setup with customization options

## How It Works

### Technical Implementation

**AppleScript Integration**: Native `osascript` execution bypasses subprocess permission limitations that caused location-based shortcuts to hang

**Dual-Layer Security**:

- Shell escaping for command construction safety
- AppleScript string escaping for script content protection

**Error Detection**:

- Apple CLI bug patterns identified and handled
- Permission error codes (1743) detected with solution guidance
- Timeout behaviors managed gracefully

### MCP Integration

1. **Tools**:
   - `run_shortcut` - AppleScript execution with comprehensive logging
   - `view_shortcut` - CLI editor opening with fallback guidance
   - `list_shortcut` - Fast CLI discovery of available shortcuts

2. **Enhanced Prompts**: AI-powered shortcut recommendation with name resolution strategies

3. **Logging Framework**: Performance tracking, permission detection, debugging information

## Real-World Examples

### Location-Based Workflows

- **"Find Coffee Shops"**: Location services handled properly via AppleScript context
- **"Weather for Current Location"**: Geographic permissions work reliably
- **"Traffic to Home"**: Maps integration with location access

### System Integration

- **"Backup Notes"**: File system operations with proper permissions
- **"System Status Report"**: Hardware monitoring and reporting
- **"Network Diagnostics"**: System-level network analysis

### Cross-Device Automation

- **"Meeting Prep"**: Calendar, Messages, and device synchronization
- **"Travel Notifications"**: Cross-device alerts and reminders
- **"Shared Workspace Setup"**: Multi-device configuration automation

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
├── shortcuts.ts           # AppleScript + CLI integration
├── helpers.ts             # Security and utility functions
└── shortcuts.test.ts      # Comprehensive test suite
```

### Core Functions

```typescript
// AppleScript execution with comprehensive logging
await runShortcut(log, "Shortcut Name", "input");

// CLI discovery and management
await listShortcuts(); // Fast shortcut enumeration
await viewShortcut(log, "Shortcut Name"); // Editor opening

// Security utilities
shellEscape(userInput); // Shell injection protection
escapeAppleScriptString(content); // AppleScript safety
```

### Testing

Comprehensive test suite covering AppleScript integration, security functions, error handling scenarios, and logging validation:

```bash
npm run test        # Run test suite with AppleScript mocks
npm run lint        # Linting and type checking
npm run format      # Code formatting
```

## Troubleshooting

### Common Issues

**"Permission denied" or Error 1743**
Grant automation permissions in System Preferences → Privacy & Security → Automation. Allow Terminal/Claude Desktop to control "Shortcuts Events."

**"Shortcut not found" with CLI commands**
Apple CLI has name resolution bugs. AppleScript execution is more forgiving. Use exact names from `list_shortcut` output. Note: UUID fallback only works with CLI commands (like `shortcuts view`), not with AppleScript execution.

**Location-based shortcuts not working**
Ensure Location Services are enabled for Shortcuts app in System Preferences → Privacy & Security → Location Services.

**Interactive shortcuts opening in editor**
This is expected behavior. Interactive shortcuts cannot display UI in MCP context but can be completed manually in the editor.

### Debugging

Check shortcut execution directly:

```bash
# Test CLI discovery
shortcuts list --show-identifiers

# Test AppleScript execution
osascript -e 'tell application "Shortcuts Events" to run the shortcut named "My Shortcut"'
```

Monitor comprehensive logging in Claude Desktop console for timing, permission detection, and error analysis.

### Performance & Reliability

### Execution Characteristics

- **Permission Context**: Reliable execution vs CLI subprocess limitations
- **Error Recovery**: Handling of Apple CLI bugs and permission issues
- **Logging Detail**: Performance timing, debugging info, permission detection

### Reliability Improvements

- ✅ **Interactive shortcuts**: File pickers and dialogs work normally
- ✅ **Location-based shortcuts**: No more hanging on permission requests
- ✅ **Permission handling**: Proper automation context for all shortcut types
- ✅ **Apple CLI bug mitigation**: Name resolution workarounds implemented
- ✅ **All shortcut types**: Interactive and automated workflows both work reliably

## Compatibility

- **macOS**: 12+ (Monterey and later)
- **Shortcuts**: All shortcut types with permission-aware handling
- **Claude Desktop**: Full MCP protocol compatibility
- **Node.js**: 22+ recommended

## What's Next

- [x] AppleScript integration with permission handling
- [x] Comprehensive logging and error detection
- [x] .dxt build process and automated releases
- [ ] Enhanced debugging features (command tracing, verbose output)
- [ ] Workflow chaining capabilities
- [ ] Performance monitoring and analytics

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes with tests covering AppleScript integration
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
