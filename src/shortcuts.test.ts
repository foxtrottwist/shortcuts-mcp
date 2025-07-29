import { exec, ExecException } from "child_process";
import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  listShortcuts,
  runShortcut,
  shellEscape,
  viewShortcut,
} from "../src/shortcuts.js";

vi.mock("child_process", () => ({
  exec: vi.fn(),
}));

const mockExec = vi.mocked(exec);

describe("shortcuts", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("shellEscape", () => {
    it("should wrap simple strings in single quotes", () => {
      expect(shellEscape("hello")).toBe("'hello'");
    });

    it("should escape single quotes correctly", () => {
      expect(shellEscape("don't")).toBe("'don'\"'\"'t'");
    });

    it("should handle multiple single quotes", () => {
      expect(shellEscape("can't won't")).toBe("'can'\"'\"'t won'\"'\"'t'");
    });

    it("should handle empty strings", () => {
      expect(shellEscape("")).toBe("''");
    });

    it("should handle strings with spaces", () => {
      expect(shellEscape("hello world")).toBe("'hello world'");
    });
  });

  describe("listShortcuts", () => {
    it("should execute shortcuts list command", async () => {
      const mockStdout = "Shortcut 1\nShortcut 2\nShortcut 3";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts list");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await listShortcuts();
      expect(result).toBe(mockStdout);
    });

    it("should handle stderr warnings", async () => {
      const mockStdout = "Shortcut 1";
      const mockStderr = "Warning: deprecated feature";
      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {});

      mockExec.mockImplementation((_command, callback) => {
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: mockStderr, stdout: mockStdout });
        return undefined as never;
      });

      const result = await listShortcuts();
      expect(result).toBe(mockStdout);
      expect(consoleSpy).toHaveBeenCalledWith(
        "Shortcuts warning: Warning: deprecated feature",
      );

      consoleSpy.mockRestore();
    });

    it("should throw error on command failure", async () => {
      const mockError = new Error("Command failed");
      mockExec.mockImplementation((_command, callback) => {
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(mockError as ExecException, null); // Cast mockError to ExecException
        return undefined as never;
      });

      await expect(listShortcuts()).rejects.toThrow(
        "Failed to list shortcut: Command failed",
      );
    });
  });

  describe("viewShortcut", () => {
    it("should execute shortcuts view command with escaped name", async () => {
      const mockStdout = "Shortcut details...";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts view 'My Shortcut'");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await viewShortcut("My Shortcut");
      expect(result).toBe(mockStdout);
    });

    it("should handle shortcut names with single quotes", async () => {
      const mockStdout = "Shortcut details...";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts view 'Don'\"'\"'t Delete'");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await viewShortcut("Don't Delete");
      expect(result).toBe(mockStdout);
    });
  });

  describe("runShortcut", () => {
    it("should execute shortcuts run command without input", async () => {
      const mockStdout = "Shortcut executed";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts run 'Test Shortcut'");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await runShortcut("Test Shortcut");
      expect(result).toBe(mockStdout);
    });

    it("should execute shortcuts run command with input", async () => {
      const mockStdout = "Shortcut executed with input";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts run 'Test Shortcut' <<< 'hello world'");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await runShortcut("Test Shortcut", "hello world");
      expect(result).toBe(mockStdout);
    });

    it("should handle empty string input", async () => {
      const mockStdout = "Shortcut executed";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe("shortcuts run 'Test Shortcut'");
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await runShortcut("Test Shortcut", "");
      expect(result).toBe(mockStdout);
    });

    it("should handle input with single quotes", async () => {
      const mockStdout = "Shortcut executed";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe(
          "shortcuts run 'Test Shortcut' <<< 'don'\"'\"'t stop'",
        );
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await runShortcut("Test Shortcut", "don't stop");
      expect(result).toBe(mockStdout);
    });

    it("should handle shortcut names and input with special characters", async () => {
      const mockStdout = "Complex test passed";
      mockExec.mockImplementation((command, callback) => {
        expect(command).toBe(
          "shortcuts run 'My \"Special\" Shortcut' <<< 'input with $pecial ch@rs'",
        );
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(null, { stderr: "", stdout: mockStdout });
        return undefined as never;
      });

      const result = await runShortcut(
        'My "Special" Shortcut',
        "input with $pecial ch@rs",
      );
      expect(result).toBe(mockStdout);
    });
  });

  describe("error handling", () => {
    it("should handle non-Error objects thrown", async () => {
      mockExec.mockImplementation((_command, callback) => {
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.("String error", null);
        return undefined as never;
      });

      await expect(listShortcuts()).rejects.toThrow(
        "Failed to list shortcut: String error",
      );
    });

    it("should preserve original error messages", async () => {
      const originalError = new Error("Permission denied");
      mockExec.mockImplementation((_command, callback) => {
        // @ts-expect-error: TypeScript struggles with exec overloads and vi.mocked type inference for the callback.
        callback?.(originalError as ExecException, null); // Cast originalError to ExecException
        return undefined as never;
      });

      await expect(runShortcut("Test")).rejects.toThrow(
        "Failed to run shortcut: Permission denied",
      );
    });
  });
});
