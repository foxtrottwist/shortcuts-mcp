// SPDX-License-Identifier: MIT
// CreateShortcutTool.swift - MCP Tool for creating shortcuts from action definitions

import Foundation
import MCP

/// Tool for creating macOS Shortcuts from action definitions.
///
/// This tool allows programmatic creation of .shortcut files by specifying
/// actions as JSON definitions. The generated file can be signed and imported
/// into the Shortcuts app.
public struct CreateShortcutTool {
    /// Tool name as registered with MCP
    public static let name = "create_shortcut"

    /// Tool definition for MCP registration
    public static let definition = Tool(
        name: name,
        description: """
            Create a new macOS Shortcut file from action definitions. \
            Returns the file path of the generated .shortcut file. \
            The file can be signed with `shortcuts sign` and imported.
            """,
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "name": .object([
                    "type": "string",
                    "description": "Name of the shortcut"
                ]),
                "actions": .object([
                    "type": "array",
                    "description":
                        "Array of action definitions. Each action needs an 'identifier' (e.g., 'is.workflow.actions.gettext') and optional 'parameters' object.",
                    "items": .object([
                        "type": "object",
                        "properties": .object([
                            "identifier": .object([
                                "type": "string",
                                "description":
                                    "Action identifier (e.g., 'is.workflow.actions.gettext', 'is.workflow.actions.showresult')"
                            ]),
                            "parameters": .object([
                                "type": "object",
                                "description": "Action-specific parameters"
                            ]),
                            "uuid": .object([
                                "type": "string",
                                "description":
                                    "Optional UUID for referencing this action's output"
                            ]),
                            "customOutputName": .object([
                                "type": "string",
                                "description": "Optional name for the action's output variable"
                            ])
                        ]),
                        "required": .array([.string("identifier")])
                    ])
                ]),
                "icon": .object([
                    "type": "object",
                    "description": "Optional icon configuration",
                    "properties": .object([
                        "color": .object([
                            "type": "object",
                            "description": "Icon color as RGB values (0-255)",
                            "properties": .object([
                                "red": .object(["type": "integer"]),
                                "green": .object(["type": "integer"]),
                                "blue": .object(["type": "integer"])
                            ])
                        ]),
                        "glyph": .object([
                            "type": "integer",
                            "description":
                                "SF Symbol glyph number (defaults to 59771 magic wand)"
                        ])
                    ])
                ])
            ]),
            "required": .array([.string("name"), .string("actions")])
        ]),
        annotations: Tool.Annotations(
            title: "Create Shortcut",
            readOnlyHint: false,
            openWorldHint: false
        )
    )

    /// Input parameters for the create_shortcut tool
    public struct Input: Sendable {
        /// The name of the shortcut to create
        public let name: String

        /// Array of action definitions
        public let actions: [ActionDefinition]

        /// Optional icon configuration
        public let icon: IconConfiguration?

        public init(
            name: String,
            actions: [ActionDefinition],
            icon: IconConfiguration? = nil
        ) {
            self.name = name
            self.actions = actions
            self.icon = icon
        }
    }

    /// Definition of a single action
    public struct ActionDefinition: Sendable {
        /// Action identifier (e.g., "is.workflow.actions.gettext")
        public let identifier: String

        /// Action-specific parameters
        public let parameters: [String: ActionParameterValue]

        /// Optional UUID for referencing this action's output
        public let uuid: String?

        /// Optional name for the output variable
        public let customOutputName: String?

        public init(
            identifier: String,
            parameters: [String: ActionParameterValue] = [:],
            uuid: String? = nil,
            customOutputName: String? = nil
        ) {
            self.identifier = identifier
            self.parameters = parameters
            self.uuid = uuid
            self.customOutputName = customOutputName
        }

        /// Convert to WorkflowAction
        public func toWorkflowAction() -> WorkflowAction {
            WorkflowAction(
                identifier: identifier,
                parameters: parameters,
                uuid: uuid,
                customOutputName: customOutputName
            )
        }
    }

    /// Icon configuration
    public struct IconConfiguration: Sendable {
        /// RGB color components
        public let red: UInt8
        public let green: UInt8
        public let blue: UInt8

        /// SF Symbol glyph number
        public let glyph: Int

        public init(red: UInt8, green: UInt8, blue: UInt8, glyph: Int = 59771) {
            self.red = red
            self.green = green
            self.blue = blue
            self.glyph = glyph
        }

        /// Convert to WorkflowIcon
        public func toWorkflowIcon() -> WorkflowIcon {
            WorkflowIcon.withColor(
                red: red,
                green: green,
                blue: blue,
                glyphNumber: glyph
            )
        }
    }

    /// Execute the create_shortcut tool
    ///
    /// - Parameter input: The tool input parameters
    /// - Returns: The tool result with the generated file path
    public static func execute(input: Input) async throws -> CallTool.Result {
        guard !input.actions.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: At least one action is required")],
                isError: true
            )
        }

        // Build icon configuration
        let icon = input.icon?.toWorkflowIcon() ?? .default

        // Create generator configuration
        let configuration = ShortcutGenerator.Configuration(
            name: input.name,
            icon: icon
        )

        // Create generator
        let generator = ShortcutGenerator(configuration: configuration)

        // Convert action definitions to workflow actions
        let workflowActions = input.actions.map { $0.toWorkflowAction() }

        do {
            // Generate the shortcut file
            let result = try await generator.generate(workflowActions: workflowActions)

            // Build response
            let response: [String: Any] = [
                "filePath": result.filePath.path,
                "fileSize": result.fileSize,
                "name": input.name,
                "actionCount": input.actions.count,
                "message":
                    "Shortcut '\(input.name)' created successfully. Sign with: shortcuts sign --mode anyone --input \"\(result.filePath.path)\" --output signed.shortcut"
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            return CallTool.Result(
                content: [.text(jsonString)],
                isError: false
            )
        } catch let error as ShortcutGenerator.GenerationError {
            return CallTool.Result(
                content: [.text("Error: \(error.localizedDescription)")],
                isError: true
            )
        } catch {
            return CallTool.Result(
                content: [.text("Error generating shortcut: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Parse tool call parameters into Input struct
    ///
    /// - Parameter arguments: The raw arguments from the MCP call
    /// - Returns: Parsed Input struct
    /// - Throws: MCPError if required parameters are missing or invalid
    public static func parseInput(from arguments: [String: Value]?) throws -> Input {
        guard let arguments else {
            throw MCPError.invalidParams("Missing arguments for \(name)")
        }

        // Extract name
        guard let nameValue = arguments["name"], let name = nameValue.stringValue else {
            throw MCPError.invalidParams("Missing or invalid required parameter: name")
        }

        // Extract actions array
        guard let actionsValue = arguments["actions"], let actionsArray = actionsValue.arrayValue
        else {
            throw MCPError.invalidParams("Missing or invalid required parameter: actions")
        }

        // Parse each action
        var actions: [ActionDefinition] = []
        for (index, actionValue) in actionsArray.enumerated() {
            guard let actionDict = actionValue.objectValue else {
                throw MCPError.invalidParams("Action at index \(index) must be an object")
            }

            guard let identifierValue = actionDict["identifier"],
                let identifier = identifierValue.stringValue
            else {
                throw MCPError.invalidParams(
                    "Action at index \(index) missing required 'identifier'")
            }

            // Parse optional parameters
            var parameters: [String: ActionParameterValue] = [:]
            if let paramsValue = actionDict["parameters"], let paramsDict = paramsValue.objectValue
            {
                parameters = try parseParameters(paramsDict)
            }

            // Parse optional uuid
            let uuid = actionDict["uuid"]?.stringValue

            // Parse optional customOutputName
            let customOutputName = actionDict["customOutputName"]?.stringValue

            actions.append(
                ActionDefinition(
                    identifier: identifier,
                    parameters: parameters,
                    uuid: uuid,
                    customOutputName: customOutputName
                ))
        }

        // Parse optional icon
        var icon: IconConfiguration?
        if let iconValue = arguments["icon"], let iconDict = iconValue.objectValue {
            icon = try parseIcon(iconDict)
        }

        return Input(name: name, actions: actions, icon: icon)
    }

    /// Parse parameter dictionary from JSON Value to ActionParameterValue
    private static func parseParameters(_ dict: [String: Value]) throws -> [String:
        ActionParameterValue]
    {
        var result: [String: ActionParameterValue] = [:]
        for (key, value) in dict {
            result[key] = try valueToActionParameter(value)
        }
        return result
    }

    /// Convert a JSON Value to ActionParameterValue
    private static func valueToActionParameter(_ value: Value) throws -> ActionParameterValue {
        if let str = value.stringValue {
            return .string(str)
        } else if let num = value.intValue {
            return .int(num)
        } else if let num = value.doubleValue {
            return .double(num)
        } else if let bool = value.boolValue {
            return .bool(bool)
        } else if let arr = value.arrayValue {
            let converted = try arr.map { try valueToActionParameter($0) }
            return .array(converted)
        } else if let dict = value.objectValue {
            let converted = try parseParameters(dict)
            return .dictionary(converted)
        } else if value.isNull {
            // Treat null as empty string for simplicity
            return .string("")
        } else {
            throw MCPError.invalidParams("Unsupported parameter value type")
        }
    }

    /// Parse icon configuration from JSON dictionary
    private static func parseIcon(_ dict: [String: Value]) throws -> IconConfiguration? {
        var red: UInt8 = 27  // Default blue color
        var green: UInt8 = 154
        var blue: UInt8 = 247
        var glyph = 59771  // Default magic wand

        if let colorValue = dict["color"], let colorDict = colorValue.objectValue {
            if let r = colorDict["red"]?.intValue {
                red = UInt8(clamping: r)
            }
            if let g = colorDict["green"]?.intValue {
                green = UInt8(clamping: g)
            }
            if let b = colorDict["blue"]?.intValue {
                blue = UInt8(clamping: b)
            }
        }

        if let g = dict["glyph"]?.intValue {
            glyph = g
        }

        return IconConfiguration(red: red, green: green, blue: blue, glyph: glyph)
    }
}

// MARK: - Value Extension for Type Access

extension Value {
    /// Get integer value if this is a number
    var intValue: Int? {
        if case .int(let i) = self {
            return i
        } else if case .double(let d) = self {
            return Int(d)
        }
        return nil
    }

    /// Get double value if this is a number
    var doubleValue: Double? {
        if case .double(let d) = self {
            return d
        } else if case .int(let i) = self {
            return Double(i)
        }
        return nil
    }

    /// Get bool value if this is a boolean
    var boolValue: Bool? {
        if case .bool(let b) = self {
            return b
        }
        return nil
    }
}
