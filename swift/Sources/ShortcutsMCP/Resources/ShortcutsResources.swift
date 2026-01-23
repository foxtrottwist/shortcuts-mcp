import Foundation
import MCP

/// Registry of all resources exposed by the Shortcuts MCP server.
///
/// Resources provide contextual information to LLMs about available shortcuts,
/// user preferences, system state, and execution history.
public enum ShortcutsResources {
    /// All available resource definitions
    public static let all: [Resource] = [
        availableShortcuts,
        systemState,
        userProfile,
        statistics,
    ]

    /// All available resource templates
    public static let templates: [Resource.Template] = [
        shortcutRuns,
    ]

    // MARK: - Resource Definitions

    /// Available shortcuts with names and identifiers for discovery and validation.
    public static let availableShortcuts = Resource(
        name: "Current shortcuts list",
        uri: "shortcuts://available",
        description: "Available shortcuts with names and identifiers for discovery and validation.",
        mimeType: "text/plain"
    )

    /// Current system time, timezone, and timestamp for time-based analysis.
    public static let systemState = Resource(
        name: "Live system state",
        uri: "context://system/current",
        description: "Current system time, timezone, and timestamp for time-based analysis.",
        mimeType: "application/json"
    )

    /// User preferences including favorite shortcuts, workflow patterns, and contextual information.
    public static let userProfile = Resource(
        name: "User preferences & usage patterns",
        uri: "context://user/profile",
        description: "User preferences including favorite shortcuts, workflow patterns, and contextual information.",
        mimeType: "application/json"
    )

    /// AI-generated execution statistics including success rates, timing analysis, and per-shortcut performance data.
    public static let statistics = Resource(
        name: "Execution statistics & insights",
        uri: "statistics://generated",
        description: "AI-generated execution statistics including success rates, timing analysis, and per-shortcut performance data.",
        mimeType: "application/json"
    )

    // MARK: - Resource Templates

    /// Execution history for a specific shortcut including success rates, timing patterns, and usage frequency.
    public static let shortcutRuns = Resource.Template(
        uriTemplate: "shortcuts://runs/{name}",
        name: "Per-shortcut execution data",
        description: "Execution history for a specific shortcut including success rates, timing patterns, and usage frequency.",
        mimeType: "text/plain"
    )

    // MARK: - Resource Loading

    /// Loads the content for a resource URI
    /// - Parameter uri: The resource URI to load
    /// - Returns: The resource content, or nil if not found
    public static func load(uri: String) async throws -> Resource.Content? {
        switch uri {
        case availableShortcuts.uri:
            return try await loadAvailableShortcuts()

        case systemState.uri:
            return loadSystemState()

        case userProfile.uri:
            return try await loadUserProfile()

        case statistics.uri:
            return try await loadStatistics()

        default:
            // Check if it matches the shortcuts://runs/{name} template
            if uri.hasPrefix("shortcuts://runs/") {
                let name = String(uri.dropFirst("shortcuts://runs/".count))
                return try await loadShortcutRuns(name: name)
            }
            return nil
        }
    }

    // MARK: - Private Loaders

    private static func loadAvailableShortcuts() async throws -> Resource.Content {
        // Use ListShortcutsTool to get cached shortcuts list
        let result = try await ListShortcutsTool.execute(arguments: nil)

        // Extract text from the result
        var text = ""
        for content in result.content {
            if case .text(let textContent) = content {
                text = textContent
                break
            }
        }

        return .text(text, uri: availableShortcuts.uri, mimeType: availableShortcuts.mimeType)
    }

    private static func loadSystemState() -> Resource.Content {
        let state = UserProfileManager.SystemState()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(state)
            let json = String(data: data, encoding: .utf8) ?? "{}"
            return .text(json, uri: systemState.uri, mimeType: systemState.mimeType)
        } catch {
            return .text("{}", uri: systemState.uri, mimeType: systemState.mimeType)
        }
    }

    private static func loadUserProfile() async throws -> Resource.Content {
        let profile = try await UserProfileManager.shared.loadUserProfile()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return .text(json, uri: userProfile.uri, mimeType: userProfile.mimeType)
    }

    private static func loadStatistics() async throws -> Resource.Content {
        let stats = try await UserProfileManager.shared.computeStatistics()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(stats)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return .text(json, uri: statistics.uri, mimeType: statistics.mimeType)
    }

    private static func loadShortcutRuns(name: String) async throws -> Resource.Content {
        let uri = "shortcuts://runs/\(name)"
        let (_, executions) = try await UserProfileManager.shared.loadExecutions()

        // Filter executions for this specific shortcut
        let shortcutExecutions = executions.filter { $0.shortcut == name }

        guard !shortcutExecutions.isEmpty else {
            return .text("No execution history for shortcut: \(name)", uri: uri, mimeType: "text/plain")
        }

        // Build summary
        let total = shortcutExecutions.count
        let successes = shortcutExecutions.filter { $0.success }.count
        let successRate = Double(successes) / Double(total) * 100
        let durations = shortcutExecutions.map { $0.duration }
        let avgDuration = durations.reduce(0, +) / durations.count

        var text = """
            Shortcut: \(name)
            Total executions: \(total)
            Successes: \(successes)
            Failures: \(total - successes)
            Success rate: \(String(format: "%.1f", successRate))%
            Average duration: \(avgDuration)ms

            Recent executions:
            """

        // Add last 10 executions
        for execution in shortcutExecutions.suffix(10) {
            let status = execution.success ? "SUCCESS" : "FAILED"
            text += "\n- [\(status)] \(execution.timestamp) (\(execution.duration)ms)"
        }

        return .text(text, uri: uri, mimeType: "text/plain")
    }
}
