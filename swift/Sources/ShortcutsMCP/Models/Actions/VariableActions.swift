// SPDX-License-Identifier: MIT
// VariableActions.swift - Variable actions for Shortcuts

import Foundation

// MARK: - Set Variable Action

/// Sets a named variable to the current input or a specific value.
///
/// Identifier: `is.workflow.actions.setvariable`
///
/// This action takes the input from the previous action and stores it
/// in a named variable for later retrieval.
public struct SetVariableAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.setvariable"

    /// The name of the variable to set
    public var variableName: String

    /// Optional value to set (if not provided, uses the input from previous action)
    public var value: TextTokenValue?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a set variable action.
    /// - Parameters:
    ///   - variableName: The name of the variable to set
    ///   - value: Optional value to set (uses previous action's output if nil)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        _ variableName: String,
        value: TextTokenValue? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.variableName = variableName
        self.value = value
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a set variable action that stores a string value.
    /// - Parameters:
    ///   - variableName: The name of the variable to set
    ///   - stringValue: The string value to store
    ///   - uuid: Optional UUID for this action
    public init(
        _ variableName: String,
        stringValue: String,
        uuid: String? = nil
    ) {
        self.variableName = variableName
        self.value = .string(stringValue)
        self.uuid = uuid
        self.customOutputName = nil
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFVariableName": .string(variableName)
        ]

        if let value {
            switch value {
            case .string(let str):
                parameters["WFInput"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFInput"] = tokenString.toParameterValue()
            case .attachment(let attachment):
                parameters["WFInput"] = attachment.toParameterValue()
            }
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Get Variable Action

/// Retrieves the value of a named variable.
///
/// Identifier: `is.workflow.actions.getvariable`
///
/// This action retrieves a previously stored variable and passes it
/// to the next action.
public struct GetVariableAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.getvariable"

    /// The variable reference to retrieve
    public var variable: TextTokenAttachment

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a get variable action for a named variable.
    /// - Parameters:
    ///   - variableName: The name of the variable to get
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        named variableName: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.variable = TextTokenAttachment.variable(named: variableName)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get variable action for any attachment (variable, action output, etc).
    /// - Parameters:
    ///   - variable: The variable attachment to retrieve
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        _ variable: TextTokenAttachment,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.variable = variable
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get variable action for a magic variable (action output).
    /// - Parameters:
    ///   - actionUUID: The UUID of the source action
    ///   - outputName: The name of the output (e.g., "Text", "URL")
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public static func magicVariable(
        actionUUID: String,
        outputName: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) -> GetVariableAction {
        GetVariableAction(
            TextTokenAttachment.actionOutput(uuid: actionUUID, outputName: outputName),
            uuid: uuid,
            customOutputName: customOutputName
        )
    }

    /// Creates a get variable action for the shortcut input.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public static func shortcutInput(
        uuid: String? = nil,
        customOutputName: String? = nil
    ) -> GetVariableAction {
        GetVariableAction(
            TextTokenAttachment.shortcutInput(),
            uuid: uuid,
            customOutputName: customOutputName
        )
    }

    /// Creates a get variable action for the clipboard.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public static func clipboard(
        uuid: String? = nil,
        customOutputName: String? = nil
    ) -> GetVariableAction {
        GetVariableAction(
            TextTokenAttachment(type: .clipboard),
            uuid: uuid,
            customOutputName: customOutputName
        )
    }

    /// Creates a get variable action for the current date.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public static func currentDate(
        uuid: String? = nil,
        customOutputName: String? = nil
    ) -> GetVariableAction {
        GetVariableAction(
            TextTokenAttachment(type: .currentDate),
            uuid: uuid,
            customOutputName: customOutputName
        )
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        let parameters: [String: ActionParameterValue] = [
            "WFVariable": variable.toParameterValue()
        ]

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Append to Variable Action

/// Appends a value to a named variable (creating it if it doesn't exist).
///
/// Identifier: `is.workflow.actions.appendvariable`
///
/// This action appends the input from the previous action to an existing
/// variable, or creates a new variable with the input as its first value.
/// Useful for building lists or accumulating values.
public struct AppendToVariableAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.appendvariable"

    /// The name of the variable to append to
    public var variableName: String

    /// Optional value to append (if not provided, uses the input from previous action)
    public var value: TextTokenValue?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates an append to variable action.
    /// - Parameters:
    ///   - variableName: The name of the variable to append to
    ///   - value: Optional value to append (uses previous action's output if nil)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        _ variableName: String,
        value: TextTokenValue? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.variableName = variableName
        self.value = value
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates an append to variable action that appends a string value.
    /// - Parameters:
    ///   - variableName: The name of the variable to append to
    ///   - stringValue: The string value to append
    ///   - uuid: Optional UUID for this action
    public init(
        _ variableName: String,
        stringValue: String,
        uuid: String? = nil
    ) {
        self.variableName = variableName
        self.value = .string(stringValue)
        self.uuid = uuid
        self.customOutputName = nil
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFVariableName": .string(variableName)
        ]

        if let value {
            switch value {
            case .string(let str):
                parameters["WFInput"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFInput"] = tokenString.toParameterValue()
            case .attachment(let attachment):
                parameters["WFInput"] = attachment.toParameterValue()
            }
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}
