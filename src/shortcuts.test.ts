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

vi.mock("./user-context.js", () => ({
  recordExecution: vi.fn(),
}));

vi.mock("./logger.js", () => ({
  logger: {
    debug: vi.fn(),
    error: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
  },
}));

const { _mockExecAsync: mockExecAsync } = (await import("util")) as unknown as {
  _mockExecAsync: ReturnType<typeof vi.fn>;
};

const { recordExecution } = await import("./user-context.js");
const mockRecordExecution = recordExecution as ReturnType<typeof vi.fn>;

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

      const result = await viewShortcut("My Shortcut");

      expect(mockExecAsync).toHaveBeenCalledWith(
        "shortcuts view 'My Shortcut'",
      );
      expect(result).toBe('Opened "My Shortcut" in Shortcuts editor');
    });

    it("should handle shortcut names with single quotes", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: "" });

      const result = await viewShortcut("Don't Delete");

      expect(mockExecAsync).toHaveBeenCalledWith(
        "shortcuts view 'Don'\"'\"'t Delete'",
      );
      expect(result).toBe('Opened "Don\'t Delete" in Shortcuts editor');
    });

    it("should log warning and throw on failure", async () => {
      const mockError = new Error("View failed");
      mockExecAsync.mockRejectedValue(mockError);

      await expect(viewShortcut("Test")).rejects.toThrow("View failed");
    });
  });

  describe("runShortcut", () => {
    it("should execute AppleScript command without input", async () => {
      const mockStdout = "Shortcut executed";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut("Test Shortcut");

      const expectedScript =
        'tell application "Shortcuts Events" to run the shortcut named "Test Shortcut"';
      const expectedCommand = `osascript -e '${expectedScript}'`;

      expect(mockExecAsync).toHaveBeenCalledWith(expectedCommand);
      expect(result).toBe(mockStdout);
      expect(mockRecordExecution).toHaveBeenCalledWith({
        duration: expect.any(Number),
        input: undefined,
        output: mockStdout,
        shortcut: "Test Shortcut",
        success: true,
      });
    });

    it("should execute AppleScript command with input", async () => {
      const mockStdout = "Shortcut executed with input";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut("Test Shortcut", "hello world");

      const expectedScript =
        'tell application "Shortcuts Events" to run the shortcut named "Test Shortcut" with input "hello world"';
      const expectedCommand = `osascript -e '${expectedScript}'`;

      expect(mockExecAsync).toHaveBeenCalledWith(expectedCommand);
      expect(result).toBe(mockStdout);
    });

    it("should handle names and input with special characters", async () => {
      const mockStdout = "Success";
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: mockStdout });

      const result = await runShortcut(
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

      const result = await runShortcut("Test");

      expect(result).toBe(mockStdout);
    });

    it("should handle timeout warnings", async () => {
      const mockStderr = "Error: operation timeout";
      mockExecAsync.mockResolvedValue({ stderr: mockStderr, stdout: "Result" });

      const result = await runShortcut("Test");

      expect(result).toBe("Result");
    });

    it("should handle null stdout", async () => {
      mockExecAsync.mockResolvedValue({ stderr: "", stdout: null });

      const result = await runShortcut("Test");

      expect(result).toBe("Shortcut completed successfully");
    });

    it("should handle permission errors", async () => {
      const mockError = new Error(
        "Error 1743: Permission denied",
      ) as ExecException;
      mockError.stderr = "Permission error";
      mockError.stdout = "";
      mockExecAsync.mockRejectedValue(mockError);

      await expect(runShortcut("Test")).rejects.toThrow(
        "Failed to run Test shortcut: Error 1743: Permission denied",
      );
      expect(mockRecordExecution).toHaveBeenCalledWith({
        duration: expect.any(Number),
        input: undefined,
        output: String(mockError),
        shortcut: "Test",
        success: false,
      });
    });

    it("should handle generic errors", async () => {
      const mockError = new Error("Generic error");
      mockExecAsync.mockRejectedValue(mockError);

      await expect(runShortcut("Test")).rejects.toThrow("Error: Generic error");
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

      await expect(runShortcut("Test")).rejects.toThrow(
        "Failed to run Test shortcut: Permission denied",
      );
    });
  });
});
