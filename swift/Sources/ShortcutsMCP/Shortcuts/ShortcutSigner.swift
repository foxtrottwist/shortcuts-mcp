import Foundation

/// An actor that handles signing macOS Shortcut files for sharing.
///
/// ShortcutSigner uses the `shortcuts sign` CLI command to sign shortcut files
/// so they can be shared with others. Signed shortcuts can be imported directly
/// into the Shortcuts app.
public actor ShortcutSigner {
    /// Shared signer instance
    public static let shared = ShortcutSigner()

    private init() {}

    // MARK: - Types

    /// Signing mode determines who can use the signed shortcut.
    public enum SigningMode: String, Sendable {
        /// Anyone can import and use the shortcut
        case anyone = "anyone"
        /// Only people in your contacts can use the shortcut
        case peopleWhoKnowMe = "people-who-know-me"
    }

    /// Errors that can occur during shortcut signing
    public enum SigningError: Error, LocalizedError {
        /// The input file does not exist
        case inputFileNotFound(path: String)
        /// The signing process failed
        case signingFailed(message: String)
        /// The signed output file was not created
        case outputFileNotCreated(path: String)
        /// A process execution error occurred
        case processError(String)

        public var errorDescription: String? {
            switch self {
            case let .inputFileNotFound(path):
                return "Input shortcut file not found: \(path)"
            case let .signingFailed(message):
                return "Failed to sign shortcut: \(message)"
            case let .outputFileNotCreated(path):
                return "Signed shortcut was not created at: \(path)"
            case let .processError(message):
                return "Process error during signing: \(message)"
            }
        }
    }

    /// Result of a successful signing operation
    public struct SigningResult: Sendable {
        /// URL to the signed shortcut file
        public let signedFileURL: URL
        /// Size of the signed file in bytes
        public let fileSize: Int64
        /// The signing mode used
        public let mode: SigningMode
    }

    // MARK: - Signing

    /// Signs a shortcut file for sharing.
    ///
    /// Uses the `shortcuts sign` CLI command to sign the shortcut file. The signed
    /// file can be imported directly into the Shortcuts app by anyone (or contacts
    /// only, depending on the mode).
    ///
    /// - Parameters:
    ///   - input: URL to the unsigned shortcut file
    ///   - output: URL where the signed shortcut should be saved
    ///   - mode: The signing mode (anyone or peopleWhoKnowMe)
    /// - Returns: A `SigningResult` containing the signed file URL and metadata
    /// - Throws: `SigningError` if signing fails
    ///
    /// Example:
    /// ```swift
    /// let signer = ShortcutSigner.shared
    /// let inputURL = URL(filePath: "/path/to/unsigned.shortcut")
    /// let outputURL = URL(filePath: "/path/to/signed.shortcut")
    ///
    /// let result = try await signer.sign(input: inputURL, output: outputURL, mode: .anyone)
    /// print("Signed file created at: \(result.signedFileURL.path)")
    /// ```
    public func sign(input: URL, output: URL, mode: SigningMode = .anyone) async throws -> SigningResult {
        // Verify input file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: input.path) else {
            throw SigningError.inputFileNotFound(path: input.path)
        }

        // Build the command with proper escaping
        let inputPath = ShellEscape.escape(input.path)
        let outputPath = ShellEscape.escape(output.path)
        let command = "shortcuts sign -i \(inputPath) -o \(outputPath) --mode \(mode.rawValue)"

        // Execute the signing command
        let (_, stderr) = try await executeCommand(command)

        // Verify the signed file was created
        guard fileManager.fileExists(atPath: output.path) else {
            // If stderr has content, include it in the error
            if !stderr.isEmpty {
                throw SigningError.signingFailed(message: stderr.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            throw SigningError.outputFileNotCreated(path: output.path)
        }

        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: output.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        return SigningResult(
            signedFileURL: output,
            fileSize: fileSize,
            mode: mode
        )
    }

    /// Signs a shortcut file and returns the signed file URL with auto-generated output path.
    ///
    /// The output file will be created in the same directory as the input with `-signed`
    /// appended to the filename.
    ///
    /// - Parameters:
    ///   - input: URL to the unsigned shortcut file
    ///   - mode: The signing mode (anyone or peopleWhoKnowMe)
    /// - Returns: URL to the signed shortcut file
    /// - Throws: `SigningError` if signing fails
    public func sign(input: URL, mode: SigningMode = .anyone) async throws -> URL {
        let outputURL = generateSignedOutputURL(for: input)
        let result = try await sign(input: input, output: outputURL, mode: mode)
        return result.signedFileURL
    }

    // MARK: - Private Helpers

    /// Generates an output URL for a signed shortcut based on the input URL.
    ///
    /// Appends "-signed" to the filename before the extension.
    private func generateSignedOutputURL(for input: URL) -> URL {
        let directory = input.deletingLastPathComponent()
        let filename = input.deletingPathExtension().lastPathComponent
        let ext = input.pathExtension
        return directory.appending(path: "\(filename)-signed.\(ext)")
    }

    /// Executes a shell command and returns stdout and stderr.
    ///
    /// - Parameter command: The shell command to execute
    /// - Returns: A tuple of (stdout, stderr) strings
    /// - Throws: `SigningError` if the process fails
    private func executeCommand(_ command: String) async throws -> (stdout: String, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: SigningError.processError(error.localizedDescription))
                return
            }

            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                let errorMessage = stderr.isEmpty
                    ? "Process exited with status \(process.terminationStatus)"
                    : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(throwing: SigningError.signingFailed(message: errorMessage))
                return
            }

            continuation.resume(returning: (stdout, stderr))
        }
    }
}
