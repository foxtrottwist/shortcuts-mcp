// SPDX-License-Identifier: MIT
// TextPipelineTemplate.swift - Template for text processing pipelines

import Foundation

/// Template for creating text processing pipelines.
///
/// This template generates a shortcut that takes input text, applies a series
/// of transformations (replace, change case, split, etc.), and optionally
/// displays the result.
///
/// ## Example Usage
///
/// ```swift
/// let engine = TemplateEngine()
/// engine.register(TextPipelineTemplate.self)
///
/// let operations = """
/// [
///   {"type": "uppercase"},
///   {"type": "replace", "find": " ", "replace": "_"}
/// ]
/// """
///
/// let actions = try engine.generate(
///     templateName: "text-pipeline",
///     parameters: [
///         "inputText": .string("Hello World"),
///         "operations": .string(operations),
///         "showResult": .boolean(true)
///     ]
/// )
/// ```
///
/// ## Supported Operations
///
/// - `uppercase` - Convert to uppercase
/// - `lowercase` - Convert to lowercase
/// - `capitalize` - Capitalize every word
/// - `titlecase` - Title case
/// - `replace` - Replace text (requires `find` and `replace` fields)
/// - `split` - Split text (optional `separator` field, default: newLines)
/// - `combine` - Combine list (optional `separator` field, default: newLines)
public struct TextPipelineTemplate: Template {
    // MARK: - Template Metadata

    public static let name = "text-pipeline"
    public static let displayName = "Text Processing Pipeline"
    public static let description = "Creates a shortcut that processes text through a series of transformations"

    public static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "inputText",
            label: "Input Text",
            type: .string,
            required: true,
            description: "The text to process"
        ),
        TemplateParameter(
            name: "operations",
            label: "Operations",
            type: .string,
            required: true,
            description: "JSON array of operations (e.g., [{\"type\": \"uppercase\"}, {\"type\": \"replace\", \"find\": \"x\", \"replace\": \"y\"}])"
        ),
        TemplateParameter(
            name: "showResult",
            label: "Show Result",
            type: .boolean,
            required: false,
            defaultValue: .boolean(true),
            description: "Whether to display the result"
        ),
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Generation

    public func generate(with parameters: [String: TemplateParameterValue]) throws
        -> [any ShortcutAction]
    {
        guard let inputText = parameters["inputText"]?.stringValue else {
            throw TemplateError.missingRequiredParameter(name: "inputText")
        }

        guard let operationsJSON = parameters["operations"]?.stringValue else {
            throw TemplateError.missingRequiredParameter(name: "operations")
        }

        let showResult = parameters["showResult"]?.boolValue ?? true

        // Parse operations JSON
        let operations = try parseOperations(from: operationsJSON)

        if operations.isEmpty {
            throw TemplateError.generationFailed(reason: "At least one operation is required")
        }

        var actions: [any ShortcutAction] = []

        // Create initial text action with UUID for referencing
        let textUUID = UUID().uuidString
        actions.append(TextAction(inputText, uuid: textUUID, customOutputName: "Input Text"))

        // Track the UUID of the last action's output for chaining
        var lastOutputUUID = textUUID
        var lastOutputName = "Text"

        // Generate transformation actions
        for (index, operation) in operations.enumerated() {
            let actionUUID = UUID().uuidString
            let outputName = "Step \(index + 1)"

            let action = try createAction(
                for: operation,
                uuid: actionUUID,
                customOutputName: outputName
            )

            actions.append(action)
            lastOutputUUID = actionUUID
            lastOutputName = outputName
        }

        // Optionally show the result
        if showResult {
            actions.append(
                ShowResultAction(
                    fromActionWithUUID: lastOutputUUID,
                    outputName: lastOutputName
                )
            )
        }

        return actions
    }

    // MARK: - Private Helpers

    /// Parses operation definitions from JSON string.
    private func parseOperations(from json: String) throws -> [OperationDefinition] {
        guard let data = json.data(using: .utf8) else {
            throw TemplateError.generationFailed(reason: "Invalid operations JSON encoding")
        }

        do {
            let operations = try JSONDecoder().decode([OperationDefinition].self, from: data)
            return operations
        } catch {
            throw TemplateError.generationFailed(
                reason: "Failed to parse operations JSON: \(error.localizedDescription)"
            )
        }
    }

    /// Creates an action for the given operation definition.
    private func createAction(
        for operation: OperationDefinition,
        uuid: String,
        customOutputName: String
    ) throws -> any ShortcutAction {
        switch operation.type {
        case "uppercase":
            return ChangeCaseAction(textCase: .uppercase, uuid: uuid, customOutputName: customOutputName)

        case "lowercase":
            return ChangeCaseAction(textCase: .lowercase, uuid: uuid, customOutputName: customOutputName)

        case "capitalize":
            return ChangeCaseAction(textCase: .capitalizeEveryWord, uuid: uuid, customOutputName: customOutputName)

        case "titlecase":
            return ChangeCaseAction(textCase: .titleCase, uuid: uuid, customOutputName: customOutputName)

        case "sentencecase":
            return ChangeCaseAction(textCase: .sentenceCase, uuid: uuid, customOutputName: customOutputName)

        case "alternatingcase":
            return ChangeCaseAction(textCase: .alternatingCase, uuid: uuid, customOutputName: customOutputName)

        case "replace":
            guard let find = operation.find else {
                throw TemplateError.generationFailed(
                    reason: "Replace operation requires 'find' field"
                )
            }
            let replaceWith = operation.replace ?? ""
            let caseSensitive = operation.caseSensitive ?? true
            let regex = operation.regex ?? false

            return ReplaceTextAction(
                find: find,
                replaceWith: replaceWith,
                caseSensitive: caseSensitive,
                regularExpression: regex,
                uuid: uuid,
                customOutputName: customOutputName
            )

        case "split":
            let separator = parseSeparator(operation.separator)
            return SplitTextAction(separator: separator, uuid: uuid, customOutputName: customOutputName)

        case "combine":
            let separator = parseSeparator(operation.separator)
            return CombineTextAction(separator: separator, uuid: uuid, customOutputName: customOutputName)

        default:
            throw TemplateError.generationFailed(
                reason: "Unknown operation type: '\(operation.type)'"
            )
        }
    }

    /// Parses a separator string into a TextSeparator enum value.
    private func parseSeparator(_ separator: String?) -> TextSeparator {
        guard let separator = separator else {
            return .newLines
        }

        switch separator.lowercased() {
        case "newlines", "newline", "lines":
            return .newLines
        case "spaces", "space":
            return .spaces
        case "everycharacter", "character", "characters":
            return .everyCharacter
        default:
            // Treat as custom separator
            return .custom(separator)
        }
    }
}

// MARK: - Operation Definition

/// Definition of a text transformation operation.
private struct OperationDefinition: Decodable {
    /// The operation type (e.g., "uppercase", "replace", "split")
    let type: String

    /// For replace: the text to find
    let find: String?

    /// For replace: the replacement text
    let replace: String?

    /// For replace: whether to match case-sensitively
    let caseSensitive: Bool?

    /// For replace: whether to use regex matching
    let regex: Bool?

    /// For split/combine: the separator type
    let separator: String?

    enum CodingKeys: String, CodingKey {
        case type
        case find
        case replace
        case caseSensitive
        case regex
        case separator
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        find = try container.decodeIfPresent(String.self, forKey: .find)
        replace = try container.decodeIfPresent(String.self, forKey: .replace)
        caseSensitive = try container.decodeIfPresent(Bool.self, forKey: .caseSensitive)
        regex = try container.decodeIfPresent(Bool.self, forKey: .regex)
        separator = try container.decodeIfPresent(String.self, forKey: .separator)
    }
}
