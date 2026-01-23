import Foundation
import MCP

/// Tool for accessing shortcut usage history, execution patterns, and user preferences.
///
/// This tool provides read and update access to user profile data including:
/// - User preferences (favorite shortcuts, workflow patterns)
/// - Context information (current projects, focus areas)
/// - Execution statistics and history
public struct ShortcutsUsageTool {
    /// Tool name as registered with MCP
    public static let name = "shortcuts_usage"

    /// Tool definition for MCP registration
    public static let definition = Tool(
        name: name,
        description: """
            Access shortcut usage history, execution patterns, and user preferences. \
            Use for usage analysis, troubleshooting, and storing user preferences.
            """,
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "action": .object([
                    "type": "string",
                    "enum": .array([.string("read"), .string("update")]),
                    "description": "Action to perform: 'read' to get data, 'update' to modify preferences"
                ]),
                "resources": .object([
                    "type": "array",
                    "items": .object([
                        "type": "string",
                        "enum": .array([.string("profile"), .string("shortcuts"), .string("statistics")])
                    ]),
                    "description": "Resources to include: 'profile' for user preferences, 'shortcuts' for available list, 'statistics' for usage data"
                ]),
                "data": .object([
                    "type": "object",
                    "description": "Data to update (for 'update' action)",
                    "properties": .object([
                        "context": .object([
                            "type": "object",
                            "properties": .object([
                                "current-projects": .object([
                                    "type": "array",
                                    "items": .object(["type": "string"])
                                ]),
                                "focus-areas": .object([
                                    "type": "array",
                                    "items": .object(["type": "string"])
                                ])
                            ])
                        ]),
                        "preferences": .object([
                            "type": "object",
                            "properties": .object([
                                "favorite-shortcuts": .object([
                                    "type": "array",
                                    "items": .object(["type": "string"])
                                ]),
                                "workflow-patterns": .object([
                                    "type": "object",
                                    "additionalProperties": .object([
                                        "type": "array",
                                        "items": .object(["type": "string"])
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ]),
            "required": .array([.string("action")])
        ]),
        annotations: Tool.Annotations(
            title: "Shortcuts Usage & Analytics",
            readOnlyHint: false,
            openWorldHint: false
        )
    )

    /// Actions supported by this tool
    public enum Action: String, Codable {
        case read
        case update
    }

    /// Resources that can be requested
    public enum Resource: String, Codable {
        case profile
        case shortcuts
        case statistics
    }

    /// Input for updating profile data
    public struct UpdateData: Codable {
        public var context: UserProfileManager.UserProfile.Context?
        public var preferences: UserProfileManager.UserProfile.Preferences?
    }

    /// Execute the shortcuts_usage tool
    public static func execute(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let arguments else {
            throw MCPError.invalidParams("Missing arguments for \(name)")
        }

        // Parse action
        guard let actionValue = arguments["action"],
              let actionString = actionValue.stringValue,
              let action = Action(rawValue: actionString) else {
            throw MCPError.invalidParams("Missing or invalid 'action' parameter")
        }

        // Parse optional resources
        var resources: [Resource] = []
        if let resourcesValue = arguments["resources"],
           case .array(let resourceArray) = resourcesValue {
            for resourceValue in resourceArray {
                if let resourceString = resourceValue.stringValue,
                   let resource = Resource(rawValue: resourceString) {
                    resources.append(resource)
                }
            }
        }

        let manager = UserProfileManager.shared
        var resultContent: [Tool.Content] = []

        // Handle requested resources
        for resource in resources {
            switch resource {
            case .profile:
                let profile = try await manager.loadUserProfile()
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(profile)
                let json = String(data: data, encoding: .utf8) ?? "{}"
                resultContent.append(.text("User Profile:\n\(json)"))

            case .shortcuts:
                // Use ListShortcutsTool to get available shortcuts
                let result = try await ListShortcutsTool.execute(arguments: nil)
                if let firstContent = result.content.first,
                   case .text(let text) = firstContent {
                    resultContent.append(.text("Available Shortcuts:\n\(text)"))
                }

            case .statistics:
                let stats = try await manager.computeStatistics()
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(stats)
                let json = String(data: data, encoding: .utf8) ?? "{}"
                resultContent.append(.text("Statistics:\n\(json)"))
            }
        }

        // Handle action
        switch action {
        case .read:
            // Just return the requested resources
            if resultContent.isEmpty {
                resultContent.append(.text("No resources requested. Specify 'resources' to get profile, shortcuts, or statistics."))
            }

        case .update:
            // Parse update data
            if let dataValue = arguments["data"] {
                let profile = try parseUpdateData(from: dataValue)
                let updatedProfile = try await manager.saveUserProfile(updates: profile)

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(updatedProfile)
                let json = String(data: data, encoding: .utf8) ?? "{}"

                // Only add profile if not already in resources
                if !resources.contains(.profile) {
                    resultContent.append(.text("Updated Profile:\n\(json)"))
                }
            } else {
                resultContent.append(.text("No data provided for update action."))
            }
        }

        return CallTool.Result(content: resultContent, isError: false)
    }

    /// Parse update data from Value
    private static func parseUpdateData(from value: Value) throws -> UserProfileManager.UserProfile {
        var profile = UserProfileManager.UserProfile()

        guard case .object(let dataObj) = value else {
            return profile
        }

        // Parse context
        if let contextValue = dataObj["context"],
           case .object(let contextObj) = contextValue {
            var context = UserProfileManager.UserProfile.Context()

            if let projectsValue = contextObj["current-projects"],
               case .array(let projectsArray) = projectsValue {
                context.currentProjects = projectsArray.compactMap { $0.stringValue }
            }

            if let focusValue = contextObj["focus-areas"],
               case .array(let focusArray) = focusValue {
                context.focusAreas = focusArray.compactMap { $0.stringValue }
            }

            profile.context = context
        }

        // Parse preferences
        if let prefsValue = dataObj["preferences"],
           case .object(let prefsObj) = prefsValue {
            var preferences = UserProfileManager.UserProfile.Preferences()

            if let favoritesValue = prefsObj["favorite-shortcuts"],
               case .array(let favoritesArray) = favoritesValue {
                preferences.favoriteShortcuts = favoritesArray.compactMap { $0.stringValue }
            }

            if let patternsValue = prefsObj["workflow-patterns"],
               case .object(let patternsObj) = patternsValue {
                var patterns: [String: [String]] = [:]
                for (key, patternValue) in patternsObj {
                    if case .array(let patternArray) = patternValue {
                        patterns[key] = patternArray.compactMap { $0.stringValue }
                    }
                }
                preferences.workflowPatterns = patterns
            }

            profile.preferences = preferences
        }

        return profile
    }
}
