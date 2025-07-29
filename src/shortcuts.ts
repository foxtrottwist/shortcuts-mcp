import { exec } from "child_process";
import { promisify } from "util";

export function listShortcuts() {
  return execShortcuts("list");
}

export function runShortcut(name: string, input?: string) {
  return execShortcuts(
    "run",
    shellEscape(name),
    input ? `<<< ${shellEscape(input)}` : "",
  );
}

export function viewShortcut(name: string) {
  return execShortcuts("view", shellEscape(name));
}

const execAsync = promisify(exec);

/**
 * Executes macOS shortcuts CLI commands with proper error handling and argument filtering.
 *
 * Constructs and executes shell commands using the native `shortcuts` CLI tool.
 * Filters out falsy arguments and handles stderr warnings gracefully.
 *
 * @async
 * @param {string} subcommand - The shortcuts CLI subcommand ('run', 'list', 'view', 'sign')
 * @param {string[]} args - Variable arguments passed to the shortcuts command (automatically escaped)
 * @returns The stdout output from the shortcuts command
 * @throws {Error} When the shortcuts command fails or returns a non-zero exit code
 *
 * @example
 * ```typescript
 * // List all shortcuts
 * const shortcuts = await execShortcuts('list');
 *
 * // Run a shortcut with input
 * const result = await execShortcuts('run', shellEscape('My Shortcut'), '<<< "input text"');
 *
 * // View shortcut in editor
 * await execShortcuts('view', shellEscape('My Shortcut'));
 * ```
 */
export async function execShortcuts(subcommand: string, ...args: string[]) {
  try {
    const { stderr, stdout } = await execAsync(
      `shortcuts ${subcommand}${args.length ? " " + args.filter(Boolean).join(" ").trim() : ""}`,
    );
    if (stderr) {
      console.warn(`Shortcuts warning: ${stderr}`);
    }
    return stdout;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to ${subcommand} shortcut: ${message}`);
  }
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
 */ export function shellEscape(str: string) {
  return `'${str.replace(/'/g, "'\"'\"'")}'`;
}
