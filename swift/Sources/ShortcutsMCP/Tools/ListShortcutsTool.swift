import Foundation
import MCP

/// Tool to list all available macOS Shortcuts.
///
/// Executes `shortcuts list --show-identifiers` and parses the output
/// to provide a JSON array of shortcuts with names and UUIDs.
/// Results are cached for 24 hours to avoid repeated CLI calls.
enum ListShortcutsTool {
    /// Tool name as registered with MCP
    static let name = "list_shortcuts"

    /// Tool definition for MCP registration
    static var definition: Tool {
        Tool(
            name: name,
            description: "List all available macOS Shortcuts with names and identifiers. Results are cached for 24 hours.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "refresh": .object([
                        "type": "boolean",
                        "description": "Force refresh the cache, ignoring any cached results"
                    ])
                ]),
                "required": .array([])
            ])
        )
    }

    /// Execute the list_shortcuts tool
    /// - Parameter arguments: Tool arguments (optional "refresh" boolean)
    /// - Returns: CallTool.Result with JSON array of shortcuts
    static func execute(arguments: [String: Value]?) async throws -> CallTool.Result {
        let forceRefresh = arguments?["refresh"]?.boolValue ?? false

        // Check cache first unless force refresh requested
        if !forceRefresh, let cached = await ShortcutsCache.shared.getCachedShortcuts() {
            let json = try encodeShortcuts(cached)
            return CallTool.Result(
                content: [.text(json)],
                isError: false
            )
        }

        // Execute CLI command
        let shortcuts = try await fetchShortcutsFromCLI()

        // Cache the results
        await ShortcutsCache.shared.cacheShortcuts(shortcuts)

        // Return JSON
        let json = try encodeShortcuts(shortcuts)
        return CallTool.Result(
            content: [.text(json)],
            isError: false
        )
    }

    /// Fetch shortcuts from the macOS shortcuts CLI
    private static func fetchShortcutsFromCLI() async throws -> [ShortcutsCache.ShortcutInfo] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list", "--show-identifiers"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw MCPError.internalError("Failed to execute shortcuts CLI: \(error.localizedDescription)")
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw MCPError.internalError("shortcuts list command failed with exit code \(process.terminationStatus)")
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw MCPError.internalError("Failed to decode shortcuts list output")
        }

        return parseShortcutsList(output)
    }

    /// Parse the output of `shortcuts list --show-identifiers`
    ///
    /// The output format is: "Shortcut Name (UUID)"
    /// One shortcut per line.
    private static func parseShortcutsList(_ output: String) -> [ShortcutsCache.ShortcutInfo] {
        output
            .split(separator: "\n")
            .compactMap { line -> ShortcutsCache.ShortcutInfo? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }

                // Format: "Name (UUID)"
                // Find the last opening parenthesis for the UUID
                guard let lastParen = trimmed.lastIndex(of: "("),
                      trimmed.hasSuffix(")") else {
                    // No UUID format, just use the name
                    return ShortcutsCache.ShortcutInfo(
                        name: trimmed,
                        identifier: ""
                    )
                }

                let name = String(trimmed[..<lastParen]).trimmingCharacters(in: .whitespaces)
                let uuidStart = trimmed.index(after: lastParen)
                let uuidEnd = trimmed.index(before: trimmed.endIndex)
                let uuid = String(trimmed[uuidStart..<uuidEnd])

                return ShortcutsCache.ShortcutInfo(name: name, identifier: uuid)
            }
    }

    /// Encode shortcuts to JSON string
    private static func encodeShortcuts(_ shortcuts: [ShortcutsCache.ShortcutInfo]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(shortcuts)
        guard let json = String(data: data, encoding: .utf8) else {
            throw MCPError.internalError("Failed to encode shortcuts as JSON")
        }
        return json
    }
}
