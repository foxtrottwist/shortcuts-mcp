import Foundation

/// An actor that handles importing shortcut files into the macOS Shortcuts app.
///
/// ShortcutImporter provides a complete workflow for importing shortcuts:
/// 1. Optionally sign the shortcut file (required for import)
/// 2. Open the file with the Shortcuts app (triggers user import prompt)
/// 3. Optionally clean up temporary files after import is triggered
///
/// The Shortcuts app will prompt the user to confirm the import. This is a security
/// measure by Apple and cannot be bypassed programmatically.
public actor ShortcutImporter {
    /// Shared importer instance
    public static let shared = ShortcutImporter()

    /// The signer used for signing shortcuts before import
    private let signer: ShortcutSigner

    private init() {
        self.signer = ShortcutSigner.shared
    }

    // MARK: - Types

    /// The status of an import operation
    public enum ImportStatus: Sendable {
        /// The import was triggered successfully (user will see import prompt)
        case triggered
        /// The import failed during signing
        case signingFailed(reason: String)
        /// The import failed when opening with Shortcuts app
        case openFailed(reason: String)
    }

    /// Result of an import operation
    public struct ImportResult: Sendable {
        /// The status of the import operation
        public let status: ImportStatus
        /// Path to the signed file (if signing was performed)
        public let signedFilePath: String?
        /// Path to the original input file
        public let originalPath: String
        /// Whether the signed file was cleaned up
        public let cleanedUp: Bool

        /// Whether the import was successfully triggered
        public var isSuccess: Bool {
            if case .triggered = status {
                return true
            }
            return false
        }

        /// Error message if the import failed
        public var errorMessage: String? {
            switch status {
            case .triggered:
                return nil
            case let .signingFailed(reason):
                return "Signing failed: \(reason)"
            case let .openFailed(reason):
                return "Failed to open with Shortcuts: \(reason)"
            }
        }
    }

    /// Errors that can occur during shortcut import
    public enum ImportError: Error, LocalizedError {
        /// The input file does not exist
        case inputFileNotFound(path: String)
        /// The signing process failed
        case signingFailed(reason: String)
        /// Failed to open the file with Shortcuts app
        case openFailed(reason: String)
        /// A process execution error occurred
        case processError(String)

        public var errorDescription: String? {
            switch self {
            case let .inputFileNotFound(path):
                return "Input shortcut file not found: \(path)"
            case let .signingFailed(reason):
                return "Failed to sign shortcut for import: \(reason)"
            case let .openFailed(reason):
                return "Failed to open shortcut with Shortcuts app: \(reason)"
            case let .processError(message):
                return "Process error during import: \(message)"
            }
        }
    }

    // MARK: - Import Methods

    /// Imports a shortcut file into the Shortcuts app.
    ///
    /// This method handles the complete import workflow:
    /// 1. Signs the shortcut file (if `signFirst` is true)
    /// 2. Opens the signed file with the Shortcuts app
    /// 3. Cleans up temporary signed file (if `cleanup` is true)
    ///
    /// The Shortcuts app will display an import prompt to the user. This is a security
    /// measure by Apple and the user must confirm the import.
    ///
    /// - Parameters:
    ///   - fileURL: URL to the shortcut file to import
    ///   - signFirst: Whether to sign the file before opening (default: true)
    ///   - cleanup: Whether to clean up the signed file after opening (default: false)
    ///   - signingMode: The signing mode to use (default: .anyone)
    /// - Returns: An `ImportResult` describing the outcome
    ///
    /// Example:
    /// ```swift
    /// let importer = ShortcutImporter.shared
    /// let shortcutURL = URL(filePath: "/path/to/my-shortcut.shortcut")
    ///
    /// let result = try await importer.importShortcut(
    ///     at: shortcutURL,
    ///     signFirst: true,
    ///     cleanup: true
    /// )
    ///
    /// if result.isSuccess {
    ///     print("Import triggered! User will see import prompt.")
    /// } else {
    ///     print("Import failed: \(result.errorMessage ?? "Unknown error")")
    /// }
    /// ```
    public func importShortcut(
        at fileURL: URL,
        signFirst: Bool = true,
        cleanup: Bool = false,
        signingMode: ShortcutSigner.SigningMode = .anyone
    ) async -> ImportResult {
        let originalPath = fileURL.path

        // Verify input file exists
        guard FileManager.default.fileExists(atPath: originalPath) else {
            return ImportResult(
                status: .openFailed(reason: "Input file not found: \(originalPath)"),
                signedFilePath: nil,
                originalPath: originalPath,
                cleanedUp: false
            )
        }

        var fileToOpen = fileURL
        var signedPath: String?
        var didSign = false

        // Step 1: Sign the file if requested
        if signFirst {
            do {
                let signedURL = try await signer.sign(input: fileURL, mode: signingMode)
                fileToOpen = signedURL
                signedPath = signedURL.path
                didSign = true
            } catch {
                let reason = (error as? ShortcutSigner.SigningError)?.errorDescription ?? error.localizedDescription
                return ImportResult(
                    status: .signingFailed(reason: reason),
                    signedFilePath: nil,
                    originalPath: originalPath,
                    cleanedUp: false
                )
            }
        }

        // Step 2: Open the file with Shortcuts app
        do {
            try await openWithShortcutsApp(fileURL: fileToOpen)
        } catch {
            let reason = (error as? ImportError)?.errorDescription ?? error.localizedDescription
            // Clean up signed file on failure if we created one
            var cleanedUp = false
            if didSign, let signedPath = signedPath, cleanup {
                cleanedUp = cleanupFile(at: signedPath)
            }
            return ImportResult(
                status: .openFailed(reason: reason),
                signedFilePath: signedPath,
                originalPath: originalPath,
                cleanedUp: cleanedUp
            )
        }

        // Step 3: Clean up the signed file if requested
        // Note: We add a small delay to ensure Shortcuts has time to read the file
        var cleanedUp = false
        if cleanup, let signedPath = signedPath {
            // Wait briefly for Shortcuts to read the file before cleanup
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            cleanedUp = cleanupFile(at: signedPath)
        }

        return ImportResult(
            status: .triggered,
            signedFilePath: signedPath,
            originalPath: originalPath,
            cleanedUp: cleanedUp
        )
    }

    /// Imports a shortcut from a file path.
    ///
    /// Convenience method that accepts a file path string instead of a URL.
    ///
    /// - Parameters:
    ///   - filePath: Path to the shortcut file to import
    ///   - signFirst: Whether to sign the file before opening (default: true)
    ///   - cleanup: Whether to clean up the signed file after opening (default: false)
    ///   - signingMode: The signing mode to use (default: .anyone)
    /// - Returns: An `ImportResult` describing the outcome
    public func importShortcut(
        atPath filePath: String,
        signFirst: Bool = true,
        cleanup: Bool = false,
        signingMode: ShortcutSigner.SigningMode = .anyone
    ) async -> ImportResult {
        let fileURL = URL(filePath: filePath)
        return await importShortcut(at: fileURL, signFirst: signFirst, cleanup: cleanup, signingMode: signingMode)
    }

    // MARK: - Private Helpers

    /// Opens a file with the Shortcuts app.
    ///
    /// Uses the `open -a "Shortcuts"` command to open the file.
    ///
    /// - Parameter fileURL: URL to the file to open
    /// - Throws: `ImportError` if the open command fails
    private func openWithShortcutsApp(fileURL: URL) async throws {
        let escapedPath = ShellEscape.escape(fileURL.path)
        let command = "open -a \"Shortcuts\" \(escapedPath)"

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]

            let stderrPipe = Pipe()
            process.standardError = stderrPipe
            process.standardOutput = FileHandle.nullDevice

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ImportError.processError(error.localizedDescription))
                return
            }

            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                let reason = stderr.isEmpty
                    ? "Process exited with status \(process.terminationStatus)"
                    : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(throwing: ImportError.openFailed(reason: reason))
                return
            }

            continuation.resume(returning: ())
        }
    }

    /// Deletes a file at the given path.
    ///
    /// - Parameter path: Path to the file to delete
    /// - Returns: `true` if the file was deleted, `false` otherwise
    @discardableResult
    private func cleanupFile(at path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            // Silently fail - cleanup is best-effort
            return false
        }
    }
}
