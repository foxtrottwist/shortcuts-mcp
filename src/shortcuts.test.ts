import { ExecException } from "child_process";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { listShortcuts, runShortcut, viewShortcut } from "./shortcuts.js";

vi.mock("util", () => {
  const mockExecAsync = vi.fn();
  return {
    _mockExecAsync: mockExecAsync,
    promisify: vi.fn(() => mockExecAsync),
  };
});

const { _mockExecAsync: mockExecAsync } = (await import("util")) as unknown as {
  _mockExecAsync: ReturnType<typeof vi.fn>;
};

const mockLogger = {
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  warn: vi.fn(),
};

describe("shortcuts", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("listShortcuts", () => {
    it("should execute shortcuts list command with --show-identifiers flag", async () => {
      const mockStdout = "Shortcut 1\nShortcut 2\nShortcut 3";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await listShortcuts();

      expect(mockExecAsync).toHaveBeenCalledWith(
        "shortcuts list --show-identifiers",
      );
      expect(result).toBe(mockStdout);
    });

    it("should return 'No shortcuts found' for empty output", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: "  \n  " });

      const result = await listShortcuts();
      expect(result).toBe("No shortcuts found");
    });

    it("should throw error on command failure", async () => {
      const mockError = new Error("Command failed") as ExecException;
      mockError.stderr = "Error output";
      mockError.stdout = "";
      mockExecAsync.mockRejectedValue(mockError);

      await expect(listShortcuts()).rejects.toThrow(
        "Failed to list shortcuts: Command failed",
      );
    });

    it("should handle non-ExecException errors", async () => {
      mockExecAsync.mockRejectedValue(new Error("Unexpected error"));

      await expect(listShortcuts()).rejects.toThrow("Error: Unexpected error");
    });
  });

  describe("viewShortcut", () => {
    it("should execute shortcuts view command with escaped name", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: "" });

      const result = await viewShortcut(mockLogger, "My Shortcut");

      expect(mockExecAsync).toHaveBeenCalledWith(
        "shortcuts view 'My Shortcut'",
      );
      expect(result).toBe('Opened "My Shortcut" in Shortcuts editor');
      expect(mockLogger.info).toHaveBeenCalledWith(
        "Opening shortcut in editor",
        { name: "My Shortcut" },
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        "Shortcut opened successfully",
        { name: "My Shortcut" },
      );
    });

    it("should handle shortcut names with single quotes", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: "" });

      const result = await viewShortcut(mockLogger, "Don't Delete");

      expect(mockExecAsync).toHaveBeenCalledWith(
        "shortcuts view 'Don'\"'\"'t Delete'",
      );
      expect(result).toBe('Opened "Don\'t Delete" in Shortcuts editor');
    });

    it("should log warning and throw on failure", async () => {
      const mockError = new Error("View failed");
      mockExecAsync.mockRejectedValue(mockError);

      await expect(viewShortcut(mockLogger, "Test")).rejects.toThrow(
        "View failed",
      );
      expect(mockLogger.warn).toHaveBeenCalledWith(
        "CLI view command failed - possible Apple name resolution bug",
        {
          name: "Test",
          suggestion: "Try exact case-sensitive name from shortcuts list",
        },
      );
    });
  });

  describe("runShortcut", () => {
    it("should execute AppleScript command without input", async () => {
      const mockStdout = "Shortcut executed";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut(mockLogger, "Test Shortcut");

      const expectedScript =
        'tell application "Shortcuts Events" to run the shortcut named "Test Shortcut"';
      const expectedCommand = `osascript -e '${expectedScript}'`;

      expect(mockExecAsync).toHaveBeenCalledWith(expectedCommand);
      expect(result).toBe(mockStdout);
      expect(mockLogger.info).toHaveBeenCalledWith("Running Shortcut started", {
        hasInput: false,
        name: "Test Shortcut",
      });
    });

    it("should execute AppleScript command with input", async () => {
      const mockStdout = "Shortcut executed with input";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut(
        mockLogger,
        "Test Shortcut",
        "hello world",
      );

      const expectedScript =
        'tell application "Shortcuts Events" to run the shortcut named "Test Shortcut" with input "hello world"';
      const expectedCommand = `osascript -e '${expectedScript}'`;

      expect(mockExecAsync).toHaveBeenCalledWith(expectedCommand);
      expect(result).toBe(mockStdout);
      expect(mockLogger.info).toHaveBeenCalledWith("Running Shortcut started", {
        hasInput: true,
        name: "Test Shortcut",
      });
    });

    it("should handle names and input with special characters", async () => {
      const mockStdout = "Success";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut(
        mockLogger,
        'My "Special" Shortcut',
        'input with "quotes"',
      );

      const expectedScript =
        'tell application "Shortcuts Events" to run the shortcut named "My \\"Special\\" Shortcut" with input "input with \\"quotes\\""';
      const expectedCommand = `osascript -e '${expectedScript}'`;

      expect(mockExecAsync).toHaveBeenCalledWith(expectedCommand);
      expect(result).toBe(mockStdout);
    });

    it("should handle stderr warnings", async () => {
      const mockStdout = "Executed";
      const mockStderr = "Warning: permission required";
      mockExecAsync.mockResolvedValue({
        stderr: mockStderr,
        stdout: mockStdout,
      });

      const result = await runShortcut(mockLogger, "Test");

      expect(result).toBe(mockStdout);
      expect(mockLogger.warn).toHaveBeenCalledWith(
        "AppleScript stderr output",
        {
          isPermissionRelated: true,
          isTimeout: false,
          name: "Test",
          stderr: mockStderr,
        },
      );
    });

    it("should handle timeout warnings", async () => {
      const mockStderr = "Error: operation timeout";
      mockExecAsync.mockResolvedValue({ stderr: mockStderr, stdout: "Result" });

      await runShortcut(mockLogger, "Test");

      expect(mockLogger.warn).toHaveBeenCalledWith(
        "AppleScript stderr output",
        {
          isPermissionRelated: false,
          isTimeout: true,
          name: "Test",
          stderr: mockStderr,
        },
      );
    });

    it("should handle null stdout", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: null });

      const result = await runShortcut(mockLogger, "Test");

      expect(result).toBe("Shortcut completed successfully");
    });

    it("should handle permission errors", async () => {
      const mockError = new Error(
        "Error 1743: Permission denied",
      ) as ExecException;
      mockError.stderr = "Permission error";
      mockError.stdout = "";
      mockExecAsync.mockRejectedValue(mockError);

      await expect(runShortcut(mockLogger, "Test")).rejects.toThrow(
        "Failed to run Test shortcut: Error 1743: Permission denied",
      );

      expect(mockLogger.error).toHaveBeenCalledWith(
        "Permission denied - automation access required",
        {
          name: "Test",
          solution:
            "Grant automation permissions in System Preferences → Privacy & Security",
        },
      );
    });

    it("should handle generic errors", async () => {
      const mockError = new Error("Generic error");
      mockExecAsync.mockRejectedValue(mockError);

      await expect(runShortcut(mockLogger, "Test")).rejects.toThrow(
        "Error: Generic error",
      );
    });
  });

  describe("error handling", () => {
    it("should handle non-Error objects thrown", async () => {
      mockExecAsync.mockRejectedValue("String error");

      await expect(listShortcuts()).rejects.toThrow("String error");
    });

    it("should preserve original error messages", async () => {
      const originalError = new Error("Permission denied") as ExecException;
      originalError.stderr = "";
      originalError.stdout = "";
      mockExecAsync.mockRejectedValue(originalError);

      await expect(runShortcut(mockLogger, "Test")).rejects.toThrow(
        "Failed to run Test shortcut: Permission denied",
      );
    });
  });
});
