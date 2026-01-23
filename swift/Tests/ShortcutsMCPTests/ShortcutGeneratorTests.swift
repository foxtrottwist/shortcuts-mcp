// SPDX-License-Identifier: MIT
// ShortcutGeneratorTests.swift - Tests for ShortcutGenerator service

import Foundation
import Testing

@testable import ShortcutsMCP

@Suite("ShortcutGenerator Tests")
struct ShortcutGeneratorTests {
    // MARK: - Configuration Tests

    @Test("Configuration defaults to sensible values")
    func testConfigurationDefaults() {
        let config = ShortcutGenerator.Configuration()

        #expect(config.name == nil)
        #expect(config.icon == .default)
        #expect(config.inputContentItemClasses.isEmpty)
        #expect(config.workflowTypes.isEmpty)
        #expect(config.minimumClientVersion == 900)
        #expect(config.minimumClientVersionString == "900")
        #expect(config.clientVersion == 2614)
    }

    @Test("Configuration can be customized")
    func testConfigurationCustomization() {
        let config = ShortcutGenerator.Configuration(
            name: "Test Shortcut",
            icon: .withColor(red: 255, green: 0, blue: 0),
            inputContentItemClasses: [.string, .url],
            workflowTypes: [.menuBar, .quickActions],
            minimumClientVersion: 1000,
            clientVersion: 3000
        )

        #expect(config.name == "Test Shortcut")
        #expect(config.inputContentItemClasses == [.string, .url])
        #expect(config.workflowTypes == [.menuBar, .quickActions])
        #expect(config.minimumClientVersion == 1000)
        #expect(config.clientVersion == 3000)
    }

    @Test("Configuration.menuBar creates menu bar shortcut config")
    func testMenuBarConfiguration() {
        let config = ShortcutGenerator.Configuration.menuBar(name: "Menu Shortcut")

        #expect(config.name == "Menu Shortcut")
        #expect(config.workflowTypes == [.menuBar])
    }

    @Test("Configuration.quickActions creates quick actions config")
    func testQuickActionsConfiguration() {
        let config = ShortcutGenerator.Configuration.quickActions(
            name: "Quick Action",
            inputTypes: [.string, .file]
        )

        #expect(config.name == "Quick Action")
        #expect(config.workflowTypes == [.quickActions])
        #expect(config.inputContentItemClasses == [.string, .file])
    }

    @Test("Configuration.widget creates notification center config")
    func testWidgetConfiguration() {
        let config = ShortcutGenerator.Configuration.widget(name: "Widget Shortcut")

        #expect(config.name == "Widget Shortcut")
        #expect(config.workflowTypes == [.notificationCenter])
    }

    // MARK: - Initialization Tests

    @Test("Generator initializes with default configuration")
    func testGeneratorDefaultInit() async {
        let generator = ShortcutGenerator()
        let config = await generator.configuration
        let outputDir = await generator.outputDirectory

        #expect(config.name == nil)
        #expect(outputDir == URL.temporaryDirectory)
    }

    @Test("Generator initializes with name and icon")
    func testGeneratorNameIconInit() async {
        let generator = ShortcutGenerator(
            name: "My Shortcut",
            icon: .withColor(red: 100, green: 150, blue: 200)
        )
        let config = await generator.configuration

        #expect(config.name == "My Shortcut")
    }

    @Test("Generator initializes with custom output directory")
    func testGeneratorCustomOutputDirectory() async {
        let customDir = URL.temporaryDirectory.appending(path: "custom-shortcuts")
        let generator = ShortcutGenerator(
            name: "Test",
            outputDirectory: customDir
        )
        let outputDir = await generator.outputDirectory

        #expect(outputDir == customDir)
    }

    // MARK: - Generation Tests

    @Test("Generator generates shortcut file from ShortcutActions")
    func testGenerateFromShortcutActions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "shortcut-gen-test-\(UUID().uuidString)")
        let generator = ShortcutGenerator(
            name: "Test Shortcut",
            outputDirectory: tempDir
        )

        let textUUID = UUID().uuidString
        let actions: [any ShortcutAction] = [
            TextAction("Hello", uuid: textUUID),
            ShowResultAction(fromActionWithUUID: textUUID),
        ]

        let result = try await generator.generate(actions: actions)

        // Verify result
        #expect(result.fileSize > 0)
        #expect(result.shortcut.name == "Test Shortcut")
        #expect(result.shortcut.actions.count == 2)

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Verify filename pattern
        #expect(result.filePath.lastPathComponent.hasPrefix("Test-Shortcut-"))
        #expect(result.filePath.pathExtension == "shortcut")

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("Generator generates shortcut file from WorkflowActions")
    func testGenerateFromWorkflowActions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "shortcut-gen-test-\(UUID().uuidString)")
        let generator = ShortcutGenerator(
            name: "Workflow Test",
            outputDirectory: tempDir
        )

        let actions = [
            WorkflowAction.text("Hello"),
            WorkflowAction.showResult("Result"),
        ]

        let result = try await generator.generate(workflowActions: actions)

        #expect(result.fileSize > 0)
        #expect(result.shortcut.actions.count == 2)
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("Generator throws error for empty actions")
    func testGenerateEmptyActionsThrows() async throws {
        let generator = ShortcutGenerator(name: "Empty")

        do {
            _ = try await generator.generate(actions: [] as [TextAction])
            Issue.record("Expected GenerationError.emptyActions")
        } catch let error as ShortcutGenerator.GenerationError {
            guard case .emptyActions = error else {
                Issue.record("Expected emptyActions error, got \(error)")
                return
            }
        }
    }

    @Test("Generator builds shortcut with proper metadata")
    func testBuildShortcutMetadata() async {
        let config = ShortcutGenerator.Configuration(
            name: "Metadata Test",
            icon: .withColor(red: 255, green: 100, blue: 50, glyphNumber: 59500),
            inputContentItemClasses: [.string, .url],
            workflowTypes: [.menuBar],
            minimumClientVersion: 1000,
            minimumClientVersionString: "1000",
            clientVersion: 3000
        )
        let generator = ShortcutGenerator(configuration: config)

        let actions = [TextAction("Test")]
        let shortcut = await generator.buildShortcut(actions: actions)

        #expect(shortcut.name == "Metadata Test")
        #expect(shortcut.icon.glyphNumber == 59500)
        #expect(shortcut.inputContentItemClasses == ["WFStringContentItem", "WFURLContentItem"])
        #expect(shortcut.types == ["MenuBar"])
        #expect(shortcut.minimumClientVersion == 1000)
        #expect(shortcut.clientVersion == 3000)
    }

    @Test("Generator creates output directory if it doesn't exist")
    func testCreateOutputDirectory() async throws {
        let uniqueDir = FileManager.default.temporaryDirectory.appending(
            path: "shortcut-gen-new-dir-\(UUID().uuidString)")

        // Ensure directory doesn't exist
        #expect(!FileManager.default.fileExists(atPath: uniqueDir.path))

        let generator = ShortcutGenerator(
            name: "Dir Test",
            outputDirectory: uniqueDir
        )

        _ = try await generator.generate(actions: [TextAction("Test")])

        // Directory should now exist
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: uniqueDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)

        // Clean up
        try? FileManager.default.removeItem(at: uniqueDir)
    }

    @Test("Generated file can be decoded back to Shortcut")
    func testGeneratedFileRoundtrip() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "shortcut-roundtrip-\(UUID().uuidString)")
        let generator = ShortcutGenerator(
            name: "Roundtrip Test",
            icon: .withColor(red: 128, green: 200, blue: 64),
            outputDirectory: tempDir
        )

        let textUUID = UUID().uuidString
        let actions: [any ShortcutAction] = [
            TextAction("Hello Roundtrip", uuid: textUUID, customOutputName: "Greeting"),
            ShowResultAction(fromActionWithUUID: textUUID, outputName: "Greeting"),
        ]

        let result = try await generator.generate(actions: actions)

        // Read and decode the file
        let fileData = try Data(contentsOf: result.filePath)
        let decoded = try Shortcut.decode(from: fileData)

        #expect(decoded.name == "Roundtrip Test")
        #expect(decoded.actions.count == 2)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(decoded.actions[0].uuid == textUUID)
        #expect(decoded.actions[1].identifier == "is.workflow.actions.showresult")

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Convenience Method Tests

    @Test("generateHelloWorld creates valid Hello World shortcut")
    func testGenerateHelloWorld() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "hello-world-\(UUID().uuidString)")

        let result = try await ShortcutGenerator.generateHelloWorld(outputDirectory: tempDir)

        #expect(result.shortcut.name == "Hello World")
        #expect(result.shortcut.actions.count == 2)
        #expect(result.shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(result.shortcut.actions[1].identifier == "is.workflow.actions.showresult")
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("generateURLFetch creates valid URL fetch shortcut")
    func testGenerateURLFetch() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "url-fetch-\(UUID().uuidString)")

        let result = try await ShortcutGenerator.generateURLFetch(
            name: "Fetch Data",
            url: "https://api.example.com/data",
            outputDirectory: tempDir
        )

        #expect(result.shortcut.name == "Fetch Data")
        #expect(result.shortcut.actions.count == 2)
        #expect(result.shortcut.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(result.shortcut.actions[0].parameters["WFURL"] == .string("https://api.example.com/data"))
        #expect(result.shortcut.actions[1].identifier == "is.workflow.actions.showresult")
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Filename Sanitization Tests

    @Test("Filename sanitization removes invalid characters")
    func testFilenameSanitization() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "sanitize-test-\(UUID().uuidString)")
        let generator = ShortcutGenerator(
            name: "Test/Name:With*Invalid<Characters>",
            outputDirectory: tempDir
        )

        let result = try await generator.generate(actions: [TextAction("Test")])

        // Filename should not contain invalid characters
        let filename = result.filePath.lastPathComponent
        #expect(!filename.contains("/"))
        #expect(!filename.contains(":"))
        #expect(!filename.contains("*"))
        #expect(!filename.contains("<"))
        #expect(!filename.contains(">"))
        #expect(filename.hasSuffix(".shortcut"))

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("Filename sanitization replaces spaces with hyphens")
    func testFilenameSanitizationSpaces() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "space-test-\(UUID().uuidString)")
        let generator = ShortcutGenerator(
            name: "My Shortcut Name",
            outputDirectory: tempDir
        )

        let result = try await generator.generate(actions: [TextAction("Test")])

        let filename = result.filePath.lastPathComponent
        #expect(filename.hasPrefix("My-Shortcut-Name-"))
        #expect(!filename.contains(" "))

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Error Handling Tests

    @Test("GenerationError has descriptive messages")
    func testGenerationErrorMessages() {
        let emptyError = ShortcutGenerator.GenerationError.emptyActions
        #expect(emptyError.localizedDescription.contains("no actions"))

        let writeError = ShortcutGenerator.GenerationError.writeFailed(
            NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        )
        #expect(writeError.localizedDescription.contains("write"))
    }

    // MARK: - Icon Configuration Tests

    @Test("Generator respects icon configuration")
    func testIconConfiguration() async throws {
        let customIcon = WorkflowIcon.withColor(
            red: 255,
            green: 59,
            blue: 48,
            alpha: 255,
            glyphNumber: 59511  // Document glyph
        )
        let generator = ShortcutGenerator(
            name: "Icon Test",
            icon: customIcon
        )

        let shortcut = await generator.buildShortcut(actions: [TextAction("Test")])

        #expect(shortcut.icon.glyphNumber == 59511)
        // Verify color is encoded correctly (RGBA-8 format)
        let expectedColor = (255 << 24) | (59 << 16) | (48 << 8) | 255
        #expect(shortcut.icon.startColor == expectedColor)
    }
}
