import Foundation
import MCP

@main
struct ShortcutsMCP {
    static func main() async throws {
        let server = Server(
            name: "shortcuts-mcp",
            version: "4.0.0"
        )

        // TODO: Register tool handlers in future iterations
        // - run_shortcut: Execute shortcuts via AppleScript
        // - view_shortcut: Open shortcut in editor
        // - shortcuts_usage: User profile and execution tracking

        let transport = StdioTransport()
        try await server.start(transport: transport)
    }
}
