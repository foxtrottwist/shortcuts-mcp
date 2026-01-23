// SPDX-License-Identifier: MIT
// TextActions.swift - Text manipulation actions for Shortcuts

import Foundation

// MARK: - Replace Text Action

/// Represents a "Replace Text" action in Shortcuts.
/// Replaces occurrences of a string with another string.
///
/// Identifier: `is.workflow.actions.text.replace`
public struct ReplaceTextAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.text.replace"

    /// The text to find
    public var findText: TextTokenValue

    /// The replacement text
    public var replaceWith: TextTokenValue

    /// Whether the search is case sensitive (default: true)
    public var caseSensitive: Bool

    /// Whether to treat findText as a regular expression (default: false)
    public var regularExpression: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a replace text action.
    /// - Parameters:
    ///   - find: The text to find
    ///   - replaceWith: The replacement text
    ///   - caseSensitive: Whether the search is case sensitive (default: true)
    ///   - regularExpression: Whether find is a regex pattern (default: false)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        find: String,
        replaceWith: String,
        caseSensitive: Bool = true,
        regularExpression: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.findText = .string(find)
        self.replaceWith = .string(replaceWith)
        self.caseSensitive = caseSensitive
        self.regularExpression = regularExpression
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a replace text action with token values.
    /// - Parameters:
    ///   - find: The text to find (token value)
    ///   - replaceWith: The replacement text (token value)
    ///   - caseSensitive: Whether the search is case sensitive (default: true)
    ///   - regularExpression: Whether find is a regex pattern (default: false)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        find: TextTokenValue,
        replaceWith: TextTokenValue,
        caseSensitive: Bool = true,
        regularExpression: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.findText = find
        self.replaceWith = replaceWith
        self.caseSensitive = caseSensitive
        self.regularExpression = regularExpression
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Find text
        switch findText {
        case .string(let str):
            parameters["WFReplaceTextFind"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFReplaceTextFind"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFReplaceTextFind"] = attachment.toParameterValue()
        }

        // Replace with text
        switch replaceWith {
        case .string(let str):
            parameters["WFReplaceTextReplace"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFReplaceTextReplace"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFReplaceTextReplace"] = attachment.toParameterValue()
        }

        // Case sensitivity (default is true, so only set when false)
        if !caseSensitive {
            parameters["WFReplaceTextCaseSensitive"] = .bool(false)
        }

        // Regular expression (default is false, so only set when true)
        if regularExpression {
            parameters["WFReplaceTextRegularExpression"] = .bool(true)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Split Text Action

/// Separator types for Split Text and Combine Text actions.
public enum TextSeparator: Sendable, Equatable {
    /// Split/join on newline characters
    case newLines

    /// Split/join on space characters
    case spaces

    /// Split on every character (for split only)
    case everyCharacter

    /// Use a custom separator string
    case custom(String)

    /// The raw value for the WFTextSeparator parameter
    var rawValue: String {
        switch self {
        case .newLines: return "New Lines"
        case .spaces: return "Spaces"
        case .everyCharacter: return "Every Character"
        case .custom: return "Custom"
        }
    }
}

/// Represents a "Split Text" action in Shortcuts.
/// Splits text into a list using a separator.
///
/// Identifier: `is.workflow.actions.text.split`
public struct SplitTextAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.text.split"

    /// The separator to split on
    public var separator: TextSeparator

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a split text action.
    /// - Parameters:
    ///   - separator: The separator to split on (default: newLines)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        separator: TextSeparator = .newLines,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.separator = separator
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a split text action with a custom separator.
    /// - Parameters:
    ///   - customSeparator: The custom separator string
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        customSeparator: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.separator = .custom(customSeparator)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFTextSeparator": .string(separator.rawValue)
        ]

        if case .custom(let customSeparator) = separator {
            parameters["WFTextCustomSeparator"] = .string(customSeparator)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Combine Text Action

/// Represents a "Combine Text" action in Shortcuts.
/// Combines a list of text items into a single string using a separator.
///
/// Identifier: `is.workflow.actions.text.combine`
public struct CombineTextAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.text.combine"

    /// The separator to join with
    public var separator: TextSeparator

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a combine text action.
    /// - Parameters:
    ///   - separator: The separator to join with (default: newLines)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        separator: TextSeparator = .newLines,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.separator = separator
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a combine text action with a custom separator.
    /// - Parameters:
    ///   - customSeparator: The custom separator string
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        customSeparator: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.separator = .custom(customSeparator)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFTextSeparator": .string(separator.rawValue)
        ]

        // Combine text doesn't support "Every Character" separator
        if case .custom(let customSeparator) = separator {
            parameters["WFTextCustomSeparator"] = .string(customSeparator)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Match Text Action

/// Represents a "Match Text" action in Shortcuts.
/// Searches text using a regular expression and returns matches.
///
/// Identifier: `is.workflow.actions.text.match`
public struct MatchTextAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.text.match"

    /// The regular expression pattern
    public var pattern: TextTokenValue

    /// Whether the match is case sensitive (default: true)
    public var caseSensitive: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a match text action.
    /// - Parameters:
    ///   - pattern: The regex pattern to match
    ///   - caseSensitive: Whether the match is case sensitive (default: true)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        pattern: String,
        caseSensitive: Bool = true,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.pattern = .string(pattern)
        self.caseSensitive = caseSensitive
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a match text action with a token value pattern.
    /// - Parameters:
    ///   - pattern: The regex pattern to match (token value)
    ///   - caseSensitive: Whether the match is case sensitive (default: true)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        pattern: TextTokenValue,
        caseSensitive: Bool = true,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.pattern = pattern
        self.caseSensitive = caseSensitive
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Pattern
        switch pattern {
        case .string(let str):
            parameters["WFMatchTextPattern"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFMatchTextPattern"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFMatchTextPattern"] = attachment.toParameterValue()
        }

        // Case sensitivity (default is true, so only set when false)
        if !caseSensitive {
            parameters["WFMatchTextCaseSensitive"] = .bool(false)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Change Case Action

/// Case options for the Change Case action.
public enum TextCase: String, Sendable {
    /// ALL UPPERCASE
    case uppercase = "UPPERCASE"

    /// all lowercase
    case lowercase = "lowercase"

    /// Capitalize Every Word
    case capitalizeEveryWord = "Capitalize Every Word"

    /// Capitalize with Title Case
    case titleCase = "Capitalize with Title Case"

    /// Capitalize with sentence case
    case sentenceCase = "Capitalize with sentence case"

    /// cApItAlIzE wItH aLtErNaTiNg CaSe
    case alternatingCase = "cApItAlIzE wItH aLtErNaTiNg CaSe"
}

/// Represents a "Change Case" action in Shortcuts.
/// Changes the case of the input text.
///
/// Identifier: `is.workflow.actions.text.changecase`
public struct ChangeCaseAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.text.changecase"

    /// The case to change to
    public var textCase: TextCase

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a change case action.
    /// - Parameters:
    ///   - textCase: The case to change to (default: uppercase)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        textCase: TextCase = .uppercase,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.textCase = textCase
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        let parameters: [String: ActionParameterValue] = [
            "WFCaseType": .string(textCase.rawValue)
        ]

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}
