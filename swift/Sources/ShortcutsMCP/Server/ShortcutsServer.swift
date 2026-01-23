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
            prompts: .init(listChanged: false),
            resources: .init(subscribe: false, listChanged: false),
            tools: .init(listChanged: false)
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

        // Register resource handlers
        await registerResourceHandlers()

        // Register prompt handlers
        await registerPromptHandlers()

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
                ViewShortcutTool.definition,
                ShortcutsUsageTool.definition,
                CreateShortcutTool.definition
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

            case ShortcutsUsageTool.name:
                return try await ShortcutsUsageTool.execute(arguments: params.arguments)

            case CreateShortcutTool.name:
                let input = try CreateShortcutTool.parseInput(from: params.arguments)
                return try await CreateShortcutTool.execute(input: input)

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

            // Combine base resources with action catalog
            var allResources = ShortcutsResources.all
            allResources.append(ActionCatalogResource.catalog)
            return ListResources.Result(resources: allResources)
        }

        // Register resources/read handler
        await server.withMethodHandler(ReadResource.self) { [weak self] params in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // Try action catalog first (handles actions:// URIs)
            if let content = try ActionCatalogResource.load(uri: params.uri) {
                return ReadResource.Result(contents: [content])
            }

            // Fall back to shortcuts resources
            guard let content = try await ShortcutsResources.load(uri: params.uri) else {
                throw MCPError.invalidParams("Unknown resource: \(params.uri)")
            }

            return ReadResource.Result(contents: [content])
        }

        // Register resources/templates/list handler
        await server.withMethodHandler(ListResourceTemplates.self) { [weak self] _ in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            // Combine base templates with action catalog templates
            var allTemplates = ShortcutsResources.templates
            allTemplates.append(contentsOf: ActionCatalogResource.templates)
            return ListResourceTemplates.Result(templates: allTemplates)
        }
    }

    /// Register all prompt handlers
    private func registerPromptHandlers() async {
        // Register prompts/list handler
        await server.withMethodHandler(ListPrompts.self) { [weak self] _ in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            return ListPrompts.Result(prompts: ShortcutsPrompts.all)
        }

        // Register prompts/get handler
        await server.withMethodHandler(GetPrompt.self) { [weak self] params in
            guard self != nil else {
                throw MCPError.internalError("Server was deallocated")
            }

            guard let result = ShortcutsPrompts.get(name: params.name, arguments: params.arguments) else {
                throw MCPError.invalidParams("Unknown prompt: \(params.name)")
            }

            return result
        }
    }
}
