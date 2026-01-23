// SPDX-License-Identifier: MIT
// WorkflowAction.swift - Workflow action model for Shortcut plist

import Foundation

/// Represents a single action in a Shortcut workflow.
public struct WorkflowAction: Codable, Sendable {
    /// Action identifier in reverse domain notation (e.g., "is.workflow.actions.showresult")
    public var identifier: String

    /// Action-specific parameters
    public var parameters: [String: ActionParameterValue]

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name
    public var customOutputName: String?

    /// Optional grouping identifier (for grouped actions like if/else)
    public var groupingIdentifier: String?

    private enum CodingKeys: String, CodingKey {
        case identifier = "WFWorkflowActionIdentifier"
        case parameters = "WFWorkflowActionParameters"
        case uuid = "UUID"
        case customOutputName = "CustomOutputName"
        case groupingIdentifier = "GroupingIdentifier"
    }

    /// Creates a workflow action.
    /// - Parameters:
    ///   - identifier: Action identifier (e.g., "is.workflow.actions.showresult")
    ///   - parameters: Action parameters (defaults to empty)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional custom output name
    ///   - groupingIdentifier: Optional grouping identifier
    public init(
        identifier: String,
        parameters: [String: ActionParameterValue] = [:],
        uuid: String? = nil,
        customOutputName: String? = nil,
        groupingIdentifier: String? = nil
    ) {
        self.identifier = identifier
        self.parameters = parameters
        self.uuid = uuid
        self.customOutputName = customOutputName
        self.groupingIdentifier = groupingIdentifier
    }
}

// MARK: - Action Parameter Value

/// A value that can be used as an action parameter.
/// Supports strings, numbers, booleans, arrays, dictionaries, and special variable references.
public enum ActionParameterValue: Codable, Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case data(Data)
    case array([ActionParameterValue])
    case dictionary([String: ActionParameterValue])

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let dataValue = try? container.decode(Data.self) {
            self = .data(dataValue)
        } else if let arrayValue = try? container.decode([ActionParameterValue].self) {
            self = .array(arrayValue)
        } else if let dictValue = try? container.decode([String: ActionParameterValue].self) {
            self = .dictionary(dictValue)
        } else {
            throw DecodingError.typeMismatch(
                ActionParameterValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode ActionParameterValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .data(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .dictionary(value):
            try container.encode(value)
        }
    }
}

// MARK: - ExpressibleBy Conformances

extension ActionParameterValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension ActionParameterValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension ActionParameterValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension ActionParameterValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension ActionParameterValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ActionParameterValue...) {
        self = .array(elements)
    }
}

extension ActionParameterValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, ActionParameterValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - Common Action Identifiers

/// Common built-in Shortcuts action identifiers.
public enum ActionIdentifier {
    /// Base prefix for Shortcuts actions
    public static let prefix = "is.workflow.actions."

    // MARK: - Result & Output

    /// Show result in notification
    public static let showResult = "\(prefix)showresult"

    /// Stop and output result
    public static let output = "\(prefix)output"

    /// Exit the shortcut
    public static let exit = "\(prefix)exit"

    /// Return to home screen
    public static let returnToHomeScreen = "\(prefix)returntohomescreen"

    // MARK: - Variables

    /// Set a variable
    public static let setVariable = "\(prefix)setvariable"

    /// Get a variable
    public static let getVariable = "\(prefix)getvariable"

    /// Add to variable (append)
    public static let addToVariable = "\(prefix)appendvariable"

    // MARK: - Text & Data

    /// Create text
    public static let text = "\(prefix)gettext"

    /// Get clipboard
    public static let getClipboard = "\(prefix)getclipboard"

    /// Set clipboard
    public static let setClipboard = "\(prefix)setclipboard"

    /// Get dictionary value
    public static let getDictionaryValue = "\(prefix)getvalueforkey"

    /// Create dictionary
    public static let dictionary = "\(prefix)dictionary"

    // MARK: - Scripting

    /// Run AppleScript (macOS only)
    public static let runAppleScript = "\(prefix)runapplescript"

    /// Run Shell Script (macOS only)
    public static let runShellScript = "\(prefix)runshellscript"

    /// Run JavaScript on Web Page
    public static let runJavaScript = "\(prefix)runjavascriptonwebpage"

    // MARK: - Control Flow

    /// If condition
    public static let ifAction = "\(prefix)conditional"

    /// Otherwise (else)
    public static let otherwise = "\(prefix)choosefrommenu"

    /// End if
    public static let endIf = "\(prefix)conditional"

    /// Repeat (loop)
    public static let repeatAction = "\(prefix)repeat.count"

    /// Repeat with each
    public static let repeatWithEach = "\(prefix)repeat.each"

    /// End repeat
    public static let endRepeat = "\(prefix)repeat.count"

    // MARK: - Web & Network

    /// Get contents of URL (HTTP request)
    public static let getContentsOfURL = "\(prefix)downloadurl"

    /// Get URL
    public static let url = "\(prefix)url"

    /// Open URL
    public static let openURL = "\(prefix)openurl"

    // MARK: - Files

    /// Get file
    public static let getFile = "\(prefix)documentpicker.open"

    /// Save file
    public static let saveFile = "\(prefix)documentpicker.save"

    /// Get file from folder
    public static let getFileFromFolder = "\(prefix)file.getfoldercontents"

    // MARK: - Notifications

    /// Show notification
    public static let showNotification = "\(prefix)notification"

    /// Ask for input
    public static let askForInput = "\(prefix)ask"

    /// Choose from menu
    public static let chooseFromMenu = "\(prefix)choosefrommenu"

    /// Show alert
    public static let showAlert = "\(prefix)alert"

    // MARK: - Apps

    /// Open app
    public static let openApp = "\(prefix)openapp"

    /// Run shortcut
    public static let runShortcut = "\(prefix)runworkflow"
}

// MARK: - Convenience Factory Methods

extension WorkflowAction {
    /// Creates a "Show Result" action.
    /// - Parameter text: The text to display
    /// - Returns: A configured WorkflowAction
    public static func showResult(_ text: String) -> WorkflowAction {
        WorkflowAction(
            identifier: ActionIdentifier.showResult,
            parameters: ["Text": .string(text)]
        )
    }

    /// Creates a "Text" action.
    /// - Parameter text: The text content
    /// - Returns: A configured WorkflowAction
    public static func text(_ text: String) -> WorkflowAction {
        WorkflowAction(
            identifier: ActionIdentifier.text,
            parameters: ["WFTextActionText": .string(text)]
        )
    }

    /// Creates a "Get Contents of URL" action.
    /// - Parameter url: The URL to fetch
    /// - Returns: A configured WorkflowAction
    public static func getContentsOfURL(_ url: String) -> WorkflowAction {
        WorkflowAction(
            identifier: ActionIdentifier.getContentsOfURL,
            parameters: ["WFURL": .string(url)]
        )
    }

    /// Creates a "Show Notification" action.
    /// - Parameters:
    ///   - body: Notification body text
    ///   - title: Optional notification title
    /// - Returns: A configured WorkflowAction
    public static func showNotification(body: String, title: String? = nil) -> WorkflowAction {
        var params: [String: ActionParameterValue] = ["WFNotificationActionBody": .string(body)]
        if let title {
            params["WFNotificationActionTitle"] = .string(title)
        }
        return WorkflowAction(
            identifier: ActionIdentifier.showNotification,
            parameters: params
        )
    }

    /// Creates an "Open URL" action.
    /// - Parameter url: The URL to open
    /// - Returns: A configured WorkflowAction
    public static func openURL(_ url: String) -> WorkflowAction {
        WorkflowAction(
            identifier: ActionIdentifier.openURL,
            parameters: ["WFInput": .string(url)]
        )
    }

    /// Creates a "Run Shell Script" action (macOS only).
    /// - Parameters:
    ///   - script: The shell script to execute
    ///   - shell: Shell type (defaults to "/bin/zsh")
    /// - Returns: A configured WorkflowAction
    public static func runShellScript(_ script: String, shell: String = "/bin/zsh") -> WorkflowAction
    {
        WorkflowAction(
            identifier: ActionIdentifier.runShellScript,
            parameters: [
                "WFShellScript": .string(script),
                "WFShellPath": .string(shell),
            ]
        )
    }

    /// Creates a "Run AppleScript" action (macOS only).
    /// - Parameter script: The AppleScript to execute
    /// - Returns: A configured WorkflowAction
    public static func runAppleScript(_ script: String) -> WorkflowAction {
        WorkflowAction(
            identifier: ActionIdentifier.runAppleScript,
            parameters: ["WFAppleScript": .string(script)]
        )
    }
}
