import Foundation
import MCP

/// Tool to open a macOS Shortcut in the Shortcuts editor.
///
/// Executes `shortcuts view <name>` to open the shortcut for viewing or editing.
/// Uses shell escaping to safely handle shortcut names with special characters.
enum ViewShortcutTool {
    /// Tool name as registered with MCP
    static let name = "view_shortcut"

    /// Tool definition for MCP registration
    static var definition: Tool {
        Tool(
            name: name,
            description: "Open a macOS Shortcut in the Shortcuts editor for viewing or editing.",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "name": .object([
                        "type": "string",
                        "description": "The name of the Shortcut to view"
                    ])
                ]),
                "required": .array(["name"])
            ]),
            annotations: Tool.Annotations(
                title: "View Shortcut",
                readOnlyHint: true,
                openWorldHint: true
            )
        )
    }

    /// Execute the view_shortcut tool
    /// - Parameter arguments: Tool arguments (requires "name" string)
    /// - Returns: CallTool.Result with success message or error
    static func execute(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let name = arguments?["name"]?.stringValue, !name.isEmpty else {
            throw MCPError.invalidParams("Missing required parameter: name")
        }

        try await openShortcutInEditor(name: name)

        return CallTool.Result(
            content: [.text("Opened \"\(name)\" in Shortcuts editor")],
            isError: false
        )
    }

    /// Open a shortcut in the Shortcuts editor using the CLI
    /// - Parameter name: The name of the shortcut to open
    private static func openShortcutInEditor(name: String) async throws {
        let process = Process()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        // Use shell to execute with proper escaping
        process.arguments = ["view", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw MCPError.internalError("Failed to execute shortcuts CLI: \(error.localizedDescription)")
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"

            // Provide helpful error message for common issues
            if errorMessage.contains("Couldn't find") || errorMessage.contains("not found") {
                throw MCPError.invalidParams(
                    "Shortcut \"\(name)\" not found. " +
                    "Try using the exact case-sensitive name from list_shortcuts. " +
                    "Note: Apple's CLI has known name resolution bugs."
                )
            }

            throw MCPError.internalError(
                "Failed to view shortcut \"\(name)\": \(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))"
            )
        }
    }
}
