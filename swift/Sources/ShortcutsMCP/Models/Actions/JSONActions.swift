// SPDX-License-Identifier: MIT
// JSONActions.swift - JSON and dictionary manipulation actions for Shortcuts

import Foundation

// MARK: - Get Dictionary Value Action

/// Mode for the Get Dictionary Value action.
public enum DictionaryValueType: String, Sendable, CaseIterable {
    /// Get a single value for a specific key
    case value = "Value"

    /// Get all keys from the dictionary
    case allKeys = "All Keys"

    /// Get all values from the dictionary
    case allValues = "All Values"
}

/// Represents a "Get Dictionary Value" action in Shortcuts.
/// Gets the value for a key in a dictionary passed into the action.
/// Supports dot notation for nested key paths (e.g., "user.address.city").
///
/// Identifier: `is.workflow.actions.getvalueforkey`
public struct GetDictionaryValueAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.getvalueforkey"

    /// The type of value to get (single value, all keys, or all values)
    public var valueType: DictionaryValueType

    /// The key to retrieve (supports dot notation for nested access)
    /// Only used when valueType is .value
    public var key: TextTokenValue?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a get dictionary value action that retrieves a single value.
    /// - Parameters:
    ///   - key: The key to retrieve (supports dot notation for nested access)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        key: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.valueType = .value
        self.key = .string(key)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get dictionary value action that retrieves a single value with a variable key.
    /// - Parameters:
    ///   - key: The key as a token value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        key: TextTokenValue,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.valueType = .value
        self.key = key
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get dictionary value action for a specific mode.
    /// - Parameters:
    ///   - valueType: The type of value to get
    ///   - key: The key (only used for .value type)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        valueType: DictionaryValueType,
        key: String? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.valueType = valueType
        self.key = key.map { .string($0) }
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFGetDictionaryValueType": .string(valueType.rawValue)
        ]

        // Only include key for single value retrieval
        if valueType == .value, let key {
            switch key {
            case .string(let str):
                parameters["WFDictionaryKey"] = .string(str)
            case .tokenString(let tokenString):
                parameters["WFDictionaryKey"] = tokenString.toParameterValue()
            case .attachment(let attachment):
                parameters["WFDictionaryKey"] = attachment.toParameterValue()
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

// MARK: - Convenience Extensions

extension GetDictionaryValueAction {
    /// Creates an action to get a value for a specific key.
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetDictionaryValueAction
    public static func getValue(
        forKey key: String,
        uuid: String? = nil
    ) -> GetDictionaryValueAction {
        GetDictionaryValueAction(key: key, uuid: uuid)
    }

    /// Creates an action to get all keys from a dictionary.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetDictionaryValueAction
    public static func getAllKeys(uuid: String? = nil) -> GetDictionaryValueAction {
        GetDictionaryValueAction(valueType: .allKeys, uuid: uuid)
    }

    /// Creates an action to get all values from a dictionary.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetDictionaryValueAction
    public static func getAllValues(uuid: String? = nil) -> GetDictionaryValueAction {
        GetDictionaryValueAction(valueType: .allValues, uuid: uuid)
    }
}

// MARK: - Set Dictionary Value Action

/// Represents a "Set Dictionary Value" action in Shortcuts.
/// Sets a value in the dictionary passed into the action.
///
/// Identifier: `is.workflow.actions.setvalueforkey`
public struct SetDictionaryValueAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.setvalueforkey"

    /// The key to set
    public var key: TextTokenValue

    /// The value to set
    public var value: TextTokenValue

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a set dictionary value action with plain strings.
    /// - Parameters:
    ///   - key: The key to set
    ///   - value: The value to set
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        key: String,
        value: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.key = .string(key)
        self.value = .string(value)
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a set dictionary value action with token values.
    /// - Parameters:
    ///   - key: The key as a token value
    ///   - value: The value as a token value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        key: TextTokenValue,
        value: TextTokenValue,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.key = key
        self.value = value
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Key
        switch key {
        case .string(let str):
            parameters["WFDictionaryKey"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFDictionaryKey"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFDictionaryKey"] = attachment.toParameterValue()
        }

        // Value
        switch value {
        case .string(let str):
            parameters["WFDictionaryValue"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFDictionaryValue"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFDictionaryValue"] = attachment.toParameterValue()
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Get Item From List Action

/// Specifier for which item to get from a list.
public enum ListItemSpecifier: Sendable, Equatable {
    /// Get the first item
    case firstItem

    /// Get the last item
    case lastItem

    /// Get a random item
    case randomItem

    /// Get an item at a specific index (1-based)
    case itemAtIndex(Int)

    /// Get items in a range (1-based, inclusive)
    case itemsInRange(start: Int, end: Int)

    /// The raw value for the WFItemSpecifier parameter
    var rawValue: String {
        switch self {
        case .firstItem: return "First Item"
        case .lastItem: return "Last Item"
        case .randomItem: return "Random Item"
        case .itemAtIndex: return "Item At Index"
        case .itemsInRange: return "Items in Range"
        }
    }
}

/// Represents a "Get Item from List" action in Shortcuts.
/// Gets an item from a list based on a specifier.
/// Lists are 1-indexed, so the first item is at index 1.
///
/// Identifier: `is.workflow.actions.getitemfromlist`
public struct GetItemFromListAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.getitemfromlist"

    /// The specifier for which item to get
    public var specifier: ListItemSpecifier

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a get item from list action.
    /// - Parameters:
    ///   - specifier: Which item to get (default: firstItem)
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        specifier: ListItemSpecifier = .firstItem,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.specifier = specifier
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFItemSpecifier": .string(specifier.rawValue)
        ]

        switch specifier {
        case .itemAtIndex(let index):
            parameters["WFItemIndex"] = .int(index)
        case .itemsInRange(let start, let end):
            parameters["WFItemRangeStart"] = .int(start)
            parameters["WFItemRangeEnd"] = .int(end)
        default:
            break
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Convenience Extensions

extension GetItemFromListAction {
    /// Creates an action to get the first item from a list.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetItemFromListAction
    public static func firstItem(uuid: String? = nil) -> GetItemFromListAction {
        GetItemFromListAction(specifier: .firstItem, uuid: uuid)
    }

    /// Creates an action to get the last item from a list.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetItemFromListAction
    public static func lastItem(uuid: String? = nil) -> GetItemFromListAction {
        GetItemFromListAction(specifier: .lastItem, uuid: uuid)
    }

    /// Creates an action to get a random item from a list.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetItemFromListAction
    public static func randomItem(uuid: String? = nil) -> GetItemFromListAction {
        GetItemFromListAction(specifier: .randomItem, uuid: uuid)
    }

    /// Creates an action to get an item at a specific index.
    /// - Parameters:
    ///   - index: The 1-based index of the item
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetItemFromListAction
    public static func itemAtIndex(_ index: Int, uuid: String? = nil) -> GetItemFromListAction {
        GetItemFromListAction(specifier: .itemAtIndex(index), uuid: uuid)
    }

    /// Creates an action to get items in a range.
    /// - Parameters:
    ///   - start: The 1-based start index (inclusive)
    ///   - end: The 1-based end index (inclusive)
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetItemFromListAction
    public static func itemsInRange(
        from start: Int,
        to end: Int,
        uuid: String? = nil
    ) -> GetItemFromListAction {
        GetItemFromListAction(specifier: .itemsInRange(start: start, end: end), uuid: uuid)
    }
}

// MARK: - Dictionary Action

/// Represents a "Dictionary" action in Shortcuts.
/// Creates a dictionary from key-value pairs.
/// The output represents JSON when converted to text.
///
/// Identifier: `is.workflow.actions.dictionary`
public struct DictionaryAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.dictionary"

    /// The dictionary items as key-value pairs
    public var items: [String: ActionParameterValue]

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a dictionary action with the given items.
    /// - Parameters:
    ///   - items: The key-value pairs for the dictionary
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        items: [String: ActionParameterValue],
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.items = items
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a dictionary action with string values.
    /// - Parameters:
    ///   - stringItems: The key-value pairs with string values
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        stringItems: [String: String],
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.items = stringItems.mapValues { .string($0) }
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        // The WFItems parameter contains an array with Value and WFSerializationType
        // The Value is a dictionary with WFDictionaryFieldValueItems array
        var fieldItems: [ActionParameterValue] = []

        for (key, value) in items.sorted(by: { $0.key < $1.key }) {
            var itemDict: [String: ActionParameterValue] = [
                "WFKey": .dictionary([
                    "Value": .dictionary(["string": .string(key)]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ]),
                "WFItemType": .int(0),  // 0 = Text
            ]

            // Add the value
            switch value {
            case .string(let str):
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string(str)]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            case .int(let num):
                itemDict["WFItemType"] = .int(3)  // 3 = Number
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string(String(num))]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            case .double(let num):
                itemDict["WFItemType"] = .int(3)  // 3 = Number
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string(String(num))]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            case .bool(let b):
                itemDict["WFItemType"] = .int(4)  // 4 = Boolean
                itemDict["WFValue"] = .bool(b)
            case .dictionary:
                // For nested dictionaries, serialize as text for now
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string("{...}")]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            case .array:
                // For arrays, serialize as text for now
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string("[...]")]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            case .data:
                // For data, serialize as text for now
                itemDict["WFValue"] = .dictionary([
                    "Value": .dictionary(["string": .string("<data>")]),
                    "WFSerializationType": .string("WFTextTokenString"),
                ])
            }

            fieldItems.append(.dictionary(itemDict))
        }

        let parameters: [String: ActionParameterValue] = [
            "WFItems": .dictionary([
                "Value": .dictionary([
                    "WFDictionaryFieldValueItems": .array(fieldItems)
                ]),
                "WFSerializationType": .string("WFDictionaryFieldValue"),
            ])
        ]

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Convenience Extensions

extension DictionaryAction {
    /// Creates an empty dictionary action.
    /// - Parameters:
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured DictionaryAction
    public static func empty(uuid: String? = nil) -> DictionaryAction {
        DictionaryAction(items: [:], uuid: uuid)
    }

    /// Creates a dictionary action from a JSON-like structure.
    /// - Parameters:
    ///   - pairs: Array of key-value tuples
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured DictionaryAction
    public static func from(
        _ pairs: [(String, ActionParameterValue)],
        uuid: String? = nil
    ) -> DictionaryAction {
        DictionaryAction(items: Dictionary(uniqueKeysWithValues: pairs), uuid: uuid)
    }
}
