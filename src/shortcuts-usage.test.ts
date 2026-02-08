import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  enrichShortcutsWithAnnotations,
  ensureDataDirectory,
  getShortcutsList,
  getSystemState,
  load,
  loadUserProfile,
  parseShortcutsList,
  recordExecution,
  recordPurpose,
  saveStatistics,
  saveUserProfile,
} from "./shortcuts-usage.js";

vi.mock("fs/promises", () => ({
  mkdir: vi.fn(),
  readFile: vi.fn(),
  writeFile: vi.fn(),
}));

vi.mock("./helpers.js", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./helpers.js")>();
  return {
    isDirectory: vi.fn(),
    isDuplicatePurpose: actual.isDuplicatePurpose,
    isFile: vi.fn(),
    isOlderThan24Hrs: vi.fn(),
  };
});

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

describe("shortcuts-usage", () => {
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

  describe("enrichShortcutsWithAnnotations", () => {
    it("should merge purposes from profile annotations", async () => {
      const shortcuts = {
        Morning: { id: "abc-123" },
        Timer: { id: "def-456" },
      };
      const profile = {
        annotations: { Morning: { purposes: ["check weather"] } },
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(profile));

      const result = await enrichShortcutsWithAnnotations(shortcuts);

      expect(result.Morning.purposes).toEqual(["check weather"]);
      expect(result.Timer.purposes).toBeUndefined();
    });

    it("should skip shortcuts without annotations", async () => {
      const shortcuts = { Timer: { id: "def-456" } };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify({}));

      const result = await enrichShortcutsWithAnnotations(shortcuts);

      expect(result.Timer.purposes).toBeUndefined();
    });

    it("should handle empty profile", async () => {
      const shortcuts = { Timer: { id: "def-456" } };
      mockIsFile.mockResolvedValue(false);
      mockIsDirectory.mockResolvedValue(false);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await enrichShortcutsWithAnnotations(shortcuts);

      expect(result).toEqual(shortcuts);
    });
  });

  describe("getShortcutsList", () => {
    it("should return cached shortcuts from JSON if fresh", async () => {
      const cache = {
        shortcuts: { "My Shortcut": { id: "abc-123" } },
        timestamp: "2025-08-04T10:00:00Z",
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(cache));
      mockIsOlderThan24Hrs.mockReturnValue(false);

      const result = await getShortcutsList();

      expect(result).toEqual({ "My Shortcut": { id: "abc-123" } });
      expect(mockListShortcuts).not.toHaveBeenCalled();
    });

    it("should refresh when cache is stale", async () => {
      const staleCache = {
        shortcuts: { Old: { id: "old-id" } },
        timestamp: "2025-08-02T10:00:00Z",
      };
      const cliOutput = "New Shortcut (new-id)";

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(staleCache));
      mockIsOlderThan24Hrs.mockReturnValue(true);
      mockListShortcuts.mockResolvedValue(cliOutput);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await getShortcutsList();

      expect(mockListShortcuts).toHaveBeenCalled();
      expect(result).toEqual({ "New Shortcut": { id: "new-id" } });
    });

    it("should refresh when no cache exists", async () => {
      const cliOutput = "Shortcut 1 (id-1)\nShortcut 2 (id-2)";

      mockIsFile.mockResolvedValue(false);
      mockListShortcuts.mockResolvedValue(cliOutput);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await getShortcutsList();

      expect(mockListShortcuts).toHaveBeenCalled();
      expect(result).toEqual({
        "Shortcut 1": { id: "id-1" },
        "Shortcut 2": { id: "id-2" },
      });
    });

    it("should gracefully handle old plaintext cache format", async () => {
      const oldFormat = `Last Updated: <<<2025-08-04T10:00:00Z>>>\n\nShortcut 1\nShortcut 2`;
      const cliOutput = "Shortcut 1 (id-1)";

      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockImplementation((filePath: string) => {
        if (filePath.includes("shortcuts-cache"))
          return Promise.resolve(oldFormat);
        // user-profile.json
        return Promise.resolve(JSON.stringify({}));
      });
      mockListShortcuts.mockResolvedValue(cliOutput);
      mockMkdir.mockResolvedValue(undefined);
      mockWriteFile.mockResolvedValue(undefined);

      const result = await getShortcutsList();

      expect(mockListShortcuts).toHaveBeenCalled();
      expect(result).toEqual({ "Shortcut 1": { id: "id-1" } });
    });
  });

  describe("parseShortcutsList", () => {
    it("should parse valid CLI output", () => {
      const output = "Morning Summary (abc-123)\nSet Timer (def-456)";
      const result = parseShortcutsList(output);

      expect(result).toEqual({
        "Morning Summary": { id: "abc-123" },
        "Set Timer": { id: "def-456" },
      });
    });

    it("should handle whitespace in names", () => {
      const output = "My Long Shortcut Name (id-123)";
      const result = parseShortcutsList(output);

      expect(result).toEqual({
        "My Long Shortcut Name": { id: "id-123" },
      });
    });

    it("should skip malformed lines", () => {
      const output = "Valid Shortcut (id-1)\nno-parens-here\n\nAnother (id-2)";
      const result = parseShortcutsList(output);

      expect(result).toEqual({
        Another: { id: "id-2" },
        "Valid Shortcut": { id: "id-1" },
      });
    });

    it("should return empty map for empty input", () => {
      expect(parseShortcutsList("")).toEqual({});
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

  describe("recordPurpose", () => {
    it("should record purpose for new shortcut", async () => {
      // loadUserProfile: file exists, empty profile
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify({}));
      mockWriteFile.mockResolvedValue(undefined);

      await recordPurpose({ purpose: "check weather", shortcut: "Morning" });

      const writeCall = mockWriteFile.mock.calls.find((call) =>
        call[0].includes("user-profile.json"),
      );
      expect(writeCall).toBeDefined();
      const written = JSON.parse(writeCall![1]);
      expect(written.annotations.Morning.purposes).toContain("check weather");
    });

    it("should append purpose to existing annotations", async () => {
      const profile = {
        annotations: { Morning: { purposes: ["check weather"] } },
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(profile));
      mockWriteFile.mockResolvedValue(undefined);

      await recordPurpose({ purpose: "read news", shortcut: "Morning" });

      const writeCall = mockWriteFile.mock.calls.find((call) =>
        call[0].includes("user-profile.json"),
      );
      const written = JSON.parse(writeCall![1]);
      expect(written.annotations.Morning.purposes).toEqual([
        "check weather",
        "read news",
      ]);
    });

    it("should skip duplicate purpose", async () => {
      const profile = {
        annotations: { Morning: { purposes: ["check weather"] } },
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(profile));
      mockWriteFile.mockResolvedValue(undefined);

      await recordPurpose({ purpose: "Check Weather", shortcut: "Morning" });

      // writeFile should not be called for user-profile (only reads happened)
      expect(mockWriteFile).not.toHaveBeenCalled();
    });

    it("should evict oldest when over cap of 8", async () => {
      const profile = {
        annotations: {
          Morning: {
            purposes: ["p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8"],
          },
        },
      };
      mockIsFile.mockResolvedValue(true);
      mockReadFile.mockResolvedValue(JSON.stringify(profile));
      mockWriteFile.mockResolvedValue(undefined);

      await recordPurpose({ purpose: "p9", shortcut: "Morning" });

      const writeCall = mockWriteFile.mock.calls.find((call) =>
        call[0].includes("user-profile.json"),
      );
      const written = JSON.parse(writeCall![1]);
      const purposes = written.annotations.Morning.purposes;
      expect(purposes).toHaveLength(8);
      expect(purposes[0]).toBe("p2");
      expect(purposes[7]).toBe("p9");
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
