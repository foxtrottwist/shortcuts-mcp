// SPDX-License-Identifier: MIT
// ActionRegistry.swift - Central registry of all available shortcut actions

import Foundation

// MARK: - Action Category

/// Categories of shortcut actions for progressive disclosure.
public enum ActionCategory: String, Sendable, CaseIterable {
    case text
    case ui
    case file
    case url
    case json
    case variable

    /// Human-readable description of the category
    public var description: String {
        switch self {
        case .text: return "Text manipulation actions"
        case .ui: return "User interface actions (alerts, menus, notifications)"
        case .file: return "File operations (save, get, select)"
        case .url: return "Network and URL actions"
        case .json: return "JSON and dictionary manipulation"
        case .variable: return "Variable storage and retrieval"
        }
    }
}

// MARK: - Action Info

/// Information about a shortcut action for the catalog.
public struct ActionInfo: Sendable, Equatable {
    /// The action identifier (e.g., "is.workflow.actions.gettext")
    public let identifier: String

    /// Short name for the action (e.g., "text", "replace")
    public let name: String

    /// Human-readable display name (e.g., "Text", "Replace Text")
    public let displayName: String

    /// Description of what the action does
    public let description: String

    /// The category this action belongs to
    public let category: ActionCategory

    /// Parameter schema for the action
    public let parameters: [ActionParameter]

    public init(
        identifier: String,
        name: String,
        displayName: String,
        description: String,
        category: ActionCategory,
        parameters: [ActionParameter] = []
    ) {
        self.identifier = identifier
        self.name = name
        self.displayName = displayName
        self.description = description
        self.category = category
        self.parameters = parameters
    }
}

// MARK: - Action Parameter

/// Parameter definition for an action.
public struct ActionParameter: Sendable, Equatable {
    /// Parameter name (e.g., "WFTextActionText")
    public let name: String

    /// Human-readable label
    public let label: String

    /// Parameter type
    public let type: ParameterType

    /// Whether the parameter is required
    public let required: Bool

    /// Default value if any
    public let defaultValue: String?

    /// Description of the parameter
    public let description: String?

    public init(
        name: String,
        label: String,
        type: ParameterType,
        required: Bool = true,
        defaultValue: String? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.label = label
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.description = description
    }
}

/// Types of action parameters.
public enum ParameterType: String, Sendable, Equatable {
    case string
    case number
    case boolean
    case variable
    case enumeration
    case dictionary
    case array
}

// MARK: - Action Registry

/// Central registry of all available shortcut actions.
public enum ActionRegistry {
    /// All registered actions
    public static let allActions: [ActionInfo] = [
        // Text actions
        textAction,
        replaceTextAction,
        splitTextAction,
        combineTextAction,
        matchTextAction,
        changeCaseAction,

        // UI actions
        showResultAction,
        showNotificationAction,
        showAlertAction,
        chooseFromMenuAction,
        askForInputAction,
        chooseFromListAction,

        // File actions
        saveFileAction,
        getFileAction,
        selectFolderAction,
        getFolderContentsAction,

        // URL actions
        urlAction,

        // JSON actions
        getDictionaryValueAction,
        setDictionaryValueAction,
        getItemFromListAction,
        dictionaryAction,

        // Variable actions
        setVariableAction,
        getVariableAction,
        appendToVariableAction,
    ]

    /// Get all actions in a specific category
    public static func actions(in category: ActionCategory) -> [ActionInfo] {
        allActions.filter { $0.category == category }
    }

    /// Get action info by name
    public static func action(named name: String) -> ActionInfo? {
        allActions.first { $0.name == name }
    }

    /// Get action info by identifier
    public static func action(withIdentifier identifier: String) -> ActionInfo? {
        allActions.first { $0.identifier == identifier }
    }

    /// Get action count for a category
    public static func actionCount(in category: ActionCategory) -> Int {
        actions(in: category).count
    }

    // MARK: - Text Actions

    public static let textAction = ActionInfo(
        identifier: TextAction.identifier,
        name: "text",
        displayName: "Text",
        description: "Creates a text value that can be used by subsequent actions",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFTextActionText",
                label: "Text",
                type: .string,
                description: "The text content (can include magic variable references)"
            )
        ]
    )

    public static let replaceTextAction = ActionInfo(
        identifier: ReplaceTextAction.identifier,
        name: "replace",
        displayName: "Replace Text",
        description: "Replaces occurrences of a string with another string",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFReplaceTextFind",
                label: "Find",
                type: .string,
                description: "The text to find"
            ),
            ActionParameter(
                name: "WFReplaceTextReplace",
                label: "Replace With",
                type: .string,
                description: "The replacement text"
            ),
            ActionParameter(
                name: "WFReplaceTextCaseSensitive",
                label: "Case Sensitive",
                type: .boolean,
                required: false,
                defaultValue: "true",
                description: "Whether the search is case sensitive"
            ),
            ActionParameter(
                name: "WFReplaceTextRegularExpression",
                label: "Regular Expression",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to treat find text as a regex pattern"
            ),
        ]
    )

    public static let splitTextAction = ActionInfo(
        identifier: SplitTextAction.identifier,
        name: "split",
        displayName: "Split Text",
        description: "Splits text into a list using a separator",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFTextSeparator",
                label: "Separator",
                type: .enumeration,
                description: "The separator type: New Lines, Spaces, Every Character, or Custom"
            ),
            ActionParameter(
                name: "WFTextCustomSeparator",
                label: "Custom Separator",
                type: .string,
                required: false,
                description: "Custom separator string (when separator is Custom)"
            ),
        ]
    )

    public static let combineTextAction = ActionInfo(
        identifier: CombineTextAction.identifier,
        name: "combine",
        displayName: "Combine Text",
        description: "Combines a list of text items into a single string using a separator",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFTextSeparator",
                label: "Separator",
                type: .enumeration,
                description: "The separator type: New Lines, Spaces, or Custom"
            ),
            ActionParameter(
                name: "WFTextCustomSeparator",
                label: "Custom Separator",
                type: .string,
                required: false,
                description: "Custom separator string (when separator is Custom)"
            ),
        ]
    )

    public static let matchTextAction = ActionInfo(
        identifier: MatchTextAction.identifier,
        name: "match",
        displayName: "Match Text",
        description: "Searches text using a regular expression and returns matches",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFMatchTextPattern",
                label: "Pattern",
                type: .string,
                description: "The regular expression pattern to match"
            ),
            ActionParameter(
                name: "WFMatchTextCaseSensitive",
                label: "Case Sensitive",
                type: .boolean,
                required: false,
                defaultValue: "true",
                description: "Whether the match is case sensitive"
            ),
        ]
    )

    public static let changeCaseAction = ActionInfo(
        identifier: ChangeCaseAction.identifier,
        name: "changecase",
        displayName: "Change Case",
        description: "Changes the case of the input text",
        category: .text,
        parameters: [
            ActionParameter(
                name: "WFCaseType",
                label: "Case",
                type: .enumeration,
                description:
                    "The case type: UPPERCASE, lowercase, Capitalize Every Word, Capitalize with Title Case, Capitalize with sentence case, or cApItAlIzE wItH aLtErNaTiNg CaSe"
            )
        ]
    )

    // MARK: - UI Actions

    public static let showResultAction = ActionInfo(
        identifier: ShowResultAction.identifier,
        name: "showresult",
        displayName: "Show Result",
        description: "Displays a value to the user",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "Text",
                label: "Text",
                type: .string,
                description: "The text to display (can include magic variable references)"
            )
        ]
    )

    public static let showNotificationAction = ActionInfo(
        identifier: ShowNotificationAction.identifier,
        name: "notification",
        displayName: "Show Notification",
        description: "Displays a local notification to the user",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "WFNotificationActionBody",
                label: "Body",
                type: .string,
                description: "The notification body text"
            ),
            ActionParameter(
                name: "WFNotificationActionTitle",
                label: "Title",
                type: .string,
                required: false,
                description: "Optional notification title"
            ),
            ActionParameter(
                name: "WFNotificationActionSound",
                label: "Play Sound",
                type: .boolean,
                required: false,
                defaultValue: "true",
                description: "Whether to play a sound"
            ),
        ]
    )

    public static let showAlertAction = ActionInfo(
        identifier: ShowAlertAction.identifier,
        name: "alert",
        displayName: "Show Alert",
        description: "Displays an alert dialog to the user",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "WFAlertActionMessage",
                label: "Message",
                type: .string,
                description: "The alert message"
            ),
            ActionParameter(
                name: "WFAlertActionTitle",
                label: "Title",
                type: .string,
                required: false,
                description: "Optional alert title"
            ),
            ActionParameter(
                name: "WFAlertActionCancelButtonShown",
                label: "Show Cancel Button",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to show a cancel button"
            ),
        ]
    )

    public static let chooseFromMenuAction = ActionInfo(
        identifier: ChooseFromMenuAction.identifier,
        name: "menu",
        displayName: "Choose from Menu",
        description: "Presents a menu of options for the user to choose from",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "WFControlFlowMode",
                label: "Control Flow Mode",
                type: .number,
                description: "0=start, 1=menu item, 2=end"
            ),
            ActionParameter(
                name: "WFMenuPrompt",
                label: "Prompt",
                type: .string,
                required: false,
                description: "The menu prompt (for start mode)"
            ),
            ActionParameter(
                name: "WFMenuItems",
                label: "Menu Items",
                type: .array,
                required: false,
                description: "Array of menu item titles (for start mode)"
            ),
            ActionParameter(
                name: "GroupingIdentifier",
                label: "Grouping Identifier",
                type: .string,
                description: "UUID to link related menu actions"
            ),
        ]
    )

    public static let askForInputAction = ActionInfo(
        identifier: AskForInputAction.identifier,
        name: "ask",
        displayName: "Ask for Input",
        description: "Prompts the user to enter a value",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "WFAskActionPrompt",
                label: "Prompt",
                type: .string,
                description: "The prompt text"
            ),
            ActionParameter(
                name: "WFInputType",
                label: "Input Type",
                type: .enumeration,
                required: false,
                defaultValue: "Text",
                description: "Input type: Text, Number, URL, Date, Time, or Date and Time"
            ),
            ActionParameter(
                name: "WFAskActionDefaultAnswer",
                label: "Default Answer",
                type: .string,
                required: false,
                description: "Optional default value"
            ),
        ]
    )

    public static let chooseFromListAction = ActionInfo(
        identifier: ChooseFromListAction.identifier,
        name: "choosefromlist",
        displayName: "Choose from List",
        description: "Presents a list of items for the user to choose from",
        category: .ui,
        parameters: [
            ActionParameter(
                name: "WFInput",
                label: "Input",
                type: .variable,
                required: false,
                description: "The input list (variable reference)"
            ),
            ActionParameter(
                name: "WFChooseFromListActionPrompt",
                label: "Prompt",
                type: .string,
                required: false,
                description: "Optional prompt text"
            ),
            ActionParameter(
                name: "WFChooseFromListActionSelectMultiple",
                label: "Select Multiple",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to allow multiple selection"
            ),
        ]
    )

    // MARK: - File Actions

    public static let saveFileAction = ActionInfo(
        identifier: SaveFileAction.identifier,
        name: "savefile",
        displayName: "Save File",
        description: "Saves data to iCloud Drive or Dropbox",
        category: .file,
        parameters: [
            ActionParameter(
                name: "WFFileStorageService",
                label: "Service",
                type: .enumeration,
                description: "Storage service: iCloud Drive or Dropbox"
            ),
            ActionParameter(
                name: "WFAskWhereToSave",
                label: "Ask Where to Save",
                type: .boolean,
                defaultValue: "true",
                description: "Whether to prompt user for save location"
            ),
            ActionParameter(
                name: "WFFileDestinationPath",
                label: "Destination Path",
                type: .string,
                required: false,
                description: "File path (when not asking)"
            ),
            ActionParameter(
                name: "WFSaveFileOverwrite",
                label: "Overwrite",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to overwrite existing files"
            ),
        ]
    )

    public static let getFileAction = ActionInfo(
        identifier: GetFileAction.identifier,
        name: "getfile",
        displayName: "Get File",
        description: "Retrieves files from iCloud Drive or Dropbox",
        category: .file,
        parameters: [
            ActionParameter(
                name: "WFFileStorageService",
                label: "Service",
                type: .enumeration,
                description: "Storage service: iCloud Drive or Dropbox"
            ),
            ActionParameter(
                name: "WFShowFilePicker",
                label: "Show File Picker",
                type: .boolean,
                defaultValue: "true",
                description: "Whether to show the document picker UI"
            ),
            ActionParameter(
                name: "WFGetFilePath",
                label: "File Path",
                type: .string,
                required: false,
                description: "File path (when not showing picker)"
            ),
            ActionParameter(
                name: "SelectMultiple",
                label: "Select Multiple",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to allow selecting multiple files"
            ),
        ]
    )

    public static let selectFolderAction = ActionInfo(
        identifier: SelectFolderAction.identifier,
        name: "selectfolder",
        displayName: "Select Folder",
        description: "Prompts the user to select a folder",
        category: .file,
        parameters: [
            ActionParameter(
                name: "SelectMultiple",
                label: "Select Multiple",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to allow selecting multiple folders"
            )
        ]
    )

    public static let getFolderContentsAction = ActionInfo(
        identifier: GetFolderContentsAction.identifier,
        name: "getfoldercontents",
        displayName: "Get Folder Contents",
        description: "Retrieves the contents of a folder",
        category: .file,
        parameters: [
            ActionParameter(
                name: "Recursive",
                label: "Recursive",
                type: .boolean,
                required: false,
                defaultValue: "false",
                description: "Whether to include contents of subfolders"
            )
        ]
    )

    // MARK: - URL Actions

    public static let urlAction = ActionInfo(
        identifier: URLAction.identifier,
        name: "url",
        displayName: "Get Contents of URL",
        description: "Makes HTTP requests and returns the response",
        category: .url,
        parameters: [
            ActionParameter(
                name: "WFURL",
                label: "URL",
                type: .string,
                description: "The URL to request"
            ),
            ActionParameter(
                name: "WFHTTPMethod",
                label: "Method",
                type: .enumeration,
                required: false,
                defaultValue: "GET",
                description: "HTTP method: GET, POST, PUT, PATCH, DELETE"
            ),
            ActionParameter(
                name: "WFHTTPHeaders",
                label: "Headers",
                type: .dictionary,
                required: false,
                description: "Custom HTTP headers"
            ),
            ActionParameter(
                name: "WFHTTPBodyType",
                label: "Body Type",
                type: .enumeration,
                required: false,
                description: "Body type: 0=JSON, 1=Form, 2=File"
            ),
            ActionParameter(
                name: "WFJSONValues",
                label: "JSON Body",
                type: .dictionary,
                required: false,
                description: "JSON body data"
            ),
        ]
    )

    // MARK: - JSON Actions

    public static let getDictionaryValueAction = ActionInfo(
        identifier: GetDictionaryValueAction.identifier,
        name: "getdictionaryvalue",
        displayName: "Get Dictionary Value",
        description:
            "Gets a value from a dictionary (supports dot notation for nested paths)",
        category: .json,
        parameters: [
            ActionParameter(
                name: "WFGetDictionaryValueType",
                label: "Value Type",
                type: .enumeration,
                defaultValue: "Value",
                description: "What to get: Value, All Keys, or All Values"
            ),
            ActionParameter(
                name: "WFDictionaryKey",
                label: "Key",
                type: .string,
                required: false,
                description: "The key to retrieve (supports dot notation)"
            ),
        ]
    )

    public static let setDictionaryValueAction = ActionInfo(
        identifier: SetDictionaryValueAction.identifier,
        name: "setdictionaryvalue",
        displayName: "Set Dictionary Value",
        description: "Sets a value in the dictionary",
        category: .json,
        parameters: [
            ActionParameter(
                name: "WFDictionaryKey",
                label: "Key",
                type: .string,
                description: "The key to set"
            ),
            ActionParameter(
                name: "WFDictionaryValue",
                label: "Value",
                type: .string,
                description: "The value to set"
            ),
        ]
    )

    public static let getItemFromListAction = ActionInfo(
        identifier: GetItemFromListAction.identifier,
        name: "getitemfromlist",
        displayName: "Get Item from List",
        description: "Gets an item from a list (1-indexed)",
        category: .json,
        parameters: [
            ActionParameter(
                name: "WFItemSpecifier",
                label: "Item",
                type: .enumeration,
                description:
                    "Which item: First Item, Last Item, Random Item, Item At Index, or Items in Range"
            ),
            ActionParameter(
                name: "WFItemIndex",
                label: "Index",
                type: .number,
                required: false,
                description: "1-based index (for Item At Index)"
            ),
            ActionParameter(
                name: "WFItemRangeStart",
                label: "Range Start",
                type: .number,
                required: false,
                description: "Start index (for Items in Range)"
            ),
            ActionParameter(
                name: "WFItemRangeEnd",
                label: "Range End",
                type: .number,
                required: false,
                description: "End index (for Items in Range)"
            ),
        ]
    )

    public static let dictionaryAction = ActionInfo(
        identifier: DictionaryAction.identifier,
        name: "dictionary",
        displayName: "Dictionary",
        description: "Creates a dictionary from key-value pairs",
        category: .json,
        parameters: [
            ActionParameter(
                name: "WFItems",
                label: "Items",
                type: .dictionary,
                description: "Key-value pairs for the dictionary"
            )
        ]
    )

    // MARK: - Variable Actions

    public static let setVariableAction = ActionInfo(
        identifier: SetVariableAction.identifier,
        name: "setvariable",
        displayName: "Set Variable",
        description: "Sets a named variable to the current input or a specific value",
        category: .variable,
        parameters: [
            ActionParameter(
                name: "WFVariableName",
                label: "Variable Name",
                type: .string,
                description: "The name of the variable to set"
            ),
            ActionParameter(
                name: "WFInput",
                label: "Input",
                type: .variable,
                required: false,
                description: "Optional value (uses previous action's output if not specified)"
            ),
        ]
    )

    public static let getVariableAction = ActionInfo(
        identifier: GetVariableAction.identifier,
        name: "getvariable",
        displayName: "Get Variable",
        description: "Retrieves the value of a variable",
        category: .variable,
        parameters: [
            ActionParameter(
                name: "WFVariable",
                label: "Variable",
                type: .variable,
                description:
                    "The variable to retrieve (named variable, magic variable, clipboard, etc.)"
            )
        ]
    )

    public static let appendToVariableAction = ActionInfo(
        identifier: AppendToVariableAction.identifier,
        name: "appendtovariable",
        displayName: "Append to Variable",
        description: "Appends a value to a named variable (creates if it doesn't exist)",
        category: .variable,
        parameters: [
            ActionParameter(
                name: "WFVariableName",
                label: "Variable Name",
                type: .string,
                description: "The name of the variable to append to"
            ),
            ActionParameter(
                name: "WFInput",
                label: "Input",
                type: .variable,
                required: false,
                description: "Optional value (uses previous action's output if not specified)"
            ),
        ]
    )
}

// MARK: - JSON Encoding Support

extension ActionCategory: Codable {}
extension ParameterType: Codable {}

extension ActionInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case name
        case displayName = "display_name"
        case description
        case category
        case parameters
    }
}

extension ActionParameter: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case label
        case type
        case required
        case defaultValue = "default_value"
        case description
    }
}
