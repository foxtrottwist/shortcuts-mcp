import Foundation

/// An actor that handles the execution of macOS Shortcuts via AppleScript.
///
/// ShortcutExecutor provides secure execution of shortcuts through the "Shortcuts Events"
/// AppleScript interface. It includes proper escaping functions to prevent shell and
/// AppleScript injection attacks.
public actor ShortcutExecutor {
    /// Shared executor instance
    public static let shared = ShortcutExecutor()

    private init() {}

    // MARK: - Security Escaping Functions

    /// Escapes a string for safe use in shell commands by wrapping in single quotes.
    ///
    /// Handles embedded single quotes by using the `'"'"'` escape sequence, which closes
    /// the current single-quoted string, adds a double-quoted single quote, then reopens
    /// single quotes. This approach is more reliable than backslash escaping.
    ///
    /// - Parameter str: The string to escape for shell command usage
    /// - Returns: The escaped string wrapped in single quotes, safe for shell execution
    ///
    /// ```swift
    /// shellEscape("My Shortcut")           // "'My Shortcut'"
    /// shellEscape("O'Reilly's Book")       // "'O'\"'\"'Reilly'\"'\"'s Book'"
    /// shellEscape("Simple text")           // "'Simple text'"
    /// shellEscape("")                      // "''"
    /// ```
    ///
    /// - Important: This function is critical for preventing shell injection attacks.
    ///   Always use this function when passing user input or dynamic content to shell commands.
    public func shellEscape(_ str: String) -> String {
        "'" + str.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }

    /// Escapes a string for safe use in AppleScript by doubling backslashes and escaping quotes.
    ///
    /// - Parameter str: The string to escape
    /// - Returns: The escaped string
    ///
    /// ```swift
    /// escapeAppleScriptString("say \"hello\"")    // "say \\\"hello\\\""
    /// escapeAppleScriptString("path\\to\\file")   // "path\\\\to\\\\file"
    /// ```
    public func escapeAppleScriptString(_ str: String) -> String {
        str.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Shortcut Execution

    /// Result of a shortcut execution
    public struct ExecutionResult: Sendable {
        /// The output from the shortcut, if any
        public let output: String

        /// Whether the execution was successful
        public let success: Bool

        /// Duration of execution in milliseconds
        public let durationMs: Int

        /// Any error that occurred
        public let error: String?
    }

    /// Error types for shortcut execution
    public enum ExecutionError: Error, LocalizedError {
        case permissionDenied(shortcut: String, message: String)
        case executionFailed(shortcut: String, message: String)
        case processError(String)

        public var errorDescription: String? {
            switch self {
            case let .permissionDenied(shortcut, message):
                return """
                    Permission denied for shortcut "\(shortcut)": \(message)
                    Grant automation permissions in System Settings → Privacy & Security → Automation
                    """
            case let .executionFailed(shortcut, message):
                return "Failed to run \(shortcut) shortcut: \(message)"
            case let .processError(message):
                return "Process error: \(message)"
            }
        }
    }

    /// Runs a macOS Shortcut by name with optional input.
    ///
    /// This function executes shortcuts using AppleScript through the "Shortcuts Events"
    /// application, which provides more reliable permission handling than the CLI.
    ///
    /// - Parameters:
    ///   - name: The name of the shortcut to run
    ///   - input: Optional input to pass to the shortcut
    /// - Returns: The output from the shortcut execution
    /// - Throws: `ExecutionError` if the shortcut fails to execute
    public func runShortcut(name: String, input: String? = nil) async throws -> String {
        let escapedName = escapeAppleScriptString(name)

        // Build the AppleScript command
        let script: String
        if let input {
            let escapedInput = escapeAppleScriptString(input)
            script = """
                tell application "Shortcuts Events" to run the shortcut named "\(escapedName)" with input "\(escapedInput)"
                """
        } else {
            script = """
                tell application "Shortcuts Events" to run the shortcut named "\(escapedName)"
                """
        }

        // Build the shell command with proper escaping
        let command = "osascript -e \(shellEscape(script))"

        do {
            let (stdout, stderr) = try await executeCommand(command)

            // Log warning if there's stderr output
            if !stderr.isEmpty {
                // Check for permission-related errors
                if stderr.contains("permission") || stderr.contains("access") {
                    // Log but don't fail - some shortcuts work despite stderr
                }
            }

            // Handle "missing value" response from AppleScript
            let output = stdout.isEmpty || stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "missing value"
                ? "Shortcut completed successfully"
                : stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            return output

        } catch let error as ExecutionError {
            throw error
        } catch {
            let errorMessage = error.localizedDescription

            // Check for permission error (error 1743)
            if errorMessage.contains("1743") || errorMessage.contains("permission") {
                throw ExecutionError.permissionDenied(shortcut: name, message: errorMessage)
            }

            throw ExecutionError.executionFailed(shortcut: name, message: errorMessage)
        }
    }

    // MARK: - Process Execution

    /// Executes a shell command and returns stdout and stderr
    ///
    /// - Parameter command: The shell command to execute
    /// - Returns: A tuple of (stdout, stderr) strings
    /// - Throws: `ExecutionError.processError` if the process fails
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
                continuation.resume(throwing: ExecutionError.processError(error.localizedDescription))
                return
            }

            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                // Include stderr in the error message for better diagnostics
                let errorMessage = stderr.isEmpty
                    ? "Process exited with status \(process.terminationStatus)"
                    : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(throwing: ExecutionError.executionFailed(
                    shortcut: "unknown",
                    message: errorMessage
                ))
                return
            }

            continuation.resume(returning: (stdout, stderr))
        }
    }
}
