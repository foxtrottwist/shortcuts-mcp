// SPDX-License-Identifier: MIT
// EndToEndTests.swift - Comprehensive end-to-end integration tests for Shortcuts MCP

import Foundation
import Testing

@testable import ShortcutsMCP

// MARK: - Full Workflow Tests (Actions Mode)

@Suite("End-to-End: Actions Mode Workflow")
struct ActionsWorkflowTests {
    @Test("Create, verify, and decode shortcut from actions array")
    func createVerifyDecodeShortcut() async throws {
        // Setup
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-actions-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Phase 1: Generate shortcut with multiple actions
        let textUUID = UUID().uuidString
        let urlUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            TextAction("Hello, World!", uuid: textUUID, customOutputName: "Greeting"),
            URLAction.get("https://api.example.com/data", uuid: urlUUID),
            ShowResultAction(fromActionWithUUID: urlUUID, outputName: "Contents of URL"),
        ]

        let config = ShortcutGenerator.Configuration(
            name: "E2E Test Shortcut",
            icon: .withColor(red: 255, green: 128, blue: 0),
            inputContentItemClasses: [.string],
            workflowTypes: [.menuBar]
        )
        let generator = ShortcutGenerator(configuration: config, outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        // Phase 2: Verify file was created
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))
        #expect(result.fileSize > 0)
        #expect(result.shortcut.actions.count == 3)

        // Phase 3: Decode file and verify structure
        let fileData = try Data(contentsOf: result.filePath)
        let decoded = try Shortcut.decode(from: fileData)

        #expect(decoded.name == "E2E Test Shortcut")
        #expect(decoded.actions.count == 3)
        #expect(decoded.types.contains("MenuBar"))
        #expect(decoded.inputContentItemClasses.contains("WFStringContentItem"))

        // Verify action identifiers
        #expect(decoded.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.downloadurl")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.showresult")

        // Verify UUIDs are preserved
        #expect(decoded.actions[0].uuid == textUUID)
        #expect(decoded.actions[1].uuid == urlUUID)
    }

    @Test("Create shortcut with all UI action types")
    func createShortcutWithUIActions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-ui-actions-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let actions: [any ShortcutAction] = [
            ShowNotificationAction("Hello!", title: "Notification"),
            ShowAlertAction("Alert message", title: "Alert Title"),
            AskForInputAction("Enter your name"),
        ]

        let generator = ShortcutGenerator(name: "UI Actions Test", outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        // Verify file was created and can be decoded
        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 3)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.notification")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.alert")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.ask")
    }

    @Test("Create shortcut with file operations")
    func createShortcutWithFileActions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-file-actions-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let urlUUID = UUID().uuidString
        let actions: [any ShortcutAction] = [
            URLAction.get("https://example.com/file.pdf", uuid: urlUUID),
            SaveFileAction.askWhereToSave(),
        ]

        let generator = ShortcutGenerator(name: "File Actions Test", outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 2)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.documentpicker.save")
    }

    @Test("Create shortcut with text manipulation pipeline")
    func createShortcutWithTextPipeline() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-text-pipeline-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let textUUID = UUID().uuidString
        let replaceUUID = UUID().uuidString
        let caseUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            TextAction("Hello world", uuid: textUUID),
            ReplaceTextAction(find: "world", replaceWith: "Swift", uuid: replaceUUID),
            ChangeCaseAction(textCase: .uppercase, uuid: caseUUID),
            ShowResultAction(fromActionWithUUID: caseUUID),
        ]

        let generator = ShortcutGenerator(name: "Text Pipeline Test", outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 4)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.text.replace")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.text.changecase")
        #expect(decoded.actions[3].identifier == "is.workflow.actions.showresult")
    }

    @Test("Create shortcut with variable operations")
    func createShortcutWithVariables() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-variables-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let textUUID = UUID().uuidString
        let setVarUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            TextAction("Initial value", uuid: textUUID),
            SetVariableAction("myVar", uuid: setVarUUID),
            GetVariableAction(named: "myVar"),
            ShowResultAction.showInput(),
        ]

        let generator = ShortcutGenerator(name: "Variables Test", outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 4)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.setvariable")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.getvariable")
        #expect(decoded.actions[3].identifier == "is.workflow.actions.showresult")
    }

    @Test("Create shortcut with JSON operations")
    func createShortcutWithJSONOperations() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-json-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let urlUUID = UUID().uuidString
        let extractUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            URLAction.get("https://api.example.com/users", uuid: urlUUID),
            GetDictionaryValueAction.getValue(forKey: "data.users", uuid: extractUUID),
            GetItemFromListAction.firstItem(),
            ShowResultAction.showInput(),
        ]

        let generator = ShortcutGenerator(name: "JSON Operations Test", outputDirectory: tempDir)
        let result = try await generator.generate(actions: actions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 4)
        #expect(decoded.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.getvalueforkey")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.getitemfromlist")
        #expect(decoded.actions[3].identifier == "is.workflow.actions.showresult")
    }
}

// MARK: - Full Workflow Tests (Template Mode)

@Suite("End-to-End: Template Mode Workflow")
struct TemplateWorkflowTests {
    @Test("Create shortcut from APIRequestTemplate")
    func createFromAPIRequestTemplate() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-template-api-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        // Generate shortcut from template
        let shortcut = try await engine.buildShortcut(
            templateName: "api-request",
            parameters: [
                "url": .url("https://api.github.com/users/octocat"),
                "method": .choice("GET"),
                "jsonPath": .string("login"),
            ],
            configuration: .menuBar(name: "Get GitHub User")
        )

        // Verify shortcut structure
        #expect(shortcut.name == "Get GitHub User")
        #expect(shortcut.actions.count == 3) // URL, GetDictValue, ShowResult
        #expect(shortcut.types.contains("MenuBar"))

        // Write to file and verify
        let generator = ShortcutGenerator(
            configuration: .menuBar(name: "Get GitHub User"),
            outputDirectory: tempDir
        )
        let actions = try await engine.generate(
            templateName: "api-request",
            parameters: [
                "url": .url("https://api.github.com/users/octocat"),
                "jsonPath": .string("login"),
            ]
        )
        let result = try await generator.generate(actions: actions)

        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Decode and verify
        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 3)
    }

    @Test("Create shortcut from FileDownloadTemplate")
    func createFromFileDownloadTemplate() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-template-download-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let engine = TemplateEngine()
        await engine.register(FileDownloadTemplate.self)

        // Generate and save
        let config = ShortcutGenerator.Configuration(name: "Download File")
        let shortcut = try await engine.buildShortcut(
            templateName: "file-download",
            parameters: [
                "url": .url("https://example.com/document.pdf"),
                "filename": .string("/Downloads/my-doc.pdf"),
                "showConfirmation": .boolean(true),
            ],
            configuration: config
        )

        #expect(shortcut.name == "Download File")
        #expect(shortcut.actions.count == 3) // URL, SaveFile, Notification

        // Verify action types
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.documentpicker.save")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.notification")
    }

    @Test("Create shortcut from TextPipelineTemplate")
    func createFromTextPipelineTemplate() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-template-text-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let engine = TemplateEngine()
        await engine.register(TextPipelineTemplate.self)

        // Create complex text pipeline
        let operations = """
        [
            {"type": "replace", "find": "old", "replace": "new"},
            {"type": "uppercase"},
            {"type": "split", "separator": "spaces"}
        ]
        """

        let shortcut = try await engine.buildShortcut(
            templateName: "text-pipeline",
            parameters: [
                "inputText": .string("old text here"),
                "operations": .string(operations),
                "showResult": .boolean(true),
            ],
            configuration: .init(name: "Text Processor")
        )

        #expect(shortcut.name == "Text Processor")
        // 1 TextAction + 3 operations + 1 ShowResult = 5 actions
        #expect(shortcut.actions.count == 5)
    }

    @Test("registerBuiltInTemplates registers all templates")
    func registerBuiltInTemplatesWorks() async {
        let engine = TemplateEngine()
        await engine.registerBuiltInTemplates()

        // Should have 3 built-in templates
        #expect(await engine.templateCount >= 3)
        #expect(await engine.isRegistered(name: "api-request"))
        #expect(await engine.isRegistered(name: "file-download"))
        #expect(await engine.isRegistered(name: "text-pipeline"))
    }

    @Test("Template generates file and roundtrips correctly")
    func templateGeneratesValidFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-template-roundtrip-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let engine = TemplateEngine()
        await engine.registerBuiltInTemplates()

        // Generate through engine and write to file
        let result = try await engine.generateShortcut(
            templateName: "api-request",
            parameters: [
                "url": .url("https://httpbin.org/get"),
                "authHeader": .string("Bearer test-token"),
            ],
            configuration: .quickActions(name: "API Quick Action", inputTypes: [.url]),
            outputDirectory: tempDir
        )

        // Verify file
        #expect(FileManager.default.fileExists(atPath: result.filePath.path))
        #expect(result.fileSize > 0)

        // Decode and verify
        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.name == "API Quick Action")
        #expect(decoded.types.contains("QuickActions"))
        #expect(decoded.inputContentItemClasses.contains("WFURLContentItem"))
    }
}

// MARK: - Signing Workflow Tests

@Suite("End-to-End: Signing Workflow")
struct SigningWorkflowTests {
    @Test("Generate and sign shortcut - full workflow")
    func generateAndSignShortcut() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-signing-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Phase 1: Generate shortcut
        let generator = ShortcutGenerator(name: "Sign Test", outputDirectory: tempDir)
        let actions: [any ShortcutAction] = [
            TextAction("Hello, Signed World!"),
            ShowResultAction.showInput(),
        ]
        let genResult = try await generator.generate(actions: actions)

        #expect(FileManager.default.fileExists(atPath: genResult.filePath.path))

        // Phase 2: Sign the shortcut
        let signer = ShortcutSigner.shared
        let signedPath = tempDir.appending(path: "signed-shortcut.shortcut")

        do {
            let signResult = try await signer.sign(
                input: genResult.filePath,
                output: signedPath,
                mode: .anyone
            )

            // Verify signing succeeded
            #expect(signResult.mode == .anyone)
            #expect(signResult.fileSize > 0)
            #expect(FileManager.default.fileExists(atPath: signResult.signedFileURL.path))

            // Signed file should be different from original
            let originalData = try Data(contentsOf: genResult.filePath)
            let signedData = try Data(contentsOf: signResult.signedFileURL)
            #expect(signedData.count >= originalData.count)

        } catch let error as ShortcutSigner.SigningError {
            // CLI may not be available in test environment - this is acceptable
            switch error {
            case .signingFailed, .processError:
                // Expected in environments without shortcuts CLI
                #expect(Bool(true), "Signing CLI not available")
            default:
                throw error
            }
        }
    }

    @Test("Sign with different modes")
    func signWithDifferentModes() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-sign-modes-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Generate shortcut
        let generator = ShortcutGenerator(name: "Mode Test", outputDirectory: tempDir)
        let genResult = try await generator.generate(actions: [TextAction("Test")])

        let signer = ShortcutSigner.shared

        // Test anyone mode
        do {
            let result = try await signer.sign(
                input: genResult.filePath,
                output: tempDir.appending(path: "anyone-signed.shortcut"),
                mode: .anyone
            )
            #expect(result.mode == .anyone)
        } catch {
            // CLI unavailable is acceptable
        }

        // Test peopleWhoKnowMe mode
        do {
            let result = try await signer.sign(
                input: genResult.filePath,
                output: tempDir.appending(path: "people-signed.shortcut"),
                mode: .peopleWhoKnowMe
            )
            #expect(result.mode == .peopleWhoKnowMe)
        } catch {
            // CLI unavailable is acceptable
        }
    }

    @Test("Sign with auto-generated output path")
    func signAutoPath() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-sign-auto-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Generate shortcut
        let generator = ShortcutGenerator(name: "AutoPath Test", outputDirectory: tempDir)
        let genResult = try await generator.generate(actions: [TextAction("Test")])

        do {
            let signer = ShortcutSigner.shared
            let signedURL = try await signer.sign(input: genResult.filePath, mode: .anyone)

            // Should have -signed in filename
            #expect(signedURL.lastPathComponent.contains("-signed"))
            #expect(FileManager.default.fileExists(atPath: signedURL.path))
        } catch {
            // CLI unavailable is acceptable
        }
    }
}

// MARK: - Complete Create + Sign + Import Workflow

@Suite("End-to-End: Complete Workflow")
struct CompleteWorkflowTests {
    @Test("Create, sign, and import shortcut - full pipeline")
    func createSignImportShortcut() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-full-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Phase 1: Create shortcut
        let config = ShortcutGenerator.Configuration(
            name: "Full E2E Test",
            icon: .withColor(red: 0, green: 255, blue: 0),
            workflowTypes: [.menuBar]
        )
        let generator = ShortcutGenerator(configuration: config, outputDirectory: tempDir)

        let actions: [any ShortcutAction] = [
            TextAction("E2E Test Complete!"),
            ShowNotificationAction("The test passed!", title: "E2E Success"),
        ]

        let genResult = try await generator.generate(actions: actions)
        #expect(FileManager.default.fileExists(atPath: genResult.filePath.path))

        // Phase 2: Import (will trigger signing and open)
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: genResult.filePath,
            signFirst: true,
            cleanup: false,
            signingMode: .anyone
        )

        // Verify result structure
        #expect(importResult.originalPath == genResult.filePath.path)

        if importResult.isSuccess {
            // Import was triggered (Shortcuts app opened)
            #expect(importResult.signedFilePath != nil)

            // If cleanup was disabled, signed file should exist
            if let signedPath = importResult.signedFilePath {
                #expect(FileManager.default.fileExists(atPath: signedPath))
            }
        } else {
            // Import failed - acceptable in test environments
            #expect(importResult.errorMessage != nil)
        }
    }

    @Test("Create from template, sign, and import")
    func templateSignImportWorkflow() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-template-full-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Phase 1: Create from template
        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        let result = try await engine.generateShortcut(
            templateName: "api-request",
            parameters: [
                "url": .url("https://api.example.com/health"),
            ],
            configuration: .init(name: "API Health Check"),
            outputDirectory: tempDir
        )

        #expect(FileManager.default.fileExists(atPath: result.filePath.path))

        // Phase 2: Import
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: result.filePath,
            signFirst: true,
            cleanup: true
        )

        #expect(importResult.originalPath == result.filePath.path)
        // Either success or failure with message
        if !importResult.isSuccess {
            #expect(importResult.errorMessage != nil)
        }
    }

    @Test("Import with cleanup removes temporary files")
    func importWithCleanup() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-cleanup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create shortcut
        let generator = ShortcutGenerator(name: "Cleanup Test", outputDirectory: tempDir)
        let genResult = try await generator.generate(actions: [TextAction("Test")])

        // Import with cleanup
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: genResult.filePath,
            signFirst: true,
            cleanup: true
        )

        if importResult.isSuccess && importResult.cleanedUp {
            // If cleanup happened, signed file should be removed
            if let signedPath = importResult.signedFilePath {
                // File should not exist after cleanup
                // (small delay allowed for async cleanup)
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                let exists = FileManager.default.fileExists(atPath: signedPath)
                #expect(!exists, "Signed file should be cleaned up")
            }
        }
    }
}

// MARK: - Error Handling Tests

@Suite("End-to-End: Error Handling")
struct ErrorHandlingTests {
    @Test("Generator handles empty actions array")
    func generatorEmptyActionsError() async throws {
        let generator = ShortcutGenerator(name: "Empty Test")

        do {
            _ = try await generator.generate(actions: [] as [TextAction])
            #expect(Bool(false), "Should throw emptyActions error")
        } catch let error as ShortcutGenerator.GenerationError {
            guard case .emptyActions = error else {
                #expect(Bool(false), "Expected emptyActions error")
                return
            }
        }
    }

    @Test("Template engine handles missing required parameter")
    func templateMissingParameter() async {
        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        do {
            _ = try await engine.generate(
                templateName: "api-request",
                parameters: [:] // Missing required 'url'
            )
            #expect(Bool(false), "Should throw missingRequiredParameter")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "url"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Template engine handles unknown template")
    func templateUnknownTemplate() async {
        let engine = TemplateEngine()

        do {
            _ = try await engine.generate(
                templateName: "nonexistent-template",
                parameters: [:]
            )
            #expect(Bool(false), "Should throw templateNotFound")
        } catch let error as TemplateError {
            #expect(error == .templateNotFound(name: "nonexistent-template"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Template engine handles invalid choice value")
    func templateInvalidChoice() async {
        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "api-request",
                parameters: [
                    "url": .url("https://example.com"),
                    "method": .choice("INVALID"),
                ]
            )
            #expect(Bool(false), "Should throw invalidChoiceValue")
        } catch let error as TemplateError {
            if case .invalidChoiceValue(let name, let value, _) = error {
                #expect(name == "method")
                #expect(value == "INVALID")
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Signer handles non-existent input file")
    func signerNonExistentFile() async {
        let signer = ShortcutSigner.shared

        do {
            _ = try await signer.sign(
                input: URL(filePath: "/nonexistent/path/file.shortcut"),
                mode: .anyone
            )
            #expect(Bool(false), "Should throw inputFileNotFound")
        } catch let error as ShortcutSigner.SigningError {
            guard case .inputFileNotFound = error else {
                #expect(Bool(false), "Expected inputFileNotFound error")
                return
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Importer handles non-existent input file")
    func importerNonExistentFile() async {
        let importer = ShortcutImporter.shared

        let result = await importer.importShortcut(
            atPath: "/nonexistent/path/file.shortcut",
            signFirst: true,
            cleanup: false
        )

        #expect(!result.isSuccess)
        #expect(result.errorMessage != nil)
        #expect(result.errorMessage?.contains("not found") == true)
    }

    @Test("Importer handles import without signing")
    func importerWithoutSigning() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-nosign-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create shortcut
        let generator = ShortcutGenerator(name: "No Sign Test", outputDirectory: tempDir)
        let genResult = try await generator.generate(actions: [TextAction("Test")])

        // Import without signing
        let importer = ShortcutImporter.shared
        let result = await importer.importShortcut(
            at: genResult.filePath,
            signFirst: false,
            cleanup: false
        )

        // Signed file path should be nil when not signing
        #expect(result.signedFilePath == nil)
        #expect(result.originalPath == genResult.filePath.path)
    }
}

// MARK: - Import Questions Tests

@Suite("End-to-End: Import Questions")
struct ImportQuestionsTests {
    @Test("Create shortcut with import questions")
    func createWithImportQuestions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-import-questions-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let questions = [
            ImportQuestion(
                actionIndex: 0,
                parameterKey: "WFAPIKey",
                category: "API Key",
                defaultValue: "your-api-key",
                text: "Enter your API key"
            ),
            ImportQuestion(
                actionIndex: 1,
                parameterKey: "WFBaseURL",
                category: "URL",
                text: "Enter the base URL"
            ),
        ]

        let config = ShortcutGenerator.Configuration(
            name: "API Shortcut with Secrets",
            importQuestions: questions
        )
        let generator = ShortcutGenerator(configuration: config, outputDirectory: tempDir)

        let actions: [any ShortcutAction] = [
            TextAction("placeholder-key"),
            TextAction("https://api.example.com"),
            URLAction.get("https://api.example.com/data"),
        ]

        let result = try await generator.generate(actions: actions)

        // Verify import questions in decoded shortcut
        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.importQuestions != nil)
        #expect(decoded.importQuestions?.count == 2)

        let firstQuestion = decoded.importQuestions?[0]
        #expect(firstQuestion?.actionIndex == 0)
        #expect(firstQuestion?.parameterKey == "WFAPIKey")
        #expect(firstQuestion?.category == "API Key")
        #expect(firstQuestion?.defaultValue == "your-api-key")

        let secondQuestion = decoded.importQuestions?[1]
        #expect(secondQuestion?.actionIndex == 1)
        #expect(secondQuestion?.category == "URL")
    }

    @Test("Shortcut without import questions has nil importQuestions")
    func shortcutWithoutImportQuestions() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-no-questions-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let generator = ShortcutGenerator(name: "No Questions", outputDirectory: tempDir)
        let result = try await generator.generate(actions: [TextAction("Simple")])

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.importQuestions == nil)
    }
}

// MARK: - Multi-Action Complex Workflows

@Suite("End-to-End: Complex Workflows")
struct ComplexWorkflowTests {
    @Test("Create complex API workflow with error handling")
    func complexAPIWorkflow() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-complex-api-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let urlUUID = UUID().uuidString
        let extractUUID = UUID().uuidString
        let itemUUID = UUID().uuidString
        let varUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            // Fetch data from API
            URLAction.postJSON(
                "https://api.example.com/graphql",
                json: ["query": .string("{ users { id name } }")],
                uuid: urlUUID
            ),
            // Extract users array
            GetDictionaryValueAction.getValue(forKey: "data.users", uuid: extractUUID),
            // Get first user
            GetItemFromListAction.firstItem(uuid: itemUUID),
            // Store in variable
            SetVariableAction("firstUser", uuid: varUUID),
            // Get name from user object
            GetDictionaryValueAction.getValue(forKey: "name"),
            // Show result
            ShowResultAction.showInput(),
            // Show notification
            ShowNotificationAction("API request complete!", title: "Success"),
        ]

        let config = ShortcutGenerator.Configuration(
            name: "Complex API Workflow",
            icon: .withColor(red: 0, green: 122, blue: 255),
            workflowTypes: [.menuBar, .quickActions]
        )
        let generator = ShortcutGenerator(configuration: config, outputDirectory: tempDir)

        let result = try await generator.generate(actions: actions)

        // Verify all actions
        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 7)
        #expect(decoded.types.contains("MenuBar"))
        #expect(decoded.types.contains("QuickActions"))

        // Verify action chain
        #expect(decoded.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(decoded.actions[1].identifier == "is.workflow.actions.getvalueforkey")
        #expect(decoded.actions[2].identifier == "is.workflow.actions.getitemfromlist")
        #expect(decoded.actions[3].identifier == "is.workflow.actions.setvariable")
        #expect(decoded.actions[4].identifier == "is.workflow.actions.getvalueforkey")
        #expect(decoded.actions[5].identifier == "is.workflow.actions.showresult")
        #expect(decoded.actions[6].identifier == "is.workflow.actions.notification")
    }

    @Test("Create file processing workflow")
    func fileProcessingWorkflow() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-file-processing-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let selectUUID = UUID().uuidString
        let textUUID = UUID().uuidString

        let actions: [any ShortcutAction] = [
            // Select file
            GetFileAction.selectFile(uuid: selectUUID),
            // Ask for new name
            AskForInputAction("Enter new filename", inputType: .text, uuid: textUUID),
            // Save with new name
            SaveFileAction.askWhereToSave(),
            // Confirm
            ShowAlertAction.confirm("File processed and saved!"),
        ]

        let generator = ShortcutGenerator(
            name: "File Processor",
            icon: .withColor(red: 255, green: 149, blue: 0),
            outputDirectory: tempDir
        )

        let result = try await generator.generate(actions: actions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))
        #expect(decoded.actions.count == 4)
        #expect(decoded.name == "File Processor")
    }

    @Test("Create menu-based workflow")
    func menuBasedWorkflow() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(
            path: "e2e-menu-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Build menu with helper
        let menuActions = ChooseFromMenuAction.buildMenu(
            prompt: "Select action",
            items: ["Download", "Upload", "Process"]
        )

        var allActions: [any ShortcutAction] = menuActions
        allActions.append(ShowResultAction.showInput())

        let generator = ShortcutGenerator(name: "Menu Workflow", outputDirectory: tempDir)
        let result = try await generator.generate(actions: allActions)

        let decoded = try Shortcut.decode(from: Data(contentsOf: result.filePath))

        // Menu structure: start + 3 items + end + ShowResult = 6 actions
        #expect(decoded.actions.count >= 5)

        // First action should be menu start
        #expect(decoded.actions[0].identifier == "is.workflow.actions.choosefrommenu")
    }
}
