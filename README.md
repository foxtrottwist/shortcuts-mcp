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
- **Reliable Execution**: No hanging on permission requests or interactive elements
- **Local Usage Tracking**: Execution history and preferences stored only on your computer

## Installation

### Option 1: Desktop Extension (.dxt) - Recommended

1. Download the latest `.dxt` file from [Releases](https://github.com/foxtrottwist/shortcuts-mcp/releases)
1. Double-click the .dxt file or drag it onto Claude Desktop
1. Click “Install” in the Claude Desktop UI
1. Restart Claude Desktop

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
What shortcuts have I used this week?
Which of my shortcuts work best for photo editing?
```

Claude can browse your complete shortcuts library, check your usage history (stored locally), and suggest options based on what’s worked for you before.

### Examples That Work

```
Claude, run my "Get Weather" shortcut
Claude, run "Create QR Code"
Claude, execute my "File Organizer"
```

Both automated and interactive shortcuts work reliably through AppleScript execution.

## Execution Tracking - Local Organization 📝

The server keeps track of your shortcut usage to help organize your workflow. **All execution history and preferences stay on your computer** - no data is transmitted anywhere.

### What Gets Tracked

- Which shortcuts you run and when
- Execution success/failure for debugging
- Basic preferences you set through Claude
- Usage patterns for shortcut suggestions

### Privacy-First Design

- Everything stored in `~/.shortcuts-mcp/` on your Mac
- No cloud sync, no data sharing, no external connections
- You can delete the folder anytime to reset
- Only you and Claude (locally) can access this information

### Practical Benefits

After using shortcuts for a while, you can ask Claude things like:

```
What shortcuts have I used this week?
Which shortcuts failed recently?
Remember I prefer the "Photo Editor Pro" shortcut for image work
```

Takes a few runs to build useful history - the tracking helps Claude give better suggestions based on what actually works for you.

## Interactive Shortcuts - Full Support ✅

**AppleScript integration enables complete interactive shortcut support.** File pickers, dialogs, prompts, and menus all work normally for user interaction.

### What Works

- ✅ **Interactive workflows** with file pickers, dialogs, and forms
- ✅ **Location-based shortcuts** with proper permission handling
- ✅ **Automated processes** that run without user input
- ✅ **System integrations** (Calendar, Messages, Notes)

### How It Works

When running interactive shortcuts:

```
Claude, run my "Create Contact" shortcut
```

**Result**: Forms and dialogs appear normally. You can fill out contact information, select files, or interact with any UI elements as if running the shortcut manually.

**Error Handling**:

- **“User canceled”**: Dialog was dismissed or timed out
- **“missing value”**: Interaction completed but returned no data
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

- **Permission Context**: AppleScript runs through “Shortcuts Events” with proper user permissions
- **Apple CLI Bug Handling**: Name resolution differences detected
- **Logging**: Timing, debugging, permission detection for troubleshooting

## Building Shortcuts for Claude

### All Shortcut Types Work

AppleScript integration supports interactive and automated shortcuts. Build shortcuts that take advantage of this:

- **Interactive workflows** with file selection and user input
- **Automated processes** for background execution
- **Hybrid approaches** combining interaction with automation

### Output Design by Shortcut Type

**For Data Retrieval Shortcuts:**
When your shortcut fetches information that Claude should receive, explicit output configuration is essential. Without it, you’ll get unexpected results.

**Real Example: Weather Shortcut**
![Weather Shortcut Configuration](https://github.com/foxtrottwist/foxtrottwist/blob/main/assets/simple-shortcut-suggestion.png)

The “Get The Weather” shortcut demonstrates proper output configuration. The “Text” action converts the weather data to the correct type, and the “Stop and output” action ensures the shortcut produces output that reaches the command line.

**What happens without proper output configuration:**

- **Before:** Shortcut gets weather data internally but returns timestamp: `"2025-08-05T16:52:06.691Z"`
- **Claude tells user:** “The current time is August 5th…”
- **After:** Text action converts data + Stop and output ensures delivery: `"Partly cloudy, 72°F"`
- **Claude tells user:** “The weather is partly cloudy, 72°F”

**For System Action Shortcuts:**
When your shortcut changes system settings or performs actions, output configuration is optional:

**Works fine without explicit output:**

```
[Adjust Brightness] → [Set Focus Mode] → (no output configuration needed)
```

Claude receives action confirmation and can tell the user the changes completed successfully.

**Key question:** *“Does the user expect Claude to tell them specific information from this shortcut?”*

- **Yes (Data Retrieval)** → Add Text action (conversion) + Stop and output action (delivery)
- **No (System Action)** → Output configuration optional, action confirmation is sufficient

**Quick test:** Run your shortcut in Terminal:

```bash
osascript -e 'tell application "Shortcuts Events" to run the shortcut named "Your Shortcut"'
```

If you see no output, Claude won’t get data either.

### Design Approaches

**Interactive**: “Photo Editor” → File picker for images, processing menu, save results
**Automated**: “Daily Backup” → Runs automatically, returns status summary
**Hybrid**: “Custom Report” → User selects data source, automatic processing

### For Best Claude Integration

While all shortcuts work, some integrate better with Claude workflows:

- **Return clear text output** that Claude can understand and act on
- **Provide completion messages** rather than silent operations
- **Include error handling** with informative responses
- **Design for both modes** when possible (interactive + automated)

**Examples**:

- **File Processing**: “Organize Files” → Returns summary with file counts and locations
- **Weather**: “Get Weather Report” → Returns structured weather data as text
- **System Tasks**: “Deploy Project” → Returns deployment status and any issues
- **Cross-Device**: “Create Event” → Returns confirmation with calendar integration details

### Real-World Interactive Examples

- **“Choose Files for Upload”**: File picker dialog for document selection
- **“Custom QR Generator”**: Input form for text/URL entry with format options
- **“Photo Processing Menu”**: Image picker followed by processing options menu
- **“Contact Creator”**: Multi-field form for complete contact information entry
- **“Project Template Selector”**: Menu-driven workflow setup with customization options

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
- `user_context` - Read and update local preferences and usage tracking
- `view_shortcut` - CLI editor opening with fallback guidance
1. **Resources** (automatically embedded):
- `shortcuts://available` - Current shortcuts list
- `execution://runs/recent` - Recent execution history (local only)
- `context://system/current` - System state for time-based suggestions
- `context://user/profile` - Local user preferences and patterns
1. **Enhanced Prompts**: AI-powered shortcut recommendation with name resolution strategies
1. **Local Data Storage**: Performance tracking, permission detection, debugging information (stays on your computer)

## Real-World Examples

### Location-Based Workflows

- **“Find Coffee Shops”**: Location services handled properly via AppleScript context
- **“Weather for Current Location”**: Geographic permissions work reliably

### System Integration

- **“Backup Notes”**: File system operations with proper permissions
- **“System Status Report”**: Hardware monitoring and reporting
- **“Network Diagnostics”**: System-level network analysis

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
├── user-context.ts        # Local execution tracking and preferences
├── helpers.ts             # Security and utility functions
├── shortcuts.test.ts      # AppleScript execution tests
├── user-context.test.ts   # User context and tracking tests
└── helpers.test.ts        # Security function tests
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

Comprehensive test suite with 63 tests covering AppleScript integration, user context tracking, security functions, error handling scenarios, and logging validation:

```bash
npm run test        # Run complete test suite (63 tests)
npm run lint        # Linting and type checking
npm run format      # Code formatting
```

## Troubleshooting

### Common Issues

**“Permission denied” or Error 1743**
Grant automation permissions in System Preferences → Privacy & Security → Automation. Allow Terminal/Claude Desktop to control “Shortcuts Events.”

**“Shortcut not found” with CLI commands**
Apple CLI has name resolution bugs. AppleScript execution is more forgiving. Use exact names from Available Shortcuts resource. Note: UUID fallback only works with CLI commands (like `shortcuts view`), not with AppleScript execution.

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

### Execution Characteristics

- **Permission Context**: Reliable execution vs CLI subprocess limitations
- **Logging Detail**: Performance timing, debugging info, permission detection

## Compatibility

- **macOS**: 12+ (Monterey and later)
- **Shortcuts**: All shortcut types with permission-aware handling
- **Claude Desktop**: Full MCP protocol compatibility
- **Node.js**: 22+ recommended

## What’s Next

- [x] AppleScript integration with permission handling
- [x] Comprehensive logging and error detection
- [x] .dxt build process and automated releases
- [x] Structured logging and error detection
- [ ] Workflow chaining capabilities
- [ ] Performance monitoring and analytics

## Contributing

1. Fork the repository
1. Create a feature branch: `git checkout -b feature/amazing-feature`
1. Make your changes with tests covering AppleScript integration
1. Run the test suite: `npm run test`
1. Submit a pull request

## License

MIT License - see <LICENSE> for details.

## Author

**Law Horne**

- Website: [lawrencehorne.com](https://lawrencehorne.com)
- Email: [hello@foxtrottwist.com](mailto:hello@foxtrottwist.com)
- MCP Projects: [lawrencehorne.com/mcp](https://lawrencehorne.com/mcp)

-----

*Part of the [Model Context Protocol](https://modelcontextprotocol.io) ecosystem - enabling AI assistants to interact with external tools and data sources.*
