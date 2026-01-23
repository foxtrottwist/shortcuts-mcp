import Foundation

/// An actor that manages user profile data including preferences, execution history, and statistics.
///
/// UserProfileManager provides thread-safe access to user data stored at ~/.shortcuts-mcp/.
/// It handles profile storage, execution tracking, and statistics computation.
public actor UserProfileManager {
    /// Shared instance for global access
    public static let shared = UserProfileManager()

    // MARK: - File Paths

    /// Base directory for all user data
    private let dataDirectory: URL

    /// Path to user profile JSON file
    private let userProfilePath: URL

    /// Path to executions directory
    private let executionsDirectory: URL

    /// Path to statistics JSON file
    private let statisticsPath: URL

    // MARK: - Initialization

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.dataDirectory = home.appending(path: ".shortcuts-mcp")
        self.userProfilePath = dataDirectory.appending(path: "user-profile.json")
        self.executionsDirectory = dataDirectory.appending(path: "executions")
        self.statisticsPath = dataDirectory.appending(path: "statistics.json")
    }

    // MARK: - Data Models

    /// User profile containing preferences and context
    public struct UserProfile: Codable, Sendable {
        public var context: Context?
        public var preferences: Preferences?

        public struct Context: Codable, Sendable {
            public var currentProjects: [String]?
            public var focusAreas: [String]?

            enum CodingKeys: String, CodingKey {
                case currentProjects = "current-projects"
                case focusAreas = "focus-areas"
            }

            public init(currentProjects: [String]? = nil, focusAreas: [String]? = nil) {
                self.currentProjects = currentProjects
                self.focusAreas = focusAreas
            }
        }

        public struct Preferences: Codable, Sendable {
            public var favoriteShortcuts: [String]?
            public var workflowPatterns: [String: [String]]?

            enum CodingKeys: String, CodingKey {
                case favoriteShortcuts = "favorite-shortcuts"
                case workflowPatterns = "workflow-patterns"
            }

            public init(favoriteShortcuts: [String]? = nil, workflowPatterns: [String: [String]]? = nil) {
                self.favoriteShortcuts = favoriteShortcuts
                self.workflowPatterns = workflowPatterns
            }
        }

        public init(context: Context? = nil, preferences: Preferences? = nil) {
            self.context = context
            self.preferences = preferences
        }
    }

    /// A single shortcut execution record
    public struct ShortcutExecution: Codable, Sendable {
        public let shortcut: String
        public let success: Bool
        public let duration: Int
        public let timestamp: String

        public init(shortcut: String, success: Bool, duration: Int, timestamp: String) {
            self.shortcut = shortcut
            self.success = success
            self.duration = duration
            self.timestamp = timestamp
        }
    }

    /// Computed statistics for shortcut usage
    public struct ShortcutStatistics: Codable, Sendable {
        public var generatedAt: String?
        public var executions: ExecutionCounts?
        public var timing: TimingStats?
        public var perShortcut: [String: PerShortcutStats]?

        public struct ExecutionCounts: Codable, Sendable {
            public var total: Int
            public var successes: Int
            public var failures: Int
            public var unknown: Int

            public init(total: Int = 0, successes: Int = 0, failures: Int = 0, unknown: Int = 0) {
                self.total = total
                self.successes = successes
                self.failures = failures
                self.unknown = unknown
            }
        }

        public struct TimingStats: Codable, Sendable {
            public var average: Int
            public var min: Int
            public var max: Int

            public init(average: Int = 0, min: Int = 0, max: Int = 0) {
                self.average = average
                self.min = min
                self.max = max
            }
        }

        public struct PerShortcutStats: Codable, Sendable {
            public var count: Int
            public var successRate: Double
            public var avgDuration: Int

            enum CodingKeys: String, CodingKey {
                case count
                case successRate = "success-rate"
                case avgDuration = "avg-duration"
            }

            public init(count: Int = 0, successRate: Double = 0.0, avgDuration: Int = 0) {
                self.count = count
                self.successRate = successRate
                self.avgDuration = avgDuration
            }
        }

        enum CodingKeys: String, CodingKey {
            case generatedAt
            case executions
            case timing
            case perShortcut = "per-shortcut"
        }

        public init() {}
    }

    /// System state information
    public struct SystemState: Codable, Sendable {
        public let timestamp: String
        public let localTime: String
        public let timezone: String
        public let hour: Int
        public let dayOfWeek: Int

        public init() {
            let now = Date()
            let calendar = Calendar.current
            let dateFormatter = ISO8601DateFormatter()
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
            localFormatter.timeStyle = .medium

            self.timestamp = dateFormatter.string(from: now)
            self.localTime = localFormatter.string(from: now)
            self.timezone = TimeZone.current.identifier
            self.hour = calendar.component(.hour, from: now)
            self.dayOfWeek = calendar.component(.weekday, from: now) - 1  // 0-indexed like JS
        }
    }

    // MARK: - Directory Management

    /// Ensures the data directory structure exists
    public func ensureDataDirectory() throws {
        let fm = FileManager.default

        // Create main data directory
        if !fm.fileExists(atPath: dataDirectory.path) {
            try fm.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        }

        // Create executions subdirectory
        if !fm.fileExists(atPath: executionsDirectory.path) {
            try fm.createDirectory(at: executionsDirectory, withIntermediateDirectories: true)
        }

        // Create empty profile file if needed
        if !fm.fileExists(atPath: userProfilePath.path) {
            try Data("{}".utf8).write(to: userProfilePath)
        }

        // Create empty statistics file if needed
        if !fm.fileExists(atPath: statisticsPath.path) {
            try Data("{}".utf8).write(to: statisticsPath)
        }
    }

    // MARK: - Profile Operations

    /// Loads the user profile from disk
    public func loadUserProfile() throws -> UserProfile {
        let fm = FileManager.default

        if !fm.fileExists(atPath: userProfilePath.path) {
            try ensureDataDirectory()
            return UserProfile()
        }

        let data = try Data(contentsOf: userProfilePath)
        let decoder = JSONDecoder()
        return try decoder.decode(UserProfile.self, from: data)
    }

    /// Saves updates to the user profile (merging with existing data)
    public func saveUserProfile(updates: UserProfile) throws -> UserProfile {
        var profile = try loadUserProfile()

        // Merge context updates
        if let newContext = updates.context {
            if profile.context == nil {
                profile.context = UserProfile.Context()
            }
            if let projects = newContext.currentProjects {
                profile.context?.currentProjects = projects
            }
            if let focusAreas = newContext.focusAreas {
                profile.context?.focusAreas = focusAreas
            }
        }

        // Merge preferences updates
        if let newPrefs = updates.preferences {
            if profile.preferences == nil {
                profile.preferences = UserProfile.Preferences()
            }
            if let favorites = newPrefs.favoriteShortcuts {
                profile.preferences?.favoriteShortcuts = favorites
            }
            if let patterns = newPrefs.workflowPatterns {
                // Merge workflow patterns
                if profile.preferences?.workflowPatterns == nil {
                    profile.preferences?.workflowPatterns = [:]
                }
                for (key, value) in patterns {
                    profile.preferences?.workflowPatterns?[key] = value
                }
            }
        }

        // Write to disk
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        try data.write(to: userProfilePath)

        return profile
    }

    // MARK: - Execution Tracking

    /// Records a shortcut execution
    public func recordExecution(shortcut: String, success: Bool, duration: Int) throws {
        try ensureDataDirectory()

        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: now)

        // Get the date string for the filename (YYYY-MM-DD)
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        let dateString = String(format: "%04d-%02d-%02d", year, month, day)
        let filename = "\(dateString).json"
        let filePath = executionsDirectory.appending(path: filename)

        let execution = ShortcutExecution(
            shortcut: shortcut,
            success: success,
            duration: duration,
            timestamp: timestamp
        )

        // Load existing executions for today
        var executions: [ShortcutExecution]
        if FileManager.default.fileExists(atPath: filePath.path) {
            let data = try Data(contentsOf: filePath)
            executions = try JSONDecoder().decode([ShortcutExecution].self, from: data)
        } else {
            executions = []
        }

        // Append new execution
        executions.append(execution)

        // Write back
        let encoder = JSONEncoder()
        let data = try encoder.encode(executions)
        try data.write(to: filePath)
    }

    /// Loads all executions from the executions directory
    public func loadExecutions() throws -> (days: Int, executions: [ShortcutExecution]) {
        let fm = FileManager.default

        if !fm.fileExists(atPath: executionsDirectory.path) {
            try ensureDataDirectory()
            return (days: 0, executions: [])
        }

        let contents = try fm.contentsOfDirectory(atPath: executionsDirectory.path)
        let datePattern = /^\d{4}-\d{2}-\d{2}\.json$/

        let jsonFiles = contents
            .filter { $0.wholeMatch(of: datePattern) != nil }
            .sorted(by: >)  // Most recent first

        var allExecutions: [ShortcutExecution] = []

        for file in jsonFiles {
            let filePath = executionsDirectory.appending(path: file)
            do {
                let data = try Data(contentsOf: filePath)
                let executions = try JSONDecoder().decode([ShortcutExecution].self, from: data)
                allExecutions.append(contentsOf: executions)
            } catch {
                // Skip unreadable files
                continue
            }
        }

        return (days: jsonFiles.count, executions: allExecutions)
    }

    // MARK: - Statistics

    /// Loads statistics from disk
    public func loadStatistics() throws -> ShortcutStatistics {
        let fm = FileManager.default

        if !fm.fileExists(atPath: statisticsPath.path) {
            try ensureDataDirectory()
            return ShortcutStatistics()
        }

        let data = try Data(contentsOf: statisticsPath)
        return try JSONDecoder().decode(ShortcutStatistics.self, from: data)
    }

    /// Saves statistics to disk
    public func saveStatistics(_ stats: ShortcutStatistics) throws -> ShortcutStatistics {
        var updatedStats = stats
        updatedStats.generatedAt = ISO8601DateFormatter().string(from: Date())

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(updatedStats)
        try data.write(to: statisticsPath)

        return updatedStats
    }

    /// Computes statistics from execution history
    public func computeStatistics() throws -> ShortcutStatistics {
        let (_, executions) = try loadExecutions()

        guard !executions.isEmpty else {
            return ShortcutStatistics()
        }

        var stats = ShortcutStatistics()
        stats.generatedAt = ISO8601DateFormatter().string(from: Date())

        // Compute execution counts
        let successes = executions.filter { $0.success }.count
        let failures = executions.count - successes
        stats.executions = ShortcutStatistics.ExecutionCounts(
            total: executions.count,
            successes: successes,
            failures: failures,
            unknown: 0
        )

        // Compute timing stats
        let durations = executions.map { $0.duration }
        let total = durations.reduce(0, +)
        let average = durations.isEmpty ? 0 : total / durations.count
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0
        stats.timing = ShortcutStatistics.TimingStats(
            average: average,
            min: minDuration,
            max: maxDuration
        )

        // Compute per-shortcut stats
        var perShortcut: [String: ShortcutStatistics.PerShortcutStats] = [:]
        var shortcutExecutions: [String: [ShortcutExecution]] = [:]

        for exec in executions {
            shortcutExecutions[exec.shortcut, default: []].append(exec)
        }

        for (shortcutName, execs) in shortcutExecutions {
            let count = execs.count
            let successes = execs.filter { $0.success }.count
            let successRate = count > 0 ? Double(successes) / Double(count) : 0.0
            let totalDuration = execs.map { $0.duration }.reduce(0, +)
            let avgDuration = count > 0 ? totalDuration / count : 0

            perShortcut[shortcutName] = ShortcutStatistics.PerShortcutStats(
                count: count,
                successRate: successRate,
                avgDuration: avgDuration
            )
        }

        stats.perShortcut = perShortcut

        return stats
    }

    // MARK: - System State

    /// Returns current system state information
    public func getSystemState() -> SystemState {
        SystemState()
    }
}
