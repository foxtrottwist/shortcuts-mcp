import Foundation
import MCP

/// Tool for executing macOS Shortcuts by name with optional input.
///
/// This tool provides the primary interface for running shortcuts through the MCP server.
/// It uses AppleScript via "Shortcuts Events" for reliable execution with proper permission
/// handling.
public struct RunShortcutTool {
    /// Tool name as registered with MCP
    public static let name = "run_shortcut"

    /// Tool definition for MCP registration
    public static let definition = Tool(
        name: name,
        description: """
            Execute a macOS Shortcut by name with optional input. \
            Supports all shortcut types including interactive workflows.
            """,
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "name": .object([
                    "type": "string",
                    "description": "The name of the Shortcut to run"
                ]),
                "input": .object([
                    "type": "string",
                    "description": "Optional input to pass to the shortcut"
                ])
            ]),
            "required": .array([.string("name")])
        ]),
        annotations: Tool.Annotations(
            title: "Run Shortcut",
            readOnlyHint: false,
            openWorldHint: true
        )
    )

    /// Input parameters for the run_shortcut tool
    public struct Input: Decodable, Sendable {
        /// The name of the shortcut to run
        public let name: String

        /// Optional input to pass to the shortcut
        public let input: String?

        public init(name: String, input: String? = nil) {
            self.name = name
            self.input = input
        }
    }

    /// Execute the run_shortcut tool
    ///
    /// - Parameter input: The tool input parameters
    /// - Returns: The tool result with execution output
    public static func execute(input: Input) async throws -> CallTool.Result {
        let executor = ShortcutExecutor.shared

        do {
            let output = try await executor.runShortcut(name: input.name, input: input.input)

            return CallTool.Result(
                content: [.text(output)],
                isError: false
            )
        } catch {
            // Return error as tool result rather than throwing
            return CallTool.Result(
                content: [.text(error.localizedDescription)],
                isError: true
            )
        }
    }

    /// Parse tool call parameters into Input struct
    ///
    /// - Parameter params: The raw parameters from the MCP call
    /// - Returns: Parsed Input struct
    /// - Throws: MCPError if required parameters are missing
    public static func parseInput(from params: CallTool.Parameters) throws -> Input {
        guard let arguments = params.arguments else {
            throw MCPError.invalidParams("Missing arguments for \(name)")
        }

        guard let nameValue = arguments["name"] else {
            throw MCPError.invalidParams("Missing required parameter: name")
        }

        // Extract name string from the JSON value
        guard let name = nameValue.stringValue else {
            throw MCPError.invalidParams("Parameter 'name' must be a string")
        }

        // Extract optional input string
        var input: String?
        if let inputValue = arguments["input"] {
            if inputValue.isNull {
                input = nil
            } else if let inputString = inputValue.stringValue {
                input = inputString
            } else {
                throw MCPError.invalidParams("Parameter 'input' must be a string")
            }
        }

        return Input(name: name, input: input)
    }
}
