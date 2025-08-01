import { ExecException } from "child_process";
import { describe, expect, it } from "vitest";

import {
  escapeAppleScriptString,
  isExecError,
  shellEscape,
} from "./helpers.js";

describe("helpers", () => {
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
});
