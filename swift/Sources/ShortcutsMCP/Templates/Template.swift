// SPDX-License-Identifier: MIT
// Template.swift - Protocol and types for shortcut templates

import Foundation

// MARK: - Template Protocol

/// Protocol for shortcut templates that generate action sequences from parameters.
///
/// Templates define reusable patterns for creating shortcuts. Each template:
/// - Has a unique identifier and display metadata
/// - Declares required and optional parameters
/// - Generates a sequence of actions when instantiated with parameters
///
/// ## Example Implementation
///
/// ```swift
/// struct HelloWorldTemplate: Template {
///     static let name = "hello-world"
///     static let displayName = "Hello World"
///     static let description = "Creates a simple shortcut that displays a greeting"
///     static let parameters: [TemplateParameter] = [
///         TemplateParameter(
///             name: "greeting",
///             label: "Greeting Text",
///             type: .string,
///             required: false,
///             defaultValue: .string("Hello, World!")
///         )
///     ]
///
///     func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction] {
///         let greeting = parameters["greeting"]?.stringValue ?? "Hello, World!"
///         let textUUID = UUID().uuidString
///         return [
///             TextAction(greeting, uuid: textUUID),
///             ShowResultAction(fromActionWithUUID: textUUID, outputName: "Text")
///         ]
///     }
/// }
/// ```
public protocol Template: Sendable {
    /// Unique identifier for the template (e.g., "hello-world", "api-fetch")
    static var name: String { get }

    /// Human-readable display name (e.g., "Hello World", "API Fetch")
    static var displayName: String { get }

    /// Description of what the template creates
    static var description: String { get }

    /// Parameters required or accepted by the template
    static var parameters: [TemplateParameter] { get }

    /// Required initializer for template instantiation.
    init()

    /// Generates actions from the given parameters.
    /// - Parameter parameters: Dictionary of parameter name to value
    /// - Returns: Array of shortcut actions
    /// - Throws: `TemplateError` if required parameters are missing or invalid
    func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction]
}

// MARK: - Template Parameter

/// Definition of a parameter accepted by a template.
public struct TemplateParameter: Sendable, Equatable, Codable {
    /// Parameter identifier (e.g., "url", "greeting")
    public let name: String

    /// Human-readable label (e.g., "URL to Fetch", "Greeting Text")
    public let label: String

    /// The type of value expected
    public let type: TemplateParameterType

    /// Whether this parameter must be provided
    public let required: Bool

    /// Default value if parameter is not provided
    public let defaultValue: TemplateParameterValue?

    /// Available options for choice type parameters
    public let options: [String]?

    /// Description of the parameter
    public let parameterDescription: String?

    /// Creates a template parameter definition.
    /// - Parameters:
    ///   - name: Parameter identifier
    ///   - label: Human-readable label
    ///   - type: Expected value type
    ///   - required: Whether the parameter is required (defaults to true)
    ///   - defaultValue: Default value if not provided
    ///   - options: Options for choice type
    ///   - description: Parameter description
    public init(
        name: String,
        label: String,
        type: TemplateParameterType,
        required: Bool = true,
        defaultValue: TemplateParameterValue? = nil,
        options: [String]? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.label = label
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.options = options
        self.parameterDescription = description
    }

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case type
        case required
        case defaultValue = "default_value"
        case options
        case parameterDescription = "description"
    }
}

// MARK: - Parameter Types

/// Types of values a template parameter can accept.
public enum TemplateParameterType: String, Sendable, Codable, CaseIterable {
    /// Plain text string
    case string

    /// URL string
    case url

    /// Integer or decimal number
    case number

    /// True/false value
    case boolean

    /// Selection from predefined options
    case choice
}

// MARK: - Parameter Values

/// Value for a template parameter.
public enum TemplateParameterValue: Sendable, Equatable {
    case string(String)
    case url(String)
    case number(Double)
    case boolean(Bool)
    case choice(String)

    /// Gets the value as a string, if applicable.
    public var stringValue: String? {
        switch self {
        case .string(let s), .url(let s), .choice(let s):
            return s
        case .number(let n):
            return String(n)
        case .boolean(let b):
            return String(b)
        }
    }

    /// Gets the value as a URL string, if applicable.
    public var urlValue: String? {
        switch self {
        case .url(let s), .string(let s):
            return s
        default:
            return nil
        }
    }

    /// Gets the value as a number, if applicable.
    public var numberValue: Double? {
        switch self {
        case .number(let n):
            return n
        case .string(let s):
            return Double(s)
        default:
            return nil
        }
    }

    /// Gets the value as an integer, if applicable.
    public var intValue: Int? {
        numberValue.map { Int($0) }
    }

    /// Gets the value as a boolean.
    public var boolValue: Bool {
        switch self {
        case .boolean(let b):
            return b
        case .string(let s):
            return ["true", "yes", "1"].contains(s.lowercased())
        case .number(let n):
            return n != 0
        default:
            return false
        }
    }

    /// Gets the value as a choice string, if applicable.
    public var choiceValue: String? {
        switch self {
        case .choice(let s), .string(let s):
            return s
        default:
            return nil
        }
    }
}

// MARK: - Codable Support for TemplateParameterValue

extension TemplateParameterValue: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "url":
            let value = try container.decode(String.self, forKey: .value)
            self = .url(value)
        case "number":
            let value = try container.decode(Double.self, forKey: .value)
            self = .number(value)
        case "boolean":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .boolean(value)
        case "choice":
            let value = try container.decode(String.self, forKey: .value)
            self = .choice(value)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown parameter value type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .url(let value):
            try container.encode("url", forKey: .type)
            try container.encode(value, forKey: .value)
        case .number(let value):
            try container.encode("number", forKey: .type)
            try container.encode(value, forKey: .value)
        case .boolean(let value):
            try container.encode("boolean", forKey: .type)
            try container.encode(value, forKey: .value)
        case .choice(let value):
            try container.encode("choice", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Template Errors

/// Errors that can occur during template operations.
public enum TemplateError: Error, LocalizedError, Equatable {
    /// A required parameter was not provided
    case missingRequiredParameter(name: String)

    /// A parameter value is invalid for its type
    case invalidParameterType(name: String, expected: TemplateParameterType, got: String)

    /// A choice parameter value is not in the allowed options
    case invalidChoiceValue(name: String, value: String, options: [String])

    /// The template was not found
    case templateNotFound(name: String)

    /// Generation failed for an unexpected reason
    case generationFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredParameter(let name):
            return "Missing required parameter: '\(name)'"
        case .invalidParameterType(let name, let expected, let got):
            return "Parameter '\(name)' expects \(expected.rawValue) but got \(got)"
        case .invalidChoiceValue(let name, let value, let options):
            return "Parameter '\(name)' value '\(value)' is not in allowed options: \(options.joined(separator: ", "))"
        case .templateNotFound(let name):
            return "Template not found: '\(name)'"
        case .generationFailed(let reason):
            return "Template generation failed: \(reason)"
        }
    }
}

// MARK: - Template Info (for catalog)

/// Information about a template for the catalog.
public struct TemplateInfo: Sendable, Codable, Equatable {
    /// Unique template identifier
    public let name: String

    /// Human-readable display name
    public let displayName: String

    /// Description of the template
    public let description: String

    /// Parameter definitions
    public let parameters: [TemplateParameter]

    /// Creates template info.
    public init(
        name: String,
        displayName: String,
        description: String,
        parameters: [TemplateParameter]
    ) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.parameters = parameters
    }

    /// Creates template info from a Template type.
    public init<T: Template>(from templateType: T.Type) {
        self.name = templateType.name
        self.displayName = templateType.displayName
        self.description = templateType.description
        self.parameters = templateType.parameters
    }

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case description
        case parameters
    }
}
