import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  ensureDataDirectory,
  getShortcutsList,
  getSystemState,
  isOlderThan24Hrs,
  load,
  loadRecents,
  loadUserProfile,
  recordExecution,
  recordRecents,
  saveStatistics,
  saveUserProfile,
} from "./user-context.js";

// Mock fs/promises
vi.mock("fs/promises", () => ({
  mkdir: vi.fn(),
  readFile: vi.fn(),
  writeFile: vi.fn(),
}));

// Mock helpers
vi.mock("./helpers.js", () => ({
  isDirectory: vi.fn(),
  isFile: vi.fn(),
}));

// Mock shortcuts
vi.mock("./shortcuts.js", () => ({
  listShortcuts: vi.fn(),
}));

const { mkdir, readFile, writeFile } = await import("fs/promises");
const { isDirectory, isFile } = await import("./helpers.js");
const { listShortcuts } = await import("./shortcuts.js");

const mockMkdir = mkdir as ReturnType<typeof vi.fn>;
const mockReadFile = readFile as ReturnType<typeof vi.fn>;
const mockWriteFile = writeFile as ReturnType<typeof vi.fn>;
const mockIsDirectory = isDirectory as ReturnType<typeof vi.fn>;
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
      mockIsDirectory.mockResolvedValue(true);

      await ensureDataDirectory();

      expect(mockIsDirectory).toHaveBeenCalledWith(
        `${process.env.HOME}/.shortcuts-mcp/`,
      );
      expect(mockMkdir).not.toHaveBeenCalled();
    });

    it("should create directories if they don't exist", async () => {
      mockIsDirectory.mockResolvedValue(false);
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
        `${process.env.HOME}/.shortcuts-mcp/executions/statistics.json`,
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
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(cachedData);

      const result = await getShortcutsList();

      expect(result).toBe(cachedData);
      expect(mockListShortcuts).not.toHaveBeenCalled();
    });

    it("should fetch new shortcuts if cache is older than 24 hours", async () => {
      const oldCachedData = `Last Updated: <<<2025-08-02T10:00:00Z>>>\n\nOld shortcuts`;
      const newShortcuts = "New Shortcut 1\nNew Shortcut 2";

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(oldCachedData);
      mockListShortcuts.mockResolvedValue(newShortcuts);
      mockIsDirectory.mockResolvedValue(false);
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

  describe("isOlderThan24Hrs", () => {
    it("should return true if timestamp is older than 24 hours", () => {
      const oldTimestamp = "2025-08-02T12:00:00Z";
      expect(isOlderThan24Hrs(oldTimestamp)).toBe(true);
    });

    it("should return false if timestamp is less than 24 hours old", () => {
      const recentTimestamp = "2025-08-04T10:00:00Z";
      expect(isOlderThan24Hrs(recentTimestamp)).toBe(false);
    });

    it("should return true for undefined timestamp", () => {
      expect(isOlderThan24Hrs(undefined)).toBe(true);
    });

    it("should return false for invalid timestamp", () => {
      expect(isOlderThan24Hrs("invalid-date")).toBe(false);
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

  describe("loadRecents", () => {
    it("should load recent executions", async () => {
      const recents = [
        {
          duration: 100,
          shortcut: "Test",
          success: true,
          timestamp: "2025-08-04T12:00:00Z",
        },
      ];
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(recents));

      const result = await loadRecents();

      expect(result).toEqual(recents);
    });

    it("should return empty array if file doesn't exist", async () => {
      mockIsFile.mockResolvedValue(false);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await loadRecents();

      expect(result).toEqual([]);
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

      // Should update recents
      expect(mockWriteFile).toHaveBeenCalledWith(
        expect.stringContaining("recents.json"),
        expect.any(String),
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

  describe("recordRecents", () => {
    it("should add to recents and trim to last 25", async () => {
      const existingRecents = Array(30)
        .fill(null)
        .map((_, i) => ({
          duration: i,
          shortcut: `Shortcut ${i}`,
          success: true,
          timestamp: `2025-08-04T${i}:00:00Z`,
        }));

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(existingRecents));
      mockWriteFile.mockResolvedValue(undefined);

      await recordRecents({
        duration: 100,
        shortcut: "New Recent",
        success: true,
        timestamp: "2025-08-04T12:00:00Z",
      });

      const writeCall = mockWriteFile.mock.calls[0];
      const writtenData = JSON.parse(writeCall[1]);

      expect(writtenData).toHaveLength(25);
      expect(writtenData[24]).toMatchObject({ shortcut: "New Recent" });
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
