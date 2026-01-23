// SPDX-License-Identifier: MIT
// CreateShortcutTool.swift - MCP Tool for creating shortcuts from action definitions or templates

import Foundation
import MCP

/// Tool for creating macOS Shortcuts from action definitions or templates.
///
/// This tool supports two modes:
/// 1. **Actions mode**: Specify actions directly as JSON definitions
/// 2. **Template mode**: Use a template name with parameters
///
/// The generated file can be signed and imported into the Shortcuts app.
public struct CreateShortcutTool {
    /// Tool name as registered with MCP
    public static let name = "create_shortcut"

    /// Shared template engine for template-based generation
    public static let templateEngine: TemplateEngine = {
        let engine = TemplateEngine()
        // Note: Templates are registered synchronously during init
        return engine
    }()

    /// Tool definition for MCP registration
    public static let definition = Tool(
        name: name,
        description: """
            Create a new macOS Shortcut file from action definitions or a template. \
            Use EITHER 'actions' array for custom shortcuts OR 'template' + 'templateParams' for template-based generation. \
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
                        "Array of action definitions (use this OR template, not both). Each action needs an 'identifier' (e.g., 'is.workflow.actions.gettext') and optional 'parameters' object.",
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
                "template": .object([
                    "type": "string",
                    "description":
                        "Template name to use for generation (use this OR actions, not both). Use list_templates tool to discover available templates."
                ]),
                "templateParams": .object([
                    "type": "object",
                    "description":
                        "Parameters for the template. Each key is a parameter name, value depends on parameter type.",
                    "additionalProperties": .bool(true)
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
                ]),
                "sign": .object([
                    "type": "boolean",
                    "description": "Whether to sign the shortcut after creation (default: true). Signing is required for import."
                ]),
                "signingMode": .object([
                    "type": "string",
                    "enum": .array([.string("anyone"), .string("peopleWhoKnowMe")]),
                    "description": "Signing mode - 'anyone' allows anyone to import, 'peopleWhoKnowMe' restricts to contacts (default: anyone)"
                ]),
                "autoImport": .object([
                    "type": "boolean",
                    "description": "Whether to automatically open the signed shortcut in the Shortcuts app for import (default: false). Requires sign=true."
                ]),
                "importQuestions": .object([
                    "type": "array",
                    "description": "Questions to prompt the user when importing the shortcut (e.g., for API keys or credentials)",
                    "items": .object([
                        "type": "object",
                        "properties": .object([
                            "actionIndex": .object([
                                "type": "integer",
                                "description": "Index of the action this question applies to (0-based)"
                            ]),
                            "parameterKey": .object([
                                "type": "string",
                                "description": "The parameter key in the action (e.g., 'WFAPIKey')"
                            ]),
                            "category": .object([
                                "type": "string",
                                "description": "Category of the question (e.g., 'API Key', 'Credential', 'URL')"
                            ]),
                            "defaultValue": .object([
                                "type": "string",
                                "description": "Default value for the parameter"
                            ]),
                            "text": .object([
                                "type": "string",
                                "description": "Display text for the question prompt"
                            ])
                        ]),
                        "required": .array([.string("actionIndex"), .string("parameterKey")])
                    ])
                ])
            ]),
            "required": .array([.string("name")])
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

        /// Array of action definitions (for actions mode)
        public let actions: [ActionDefinition]?

        /// Template name (for template mode)
        public let template: String?

        /// Template parameters (for template mode)
        public let templateParams: [String: TemplateParameterValue]?

        /// Optional icon configuration
        public let icon: IconConfiguration?

        /// Whether to sign the shortcut after creation
        public let sign: Bool

        /// Signing mode (anyone or peopleWhoKnowMe)
        public let signingMode: ShortcutSigner.SigningMode

        /// Whether to auto-import the shortcut into the Shortcuts app
        public let autoImport: Bool

        /// Import questions for user prompts when importing
        public let importQuestions: [ImportQuestion]?

        /// Creates input for actions mode
        public init(
            name: String,
            actions: [ActionDefinition],
            icon: IconConfiguration? = nil,
            sign: Bool = true,
            signingMode: ShortcutSigner.SigningMode = .anyone,
            autoImport: Bool = false,
            importQuestions: [ImportQuestion]? = nil
        ) {
            self.name = name
            self.actions = actions
            self.template = nil
            self.templateParams = nil
            self.icon = icon
            self.sign = sign
            self.signingMode = signingMode
            self.autoImport = autoImport
            self.importQuestions = importQuestions
        }

        /// Creates input for template mode
        public init(
            name: String,
            template: String,
            templateParams: [String: TemplateParameterValue] = [:],
            icon: IconConfiguration? = nil,
            sign: Bool = true,
            signingMode: ShortcutSigner.SigningMode = .anyone,
            autoImport: Bool = false,
            importQuestions: [ImportQuestion]? = nil
        ) {
            self.name = name
            self.actions = nil
            self.template = template
            self.templateParams = templateParams
            self.icon = icon
            self.sign = sign
            self.signingMode = signingMode
            self.autoImport = autoImport
            self.importQuestions = importQuestions
        }

        /// Determines the creation mode
        public var mode: CreationMode {
            if let template, !template.isEmpty {
                return .template
            }
            return .actions
        }
    }

    /// Mode for shortcut creation
    public enum CreationMode {
        case actions
        case template
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
        switch input.mode {
        case .actions:
            return try await executeActionsMode(input: input)
        case .template:
            return try await executeTemplateMode(input: input)
        }
    }

    /// Execute in actions mode (original behavior)
    private static func executeActionsMode(input: Input) async throws -> CallTool.Result {
        guard let actions = input.actions, !actions.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: At least one action is required when using actions mode")],
                isError: true
            )
        }

        // Build icon configuration
        let icon = input.icon?.toWorkflowIcon() ?? .default

        // Create generator configuration with import questions
        let configuration = ShortcutGenerator.Configuration(
            name: input.name,
            icon: icon,
            importQuestions: input.importQuestions
        )

        // Create generator
        let generator = ShortcutGenerator(configuration: configuration)

        // Convert action definitions to workflow actions
        let workflowActions = actions.map { $0.toWorkflowAction() }

        do {
            // Generate the shortcut file
            let result = try await generator.generate(workflowActions: workflowActions)

            // Build response
            var response: [String: Any] = [
                "filePath": result.filePath.path,
                "fileSize": result.fileSize,
                "name": input.name,
                "actionCount": actions.count,
                "mode": "actions"
            ]

            // Handle signing if requested
            var signedFilePath: String?
            if input.sign {
                do {
                    let signer = ShortcutSigner.shared
                    let signedURL = try await signer.sign(
                        input: result.filePath,
                        mode: input.signingMode
                    )
                    signedFilePath = signedURL.path
                    response["signedFilePath"] = signedURL.path
                    response["signed"] = true
                } catch {
                    return CallTool.Result(
                        content: [.text("Error signing shortcut: \(error.localizedDescription)")],
                        isError: true
                    )
                }
            } else {
                response["signed"] = false
            }

            // Handle auto-import if requested
            if input.autoImport {
                if !input.sign {
                    return CallTool.Result(
                        content: [.text("Error: autoImport requires sign=true (shortcuts must be signed before import)")],
                        isError: true
                    )
                }

                if let signedPath = signedFilePath {
                    let importer = ShortcutImporter.shared
                    let importResult = await importer.importShortcut(
                        atPath: signedPath,
                        signFirst: false, // Already signed
                        cleanup: false
                    )

                    response["imported"] = importResult.isSuccess
                    if !importResult.isSuccess {
                        response["importError"] = importResult.errorMessage
                    }
                } else {
                    response["imported"] = false
                    response["importError"] = "No signed file available for import"
                }
            } else {
                response["imported"] = false
            }

            // Build message based on what was done
            var message = "Shortcut '\(input.name)' created successfully."
            if input.sign, let signedPath = signedFilePath {
                message += " Signed file: \(signedPath)"
            } else {
                message += " Sign with: shortcuts sign --mode anyone --input \"\(result.filePath.path)\" --output signed.shortcut"
            }
            if input.autoImport, let imported = response["imported"] as? Bool, imported {
                message += " Import triggered - check Shortcuts app."
            }
            response["message"] = message

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

    /// Execute in template mode
    private static func executeTemplateMode(input: Input) async throws -> CallTool.Result {
        guard let templateName = input.template, !templateName.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: Template name is required when using template mode")],
                isError: true
            )
        }

        // Ensure built-in templates are registered
        await templateEngine.registerBuiltInTemplates()

        // Check if template exists
        let templateInfo = await templateEngine.getTemplateInfo(name: templateName)
        guard templateInfo != nil else {
            let availableTemplates = await templateEngine.listTemplates().map(\.name)
            return CallTool.Result(
                content: [
                    .text(
                        "Error: Template '\(templateName)' not found. Available templates: \(availableTemplates.joined(separator: ", "))"
                    )
                ],
                isError: true
            )
        }

        // Build icon configuration
        let icon = input.icon?.toWorkflowIcon() ?? .default

        // Create generator configuration with import questions
        let configuration = ShortcutGenerator.Configuration(
            name: input.name,
            icon: icon,
            importQuestions: input.importQuestions
        )

        do {
            // Generate shortcut from template
            let params = input.templateParams ?? [:]
            let result = try await templateEngine.generateShortcut(
                templateName: templateName,
                parameters: params,
                configuration: configuration
            )

            // Build response
            var response: [String: Any] = [
                "filePath": result.filePath.path,
                "fileSize": result.fileSize,
                "name": input.name,
                "actionCount": result.shortcut.actions.count,
                "mode": "template",
                "template": templateName
            ]

            // Handle signing if requested
            var signedFilePath: String?
            if input.sign {
                do {
                    let signer = ShortcutSigner.shared
                    let signedURL = try await signer.sign(
                        input: result.filePath,
                        mode: input.signingMode
                    )
                    signedFilePath = signedURL.path
                    response["signedFilePath"] = signedURL.path
                    response["signed"] = true
                } catch {
                    return CallTool.Result(
                        content: [.text("Error signing shortcut: \(error.localizedDescription)")],
                        isError: true
                    )
                }
            } else {
                response["signed"] = false
            }

            // Handle auto-import if requested
            if input.autoImport {
                if !input.sign {
                    return CallTool.Result(
                        content: [.text("Error: autoImport requires sign=true (shortcuts must be signed before import)")],
                        isError: true
                    )
                }

                if let signedPath = signedFilePath {
                    let importer = ShortcutImporter.shared
                    let importResult = await importer.importShortcut(
                        atPath: signedPath,
                        signFirst: false, // Already signed
                        cleanup: false
                    )

                    response["imported"] = importResult.isSuccess
                    if !importResult.isSuccess {
                        response["importError"] = importResult.errorMessage
                    }
                } else {
                    response["imported"] = false
                    response["importError"] = "No signed file available for import"
                }
            } else {
                response["imported"] = false
            }

            // Build message based on what was done
            var message = "Shortcut '\(input.name)' created from template '\(templateName)'."
            if input.sign, let signedPath = signedFilePath {
                message += " Signed file: \(signedPath)"
            } else {
                message += " Sign with: shortcuts sign --mode anyone --input \"\(result.filePath.path)\" --output signed.shortcut"
            }
            if input.autoImport, let imported = response["imported"] as? Bool, imported {
                message += " Import triggered - check Shortcuts app."
            }
            response["message"] = message

            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            return CallTool.Result(
                content: [.text(jsonString)],
                isError: false
            )
        } catch let error as TemplateError {
            return CallTool.Result(
                content: [.text("Template error: \(error.localizedDescription)")],
                isError: true
            )
        } catch let error as ShortcutGenerator.GenerationError {
            return CallTool.Result(
                content: [.text("Generation error: \(error.localizedDescription)")],
                isError: true
            )
        } catch {
            return CallTool.Result(
                content: [
                    .text("Error generating shortcut from template: \(error.localizedDescription)")
                ],
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

        // Extract name (always required)
        guard let nameValue = arguments["name"], let name = nameValue.stringValue else {
            throw MCPError.invalidParams("Missing or invalid required parameter: name")
        }

        // Parse optional icon
        var icon: IconConfiguration?
        if let iconValue = arguments["icon"], let iconDict = iconValue.objectValue {
            icon = try parseIcon(iconDict)
        }

        // Parse signing options
        let sign = arguments["sign"]?.boolValue ?? true
        let signingMode: ShortcutSigner.SigningMode
        if let modeStr = arguments["signingMode"]?.stringValue {
            switch modeStr {
            case "peopleWhoKnowMe":
                signingMode = .peopleWhoKnowMe
            default:
                signingMode = .anyone
            }
        } else {
            signingMode = .anyone
        }

        // Parse auto-import option
        let autoImport = arguments["autoImport"]?.boolValue ?? false

        // Parse import questions
        var importQuestions: [ImportQuestion]?
        if let questionsValue = arguments["importQuestions"],
           let questionsArray = questionsValue.arrayValue {
            importQuestions = try parseImportQuestions(questionsArray)
        }

        // Check if template mode or actions mode
        let hasTemplate = arguments["template"]?.stringValue != nil
        let hasActions = arguments["actions"]?.arrayValue != nil

        if hasTemplate && hasActions {
            throw MCPError.invalidParams(
                "Cannot specify both 'template' and 'actions'. Use one or the other.")
        }

        if hasTemplate {
            // Template mode
            guard let templateValue = arguments["template"], let template = templateValue.stringValue
            else {
                throw MCPError.invalidParams("Missing or invalid parameter: template")
            }

            // Parse template parameters
            var templateParams: [String: TemplateParameterValue] = [:]
            if let paramsValue = arguments["templateParams"],
                let paramsDict = paramsValue.objectValue
            {
                templateParams = try parseTemplateParameters(paramsDict)
            }

            return Input(
                name: name,
                template: template,
                templateParams: templateParams,
                icon: icon,
                sign: sign,
                signingMode: signingMode,
                autoImport: autoImport,
                importQuestions: importQuestions
            )
        } else {
            // Actions mode (original behavior)
            guard let actionsValue = arguments["actions"], let actionsArray = actionsValue.arrayValue
            else {
                throw MCPError.invalidParams(
                    "Missing required parameter: either 'actions' array or 'template' name must be provided"
                )
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
                if let paramsValue = actionDict["parameters"],
                    let paramsDict = paramsValue.objectValue
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

            return Input(
                name: name,
                actions: actions,
                icon: icon,
                sign: sign,
                signingMode: signingMode,
                autoImport: autoImport,
                importQuestions: importQuestions
            )
        }
    }

    /// Parse import questions from JSON array
    private static func parseImportQuestions(_ array: [Value]) throws -> [ImportQuestion] {
        var questions: [ImportQuestion] = []
        for (index, value) in array.enumerated() {
            guard let dict = value.objectValue else {
                throw MCPError.invalidParams("Import question at index \(index) must be an object")
            }

            guard let actionIndexValue = dict["actionIndex"],
                  let actionIndex = actionIndexValue.intValue else {
                throw MCPError.invalidParams("Import question at index \(index) missing required 'actionIndex'")
            }

            guard let parameterKeyValue = dict["parameterKey"],
                  let parameterKey = parameterKeyValue.stringValue else {
                throw MCPError.invalidParams("Import question at index \(index) missing required 'parameterKey'")
            }

            let category = dict["category"]?.stringValue
            let defaultValue = dict["defaultValue"]?.stringValue
            let text = dict["text"]?.stringValue

            questions.append(ImportQuestion(
                actionIndex: actionIndex,
                parameterKey: parameterKey,
                category: category,
                defaultValue: defaultValue,
                text: text
            ))
        }
        return questions
    }

    /// Parse template parameters from JSON Value to TemplateParameterValue
    private static func parseTemplateParameters(_ dict: [String: Value]) throws
        -> [String: TemplateParameterValue]
    {
        var result: [String: TemplateParameterValue] = [:]
        for (key, value) in dict {
            result[key] = try valueToTemplateParameter(value)
        }
        return result
    }

    /// Convert a JSON Value to TemplateParameterValue
    private static func valueToTemplateParameter(_ value: Value) throws -> TemplateParameterValue {
        if let str = value.stringValue {
            // Check if it looks like a URL
            if str.hasPrefix("http://") || str.hasPrefix("https://") || str.hasPrefix("file://") {
                return .url(str)
            }
            return .string(str)
        } else if let num = value.doubleValue {
            return .number(num)
        } else if let bool = value.boolValue {
            return .boolean(bool)
        } else if value.isNull {
            return .string("")
        } else {
            throw MCPError.invalidParams(
                "Unsupported template parameter value type. Supported: string, number, boolean.")
        }
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
