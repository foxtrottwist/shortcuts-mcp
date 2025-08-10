import { exec } from "child_process";
import { promisify } from "util";

import {
  escapeAppleScriptString,
  isExecError,
  shellEscape,
} from "./helpers.js";
import { logger } from "./logger.js";
import { recordExecution } from "./shortcuts-usage.js";

const execAsync = promisify(exec);

export async function listShortcuts() {
  try {
    const { stdout } = await execAsync("shortcuts list --show-identifiers");
    return stdout.trim() || "No shortcuts found";
  } catch (error) {
    logger.error({ error: String(error) }, "Failed to list shortcuts");
    throw new Error(
      isExecError(error)
        ? `Failed to list shortcuts: ${error.message}`
        : String(error),
    );
  }
}

export async function runShortcut(shortcut: string, input?: string) {
  const escapedName = escapeAppleScriptString(shortcut);
  const script = input
    ? `tell application "Shortcuts Events" to run the shortcut named "${escapedName}" with input "${escapeAppleScriptString(input)}"`
    : `tell application "Shortcuts Events" to run the shortcut named "${escapedName}"`;
  const command = `osascript -e ${shellEscape(script)}`;

  const startTime = Date.now();
  try {
    const { stderr, stdout } = await execAsync(command);
    const duration = Date.now() - startTime;

    if (stderr) {
      logger.warn(
        {
          isPermissionRelated:
            stderr.includes("permission") || stderr.includes("access"),
          isTimeout: stderr.includes("timeout"),
          shortcut,
          stderr,
        },
        "AppleScript stderr output",
      );
    }

    const output =
      stdout && stdout !== "missing value"
        ? stdout
        : "Shortcut completed successfully";

    await recordExecution({ duration, shortcut, success: true });

    return output;
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error(
      {
        command: command.substring(0, 50) + "...",
        duration,
        errorType: isExecError(error) ? "exec" : "other",
        shortcut,
      },
      "Shortcut execution failed",
    );

    if (
      isExecError(error) &&
      (error.message.includes("1743") || error.message.includes("permission"))
    ) {
      logger.error(
        {
          shortcut,
          solution:
            "Grant automation permissions in System Preferences → Privacy & Security",
        },
        "Permission denied - automation access required",
      );
    }

    await recordExecution({
      duration,
      shortcut,
      success: false,
    });

    throw new Error(
      isExecError(error)
        ? `Failed to run ${shortcut} shortcut: ${error.message}`
        : String(error),
    );
  }
}

export async function viewShortcut(name: string) {
  logger.info({ name }, "Opening shortcut in editor");

  try {
    await execAsync(`shortcuts view ${shellEscape(name)}`);
    logger.info("Shortcut opened successfully", { name });
    return `Opened "${name}" in Shortcuts editor`;
  } catch (error) {
    logger.warn(
      {
        name,
        suggestion: "Try exact case-sensitive name from shortcuts list",
      },
      "CLI view command failed - possible Apple name resolution bug",
    );
    throw error;
  }
}
