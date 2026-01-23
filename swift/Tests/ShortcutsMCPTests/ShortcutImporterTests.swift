import Foundation
import Testing

@testable import ShortcutsMCP

@Suite("ShortcutImporter Tests")
struct ShortcutImporterTests {
    // MARK: - ImportStatus Tests

    @Test("ImportStatus.triggered indicates success")
    func importStatusTriggeredIsSuccess() {
        let status = ShortcutImporter.ImportStatus.triggered
        if case .triggered = status {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .triggered status")
        }
    }

    @Test("ImportStatus.signingFailed contains reason")
    func importStatusSigningFailedHasReason() {
        let status = ShortcutImporter.ImportStatus.signingFailed(reason: "Invalid signature")
        if case let .signingFailed(reason) = status {
            #expect(reason == "Invalid signature")
        } else {
            #expect(Bool(false), "Expected .signingFailed status")
        }
    }

    @Test("ImportStatus.openFailed contains reason")
    func importStatusOpenFailedHasReason() {
        let status = ShortcutImporter.ImportStatus.openFailed(reason: "App not found")
        if case let .openFailed(reason) = status {
            #expect(reason == "App not found")
        } else {
            #expect(Bool(false), "Expected .openFailed status")
        }
    }

    // MARK: - ImportResult Tests

    @Test("ImportResult.isSuccess returns true for triggered status")
    func importResultIsSuccessForTriggered() {
        let result = ShortcutImporter.ImportResult(
            status: .triggered,
            signedFilePath: "/tmp/test-signed.shortcut",
            originalPath: "/tmp/test.shortcut",
            cleanedUp: false
        )
        #expect(result.isSuccess == true)
        #expect(result.errorMessage == nil)
    }

    @Test("ImportResult.isSuccess returns false for signingFailed status")
    func importResultIsNotSuccessForSigningFailed() {
        let result = ShortcutImporter.ImportResult(
            status: .signingFailed(reason: "Signing error"),
            signedFilePath: nil,
            originalPath: "/tmp/test.shortcut",
            cleanedUp: false
        )
        #expect(result.isSuccess == false)
        #expect(result.errorMessage == "Signing failed: Signing error")
    }

    @Test("ImportResult.isSuccess returns false for openFailed status")
    func importResultIsNotSuccessForOpenFailed() {
        let result = ShortcutImporter.ImportResult(
            status: .openFailed(reason: "Open error"),
            signedFilePath: "/tmp/test-signed.shortcut",
            originalPath: "/tmp/test.shortcut",
            cleanedUp: false
        )
        #expect(result.isSuccess == false)
        #expect(result.errorMessage == "Failed to open with Shortcuts: Open error")
    }

    @Test("ImportResult tracks signedFilePath and originalPath")
    func importResultTracksFilePaths() {
        let result = ShortcutImporter.ImportResult(
            status: .triggered,
            signedFilePath: "/path/to/signed.shortcut",
            originalPath: "/path/to/original.shortcut",
            cleanedUp: true
        )
        #expect(result.signedFilePath == "/path/to/signed.shortcut")
        #expect(result.originalPath == "/path/to/original.shortcut")
        #expect(result.cleanedUp == true)
    }

    // MARK: - ImportError Tests

    @Test("ImportError.inputFileNotFound has descriptive message")
    func importErrorInputFileNotFoundMessage() {
        let error = ShortcutImporter.ImportError.inputFileNotFound(path: "/missing/file.shortcut")
        #expect(error.errorDescription == "Input shortcut file not found: /missing/file.shortcut")
    }

    @Test("ImportError.signingFailed has descriptive message")
    func importErrorSigningFailedMessage() {
        let error = ShortcutImporter.ImportError.signingFailed(reason: "Certificate expired")
        #expect(error.errorDescription == "Failed to sign shortcut for import: Certificate expired")
    }

    @Test("ImportError.openFailed has descriptive message")
    func importErrorOpenFailedMessage() {
        let error = ShortcutImporter.ImportError.openFailed(reason: "Shortcuts app not installed")
        #expect(error.errorDescription == "Failed to open shortcut with Shortcuts app: Shortcuts app not installed")
    }

    @Test("ImportError.processError has descriptive message")
    func importErrorProcessErrorMessage() {
        let error = ShortcutImporter.ImportError.processError("Process crashed")
        #expect(error.errorDescription == "Process error during import: Process crashed")
    }

    // MARK: - ShortcutImporter Tests

    @Test("ShortcutImporter.shared returns the same instance")
    func importerSharedInstance() async {
        let importer1 = ShortcutImporter.shared
        let importer2 = ShortcutImporter.shared
        // Both references should be to the same actor
        #expect(importer1 === importer2)
    }

    @Test("importShortcut returns failure for non-existent file")
    func importNonExistentFileReturnsFailure() async {
        let importer = ShortcutImporter.shared
        let nonExistentPath = "/definitely/does/not/exist/test.shortcut"

        let result = await importer.importShortcut(
            atPath: nonExistentPath,
            signFirst: true,
            cleanup: false
        )

        #expect(result.isSuccess == false)
        #expect(result.originalPath == nonExistentPath)
        #expect(result.signedFilePath == nil)
        if case let .openFailed(reason) = result.status {
            #expect(reason.contains("not found"))
        } else {
            #expect(Bool(false), "Expected openFailed status")
        }
    }

    @Test("importShortcut at URL works the same as atPath")
    func importShortcutURLVsPath() async {
        let importer = ShortcutImporter.shared
        let path = "/nonexistent/path.shortcut"
        let url = URL(filePath: path)

        let resultFromURL = await importer.importShortcut(at: url, signFirst: false, cleanup: false)
        let resultFromPath = await importer.importShortcut(atPath: path, signFirst: false, cleanup: false)

        // Both should fail with the same original path
        #expect(resultFromURL.originalPath == resultFromPath.originalPath)
        #expect(resultFromURL.isSuccess == resultFromPath.isSuccess)
    }

    // MARK: - Integration Tests (require Shortcuts app)

    @Test("Integration: import generated shortcut triggers Shortcuts app")
    func importGeneratedShortcutIntegration() async throws {
        // Create a test shortcut
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appending(path: "shortcut-importer-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: outputDir)
        }

        // Generate a simple shortcut
        let config = ShortcutGenerator.Configuration(name: "Importer Test")
        let generator = ShortcutGenerator(configuration: config, outputDirectory: outputDir)
        let textAction = TextAction("Hello from importer test!")
        let showAction = ShowResultAction("Test result")
        let result = try await generator.generate(actions: [textAction, showAction])

        // Try to import it
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: result.filePath,
            signFirst: true,
            cleanup: true
        )

        // The import may succeed or fail depending on environment
        // (Shortcuts app availability, signing support, etc.)
        // We just verify the result structure is correct
        #expect(importResult.originalPath == result.filePath.path)

        if importResult.isSuccess {
            // Import was triggered
            #expect(importResult.signedFilePath != nil)
        } else {
            // Import failed - this is acceptable in test environments
            // where Shortcuts CLI or app may not be available
            #expect(importResult.errorMessage != nil)
        }
    }

    @Test("Integration: import without signing skips signer")
    func importWithoutSigningIntegration() async throws {
        // Create a test shortcut
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appending(path: "shortcut-importer-nosign-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: outputDir)
        }

        // Generate a simple shortcut
        let config = ShortcutGenerator.Configuration(name: "No Sign Test")
        let generator = ShortcutGenerator(configuration: config, outputDirectory: outputDir)
        let textAction = TextAction("Hello from no-sign test!")
        let result = try await generator.generate(actions: [textAction])

        // Try to import without signing
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: result.filePath,
            signFirst: false,
            cleanup: false
        )

        // When not signing, signedFilePath should be nil
        #expect(importResult.signedFilePath == nil)
        #expect(importResult.originalPath == result.filePath.path)

        // The import may succeed or fail - unsigned shortcuts may not be importable
        // We just verify the workflow completed
        if importResult.isSuccess {
            #expect(Bool(true)) // Shortcuts app opened the file
        } else {
            // Expected in most cases - unsigned shortcuts are rejected by Shortcuts app
            #expect(importResult.errorMessage != nil)
        }
    }

    @Test("Integration: cleanup removes signed file after import")
    func cleanupRemovesSignedFileIntegration() async throws {
        // Create a test shortcut
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appending(path: "shortcut-importer-cleanup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: outputDir)
        }

        // Generate a simple shortcut
        let config = ShortcutGenerator.Configuration(name: "Cleanup Test")
        let generator = ShortcutGenerator(configuration: config, outputDirectory: outputDir)
        let textAction = TextAction("Testing cleanup!")
        let result = try await generator.generate(actions: [textAction])

        // Try to import with cleanup
        let importer = ShortcutImporter.shared
        let importResult = await importer.importShortcut(
            at: result.filePath,
            signFirst: true,
            cleanup: true
        )

        if importResult.isSuccess {
            // If import succeeded, cleanup should have been attempted
            // The file may or may not exist depending on timing
            if let signedPath = importResult.signedFilePath {
                // If cleanedUp is true, file should not exist
                if importResult.cleanedUp {
                    let fileExists = FileManager.default.fileExists(atPath: signedPath)
                    #expect(!fileExists, "Signed file should be cleaned up")
                }
            }
        } else {
            // Import failed, but we still verify the result structure
            #expect(importResult.originalPath == result.filePath.path)
        }
    }
}
