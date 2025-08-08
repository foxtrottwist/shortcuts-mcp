import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  ensureDataDirectory,
  getShortcutsList,
  getSystemState,
  load,
  loadUserProfile,
  recordExecution,
  saveStatistics,
  saveUserProfile,
} from "./user-context.js";

vi.mock("fs/promises", () => ({
  mkdir: vi.fn(),
  readFile: vi.fn(),
  writeFile: vi.fn(),
}));

vi.mock("./helpers.js", () => ({
  isDirectory: vi.fn(),
  isFile: vi.fn(),
  isOlderThan24Hrs: vi.fn(),
}));

vi.mock("./shortcuts.js", () => ({
  listShortcuts: vi.fn(),
}));

const { mkdir, readFile, writeFile } = await import("fs/promises");
const { isDirectory, isFile, isOlderThan24Hrs } = await import("./helpers.js");
const { listShortcuts } = await import("./shortcuts.js");

const mockMkdir = mkdir as ReturnType<typeof vi.fn>;
const mockReadFile = readFile as ReturnType<typeof vi.fn>;
const mockWriteFile = writeFile as ReturnType<typeof vi.fn>;
const mockIsDirectory = isDirectory as ReturnType<typeof vi.fn>;
const mockIsOlderThan24Hrs = isOlderThan24Hrs as ReturnType<typeof vi.fn>;
const mockIsFile = isFile as ReturnType<typeof vi.fn>;
const mockListShortcuts = listShortcuts as ReturnType<typeof vi.fn>;

describe("user-context", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2025-08-04T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe("ensureDataDirectory", () => {
    it("should not create directories if they already exist", async () => {
      mockIsFile.mockResolvedValue(true);
      mockMkdir.mockResolvedValue(undefined);

      await ensureDataDirectory();

      expect(mockMkdir).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/`,
        { recursive: true },
      );
      expect(mockMkdir).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/executions/`,
        { recursive: true },
      );
      expect(mockWriteFile).not.toHaveBeenCalled();
    });

    it("should create directories if they don't exist", async () => {
      mockIsFile.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      await ensureDataDirectory();

      expect(mockMkdir).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/`,
        { recursive: true },
      );
      expect(mockMkdir).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/executions/`,
        { recursive: true },
      );
      expect(mockWriteFile).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/statistics.json`,
        JSON.stringify({}),
      );
      expect(mockWriteFile).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/user-profile.json`,
        JSON.stringify({}),
      );
    });
  });

  describe("getShortcutsList", () => {
    it("should return cached shortcuts if less than 24 hours old", async () => {
      const cachedData = `Last Updated: <<<2025-08-04T10:00:00Z>>>\n\nShortcut 1\nShortcut 2`;
      const expectedShortcuts = `Shortcut 1\nShortcut 2`;
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(cachedData);

      const result = await getShortcutsList();

      expect(result).toBe(expectedShortcuts);
      expect(mockListShortcuts).not.toHaveBeenCalled();
    });

    it("should fetch new shortcuts if cache is older than 24 hours", async () => {
      const oldCachedData = `Last Updated: <<<2025-08-02T10:00:00Z>>>\n\nOld shortcuts`;
      const newShortcuts = "New Shortcut 1\nNew Shortcut 2";

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(oldCachedData);
      mockListShortcuts.mockResolvedValue(newShortcuts);
      mockIsDirectory.mockResolvedValue(false);
      mockIsOlderThan24Hrs.mockReturnValue(true);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await getShortcutsList();

      expect(mockListShortcuts).toHaveBeenCalled();
      expect(mockWriteFile).toHaveBeenCalledWith(
        expect.stringContaining("shortcuts-cache.txt"),
        expect.stringContaining(newShortcuts),
      );
      expect(result).toBe(newShortcuts);
    });

    it("should fetch shortcuts if no cache exists", async () => {
      const shortcuts = "Shortcut 1\nShortcut 2";

      mockIsFile.mockResolvedValue(false);
      mockListShortcuts.mockResolvedValue(shortcuts);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await getShortcutsList();

      expect(mockListShortcuts).toHaveBeenCalled();
      expect(result).toBe(shortcuts);
    });
  });

  describe("getSystemState", () => {
    it("should return current system state", () => {
      const state = getSystemState();

      expect(state).toMatchObject({
        dayOfWeek: expect.any(Number),
        hour: expect.any(Number),
        localTime: expect.any(String),
        timestamp: "2025-08-04T12:00:00.000Z",
        timezone: expect.any(String),
      });
      // Verify it's using the mocked time
      expect(state.timestamp).toBe("2025-08-04T12:00:00.000Z");
    });
  });

  describe("load", () => {
    it("should load and parse JSON file if it exists", async () => {
      const data = { test: "data" };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(data));

      const result = await load("/path/to/file.json", {});

      expect(result).toEqual(data);
      expect(mockReadFile).toHaveBeenCalledWith("/path/to/file.json", "utf8");
    });

    it("should return default value if file doesn't exist", async () => {
      const defaultValue = { default: true };
      mockIsFile.mockResolvedValue(false);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await load("/path/to/file.json", defaultValue);

      expect(result).toEqual(defaultValue);
      expect(mockReadFile).not.toHaveBeenCalled();
    });

    it("should throw error for corrupted JSON", async () => {
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue("invalid json {");

      await expect(load("/path/to/file.json", {})).rejects.toThrow(
        "File at /path/to/file.json corrupted - please reset",
      );
    });
  });

  describe("loadUserProfile", () => {
    it("should load user profile", async () => {
      const profile = {
        preferences: { "favorite-shortcuts": ["Test"] },
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(profile));

      const result = await loadUserProfile();

      expect(result).toEqual(profile);
    });

    it("should return empty object if file doesn't exist", async () => {
      mockIsFile.mockResolvedValue(false);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await loadUserProfile();

      expect(result).toEqual({});
    });
  });

  describe("recordExecution", () => {
    it("should record execution to daily file and recents", async () => {
      mockIsFile.mockResolvedValue(false);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      await recordExecution({
        duration: 100,
        input: "test input",
        output: "test output",
        shortcut: "Test Shortcut",
        success: true,
      });

      // Should write to daily file
      expect(mockWriteFile).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/executions/2025-08-04.json`,
        expect.stringContaining("Test Shortcut"),
      );
    });

    it("should append to existing daily file", async () => {
      const existingData = [{ shortcut: "Existing", timestamp: "earlier" }];
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(existingData));
      mockWriteFile.mockResolvedValue(undefined);

      await recordExecution({
        duration: 200,
        input: "",
        output: "output",
        shortcut: "New Shortcut",
        success: false,
      });

      const writeCall = mockWriteFile.mock.calls.find((call) =>
        call[0].includes("2025-08-04.json"),
      );

      expect(writeCall).toBeDefined();
      const writtenData = JSON.parse(writeCall![1]);
      expect(writtenData).toHaveLength(2);
      expect(writtenData[0]).toEqual(existingData[0]);
      expect(writtenData[1]).toMatchObject({
        shortcut: "New Shortcut",
        success: false,
      });
    });
  });

  describe("saveStatistics", () => {
    it("should merge new statistics with existing", async () => {
      const existing = {
        executions: { failures: 2, successes: 8, total: 10, unknown: 0 },
      };
      const newStats = {
        executions: { failures: 1, successes: 4, total: 5, unknown: 0 },
        timing: { average: 100, max: 150, min: 50 },
      };

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(existing));
      mockWriteFile.mockResolvedValue(undefined);

      const result = await saveStatistics(newStats);

      expect(mockWriteFile).toHaveBeenCalledWith(
        expect.stringContaining("statistics.json"),
        expect.stringContaining('"timing"'),
      );
      expect(result).toMatchObject({
        executions: { failures: 1, successes: 4, total: 5, unknown: 0 },
        timing: { average: 100, max: 150, min: 50 },
      });
    });
  });

  describe("saveUserProfile", () => {
    it("should merge new profile data with existing", async () => {
      const existing = {
        preferences: { "favorite-shortcuts": ["Old Favorite"] },
      };
      const newData = {
        context: { "current-projects": ["Project A"] },
        preferences: { "workflow-patterns": { morning: ["Coffee", "News"] } },
      };

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(existing));
      mockWriteFile.mockResolvedValue(undefined);

      const result = await saveUserProfile(newData);

      expect(result).toMatchObject({
        context: { "current-projects": ["Project A"] },
        preferences: {
          "favorite-shortcuts": ["Old Favorite"],
          "workflow-patterns": { morning: ["Coffee", "News"] },
        },
      });
    });
  });
});
