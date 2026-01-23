// SPDX-License-Identifier: MIT
// ActionCatalogResource.swift - MCP resource for action catalog with progressive disclosure

import Foundation
import MCP

/// MCP resource provider for the action catalog with progressive disclosure.
///
/// Progressive disclosure structure:
/// - `actions://catalog` - Returns category directory (lightweight overview)
/// - `actions://catalog/{category}` - Returns actions in that category
/// - `actions://catalog/{category}/{action}` - Returns full action schema
///
/// This design reduces token usage by allowing LLMs to fetch only what they need.
public enum ActionCatalogResource {
    // MARK: - Resource Definitions

    /// The root catalog resource (category directory)
    public static let catalog = Resource(
        name: "Action Catalog",
        uri: "actions://catalog",
        description:
            "Directory of action categories available for creating shortcuts. Use category URIs for details.",
        mimeType: "application/json"
    )

    // MARK: - Resource Templates

    /// Template for category resources
    public static let categoryTemplate = Resource.Template(
        uriTemplate: "actions://catalog/{category}",
        name: "Action Category",
        description: "List of actions in a specific category with identifiers and descriptions",
        mimeType: "application/json"
    )

    /// Template for action detail resources
    public static let actionTemplate = Resource.Template(
        uriTemplate: "actions://catalog/{category}/{action}",
        name: "Action Details",
        description: "Full parameter schema for a specific action",
        mimeType: "application/json"
    )

    /// All resource templates for progressive disclosure
    public static let templates: [Resource.Template] = [
        categoryTemplate,
        actionTemplate,
    ]

    // MARK: - Resource Loading

    /// Loads content for an action catalog URI
    /// - Parameter uri: The resource URI
    /// - Returns: Resource content, or nil if not a valid catalog URI
    public static func load(uri: String) throws -> Resource.Content? {
        guard uri.hasPrefix("actions://catalog") else {
            return nil
        }

        let path = String(uri.dropFirst("actions://catalog".count))

        // Root catalog - category directory
        if path.isEmpty || path == "/" {
            return loadCategoryDirectory()
        }

        // Parse path components
        let components = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")
            .map(String.init)

        switch components.count {
        case 1:
            // Category resource: /text, /ui, etc.
            let categoryName = components[0]
            return try loadCategory(named: categoryName)

        case 2:
            // Action resource: /text/replace, /ui/alert, etc.
            let categoryName = components[0]
            let actionName = components[1]
            return try loadAction(named: actionName, inCategory: categoryName)

        default:
            return nil
        }
    }

    // MARK: - Category Directory

    /// Loads the category directory (root catalog)
    private static func loadCategoryDirectory() -> Resource.Content {
        let categories = ActionCategory.allCases.map { category in
            CategoryEntry(
                name: category.rawValue,
                description: category.description,
                uri: "actions://catalog/\(category.rawValue)",
                actionCount: ActionRegistry.actionCount(in: category)
            )
        }

        let directory = CategoryDirectory(categories: categories)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = (try? encoder.encode(directory)) ?? Data()
        let json = String(data: data, encoding: .utf8) ?? "{}"

        return .text(json, uri: catalog.uri, mimeType: catalog.mimeType)
    }

    // MARK: - Category Resource

    /// Loads a category resource with action summaries
    private static func loadCategory(named name: String) throws -> Resource.Content {
        guard let category = ActionCategory(rawValue: name) else {
            throw ActionCatalogError.invalidCategory(name)
        }

        let actions = ActionRegistry.actions(in: category)
        let summaries = actions.map { action in
            ActionSummary(
                name: action.name,
                identifier: action.identifier,
                displayName: action.displayName,
                description: action.description,
                uri: "actions://catalog/\(category.rawValue)/\(action.name)"
            )
        }

        let categoryInfo = CategoryInfo(
            name: category.rawValue,
            description: category.description,
            actions: summaries
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = (try? encoder.encode(categoryInfo)) ?? Data()
        let json = String(data: data, encoding: .utf8) ?? "{}"
        let uri = "actions://catalog/\(name)"

        return .text(json, uri: uri, mimeType: "application/json")
    }

    // MARK: - Action Detail Resource

    /// Loads full action details with parameter schema
    private static func loadAction(named name: String, inCategory categoryName: String) throws
        -> Resource.Content
    {
        guard let category = ActionCategory(rawValue: categoryName) else {
            throw ActionCatalogError.invalidCategory(categoryName)
        }

        let actions = ActionRegistry.actions(in: category)
        guard let action = actions.first(where: { $0.name == name }) else {
            throw ActionCatalogError.actionNotFound(name, inCategory: categoryName)
        }

        let detail = ActionDetail(
            name: action.name,
            identifier: action.identifier,
            displayName: action.displayName,
            description: action.description,
            category: action.category.rawValue,
            parameters: action.parameters.map { param in
                ParameterDetail(
                    name: param.name,
                    label: param.label,
                    type: param.type.rawValue,
                    required: param.required,
                    defaultValue: param.defaultValue,
                    description: param.description
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = (try? encoder.encode(detail)) ?? Data()
        let json = String(data: data, encoding: .utf8) ?? "{}"
        let uri = "actions://catalog/\(categoryName)/\(name)"

        return .text(json, uri: uri, mimeType: "application/json")
    }
}

// MARK: - Error Types

/// Errors that can occur when loading action catalog resources
public enum ActionCatalogError: Error, LocalizedError {
    case invalidCategory(String)
    case actionNotFound(String, inCategory: String)

    public var errorDescription: String? {
        switch self {
        case .invalidCategory(let name):
            let validCategories = ActionCategory.allCases.map(\.rawValue).joined(separator: ", ")
            return "Invalid category '\(name)'. Valid categories: \(validCategories)"
        case .actionNotFound(let name, let category):
            return "Action '\(name)' not found in category '\(category)'"
        }
    }
}

// MARK: - Response Models

/// Category directory entry (lightweight)
struct CategoryEntry: Codable, Sendable {
    let name: String
    let description: String
    let uri: String
    let actionCount: Int

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case uri
        case actionCount = "action_count"
    }
}

/// Category directory response
struct CategoryDirectory: Codable, Sendable {
    let categories: [CategoryEntry]
}

/// Action summary (without full parameter details)
struct ActionSummary: Codable, Sendable {
    let name: String
    let identifier: String
    let displayName: String
    let description: String
    let uri: String

    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case displayName = "display_name"
        case description
        case uri
    }
}

/// Category info with action summaries
struct CategoryInfo: Codable, Sendable {
    let name: String
    let description: String
    let actions: [ActionSummary]
}

/// Parameter detail for action schema
struct ParameterDetail: Codable, Sendable {
    let name: String
    let label: String
    let type: String
    let required: Bool
    let defaultValue: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case type
        case required
        case defaultValue = "default_value"
        case description
    }
}

/// Full action detail with parameter schema
struct ActionDetail: Codable, Sendable {
    let name: String
    let identifier: String
    let displayName: String
    let description: String
    let category: String
    let parameters: [ParameterDetail]

    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case displayName = "display_name"
        case description
        case category
        case parameters
    }
}
