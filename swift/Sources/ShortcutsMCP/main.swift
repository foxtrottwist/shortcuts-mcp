import Foundation
import MCP

@main
struct ShortcutsMCP {
    static func main() async throws {
        let configuration = ShortcutsServer.Configuration(
            instructions: """
                Shortcuts MCP provides tools to interact with macOS Shortcuts app.
                Available operations:
                - Run shortcuts by name
                - View shortcuts in the Shortcuts editor
                - Get user context and execution history
                """
        )

        let server = ShortcutsServer(configuration: configuration)
        let transport = StdioTransport()

        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
