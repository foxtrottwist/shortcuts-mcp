// SPDX-License-Identifier: MIT
// UIActions.swift - UI actions for notifications, alerts, and menus in Shortcuts

import Foundation

// MARK: - Show Notification Action

/// Represents a "Show Notification" action in Shortcuts.
/// This action displays a local notification to the user.
///
/// Identifier: `is.workflow.actions.notification`
public struct ShowNotificationAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.notification"

    /// The notification body text
    public var body: TextTokenValue

    /// Optional notification title
    public var title: TextTokenValue?

    /// Whether to play a sound (defaults to true)
    public var playSound: Bool

    /// Optional attachment (image, file, etc.)
    public var attachment: TextTokenAttachment?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Creates a show notification action with a plain string body.
    /// - Parameters:
    ///   - body: The notification body text
    ///   - title: Optional notification title
    ///   - playSound: Whether to play a sound (defaults to true)
    ///   - attachment: Optional attachment
    ///   - uuid: Optional UUID for this action
    public init(
        _ body: String,
        title: String? = nil,
        playSound: Bool = true,
        attachment: TextTokenAttachment? = nil,
        uuid: String? = nil
    ) {
        self.body = .string(body)
        self.title = title.map { .string($0) }
        self.playSound = playSound
        self.attachment = attachment
        self.uuid = uuid
    }

    /// Creates a show notification action with token values.
    /// - Parameters:
    ///   - body: The notification body as a token value
    ///   - title: Optional notification title as a token value
    ///   - playSound: Whether to play a sound (defaults to true)
    ///   - attachment: Optional attachment
    ///   - uuid: Optional UUID for this action
    public init(
        body: TextTokenValue,
        title: TextTokenValue? = nil,
        playSound: Bool = true,
        attachment: TextTokenAttachment? = nil,
        uuid: String? = nil
    ) {
        self.body = body
        self.title = title
        self.playSound = playSound
        self.attachment = attachment
        self.uuid = uuid
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Set body parameter
        switch body {
        case .string(let str):
            parameters["WFNotificationActionBody"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFNotificationActionBody"] = tokenString.toParameterValue()
        case .attachment(let att):
            parameters["WFNotificationActionBody"] = att.toParameterValue()
        }

        // Set title parameter if present
        if let title {
            switch title {
            case .string(let str):
                parameters["WFNotificationActionTitle"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFNotificationActionTitle"] = tokenString.toParameterValue()
            case .attachment(let att):
                parameters["WFNotificationActionTitle"] = att.toParameterValue()
            }
        }

        // Set sound parameter (only if false, since true is the default)
        if !playSound {
            parameters["WFNotificationActionSound"] = .bool(false)
        }

        // Set attachment if present
        if let attachment {
            parameters["WFInput"] = attachment.toParameterValue()
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid
        )
    }
}

// MARK: - Show Alert Action

/// Represents a "Show Alert" action in Shortcuts.
/// This action displays an alert dialog to the user.
///
/// Identifier: `is.workflow.actions.alert`
public struct ShowAlertAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.alert"

    /// The alert message
    public var message: TextTokenValue

    /// Optional alert title
    public var title: TextTokenValue?

    /// Whether to show a cancel button (defaults to false)
    public var showCancelButton: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Creates a show alert action with a plain string message.
    /// - Parameters:
    ///   - message: The alert message
    ///   - title: Optional alert title
    ///   - showCancelButton: Whether to show a cancel button (defaults to false)
    ///   - uuid: Optional UUID for this action
    public init(
        _ message: String,
        title: String? = nil,
        showCancelButton: Bool = false,
        uuid: String? = nil
    ) {
        self.message = .string(message)
        self.title = title.map { .string($0) }
        self.showCancelButton = showCancelButton
        self.uuid = uuid
    }

    /// Creates a show alert action with token values.
    /// - Parameters:
    ///   - message: The alert message as a token value
    ///   - title: Optional alert title as a token value
    ///   - showCancelButton: Whether to show a cancel button (defaults to false)
    ///   - uuid: Optional UUID for this action
    public init(
        message: TextTokenValue,
        title: TextTokenValue? = nil,
        showCancelButton: Bool = false,
        uuid: String? = nil
    ) {
        self.message = message
        self.title = title
        self.showCancelButton = showCancelButton
        self.uuid = uuid
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Set message parameter
        switch message {
        case .string(let str):
            parameters["WFAlertActionMessage"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFAlertActionMessage"] = tokenString.toParameterValue()
        case .attachment(let att):
            parameters["WFAlertActionMessage"] = att.toParameterValue()
        }

        // Set title parameter if present
        if let title {
            switch title {
            case .string(let str):
                parameters["WFAlertActionTitle"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFAlertActionTitle"] = tokenString.toParameterValue()
            case .attachment(let att):
                parameters["WFAlertActionTitle"] = att.toParameterValue()
            }
        }

        // Set cancel button parameter (only if true, since false is the default)
        if showCancelButton {
            parameters["WFAlertActionCancelButtonShown"] = .bool(true)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid
        )
    }
}

// MARK: - Convenience Extensions for Alert

extension ShowAlertAction {
    /// Creates a confirmation alert with OK and Cancel buttons.
    /// - Parameters:
    ///   - message: The alert message
    ///   - title: Optional alert title
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured ShowAlertAction with cancel button shown
    public static func confirm(
        _ message: String,
        title: String? = nil,
        uuid: String? = nil
    ) -> ShowAlertAction {
        ShowAlertAction(message, title: title, showCancelButton: true, uuid: uuid)
    }
}

// MARK: - Choose From Menu Action

/// Control flow mode for menu actions.
public enum MenuControlFlowMode: Int, Sendable {
    /// Start of the menu (contains prompt and items)
    case start = 0
    /// A menu item case
    case menuItem = 1
    /// End of the menu block
    case end = 2
}

/// Represents a "Choose from Menu" action in Shortcuts.
/// This action presents a menu of options for the user to choose from.
///
/// The menu structure requires multiple actions:
/// 1. Start action with prompt and menu items (controlFlowMode = 0)
/// 2. One menu item action per option (controlFlowMode = 1)
/// 3. End action (controlFlowMode = 2)
///
/// All related menu actions must share the same GroupingIdentifier.
///
/// Identifier: `is.workflow.actions.choosefrommenu`
public struct ChooseFromMenuAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.choosefrommenu"

    /// The control flow mode
    public var controlFlowMode: MenuControlFlowMode

    /// The menu prompt (only for start mode)
    public var prompt: String?

    /// The menu items (only for start mode)
    public var menuItems: [String]?

    /// The menu item title (only for menuItem mode)
    public var menuItemTitle: String?

    /// Grouping identifier to link related menu actions
    public var groupingIdentifier: String

    /// Optional UUID for this action instance
    public var uuid: String?

    // MARK: - Initializers

    /// Creates a menu start action with prompt and items.
    /// - Parameters:
    ///   - prompt: The menu prompt
    ///   - items: The menu item titles
    ///   - groupingIdentifier: Identifier to link related menu actions
    ///   - uuid: Optional UUID for this action
    public init(
        prompt: String,
        items: [String],
        groupingIdentifier: String = UUID().uuidString,
        uuid: String? = nil
    ) {
        self.controlFlowMode = .start
        self.prompt = prompt
        self.menuItems = items
        self.menuItemTitle = nil
        self.groupingIdentifier = groupingIdentifier
        self.uuid = uuid
    }

    /// Creates a menu item case action.
    /// - Parameters:
    ///   - itemTitle: The menu item title
    ///   - groupingIdentifier: Identifier to link related menu actions
    ///   - uuid: Optional UUID for this action
    public init(
        itemTitle: String,
        groupingIdentifier: String,
        uuid: String? = nil
    ) {
        self.controlFlowMode = .menuItem
        self.prompt = nil
        self.menuItems = nil
        self.menuItemTitle = itemTitle
        self.groupingIdentifier = groupingIdentifier
        self.uuid = uuid
    }

    /// Creates a menu end action.
    /// - Parameters:
    ///   - groupingIdentifier: Identifier to link related menu actions
    ///   - uuid: Optional UUID for this action
    public init(
        endMenuWithGroupingIdentifier groupingIdentifier: String,
        uuid: String? = nil
    ) {
        self.controlFlowMode = .end
        self.prompt = nil
        self.menuItems = nil
        self.menuItemTitle = nil
        self.groupingIdentifier = groupingIdentifier
        self.uuid = uuid
    }

    /// Creates a menu action with explicit control flow mode.
    private init(
        controlFlowMode: MenuControlFlowMode,
        prompt: String?,
        menuItems: [String]?,
        menuItemTitle: String?,
        groupingIdentifier: String,
        uuid: String?
    ) {
        self.controlFlowMode = controlFlowMode
        self.prompt = prompt
        self.menuItems = menuItems
        self.menuItemTitle = menuItemTitle
        self.groupingIdentifier = groupingIdentifier
        self.uuid = uuid
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFControlFlowMode": .int(controlFlowMode.rawValue)
        ]

        switch controlFlowMode {
        case .start:
            if let prompt {
                parameters["WFMenuPrompt"] = .string(prompt)
            }
            if let menuItems {
                parameters["WFMenuItems"] = .array(menuItems.map { .string($0) })
            }
        case .menuItem:
            if let menuItemTitle {
                parameters["WFMenuItemTitle"] = .string(menuItemTitle)
            }
        case .end:
            // No additional parameters for end
            break
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            groupingIdentifier: groupingIdentifier
        )
    }
}

// MARK: - Menu Builder

extension ChooseFromMenuAction {
    /// Creates a complete menu structure with all required actions.
    /// - Parameters:
    ///   - prompt: The menu prompt
    ///   - items: The menu item titles
    ///   - groupingIdentifier: Identifier to link related menu actions
    /// - Returns: Array of menu actions (start, items, end)
    public static func buildMenu(
        prompt: String,
        items: [String],
        groupingIdentifier: String = UUID().uuidString
    ) -> [ChooseFromMenuAction] {
        var actions: [ChooseFromMenuAction] = []

        // Start action
        actions.append(ChooseFromMenuAction(
            prompt: prompt,
            items: items,
            groupingIdentifier: groupingIdentifier
        ))

        // Menu item actions
        for item in items {
            actions.append(ChooseFromMenuAction(
                itemTitle: item,
                groupingIdentifier: groupingIdentifier
            ))
        }

        // End action
        actions.append(ChooseFromMenuAction(
            endMenuWithGroupingIdentifier: groupingIdentifier
        ))

        return actions
    }
}

// MARK: - Ask For Input Action

/// Input types for the Ask for Input action.
public enum AskInputType: String, Sendable, CaseIterable {
    case text = "Text"
    case number = "Number"
    case url = "URL"
    case date = "Date"
    case time = "Time"
    case dateAndTime = "Date and Time"
}

/// Represents an "Ask for Input" action in Shortcuts.
/// This action prompts the user to enter a value.
///
/// Identifier: `is.workflow.actions.ask`
public struct AskForInputAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.ask"

    /// The prompt text
    public var prompt: TextTokenValue

    /// The input type (defaults to text)
    public var inputType: AskInputType

    /// Optional default value
    public var defaultAnswer: TextTokenValue?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates an ask for input action with a plain string prompt.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - inputType: The input type (defaults to text)
    ///   - defaultAnswer: Optional default value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        _ prompt: String,
        inputType: AskInputType = .text,
        defaultAnswer: String? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.prompt = .string(prompt)
        self.inputType = inputType
        self.defaultAnswer = defaultAnswer.map { .string($0) }
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates an ask for input action with token values.
    /// - Parameters:
    ///   - prompt: The prompt as a token value
    ///   - inputType: The input type (defaults to text)
    ///   - defaultAnswer: Optional default value as a token value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        prompt: TextTokenValue,
        inputType: AskInputType = .text,
        defaultAnswer: TextTokenValue? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.prompt = prompt
        self.inputType = inputType
        self.defaultAnswer = defaultAnswer
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Set prompt parameter
        switch prompt {
        case .string(let str):
            parameters["WFAskActionPrompt"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFAskActionPrompt"] = tokenString.toParameterValue()
        case .attachment(let att):
            parameters["WFAskActionPrompt"] = att.toParameterValue()
        }

        // Set input type (only if not text, since text is the default)
        if inputType != .text {
            parameters["WFInputType"] = .string(inputType.rawValue)
        }

        // Set default answer if present
        if let defaultAnswer {
            switch defaultAnswer {
            case .string(let str):
                parameters["WFAskActionDefaultAnswer"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFAskActionDefaultAnswer"] = tokenString.toParameterValue()
            case .attachment(let att):
                parameters["WFAskActionDefaultAnswer"] = att.toParameterValue()
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

// MARK: - Convenience Extensions for Ask

extension AskForInputAction {
    /// Creates an ask for input action that requests a number.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - defaultAnswer: Optional default value
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured AskForInputAction for number input
    public static func askForNumber(
        _ prompt: String,
        defaultAnswer: String? = nil,
        uuid: String? = nil
    ) -> AskForInputAction {
        AskForInputAction(prompt, inputType: .number, defaultAnswer: defaultAnswer, uuid: uuid)
    }

    /// Creates an ask for input action that requests a URL.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - defaultAnswer: Optional default value
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured AskForInputAction for URL input
    public static func askForURL(
        _ prompt: String,
        defaultAnswer: String? = nil,
        uuid: String? = nil
    ) -> AskForInputAction {
        AskForInputAction(prompt, inputType: .url, defaultAnswer: defaultAnswer, uuid: uuid)
    }

    /// Creates an ask for input action that requests a date.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured AskForInputAction for date input
    public static func askForDate(
        _ prompt: String,
        uuid: String? = nil
    ) -> AskForInputAction {
        AskForInputAction(prompt, inputType: .date, uuid: uuid)
    }

    /// Creates an ask for input action that requests a time.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured AskForInputAction for time input
    public static func askForTime(
        _ prompt: String,
        uuid: String? = nil
    ) -> AskForInputAction {
        AskForInputAction(prompt, inputType: .time, uuid: uuid)
    }

    /// Creates an ask for input action that requests a date and time.
    /// - Parameters:
    ///   - prompt: The prompt text
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured AskForInputAction for date and time input
    public static func askForDateTime(
        _ prompt: String,
        uuid: String? = nil
    ) -> AskForInputAction {
        AskForInputAction(prompt, inputType: .dateAndTime, uuid: uuid)
    }
}

// MARK: - Choose From List Action

/// Represents a "Choose from List" action in Shortcuts.
/// This action presents a list of items for the user to choose from.
///
/// Identifier: `is.workflow.actions.choosefromlist`
public struct ChooseFromListAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.choosefromlist"

    /// The input list (variable reference to a list)
    public var input: TextTokenAttachment?

    /// Optional prompt text
    public var prompt: String?

    /// Whether to allow multiple selection (defaults to false)
    public var selectMultiple: Bool

    /// Whether to select all by default (defaults to false, only applies when selectMultiple is true)
    public var selectAll: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a choose from list action.
    /// - Parameters:
    ///   - input: The input list variable
    ///   - prompt: Optional prompt text
    ///   - selectMultiple: Whether to allow multiple selection
    ///   - selectAll: Whether to select all by default
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        input: TextTokenAttachment? = nil,
        prompt: String? = nil,
        selectMultiple: Bool = false,
        selectAll: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.input = input
        self.prompt = prompt
        self.selectMultiple = selectMultiple
        self.selectAll = selectAll
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a choose from list action that receives input from a previous action.
    /// - Parameters:
    ///   - sourceUUID: UUID of the action whose output to use
    ///   - outputName: Name of the output (defaults to "List")
    ///   - prompt: Optional prompt text
    ///   - selectMultiple: Whether to allow multiple selection
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        fromActionWithUUID sourceUUID: String,
        outputName: String = "List",
        prompt: String? = nil,
        selectMultiple: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.input = .actionOutput(uuid: sourceUUID, outputName: outputName)
        self.prompt = prompt
        self.selectMultiple = selectMultiple
        self.selectAll = false
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Set input if present
        if let input {
            parameters["WFInput"] = input.toParameterValue()
        }

        // Set prompt if present
        if let prompt {
            parameters["WFChooseFromListActionPrompt"] = .string(prompt)
        }

        // Set multiple selection (only if true, since false is the default)
        if selectMultiple {
            parameters["WFChooseFromListActionSelectMultiple"] = .bool(true)

            // Set select all (only if true and multiple selection is enabled)
            if selectAll {
                parameters["WFChooseFromListActionSelectAll"] = .bool(true)
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

// MARK: - Convenience Extensions for Choose From List

extension ChooseFromListAction {
    /// Creates a choose from list action that uses the shortcut's input.
    /// - Parameters:
    ///   - prompt: Optional prompt text
    ///   - selectMultiple: Whether to allow multiple selection
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured ChooseFromListAction that uses shortcut input
    public static func fromShortcutInput(
        prompt: String? = nil,
        selectMultiple: Bool = false,
        uuid: String? = nil
    ) -> ChooseFromListAction {
        ChooseFromListAction(
            input: .shortcutInput(),
            prompt: prompt,
            selectMultiple: selectMultiple,
            uuid: uuid
        )
    }

    /// Creates a choose from list action that uses a named variable.
    /// - Parameters:
    ///   - variableName: The name of the variable containing the list
    ///   - prompt: Optional prompt text
    ///   - selectMultiple: Whether to allow multiple selection
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured ChooseFromListAction that uses a named variable
    public static func fromVariable(
        _ variableName: String,
        prompt: String? = nil,
        selectMultiple: Bool = false,
        uuid: String? = nil
    ) -> ChooseFromListAction {
        ChooseFromListAction(
            input: .variable(named: variableName),
            prompt: prompt,
            selectMultiple: selectMultiple,
            uuid: uuid
        )
    }
}
