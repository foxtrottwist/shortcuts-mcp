import { deepmerge } from "@fastify/deepmerge";
import { mkdir, readFile, writeFile } from "fs/promises";

import { isDirectory, isFile } from "./helpers.js";
import { logger } from "./logger.js";
import { listShortcuts } from "./shortcuts.js";

/*
~/.shortcuts-mcp/
├── user-profile.json          # User preferences and context settings
└── executions/
    ├── 2025-08-01.json        # Daily execution logs (raw data)
    ├── 2025-07-31.json        # Previous daily logs
    ├── recent.json            # Last 50 executions (quick access)
    └── statistics.json        # 30-day computed statistics

# File Contents:
# user-profile.json    - Manual preferences, current projects, focus areas
# daily logs          - Individual execution records with timestamps
# recent.json         - Cache of most recent executions  
# statistics.json     - Computed stats: totals, timing, per-shortcut data
 */

const DATA_DIRECTORY = `${process.env.HOME}/.shortcuts-mcp/`;
const USER_PROFILE = `${DATA_DIRECTORY}user-profile.json`;
const EXECUTIONS = `${DATA_DIRECTORY}executions/`;
const RECENT_EXECUTIONS = `${EXECUTIONS}recents.json`;
const SHORTCUTS_CACHE = `${DATA_DIRECTORY}shortcuts-cache.txt`;
const STATISTICS = `${EXECUTIONS}statistics.json`;

export type RecentShortcutExecution = {
  duration: number;
  shortcut: string;
  success: boolean;
  timestamp: string;
};

export type ShortcutExecution = {
  duration: number;
  input: string;
  output: string;
  shortcut: string;
  success: boolean;
  timestamp: string;
};

export type ShortCutStatistics = Partial<{
  executions: {
    failures: number;
    successes: number;
    total: number;
    unknown: number;
  };
  "per-shortcut": Record<
    string,
    {
      "avg-duration": number;
      count: number;
      "success-rate": number;
    }
  >;
  timing: {
    average: number; // milliseconds
    max: number;
    min: number;
  };
}>;

export type UserProfile = {
  context?: {
    "current-projects"?: string[];
    "focus-areas"?: string[];
  };
  preferences?: {
    "favorite-shortcuts"?: string[];
    "workflow-patterns"?: Record<string, string[]>;
  };
};

export async function ensureDataDirectory() {
  if (await isDirectory(DATA_DIRECTORY)) {
    return;
  }

  try {
    await mkdir(DATA_DIRECTORY, { recursive: true });
    await mkdir(EXECUTIONS, { recursive: true });
    await writeFile(RECENT_EXECUTIONS, JSON.stringify([]));
    await writeFile(STATISTICS, JSON.stringify({}));
    await writeFile(USER_PROFILE, JSON.stringify({}));
    logger.info("Data directory initialized");
  } catch (error) {
    logger.error({ error: String(error) }, "Failed to create data directory");
    throw error;
  }
}

export async function getShortcutsList() {
  if (await isFile(SHORTCUTS_CACHE)) {
    const shortcuts = await readFile(SHORTCUTS_CACHE, "utf8");
    const timestamp = shortcuts.match(/<<<(.*?)>>>/)?.[1];
    if (!isOlderThan24Hrs(timestamp)) {
      return shortcuts;
    }
  }

  logger.info("Refreshing shortcuts cache");

  await ensureDataDirectory();
  const timestamp = `Last Updated: <<<${new Date().toISOString()}>>>\n\n`;
  const shortcuts = await listShortcuts();
  await writeFile(SHORTCUTS_CACHE, timestamp + shortcuts);
  return shortcuts;
}

export function getSystemState() {
  return {
    dayOfWeek: new Date().getDay(),
    hour: new Date().getHours(),
    localTime: new Date().toLocaleString(),
    timestamp: new Date().toISOString(),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  };
}

export function isOlderThan24Hrs(timestamp?: string) {
  if (!timestamp) return true;
  const ts = new Date(timestamp.trim()).getTime();
  return !isNaN(ts) && Date.now() - ts > 24 * 60 * 60 * 1000;
}

export async function load<T = unknown>(path: string, defaultValue: T) {
  if (await isFile(path)) {
    const executions = await readFile(path, "utf8");

    try {
      return JSON.parse(executions) as T;
    } catch (error) {
      logger.error({ error: String(error), path }, "JSON file corrupted");
      throw new Error(`File at ${path} corrupted - please reset`);
    }
  }

  await ensureDataDirectory();
  return defaultValue;
}

export async function loadRecents() {
  return await load<RecentShortcutExecution[]>(RECENT_EXECUTIONS, []);
}

export async function loadUserProfile() {
  return await load<UserProfile>(USER_PROFILE, {});
}

export async function recordExecution({
  duration = 0,
  input = "",
  output = "null",
  shortcut = "null",
  success = false,
}) {
  const timestamp = new Date().toISOString();
  const dateString = timestamp.split("T")[0]; // "2025-08-02"
  const filename = `${dateString}.json`;
  const path = `${EXECUTIONS}${filename}`;

  await recordRecents({ duration, shortcut, success, timestamp });

  const execution: ShortcutExecution = {
    duration,
    input,
    output,
    shortcut,
    success,
    timestamp,
  };

  const executions = await load<ShortcutExecution[]>(path, []);
  executions.push(execution);
  await writeFile(path, JSON.stringify(executions));
  logger.debug({ shortcut, success }, "Execution recorded");
}

export async function recordRecents({
  duration = 0,
  shortcut = "",
  success = false,
  timestamp = "",
}) {
  const recent: RecentShortcutExecution = {
    duration,
    shortcut,
    success,
    timestamp,
  };

  const recents = await load<RecentShortcutExecution[]>(RECENT_EXECUTIONS, []);
  recents.push(recent);
  const trimmedRecents = recents.slice(-25);
  await writeFile(RECENT_EXECUTIONS, JSON.stringify(trimmedRecents));
}

export async function saveStatistics(data: ShortCutStatistics) {
  const stats = await load<ShortCutStatistics>(STATISTICS, {});
  const updatedStats = deepmerge()(stats, data);
  await writeFile(STATISTICS, JSON.stringify(updatedStats));
  return updatedStats;
}

export async function saveUserProfile(data: UserProfile) {
  const profile = await load<UserProfile>(USER_PROFILE, {});
  const updatedProfile = deepmerge()(profile, data);
  await writeFile(USER_PROFILE, JSON.stringify(updatedProfile));
  return updatedProfile;
}
