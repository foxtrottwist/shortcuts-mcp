import { exec } from "child_process";
import { SerializableValue } from "fastmcp";
import { promisify } from "util";

import {
  escapeAppleScriptString,
  isExecError,
  shellEscape,
} from "./helpers.js";

type Logger = {
  debug: (message: string, data?: SerializableValue) => void;
  error: (message: string, data?: SerializableValue) => void;
  info: (message: string, data?: SerializableValue) => void;
  warn: (message: string, data?: SerializableValue) => void;
};

const execAsync = promisify(exec);

export async function listShortcuts(log: Logger) {
  try {
    const { stdout } = await execAsync("shortcuts list --show-identifiers");
    return stdout.trim() || "No shortcuts found";
  } catch (error) {
    throw new Error(
      isExecError(error)
        ? `Failed to list shortcuts: ${error.message}`
        : String(error),
    );
  }
}

export async function runShortcut(log: Logger, name: string, input?: string) {
  log.info("Running Shortcut started", { hasInput: !!input, name });

  const escapedName = escapeAppleScriptString(name);
  const script = input
    ? `tell application "Shortcuts Events" to run the shortcut named "${escapedName}" with input "${escapeAppleScriptString(input)}"`
    : `tell application "Shortcuts Events" to run the shortcut named "${escapedName}"`;
  const command = `osascript -e ${shellEscape(script)}`;

  log.debug("AppleScript command constructed", {
    commandLength: command.length,
    escapedName,
    originalName: name,
    script: script.substring(0, 100) + "...",
  });

  const startTime = Date.now();
  try {
    const { stderr, stdout } = await execAsync(command);
    const duration = Date.now() - startTime;

    log.info("Shortcut execution completed", {
      duration,
      hasStderr: !!stderr,
      name,
      outputLength: stdout?.length ?? 0,
    });

    if (stderr) {
      log.warn("AppleScript stderr output", {
        isPermissionRelated:
          stderr.includes("permission") || stderr.includes("access"),
        isTimeout: stderr.includes("timeout"),
        name,
        stderr,
      });
    }
    return stdout ?? "Shortcut completed successfully";
  } catch (error) {
    const duration = Date.now() - startTime;
    log.error("Shortcut execution failed", {
      command: command.substring(0, 50) + "...",
      duration,
      errorType: isExecError(error) ? "exec" : "other",
      name,
    });

    if (
      isExecError(error) &&
      (error.message.includes("1743") || error.message.includes("permission"))
    ) {
      log.error("Permission denied - automation access required", {
        name,
        solution:
          "Grant automation permissions in System Preferences → Privacy & Security",
      });
    }

    throw new Error(
      isExecError(error)
        ? `Failed to run ${name} shortcut: ${error.message}`
        : String(error),
    );
  }
}

export async function viewShortcut(log: Logger, name: string) {
  log.info("Opening shortcut in editor", { name });

  try {
    await execAsync(`shortcuts view ${shellEscape(name)}`);
    log.info("Shortcut opened successfully", { name });
    return `Opened "${name}" in Shortcuts editor`;
  } catch (error) {
    log.warn("CLI view command failed - possible Apple name resolution bug", {
      name,
      suggestion: "Try exact case-sensitive name from shortcuts list",
    });
    throw error;
  }
}
