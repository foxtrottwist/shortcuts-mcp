# Shortcuts MCP

A TypeScript MCP server that lets Claude execute your macOS Shortcuts through hybrid AppleScript and CLI integration. Reliable execution for all shortcut types including location-based workflows that previously failed with permission issues.

## Why This Exists

Your shortcuts collection handles everything from quick notes to complex workflows, but using them from Claude meant manual execution or complicated workarounds. This server bridges that gap with robust AppleScript integration that works reliably across all shortcut types.

## What You Get

- **Hybrid Integration**: AppleScript execution for reliability + native CLI for discovery and management
- **Permission-Aware**: Handles location services, automation permissions, and interactive contexts gracefully
- **Universal Compatibility**: Works with any shortcut type including those requiring system permissions
- **Smart Error Handling**: Comprehensive logging, timeout management, and Apple CLI bug detection
- **Cross-Device Capabilities**: Shortcuts sync across Apple devices, enabling ecosystem-wide automation
- **Zero Dependencies**: Native osascript execution without external packages

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

All shortcut types execute reliably including location-based shortcuts that previously hung indefinitely.

### Location-Based Workflows

```
Claude, run my "Find Nearby Coffee" shortcut
```

AppleScript execution handles location permissions properly where CLI subprocess execution failed.

### Finding the Right Shortcut

```
What shortcuts do I have available for text processing?
```

Claude browses your complete shortcuts library and suggests optimal options for specific tasks.

### Cross-Device Workflows

```
Run my "Save Research Notes" shortcut
```

Trigger automations that work across your Apple ecosystem—save to iCloud, add iPhone reminders, send Apple Watch notifications.

## Interactive Shortcuts - Full Support ✅

**Breakthrough**: The AppleScript implementation **fully supports interactive shortcuts** with complete UI display capability. File pickers, dialogs, prompts, and menus all appear normally for user interaction.

### What Works Reliably

- ✅ **All automated shortcuts** including location-based workflows
- ✅ **Interactive shortcuts with full UI support** (file pickers, dialogs, prompts)
- ✅ **Background processing** with system permission requirements
- ✅ **Text output shortcuts** with comprehensive result handling
- ✅ **Clipboard operations** and system automation
- ✅ **Apple ecosystem integrations** (Calendar, Messages, Notes)
- ✅ **User input forms and menu selections**

### Interactive Shortcut Behavior

When running interactive shortcuts:

```
Claude, run my "Make QR Code" shortcut
```

**AppleScript Behavior**: UI elements appear normally for user interaction. You can:

- **Select files** from file picker dialogs
- **Fill out input forms** and prompts
- **Choose from menus** and option lists
- **Interact with all UI elements** as if running manually

**Possible Results**:

- **Successful completion** with actual data output
- **"User canceled"** if dialog is dismissed or times out
- **"missing value"** if interaction completes but returns no data

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

### Universal Compatibility

The AppleScript implementation supports **all shortcut types** including interactive workflows. Build shortcuts that take full advantage of this capability:

- **Interactive workflows** with file pickers, forms, and menus work perfectly
- **Automated processes** for seamless background execution
- **Hybrid approaches** combining user interaction with automation
- **Cross-device integration** leveraging your entire Apple ecosystem

### Design Strategies

**Interactive Workflows**: "Photo Editor" → File picker for image selection, processing options menu, saves results
**Background Automation**: "Schedule Backup" → Runs automatically without user input, returns status
**Hybrid Approach**: "Custom Report" → User selects data source, automatic processing and formatting
**Cross-Device**: "Meeting Setup" → Interactive room selection, automatic calendar and device notifications

### Claude-Optimized Shortcuts

While all shortcut types work, some designs integrate better with Claude workflows:

**For Best Claude Integration:**

- **Return structured text output** that Claude can parse and act upon
- **Provide clear completion messages** rather than silent operations
- **Include error handling** with informative text responses
- **Design for both interactive and automated use** when possible

**Examples of Claude-Optimized Design:**

**Text Processing**: "Extract OCR Text" → Returns formatted text instead of just displaying results
**Weather Information**: "Get Weather Report" → Returns structured weather data as text
**File Operations**: "Organize Desktop" → Returns completion summary with file counts and locations
**Cross-Device**: "Create Event" → Returns confirmation with calendar integration status

**Interactive vs Automated Versions:**

- **Interactive**: "Choose Files to Process" → File picker, user selection, processing
- **Automated**: "Process Desktop Files" → Automatic folder processing, summary output
- **Best**: Hybrid shortcut that detects input and adapts behavior accordingly

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
Apple CLI has name resolution bugs. AppleScript execution is more forgiving. Use exact names from `list_shortcut` output or try UUID fallback.

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

## Performance & Reliability

### Execution Characteristics

- **AppleScript Overhead**: 200-500ms acceptable for automation use case
- **Permission Context**: Reliable execution vs CLI subprocess limitations
- **Error Recovery**: Graceful handling of Apple CLI bugs and permission issues
- **Logging Detail**: Performance timing, debugging info, permission detection

### Reliability Improvements

- ✅ **Interactive shortcuts**: Full UI support with proper dialog handling
- ✅ **Location-based shortcuts**: No more indefinite hanging
- ✅ **Permission-aware execution**: Proper automation context handling
- ✅ **Apple CLI bug mitigation**: Name resolution workarounds implemented
- ✅ **Universal compatibility**: All shortcut types work reliably

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
