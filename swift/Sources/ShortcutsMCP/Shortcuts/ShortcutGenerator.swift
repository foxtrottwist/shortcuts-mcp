// SPDX-License-Identifier: MIT
// ShortcutGenerator.swift - Service for generating .shortcut files

import Foundation

/// Service for generating macOS/iOS Shortcut files.
///
/// `ShortcutGenerator` takes a configuration and array of actions, builds a
/// complete `Shortcut` struct with proper metadata, serializes it to binary
/// plist format, and writes the result to a `.shortcut` file.
///
/// ## Example Usage
///
/// ```swift
/// let generator = ShortcutGenerator(
///     name: "Hello World",
///     icon: .withColor(red: 255, green: 59, blue: 48) // Red
/// )
///
/// let actions: [any ShortcutAction] = [
///     TextAction("Hello, World!", uuid: "text-uuid"),
///     ShowResultAction(fromActionWithUUID: "text-uuid", outputName: "Text")
/// ]
///
/// let path = try await generator.generate(actions: actions)
/// print("Shortcut saved to: \(path)")
/// ```
public actor ShortcutGenerator {
    // MARK: - Configuration

    /// Configuration options for shortcut generation.
    public struct Configuration: Sendable {
        /// Name of the shortcut (used in metadata)
        public var name: String?

        /// Icon configuration
        public var icon: WorkflowIcon

        /// Accepted input content types
        public var inputContentItemClasses: [InputContentItemClass]

        /// Workflow types (visibility contexts)
        public var workflowTypes: [WorkflowType]

        /// Import questions for user prompts on import
        public var importQuestions: [ImportQuestion]?

        /// Minimum client version (defaults to 900 for iOS 15+)
        public var minimumClientVersion: Int

        /// Minimum client version string
        public var minimumClientVersionString: String

        /// Client version that created this shortcut
        public var clientVersion: Int

        /// Client release semantic version
        public var clientRelease: String?

        /// Creates a new configuration with default values.
        /// - Parameters:
        ///   - name: Optional shortcut name
        ///   - icon: Icon configuration (defaults to blue magic wand)
        ///   - inputContentItemClasses: Accepted input types (defaults to empty)
        ///   - workflowTypes: Visibility contexts (defaults to empty)
        ///   - importQuestions: Optional import prompts
        ///   - minimumClientVersion: Minimum app version (defaults to 900)
        ///   - minimumClientVersionString: Minimum version string (defaults to "900")
        ///   - clientVersion: Client version (defaults to 2614)
        ///   - clientRelease: Optional semantic version
        public init(
            name: String? = nil,
            icon: WorkflowIcon = .default,
            inputContentItemClasses: [InputContentItemClass] = [],
            workflowTypes: [WorkflowType] = [],
            importQuestions: [ImportQuestion]? = nil,
            minimumClientVersion: Int = 900,
            minimumClientVersionString: String = "900",
            clientVersion: Int = 2614,
            clientRelease: String? = nil
        ) {
            self.name = name
            self.icon = icon
            self.inputContentItemClasses = inputContentItemClasses
            self.workflowTypes = workflowTypes
            self.importQuestions = importQuestions
            self.minimumClientVersion = minimumClientVersion
            self.minimumClientVersionString = minimumClientVersionString
            self.clientVersion = clientVersion
            self.clientRelease = clientRelease
        }

        /// Creates a configuration for a Menu Bar shortcut.
        /// - Parameters:
        ///   - name: Shortcut name
        ///   - icon: Icon configuration
        public static func menuBar(name: String, icon: WorkflowIcon = .default) -> Configuration {
            Configuration(
                name: name,
                icon: icon,
                workflowTypes: [.menuBar]
            )
        }

        /// Creates a configuration for a Quick Actions shortcut.
        /// - Parameters:
        ///   - name: Shortcut name
        ///   - icon: Icon configuration
        ///   - inputTypes: Accepted input content types
        public static func quickActions(
            name: String,
            icon: WorkflowIcon = .default,
            inputTypes: [InputContentItemClass] = []
        ) -> Configuration {
            Configuration(
                name: name,
                icon: icon,
                inputContentItemClasses: inputTypes,
                workflowTypes: [.quickActions]
            )
        }

        /// Creates a configuration for a Notification Center widget shortcut.
        /// - Parameters:
        ///   - name: Shortcut name
        ///   - icon: Icon configuration
        public static func widget(name: String, icon: WorkflowIcon = .default) -> Configuration {
            Configuration(
                name: name,
                icon: icon,
                workflowTypes: [.notificationCenter]
            )
        }
    }

    // MARK: - Properties

    /// The generator configuration
    public let configuration: Configuration

    /// Directory for output files (defaults to system temp directory)
    public let outputDirectory: URL

    // MARK: - Initialization

    /// Creates a new shortcut generator with the specified configuration.
    /// - Parameters:
    ///   - configuration: Generator configuration
    ///   - outputDirectory: Directory for output files (defaults to temp directory)
    public init(
        configuration: Configuration = Configuration(),
        outputDirectory: URL? = nil
    ) {
        self.configuration = configuration
        self.outputDirectory = outputDirectory ?? URL.temporaryDirectory
    }

    /// Creates a new shortcut generator with basic options.
    /// - Parameters:
    ///   - name: Shortcut name
    ///   - icon: Icon configuration (defaults to blue magic wand)
    ///   - outputDirectory: Directory for output files (defaults to temp directory)
    public init(
        name: String? = nil,
        icon: WorkflowIcon = .default,
        outputDirectory: URL? = nil
    ) {
        self.configuration = Configuration(name: name, icon: icon)
        self.outputDirectory = outputDirectory ?? URL.temporaryDirectory
    }

    // MARK: - Generation

    /// Errors that can occur during shortcut generation.
    public enum GenerationError: Error, LocalizedError {
        case emptyActions
        case encodingFailed(Error)
        case writeFailed(Error)
        case directoryCreationFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .emptyActions:
                return "Cannot generate a shortcut with no actions"
            case let .encodingFailed(error):
                return "Failed to encode shortcut: \(error.localizedDescription)"
            case let .writeFailed(error):
                return "Failed to write shortcut file: \(error.localizedDescription)"
            case let .directoryCreationFailed(error):
                return "Failed to create output directory: \(error.localizedDescription)"
            }
        }
    }

    /// Result of shortcut generation.
    public struct GenerationResult: Sendable {
        /// Path to the generated .shortcut file
        public let filePath: URL

        /// Size of the generated file in bytes
        public let fileSize: Int

        /// The generated shortcut (for inspection)
        public let shortcut: Shortcut
    }

    /// Generates a shortcut file from the given actions.
    /// - Parameter actions: Array of shortcut actions (must not be empty)
    /// - Returns: Generation result with file path and metadata
    /// - Throws: `GenerationError` if generation fails
    public func generate(actions: [any ShortcutAction]) async throws -> GenerationResult {
        guard !actions.isEmpty else {
            throw GenerationError.emptyActions
        }

        // Convert actions to WorkflowActions
        let workflowActions = actions.map { $0.toWorkflowAction() }

        // Build the shortcut
        let shortcut = buildShortcut(actions: workflowActions)

        // Encode to plist
        let data: Data
        do {
            data = try shortcut.encodeToPlist()
        } catch {
            throw GenerationError.encodingFailed(error)
        }

        // Ensure output directory exists
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw GenerationError.directoryCreationFailed(error)
        }

        // Generate filename
        let filename = generateFilename()
        let filePath = outputDirectory.appending(path: filename)

        // Write to file
        do {
            try data.write(to: filePath)
        } catch {
            throw GenerationError.writeFailed(error)
        }

        return GenerationResult(
            filePath: filePath,
            fileSize: data.count,
            shortcut: shortcut
        )
    }

    /// Generates a shortcut file from WorkflowAction objects directly.
    /// - Parameter actions: Array of workflow actions (must not be empty)
    /// - Returns: Generation result with file path and metadata
    /// - Throws: `GenerationError` if generation fails
    public func generate(workflowActions actions: [WorkflowAction]) async throws -> GenerationResult
    {
        guard !actions.isEmpty else {
            throw GenerationError.emptyActions
        }

        // Build the shortcut
        let shortcut = buildShortcut(actions: actions)

        // Encode to plist
        let data: Data
        do {
            data = try shortcut.encodeToPlist()
        } catch {
            throw GenerationError.encodingFailed(error)
        }

        // Ensure output directory exists
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw GenerationError.directoryCreationFailed(error)
        }

        // Generate filename
        let filename = generateFilename()
        let filePath = outputDirectory.appending(path: filename)

        // Write to file
        do {
            try data.write(to: filePath)
        } catch {
            throw GenerationError.writeFailed(error)
        }

        return GenerationResult(
            filePath: filePath,
            fileSize: data.count,
            shortcut: shortcut
        )
    }

    /// Builds a Shortcut struct without writing to disk.
    /// - Parameter actions: Array of shortcut actions
    /// - Returns: The built Shortcut
    public func buildShortcut(actions: [any ShortcutAction]) -> Shortcut {
        let workflowActions = actions.map { $0.toWorkflowAction() }
        return buildShortcut(actions: workflowActions)
    }

    // MARK: - Private Helpers

    /// Builds a Shortcut struct from configuration and actions.
    private func buildShortcut(actions: [WorkflowAction]) -> Shortcut {
        Shortcut(
            name: configuration.name,
            icon: configuration.icon,
            actions: actions,
            inputContentItemClasses: configuration.inputContentItemClasses.map(\.rawValue),
            types: configuration.workflowTypes.map(\.rawValue),
            minimumClientVersion: configuration.minimumClientVersion,
            minimumClientVersionString: configuration.minimumClientVersionString,
            clientVersion: configuration.clientVersion,
            clientRelease: configuration.clientRelease,
            importQuestions: configuration.importQuestions
        )
    }

    /// Generates a unique filename for the shortcut.
    private func generateFilename() -> String {
        let baseName = configuration.name ?? "Shortcut"
        let sanitized = sanitizeFilename(baseName)
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(sanitized)-\(timestamp).shortcut"
    }

    /// Sanitizes a string for use as a filename.
    private func sanitizeFilename(_ name: String) -> String {
        // Remove or replace invalid filename characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let components = name.unicodeScalars.filter { !invalidCharacters.contains($0) }
        var result = String(String.UnicodeScalarView(components))

        // Replace spaces with hyphens
        result = result.replacingOccurrences(of: " ", with: "-")

        // Limit length
        if result.count > 50 {
            result = String(result.prefix(50))
        }

        // Ensure non-empty
        if result.isEmpty {
            result = "Shortcut"
        }

        return result
    }
}

// MARK: - Convenience Methods

extension ShortcutGenerator {
    /// Generates a simple "Hello World" shortcut.
    /// - Returns: Generation result
    public static func generateHelloWorld(
        outputDirectory: URL? = nil
    ) async throws -> GenerationResult {
        let generator = ShortcutGenerator(
            name: "Hello World",
            icon: .withColor(red: 255, green: 59, blue: 48, glyphNumber: 59511),  // Red with document
            outputDirectory: outputDirectory
        )

        let textUUID = UUID().uuidString
        let actions: [any ShortcutAction] = [
            TextAction("Hello, World!", uuid: textUUID),
            ShowResultAction(fromActionWithUUID: textUUID, outputName: "Text"),
        ]

        return try await generator.generate(actions: actions)
    }

    /// Generates a shortcut that fetches data from a URL.
    /// - Parameters:
    ///   - name: Shortcut name
    ///   - url: URL to fetch
    ///   - outputDirectory: Output directory
    /// - Returns: Generation result
    public static func generateURLFetch(
        name: String,
        url: String,
        outputDirectory: URL? = nil
    ) async throws -> GenerationResult {
        let generator = ShortcutGenerator(
            name: name,
            icon: .withColor(red: 52, green: 199, blue: 89, glyphNumber: 59684),  // Green with globe
            outputDirectory: outputDirectory
        )

        let urlUUID = UUID().uuidString
        let actions: [any ShortcutAction] = [
            URLAction.get(url, uuid: urlUUID),
            ShowResultAction(fromActionWithUUID: urlUUID, outputName: "Contents of URL"),
        ]

        return try await generator.generate(actions: actions)
    }
}
