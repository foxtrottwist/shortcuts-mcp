# Shortcuts MCP

A TypeScript MCP server that connects LLMs to your macOS Shortcuts library. Interactive workflows with file pickers, dialogs, and prompts work through AppleScript integration, while CLI handles discovery and management.

## Why This Exists

I wanted to integrate my existing automation workflows with AI assistance. Rather than manually triggering shortcuts outside of my LLM and then copying results back, this server lets me run shortcuts directly within AI conversations for better automation.

## What You Get

### Base Features (TypeScript & Swift)

- **Interactive Support**: File pickers, dialogs, and prompts work normally through AppleScript execution
- **Hybrid Integration**: AppleScript for compatibility + CLI for discovery and management
- **Permission Handling**: Location services, system integrations work with proper permission context
- **All Shortcut Types**: Interactive workflows and automation both work reliably
- **Reliable Execution**: No hanging on permission requests or interactive elements
- **Local Usage Tracking**: Execution history and preferences stored only on your computer
- **Intelligent Analytics**: Automatic usage pattern analysis via MCP sampling (when supported)

### Swift Version Additions

- **Programmatic Shortcut Generation**: Create .shortcut files directly via the `create_shortcut` tool with action definitions
- **Pre-built Templates**: Use templates for common patterns (Text processing, API requests, File downloads)
- **Action Catalog**: Progressive disclosure resource showing all available actions and their parameters
- **Shortcut Signing**: Sign generated shortcuts for distribution via `--mode anyone` or `--mode people-who-know-me`
- **Auto-Import**: Automatically import generated shortcuts into the Shortcuts app
- **Import Questions**: Add import-time prompts for secrets (API keys, credentials, URLs)
- **Native Performance**: Written in Swift 6 for better performance and type safety

## Installation

### Option 1: MCP Bundle (.mcpb) - Recommended

1. Download the latest `.mcpb` file from [Releases](https://github.com/foxtrottwist/shortcuts-mcp/releases)
1. Double-click the .mcpb file or drag it onto Claude Desktop
1. Click "Install" in the Claude Desktop UI
1. Restart Claude Desktop

### Option 2: Manual Installation (TypeScript)

Clone and build the TypeScript version locally:

```bash
git clone https://github.com/foxtrottwist/shortcuts-mcp.git
cd shortcuts-mcp
npm install
npm run build
```

Add to your MCP client configuration. For Claude Desktop:

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

### Option 3: Build from Swift Source

Clone and build the Swift version locally:

```bash
git clone https://github.com/foxtrottwist/shortcuts-mcp.git
cd shortcuts-mcp/swift
swift build -c release
```

The compiled server will be at `.build/release/shortcuts-mcp`. Add to your MCP client configuration:

```json
{
  "mcpServers": {
    "shortcuts-mcp": {
      "command": "/absolute/path/to/shortcuts-mcp/swift/.build/release/shortcuts-mcp"
    }
  }
}
```

## Tested MCP Clients

This server has been tested with the following MCP clients:

- **[Claude Desktop](https://claude.ai/download)**
- **[LM Studio](https://lmstudio.ai/)** - Tested with models like `gpt-oss` and `qwen3-1.7b` (manual installation only)

## Tools Reference

### Shortcut Execution

**`run_shortcut`** - Execute an existing shortcut
- `name` (string, required): Name of the shortcut to run
- `input` (string, optional): Input data to pass to the shortcut

Example: Run the "Get Weather" shortcut with the current location.

### Shortcut Discovery

**`list_shortcuts`** - Discover available shortcuts
- `refresh` (boolean, optional): Bypass cache and fetch fresh list

Returns array of shortcuts with names and identifiers. Results are cached for 24 hours.

**`view_shortcut`** - Open a shortcut in the editor
- `name` (string, required): Name of the shortcut to open

Opens the shortcut in the macOS Shortcuts app for editing.

### Shortcut Generation (Swift Version)

**`create_shortcut`** - Create a new .shortcut file (Swift only)

Two modes available:

**Mode 1: From Actions**
- `name` (string, required): Shortcut name
- `actions` (array, required): Array of action definitions
- `icon` (object, optional): Icon configuration {color: {red, green, blue}, glyph}
- `sign` (boolean, optional): Sign the shortcut after creation
- `signingMode` (choice, optional): "anyone" or "peopleWhoKnowMe"
- `autoImport` (boolean, optional): Automatically import to Shortcuts app
- `importQuestions` (array, optional): Import prompts for secrets

Returns: `{filePath, fileSize, name, actionCount, message, signed, signedFilePath, imported}`

**Mode 2: From Templates**
- `name` (string, required): Shortcut name
- `template` (string, required): Template name (e.g., "api-request", "text-pipeline")
- `templateParams` (object, required): Parameters for the template
- `sign` (boolean, optional): Sign after creation
- `autoImport` (boolean, optional): Auto-import to Shortcuts app

Example: Create a shortcut that fetches weather data from an API:

```json
{
  "name": "weather-fetcher",
  "template": "api-request",
  "templateParams": {
    "url": "https://api.weather.gov/points/40.7128,-74.0060",
    "jsonPath": "properties.periods.0"
  },
  "autoImport": true
}
```

**`list_templates`** - Discover available templates (Swift only)
- `verbose` (boolean, optional): Show detailed parameter information

Returns list of available templates with names, descriptions, and parameters.

### User Profile & Tracking

**`shortcuts_usage`** - Read and update user profile
- `action` (string, required): "read" or "update"
- `resources` (array, optional): Which resources to return ("profile", "shortcuts", "statistics")
- `data` (object, optional): For "update", context and preferences to set

## Resources Reference

### Always Available

**`shortcuts://available`** - Current list of shortcuts in your library
Returns list of all shortcuts with names and identifiers.

**`context://system/current`** - Current system state
Returns timezone, time, and other system information for time-based decisions.

**`context://user/profile`** - User preferences and execution patterns
Returns projects, focus areas, favorite shortcuts, and workflow patterns.

**`statistics://generated`** - Execution statistics and insights
Returns usage patterns, success rates, timing statistics per shortcut.

### Template Catalog (Swift Only)

**`shortcuts://runs/{name}`** - Execution history for a specific shortcut
Returns all execution records and timing data for a given shortcut.

### Action Catalog (Swift Only)

**`actions://catalog`** - Progressive disclosure action directory
Returns category overview (text, ui, file, url, json, variable).

**`actions://catalog/{category}`** - Actions in a category
Returns action summaries with identifiers and descriptions.

**`actions://catalog/{category}/{action}`** - Action parameter schema
Returns complete parameter documentation for a specific action.

Progressive disclosure design minimizes token usage while providing complete action documentation.

## Templates Reference (Swift Only)

### Available Templates

**`api-request`** - Fetch data from an API and optionally extract JSON
- `url` (URL, required): API endpoint
- `method` (choice, optional): GET/POST/PUT/DELETE, default GET
- `authHeader` (string, optional): Authorization header value
- `jsonPath` (string, optional): Dot-notation path to extract from response

**`text-pipeline`** - Apply multiple text transformations
- `inputText` (string, required): Input text to process
- `operations` (string, required): JSON array of transformation operations
- `showResult` (boolean, optional): Display result, default true

Operations support: `uppercase`, `lowercase`, `capitalize`, `titlecase`, `sentencecase`, `alternatingcase`, `replace`, `split`, `combine`

**`file-download`** - Download a file from URL and save to disk
- `url` (URL, required): File to download
- `filename` (string, optional): Destination path, or prompt if not provided
- `showConfirmation` (boolean, optional): Show download complete notification, default true

## MCP Prompts

**`Recommend a Shortcut`** - Get intelligent shortcut suggestions
- `task_description` (required): What you want to accomplish
- `context` (optional): Additional context

The LLM analyzes your shortcuts library and usage history to recommend the best shortcut for your task.

## How to Use It

### Interactive Workflows

```
Run my "Photo Organizer" shortcut
```

File pickers and dialogs appear normally for user interaction. All shortcut types work including location-based and permission-requiring workflows.

### Finding the Right Shortcut

```
What shortcuts do I have for file processing?
What shortcuts have I used this week?
Which of my shortcuts work best for photo editing?
```

Your AI assistant can browse your complete shortcuts library, check your usage history (stored locally), and suggest options based on what's worked for you before.

### Examples That Work

```
Run my "Get Weather" shortcut
Run "Create QR Code"
Execute my "File Organizer"
```

Both automated and interactive shortcuts work reliably through AppleScript execution.

## Execution Tracking - Local Organization

The server keeps track of your shortcut usage to help organize your workflow. **All execution history and preferences stay on your computer** - no data is transmitted anywhere.

### What Gets Tracked

- Which shortcuts you run and when
- Execution success/failure for debugging
- Basic preferences you set through your AI assistant
- Usage patterns for shortcut suggestions

**Privacy Note**: Shortcut inputs and outputs are not stored locally. Be cautious when running shortcuts containing sensitive information, as you control what data is shared with your AI assistant.

### Privacy-First Design

- Everything stored in `~/.shortcuts-mcp/` on your Mac
- No cloud sync, no data sharing, no external connections
- You can delete the folder anytime to reset
- Only you and your AI assistant (locally) can access this information

### Practical Benefits

After using shortcuts for a while, you can ask your AI assistant things like:

```
What shortcuts have I used this week?
Which shortcuts failed recently?
Remember I prefer the "Photo Editor Pro" shortcut for image work
```

Takes a few runs to build useful history - the tracking helps your AI assistant give better suggestions based on what actually works for you.

### MCP Sampling for Intelligent Analytics

When your MCP client supports sampling, the server automatically generates statistics from your usage data. This includes:

- Success rate analysis across different shortcuts
- Performance timing patterns
- Usage trend identification
- Personalized shortcut recommendations

**Current Status**: Claude Desktop does not yet support MCP sampling, so analytics are not available. The server detects sampling capability automatically and enables these features when supported.

## Interactive Shortcuts - Full Support

**AppleScript integration enables complete interactive shortcut support.** File pickers, dialogs, prompts, and menus all work normally for user interaction.

### What Works

- **Interactive workflows** with file pickers, dialogs, and forms
- **Location-based shortcuts** with proper permission handling
- **Automated processes** that run without user input
- **System integrations** (Calendar, Messages, Notes)

### How It Works

When running interactive shortcuts:

```
Run my "Create Contact" shortcut
```

**Result**: Forms and dialogs appear normally. You can fill out contact information, select files, or interact with any UI elements as if running the shortcut manually.

**Error Handling**:

- **"User canceled"**: Dialog was dismissed or timed out
- **"missing value"**: Interaction completed but returned no data
- **Successful completion**: Normal data output from interaction

## Architecture Improvements

### Hybrid Execution Model

```
AI Assistant ←→ MCP Server ←→ [AppleScript Execution + CLI Discovery] ←→ Shortcuts App ←→ Apple Ecosystem
```

**AppleScript Execution**: Reliable permission context for all shortcut types
**CLI Discovery**: Fast listing and identification of available shortcuts
**Permission Awareness**: Graceful handling of location services and system permissions

### Reliability Enhancements

- **Permission Context**: AppleScript runs through "Shortcuts Events" with proper user permissions
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
When your shortcut fetches information that your AI assistant should receive, explicit output configuration is essential. Without it, you'll get unexpected results.

**Real Example: Weather Shortcut**
![Weather Shortcut Configuration](https://github.com/foxtrottwist/foxtrottwist/blob/main/assets/simple-shortcut-suggestion.png)

The "Get The Weather" shortcut demonstrates proper output configuration. The "Text" action converts the weather data to the correct type, and the "Stop and output" action ensures the shortcut produces output that reaches the command line.

**What happens without proper output configuration:**

- **Before:** Shortcut gets weather data internally but returns timestamp: `"2025-08-05T16:52:06.691Z"`
- **AI assistant tells user:** "The current time is August 5th…"
- **After:** Text action converts data + Stop and output ensures delivery: `"Partly cloudy, 72°F"`
- **AI assistant tells user:** "The weather is partly cloudy, 72°F"

**For System Action Shortcuts:**
When your shortcut changes system settings or performs actions, output configuration is optional:

**Works fine without explicit output:**

```
[Adjust Brightness] → [Set Focus Mode] → (no output configuration needed)
```

Your AI assistant receives action confirmation and can tell the user the changes completed successfully.

**Key question:** _"Does the user expect their AI assistant to tell them specific information from this shortcut?"_

- **Yes (Data Retrieval)** → Add Text action (conversion) + Stop and output action (delivery)
- **No (System Action)** → Output configuration optional, action confirmation is sufficient

**Quick test:** Run your shortcut in Terminal:

```bash
osascript -e 'tell application "Shortcuts Events" to run the shortcut named "Your Shortcut"'
```

If you see no output, your LLM won't get data either.

### Design Approaches

**Interactive**: "Photo Editor" → File picker for images, processing menu, save results
**Automated**: "Daily Backup" → Runs automatically, returns status summary
**Hybrid**: "Custom Report" → User selects data source, automatic processing

### For Best Claude Integration

While all shortcuts work, some integrate better with AI assistant workflows:

- **Return clear text output** that your AI assistant can understand and act on
- **Provide completion messages** rather than silent operations
- **Include error handling** with informative responses
- **Design for both modes** when possible (interactive + automated)

**Examples**:

- **File Processing**: "Organize Files" → Returns summary with file counts and locations
- **Weather**: "Get Weather Report" → Returns structured weather data as text
- **System Tasks**: "Deploy Project" → Returns deployment status and any issues
- **Cross-Device**: "Create Event" → Returns confirmation with calendar integration details

### Real-World Interactive Examples

**Note**: These examples show what's possible - you need to create and configure these shortcuts in your Shortcuts app first.

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

- Permission error codes (1743) detected with solution guidance
- Timeout behaviors managed gracefully

### MCP Integration

1. **Tools**:

- `run_shortcut` - AppleScript execution with comprehensive logging
- `shortcuts_usage` - Read and update local preferences and usage tracking
- `view_shortcut` - CLI editor opening with fallback guidance

1. **Resources** (automatically embedded):

- `shortcuts://available` - Current shortcuts list
- `context://system/current` - System state for time-based suggestions
- `context://user/profile` - User preferences and usage patterns
- `statistics://generated` - AI-generated statistics from execution history (when sampling supported)

1. **Enhanced Prompts**: AI-powered shortcut recommendation with name resolution strategies
1. **Local Data Storage**: Performance tracking, permission detection, debugging information (stays on your computer)

## Real-World Examples

**Note**: These examples show what's possible - you need to create and configure these shortcuts in your Shortcuts app first.

### Location-Based Workflows

- **"Find Coffee Shops"**: Location services handled properly via AppleScript context
- **"Weather for Current Location"**: Geographic permissions work reliably

### System Integration

- **"Backup Notes"**: File system operations with proper permissions
- **"System Status Report"**: Hardware monitoring and reporting
- **"Network Diagnostics"**: System-level network analysis

## Development

### TypeScript Implementation

The original TypeScript implementation is available in `src/`:

#### Prerequisites

- Node.js 22+
- macOS with Shortcuts app
- TypeScript knowledge for contributions

#### Setup

```bash
cd shortcuts-mcp
npm install
npm run dev          # Development mode with hot reload
npm run build        # Build for production
npm run build:mcpb   # Build .mcpb bundle
npm run test         # Run test suite
npm run lint         # Linting and type checking
npm run format       # Code formatting
```

#### Project Structure

```
src/
├── server.ts              # MCP server configuration
├── shortcuts.ts           # AppleScript + CLI integration
├── shortcuts-usage.ts     # Local execution tracking and preferences
├── sampling.ts            # AI-driven statistics generation via MCP sampling
├── helpers.ts             # Security and utility functions
├── shortcuts.test.ts      # AppleScript execution tests
├── shortcuts-usage.test.ts # Usage tracking and analytics tests
└── helpers.test.ts        # Security function tests
```

### Swift Implementation

A new native Swift implementation is available in `swift/`, offering better performance and direct access to Swift ecosystem tools.

#### Prerequisites

- Swift 6.0+ (Xcode 16+)
- macOS 15.0+
- Basic Swift knowledge for contributions

#### Setup

```bash
cd swift
swift build              # Build debug version
swift build -c release   # Build optimized release version
swift run ShortcutsMCP   # Run the server directly
```

#### Running Tests

```bash
swift test               # Run all tests
swift test --filter TextPipelineTemplateTests  # Run specific test suite
```

#### Project Structure

```
swift/Sources/ShortcutsMCP/
├── main.swift                           # Entry point
├── Server/
│   └── ShortcutsServer.swift           # MCP server wrapper
├── Tools/
│   ├── RunShortcutTool.swift           # Execute shortcuts
│   ├── ListShortcutsTool.swift         # Discover available shortcuts
│   ├── ViewShortcutTool.swift          # Open shortcut in editor
│   ├── CreateShortcutTool.swift        # Create .shortcut files
│   ├── ListTemplatesTool.swift         # Discover templates
│   └── ShortcutsUsageTool.swift        # User profile and tracking
├── Resources/
│   ├── ShortcutsResources.swift        # MCP resources (shortcuts list, profile, stats)
│   ├── ShortcutsPrompts.swift          # MCP prompts (recommendations)
│   └── ActionCatalogResource.swift     # Progressive disclosure action catalog
├── Models/
│   ├── Shortcut.swift                  # Plist-based shortcut structure
│   ├── WorkflowAction.swift            # Base action type
│   ├── MagicVariable.swift             # Variable references between actions
│   └── Actions/                        # Action implementations
│       ├── TextAction.swift
│       ├── ShowResultAction.swift
│       ├── URLAction.swift
│       ├── FileActions.swift
│       ├── TextActions.swift
│       ├── UIActions.swift
│       ├── VariableActions.swift
│       ├── JSONActions.swift
│       └── ActionRegistry.swift        # Centralized action catalog
├── Shortcuts/
│   ├── ShortcutExecutor.swift          # AppleScript execution
│   ├── ShortcutGenerator.swift         # Build .shortcut files
│   ├── ShortcutSigner.swift            # Sign .shortcut files
│   └── ShortcutImporter.swift          # Auto-import to Shortcuts app
├── Templates/
│   ├── Template.swift                  # Template protocol
│   ├── TemplateEngine.swift            # Template registration and generation
│   └── Definitions/
│       ├── TextPipelineTemplate.swift
│       ├── APIRequestTemplate.swift
│       └── FileDownloadTemplate.swift
├── UserProfile/
│   └── UserProfileManager.swift        # Execution tracking and profile
└── Utilities/
    ├── ShellEscape.swift               # Shell injection protection
    └── ShortcutsCache.swift            # 24-hour cache for shortcuts list
```

#### Key Swift Modules

- **MCP Server**: Built on `modelcontextprotocol/swift-sdk` (v0.10.0+)
- **Concurrency**: Actors for thread-safe shared state (ShortcutExecutor, ShortcutsCache, UserProfileManager, TemplateEngine)
- **Plist Handling**: Native `PropertyListEncoder`/`PropertyListDecoder` for .shortcut files
- **Shell Integration**: Process API for AppleScript and CLI commands with proper escaping

## Troubleshooting

### Common Issues

**"Permission denied" or Error 1743**
Grant automation permissions in System Preferences → Privacy & Security → Automation. Allow Terminal/Claude Desktop to control "Shortcuts Events."

**"Shortcut not found" with CLI commands**
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

Monitor comprehensive logging in your MCP client console for timing, permission detection, and error analysis.

### Execution Characteristics

- **Permission Context**: Reliable execution vs CLI subprocess limitations
- **Logging Detail**: Performance timing, debugging info, permission detection

## Compatibility

- **macOS**: 12+ (Monterey and later)
- **Shortcuts**: All shortcut types with permission-aware handling
- **MCP Clients**: Full MCP protocol compatibility
- **Node.js**: 22+ recommended

## What's Next

- [x] AppleScript integration with permission handling
- [x] Comprehensive logging and error detection
- [x] MCPB bundle format and automated releases
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

---

_Part of the [Model Context Protocol](https://modelcontextprotocol.io) ecosystem - enabling AI assistants to interact with external tools and data sources._
