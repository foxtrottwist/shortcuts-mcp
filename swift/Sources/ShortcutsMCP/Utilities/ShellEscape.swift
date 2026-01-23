import Foundation

/// Shell escaping utilities for safe command execution.
///
/// These functions prevent shell injection attacks by properly escaping
/// user-provided input before passing it to shell commands.
enum ShellEscape {
    /// Escapes a string for safe use in shell commands by wrapping in single quotes.
    ///
    /// Handles embedded single quotes by using the `'"'"'` escape sequence, which:
    /// 1. Closes the current single-quoted string
    /// 2. Adds a double-quoted single quote
    /// 3. Reopens single quotes
    ///
    /// - Parameter str: The string to escape for shell command usage
    /// - Returns: The escaped string wrapped in single quotes
    ///
    /// Example:
    /// ```swift
    /// ShellEscape.escape("My Shortcut")        // "'My Shortcut'"
    /// ShellEscape.escape("O'Reilly's Book")    // "'O'\"'\"'Reilly'\"'\"'s Book'"
    /// ```
    ///
    /// - Important: Always use this function when passing user input to shell commands.
    static func escape(_ str: String) -> String {
        "'\(str.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
    }
}
