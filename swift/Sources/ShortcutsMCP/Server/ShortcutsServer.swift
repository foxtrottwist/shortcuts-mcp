import Foundation
import MCP

/// A wrapper around the MCP Server that provides the Shortcuts MCP implementation.
///
/// ShortcutsServer configures the MCP Server with:
/// - Tool handlers for shortcut operations
/// - Resource providers for shortcuts context
/// - Proper capabilities declaration
public actor ShortcutsServer {
    /// Server version (matches package version)
    public static let version = "4.0.0"

    /// The underlying MCP server
    private let server: Server

    /// The transport used for communication
    private var transport: (any Transport)?

    /// Server configuration
    public struct Configuration: Sendable {
        /// Server name as reported to clients
        public var name: String

        /// Server version
        public var version: String

        /// Instructions for the LLM about available capabilities
        public var instructions: String?

        /// Whether to use strict MCP protocol mode
        public var strictMode: Bool

        public init(
            name: String = "shortcuts-mcp",
            version: String = ShortcutsServer.version,
            instructions: String? = nil,
            strictMode: Bool = false
        ) {
            self.name = name
            self.version = version
            self.instructions = instructions
            self.strictMode = strictMode
        }

        /// Default configuration
        public static let `default` = Configuration()
    }

    /// Initialize a new ShortcutsServer with the given configuration
    /// - Parameter configuration: Server configuration options
    public init(configuration: Configuration = .default) {
        // Configure MCP server capabilities
        let capabilities = Server.Capabilities(
            tools: .init(listChanged: false)
            // Resources and prompts will be added in future iterations
        )

        self.server = Server(
            name: configuration.name,
            version: configuration.version,
            instructions: configuration.instructions,
            capabilities: capabilities,
            configuration: configuration.strictMode ? .strict : .default
        )
    }

    /// Start the server with the given transport
    /// - Parameter transport: The transport to use (e.g., StdioTransport)
    public func start(transport: any Transport) async throws {
        self.transport = transport

        // Register tool handlers
        await registerToolHandlers()

        // Register resource handlers (placeholder for future)
        await registerResourceHandlers()

        // Start the underlying MCP server
        try await server.start(transport: transport)
    }

    /// Stop the server and clean up resources
    public func stop() async {
        await server.stop()
        transport = nil
    }

    /// Wait until the server has completed (useful for keeping the process alive)
    public func waitUntilCompleted() async {
        await server.waitUntilCompleted()
    }

    // MARK: - Handler Registration

    /// Register all tool handlers
    private func registerToolHandlers() async {
        // Register tools/list handler
        await server.withMethodHandler(ListTools.self) { [weak self] _ in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // Return all registered tools
            return ListTools.Result(tools: [
                RunShortcutTool.definition,
                ListShortcutsTool.definition,
                ViewShortcutTool.definition
            ])
        }

        // Register tools/call handler
        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // Dispatch to appropriate tool handler
            switch params.name {
            case RunShortcutTool.name:
                let input = try RunShortcutTool.parseInput(from: params)
                return try await RunShortcutTool.execute(input: input)

            case ListShortcutsTool.name:
                return try await ListShortcutsTool.execute(arguments: params.arguments)

            case ViewShortcutTool.name:
                return try await ViewShortcutTool.execute(arguments: params.arguments)

            default:
                throw MCPError.invalidParams("Unknown tool: \(params.name)")
            }
        }
    }

    /// Register all resource handlers
    private func registerResourceHandlers() async {
        // Register resources/list handler
        await server.withMethodHandler(ListResources.self) { [weak self] _ in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // TODO: Return actual resources in future iterations
            return ListResources.Result(resources: [])
        }

        // Register resources/read handler
        await server.withMethodHandler(ReadResource.self) { [weak self] params in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // TODO: Implement actual resource reading in future iterations
            throw MCPError.invalidParams("Unknown resource: \(params.uri)")
        }
    }
}
