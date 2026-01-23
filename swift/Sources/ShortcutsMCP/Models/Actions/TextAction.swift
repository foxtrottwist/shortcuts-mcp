// SPDX-License-Identifier: MIT
// TextAction.swift - Text action for creating text values in Shortcuts

import Foundation

/// Represents a "Text" action in Shortcuts.
/// This action creates a text value that can be used by subsequent actions.
///
/// Identifier: `is.workflow.actions.gettext`
public struct TextAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.gettext"

    /// The text content (can include magic variable placeholders)
    public var text: TextTokenValue

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a text action with a plain string.
    /// - Parameters:
    ///   - text: The text content
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(_ text: String, uuid: String? = nil, customOutputName: String? = nil) {
        self.text = .string(text)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a text action with a token value (supports magic variables).
    /// - Parameters:
    ///   - text: The text token value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(_ text: TextTokenValue, uuid: String? = nil, customOutputName: String? = nil) {
        self.text = text
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        switch text {
        case .string(let str):
            parameters["WFTextActionText"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFTextActionText"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFTextActionText"] = attachment.toParameterValue()
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Text Token Value

/// A text value that can be a plain string, a string with inline variables,
/// or a reference to another action's output (magic variable).
public enum TextTokenValue: Sendable, Equatable {
    /// A plain string value
    case string(String)

    /// A string with inline variable attachments
    case tokenString(TextTokenString)

    /// A reference to another action's output (magic variable)
    case attachment(TextTokenAttachment)
}

// MARK: - Text Token String

/// A string value that can contain inline variable references.
/// Uses the Object Replacement Character (U+FFFC) as placeholders for variables.
public struct TextTokenString: Sendable, Equatable {
    /// The string content with U+FFFC placeholders for variables
    public var string: String

    /// Attachments mapped by their position and length in the string
    /// Key format: "{position, length}" (e.g., "{5, 1}")
    public var attachmentsByRange: [String: TextTokenAttachment]

    /// Creates a text token string.
    /// - Parameters:
    ///   - string: The string with U+FFFC placeholders
    ///   - attachmentsByRange: Attachments keyed by position
    public init(string: String, attachmentsByRange: [String: TextTokenAttachment]) {
        self.string = string
        self.attachmentsByRange = attachmentsByRange
    }

    /// Creates a text token string with a single magic variable reference.
    /// - Parameter attachment: The magic variable attachment
    public init(attachment: TextTokenAttachment) {
        // Single attachment at position 0
        self.string = "\u{FFFC}"
        self.attachmentsByRange = ["{0, 1}": attachment]
    }

    /// Converts to an ActionParameterValue for encoding.
    public func toParameterValue() -> ActionParameterValue {
        var attachmentsDict: [String: ActionParameterValue] = [:]
        for (range, attachment) in attachmentsByRange {
            attachmentsDict[range] = attachment.toDictionaryValue()
        }

        return .dictionary([
            "Value": .dictionary([
                "string": .string(string),
                "attachmentsByRange": .dictionary(attachmentsDict),
            ]),
            "WFSerializationType": .string("WFTextTokenString"),
        ])
    }
}

// MARK: - Text Token Attachment

/// A reference to a variable or action output.
public struct TextTokenAttachment: Sendable, Equatable {
    /// The type of attachment
    public var type: AttachmentType

    /// UUID of the source action (for ActionOutput type)
    public var outputUUID: String?

    /// Name of the output (for ActionOutput type)
    public var outputName: String?

    /// Name of the variable (for Variable type)
    public var variableName: String?

    /// Variable modifications (e.g., get property, coerce type)
    public var aggrandizements: [Aggrandizement]?

    /// Creates a text token attachment.
    public init(
        type: AttachmentType,
        outputUUID: String? = nil,
        outputName: String? = nil,
        variableName: String? = nil,
        aggrandizements: [Aggrandizement]? = nil
    ) {
        self.type = type
        self.outputUUID = outputUUID
        self.outputName = outputName
        self.variableName = variableName
        self.aggrandizements = aggrandizements
    }

    /// Creates a magic variable reference to another action's output.
    /// - Parameters:
    ///   - uuid: UUID of the source action
    ///   - outputName: Name of the output (defaults to "Text")
    public static func actionOutput(uuid: String, outputName: String = "Text")
        -> TextTokenAttachment
    {
        TextTokenAttachment(type: .actionOutput, outputUUID: uuid, outputName: outputName)
    }

    /// Creates a reference to the shortcut input.
    public static func shortcutInput() -> TextTokenAttachment {
        TextTokenAttachment(type: .extensionInput)
    }

    /// Creates a reference to a named variable.
    /// - Parameter name: The variable name
    public static func variable(named name: String) -> TextTokenAttachment {
        TextTokenAttachment(type: .variable, variableName: name)
    }

    /// Converts to an ActionParameterValue for encoding as a standalone value.
    public func toParameterValue() -> ActionParameterValue {
        .dictionary([
            "Value": toDictionaryValue(),
            "WFSerializationType": .string("WFTextTokenAttachment"),
        ])
    }

    /// Converts to a dictionary value (for use within attachmentsByRange).
    func toDictionaryValue() -> ActionParameterValue {
        var dict: [String: ActionParameterValue] = [
            "Type": .string(type.rawValue)
        ]

        if let outputUUID {
            dict["OutputUUID"] = .string(outputUUID)
        }
        if let outputName {
            dict["OutputName"] = .string(outputName)
        }
        if let variableName {
            dict["VariableName"] = .string(variableName)
        }
        if let aggrandizements, !aggrandizements.isEmpty {
            dict["Aggrandizements"] = .array(aggrandizements.map { $0.toDictionaryValue() })
        }

        return .dictionary(dict)
    }
}

// MARK: - Attachment Type

/// Types of variable attachments in Shortcuts.
public enum AttachmentType: String, Sendable {
    /// Reference to another action's output (magic variable)
    case actionOutput = "ActionOutput"

    /// Reference to the shortcut's input
    case extensionInput = "ExtensionInput"

    /// Reference to a named variable
    case variable = "Variable"

    /// Reference to the clipboard
    case clipboard = "Clipboard"

    /// Reference to current date
    case currentDate = "CurrentDate"

    /// Reference to asking when run
    case ask = "Ask"
}

// MARK: - Aggrandizement

/// A modification applied to a variable (e.g., get property, coerce type).
public struct Aggrandizement: Sendable, Equatable {
    /// The type of aggrandizement
    public var type: AggrandizementType

    /// Property name (for getProperty type)
    public var propertyName: String?

    /// Coercion class (for coercion type)
    public var coercionClass: String?

    /// Creates an aggrandizement.
    public init(
        type: AggrandizementType, propertyName: String? = nil, coercionClass: String? = nil
    ) {
        self.type = type
        self.propertyName = propertyName
        self.coercionClass = coercionClass
    }

    /// Creates a property getter aggrandizement.
    public static func getProperty(_ name: String) -> Aggrandizement {
        Aggrandizement(type: .property, propertyName: name)
    }

    /// Creates a type coercion aggrandizement.
    public static func coerce(to classType: String) -> Aggrandizement {
        Aggrandizement(type: .coercion, coercionClass: classType)
    }

    func toDictionaryValue() -> ActionParameterValue {
        var dict: [String: ActionParameterValue] = [
            "Type": .string(type.rawValue)
        ]

        if let propertyName {
            dict["PropertyName"] = .string(propertyName)
        }
        if let coercionClass {
            dict["CoercionItemClass"] = .string(coercionClass)
        }

        return .dictionary(dict)
    }
}

/// Types of variable modifications.
public enum AggrandizementType: String, Sendable {
    /// Get a property of the variable
    case property = "WFPropertyVariableAggrandizement"

    /// Coerce the variable to a different type
    case coercion = "WFCoercionVariableAggrandizement"
}

// MARK: - Shortcut Action Protocol

/// Protocol for types that can be converted to WorkflowAction.
public protocol ShortcutAction: Sendable {
    /// The action identifier
    static var identifier: String { get }

    /// Converts this action to a generic WorkflowAction.
    func toWorkflowAction() -> WorkflowAction
}
