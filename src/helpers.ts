import { ExecException } from "child_process";
import { stat } from "fs/promises";

/**
 * Escapes a string for safe use in AppleScript by doubling backslashes and escaping quotes.
 *
 * @param str - The string to escape
 * @returns The escaped string
 *
 * @example
 * ```typescript
 * escapeAppleScriptString('say "hello"');    // 'say \\"hello\\"'
 * escapeAppleScriptString('path\\to\\file');  // 'path\\\\to\\\\file'
 * ```
 */
export function escapeAppleScriptString(str: string): string {
  return str.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}
export async function isDirectory(path: string) {
  return stat(path)
    .then((res) => res.isDirectory())
    .catch(() => false);
}
/**
 * Type guard to check if an error is an ExecException with stderr/stdout properties.
 *
 * @param e - The error to check
 * @returns True if the error is an ExecException
 *
 * @example
 * ```typescript
 * if (isExecError(error)) {
 *   console.error('Command failed:', error.stderr);
 * }
 * ```
 */
export function isExecError(e: unknown): e is ExecException {
  return typeof e === "object" && e !== null && "stderr" in e && "stdout" in e;
}

export async function isFile(path: string) {
  return stat(path)
    .then((res) => res.isFile())
    .catch(() => false);
}

/**
 * Escapes a string for safe use in shell commands by wrapping in single quotes.
 *
 * Handles embedded single quotes by using the '"'"' escape sequence, which closes
 * the current single-quoted string, adds a double-quoted single quote, then reopens
 * single quotes. This approach is more reliable than backslash escaping.
 *
 * @param {string} str - The string to escape for shell command usage
 * @returns The escaped string wrapped in single quotes, safe for shell execution
 *
 * @example
 * ```typescript
 * shellEscape("My Shortcut");           // "'My Shortcut'"
 * shellEscape("O'Reilly's Book");       // "'O'\"'\"'Reilly'\"'\"'s Book'"
 * shellEscape("Simple text");           // "'Simple text'"
 * shellEscape("");                      // "''"
 * ```
 *
 * @security This function is critical for preventing shell injection attacks.
 * Always use this function when passing user input or dynamic content to shell commands.
 */
export function shellEscape(str: string) {
  return `'${str.replace(/'/g, "'\"'\"'")}'`;
}
