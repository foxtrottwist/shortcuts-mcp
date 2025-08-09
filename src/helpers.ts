import { ExecException } from "child_process";
import { readFileSync } from "fs";
import { stat } from "fs/promises";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

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

export function getVersion() {
  try {
    const __dirname = dirname(fileURLToPath(import.meta.url));
    const packagePath = join(__dirname, "../package.json");
    const packageJson = JSON.parse(readFileSync(packagePath, "utf8"));
    return packageJson.version;
  } catch {
    return "unknown";
  }
}
/**
 * Checks if a path is a directory.
 *
 * @param path - The path to check
 * @returns True if path is a directory, false otherwise
 */
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

/**
 * Checks if a path is a file.
 *
 * @param path - The path to check
 * @returns True if path is a file, false otherwise
 */
export async function isFile(path: string) {
  return stat(path)
    .then((res) => res.isFile())
    .catch(() => false);
}

/**
 * Checks if a timestamp is older than 24 hours from the current time.
 *
 * @param timestamp - The timestamp to check (Date object or ISO string)
 * @returns True if timestamp is older than 24 hours, false otherwise
 *
 * @example
 * ```typescript
 * isOlderThan24Hrs("2025-08-01T12:00:00Z");     // true (if current time is Aug 3+)
 * isOlderThan24Hrs(new Date("2025-08-08T10:00:00Z")); // false (if current time is Aug 8 11am)
 * isOlderThan24Hrs(undefined);                   // true (no timestamp means needs refresh)
 * isOlderThan24Hrs("invalid-date");              // false (invalid dates are not old)
 * ```
 */
export function isOlderThan24Hrs(timestamp?: Date | string) {
  if (!timestamp) return true;

  let ts: number;

  if (timestamp instanceof Date) {
    ts = timestamp.getTime();
  } else {
    ts = new Date(timestamp.trim()).getTime();
  }

  return !isNaN(ts) && new Date().getTime() - ts > 24 * 60 * 60 * 1000;
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

/**
 * Safely attempts to parse a JSON string with error handling.
 *
 * @param s - The string to parse as JSON
 * @param handleError - Callback function to handle parse errors
 * @returns Parsed JSON object if successful, undefined if parsing fails
 *
 * @example
 * ```typescript
 * const data = tryJSONParse('{"key": "value"}', (e) => console.error(e));
 * // Returns: { key: "value" }
 *
 * const invalid = tryJSONParse('invalid json', (e) => console.error(e));
 * // Returns: undefined (and logs error)
 * ```
 */
export function tryJSONParse(s: string, handleError: (e: unknown) => void) {
  try {
    return JSON.parse(s);
  } catch (e) {
    handleError(e);
  }
}
