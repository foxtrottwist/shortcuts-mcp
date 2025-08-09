import { ExecException } from "child_process";
import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  escapeAppleScriptString,
  isDirectory,
  isExecError,
  isFile,
  isOlderThan24Hrs,
  shellEscape,
} from "./helpers.js";

vi.mock("fs/promises", () => ({
  stat: vi.fn(),
}));

const { stat } = await import("fs/promises");
const mockStat = stat as ReturnType<typeof vi.fn>;

describe("helpers", () => {
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

  describe("escapeAppleScriptString", () => {
    it("should escape backslashes", () => {
      expect(escapeAppleScriptString("path\\to\\file")).toBe(
        "path\\\\to\\\\file",
      );
    });

    it("should escape double quotes", () => {
      expect(escapeAppleScriptString('say "hello"')).toBe('say \\"hello\\"');
    });

    it("should escape both backslashes and quotes", () => {
      expect(escapeAppleScriptString('path\\to\\"file"')).toBe(
        'path\\\\to\\\\\\"file\\"',
      );
    });

    it("should handle empty strings", () => {
      expect(escapeAppleScriptString("")).toBe("");
    });
  });

  describe("isExecError", () => {
    it("should return true for valid ExecException objects", () => {
      const error = new Error("Command failed") as ExecException;
      error.stderr = "error output";
      error.stdout = "standard output";

      expect(isExecError(error)).toBe(true);
    });

    it("should return true even with empty stderr/stdout", () => {
      const error = new Error("Command failed") as ExecException;
      error.stderr = "";
      error.stdout = "";

      expect(isExecError(error)).toBe(true);
    });

    it("should return false for regular Error objects", () => {
      const error = new Error("Regular error");
      expect(isExecError(error)).toBe(false);
    });

    it("should return false for objects missing stderr", () => {
      const error = { message: "error", stdout: "output" };
      expect(isExecError(error)).toBe(false);
    });

    it("should return false for objects missing stdout", () => {
      const error = { message: "error", stderr: "error" };
      expect(isExecError(error)).toBe(false);
    });

    it("should return false for null", () => {
      expect(isExecError(null)).toBe(false);
    });

    it("should return false for undefined", () => {
      expect(isExecError(undefined)).toBe(false);
    });

    it("should return false for non-object types", () => {
      expect(isExecError("string")).toBe(false);
      expect(isExecError(123)).toBe(false);
      expect(isExecError(true)).toBe(false);
    });

    it("should handle objects with additional ExecException properties", () => {
      const error = new Error("Command failed") as ExecException;
      error.stderr = "error";
      error.stdout = "output";
      error.code = 1;
      error.killed = false;
      error.signal = undefined;
      error.cmd = "test command";

      expect(isExecError(error)).toBe(true);
    });
  });

  describe("isDirectory", () => {
    it("should return true for directories", async () => {
      mockStat.mockResolvedValueOnce({
        isDirectory: () => true,
        isFile: () => false,
      });

      const result = await isDirectory("/some/path");
      expect(result).toBe(true);
      expect(mockStat).toHaveBeenCalledWith("/some/path");
    });

    it("should return false for files", async () => {
      mockStat.mockResolvedValueOnce({
        isDirectory: () => false,
        isFile: () => true,
      });

      const result = await isDirectory("/some/file.txt");
      expect(result).toBe(false);
    });

    it("should return false on stat error", async () => {
      mockStat.mockRejectedValueOnce(new Error("File not found"));

      const result = await isDirectory("/nonexistent");
      expect(result).toBe(false);
    });
  });

  describe("isFile", () => {
    it("should return true for files", async () => {
      mockStat.mockResolvedValueOnce({
        isDirectory: () => false,
        isFile: () => true,
      });

      const result = await isFile("/some/file.txt");
      expect(result).toBe(true);
      expect(mockStat).toHaveBeenCalledWith("/some/file.txt");
    });

    it("should return false for directories", async () => {
      mockStat.mockResolvedValueOnce({
        isDirectory: () => true,
        isFile: () => false,
      });

      const result = await isFile("/some/directory");
      expect(result).toBe(false);
    });

    it("should return false on stat error", async () => {
      mockStat.mockRejectedValueOnce(new Error("File not found"));

      const result = await isFile("/nonexistent");
      expect(result).toBe(false);
    });
  });
});

describe("isOlderThan24Hrs", () => {
  it("should return true if timestamp is older than 24 hours", () => {
    const twoDaysAgo = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    expect(isOlderThan24Hrs(twoDaysAgo)).toBe(true);
  });

  it("should return false if timestamp is less than 24 hours old", () => {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    expect(isOlderThan24Hrs(oneHourAgo)).toBe(false);
  });

  it("should return true for undefined timestamp", () => {
    expect(isOlderThan24Hrs(undefined)).toBe(true);
  });

  it("should return false for invalid timestamp", () => {
    expect(isOlderThan24Hrs("invalid-date")).toBe(false);
  });
});
