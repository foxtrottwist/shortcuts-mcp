// SPDX-License-Identifier: MIT
// ShowResultAction.swift - Show Result action for displaying output in Shortcuts

import Foundation

/// Represents a "Show Result" action in Shortcuts.
/// This action displays a value to the user.
///
/// Identifier: `is.workflow.actions.showresult`
public struct ShowResultAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.showresult"

    /// The text to display (can include magic variable references)
    public var text: TextTokenValue

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Creates a show result action with a plain string.
    /// - Parameters:
    ///   - text: The text to display
    ///   - uuid: Optional UUID for this action
    public init(_ text: String, uuid: String? = nil) {
        self.text = .string(text)
        self.uuid = uuid
    }

    /// Creates a show result action with a token value (supports magic variables).
    /// - Parameters:
    ///   - text: The text token value
    ///   - uuid: Optional UUID for this action
    public init(_ text: TextTokenValue, uuid: String? = nil) {
        self.text = text
        self.uuid = uuid
    }

    /// Creates a show result action that displays the output from another action.
    /// - Parameters:
    ///   - sourceUUID: UUID of the action whose output to display
    ///   - outputName: Name of the output (defaults to "Text")
    ///   - uuid: Optional UUID for this action
    public init(
        fromActionWithUUID sourceUUID: String, outputName: String = "Text", uuid: String? = nil
    ) {
        self.text = .attachment(.actionOutput(uuid: sourceUUID, outputName: outputName))
        self.uuid = uuid
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        switch text {
        case .string(let str):
            parameters["Text"] = .string(str)
        case .tokenString(let tokenString):
            parameters["Text"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["Text"] = attachment.toParameterValue()
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid
        )
    }
}

// MARK: - Convenience Extensions

extension ShowResultAction {
    /// Creates a show result action that displays the shortcut's input.
    /// - Parameter uuid: Optional UUID for this action
    public static func showInput(uuid: String? = nil) -> ShowResultAction {
        ShowResultAction(.attachment(.shortcutInput()), uuid: uuid)
    }

    /// Creates a show result action that displays a named variable.
    /// - Parameters:
    ///   - variableName: The name of the variable to display
    ///   - uuid: Optional UUID for this action
    public static func showVariable(_ variableName: String, uuid: String? = nil) -> ShowResultAction
    {
        ShowResultAction(.attachment(.variable(named: variableName)), uuid: uuid)
    }
}
