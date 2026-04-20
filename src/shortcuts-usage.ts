import deepmerge from "@fastify/deepmerge";
import { mkdir, readdir, readFile, writeFile } from "fs/promises";
import path from "path";

import {
  isDirectory,
  isDuplicatePurpose,
  isFile,
  isOlderThan24Hrs,
} from "./helpers.js";
import { logger } from "./logger.js";
import { listShortcuts } from "./shortcuts.js";

/*
~/.shortcuts-mcp/
├── user-profile.json          # User preferences and context settings
├── statistics.json        # 30-day computed statistics
└── executions/
    ├── 2025-08-01.json        # Daily execution logs (raw data)
    ├── 2025-07-31.json        # Previous daily logs

# File Contents:
# user-profile.json    - Manual preferences, current projects, focus areas
# daily logs          - Individual execution records with timestamps
# statistics.json     - Computed stats: totals, timing, per-shortcut data
 */

const DATED_FILE = /^\d{4}-\d{2}-\d{2}\.json$/;
const DATA_DIRECTORY = `${process.env.HOME}/.shortcuts-mcp/`;
const USER_PROFILE = `${DATA_DIRECTORY}user-profile.json`;
const EXECUTIONS = `${DATA_DIRECTORY}executions/`;
const SHORTCUTS_CACHE = `${DATA_DIRECTORY}shortcuts-cache.txt`;
const STATISTICS = `${DATA_DIRECTORY}statistics.json`;

export type RecentShortcutExecution = {
  duration: number;
  shortcut: string;
  success: boolean;
  timestamp: string;
};

export type ShortcutAnnotation = {
  purposes: string[];
};

export type ShortcutEntry = {
  id: string;
  purposes?: string[];
};

export type ShortcutExecution = {
  duration: number;
  shortcut: string;
  success: boolean;
  timestamp: string;
};

export type ShortcutsMap = Record<string, ShortcutEntry>;

export type ShortCutStatistics = Partial<{
  generatedAt: string;
  // eslint-disable-next-line perfectionist/sort-object-types
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
  annotations?: Record<string, ShortcutAnnotation>;
  context?: {
    "current-projects"?: string[];
    "focus-areas"?: string[];
  };
  preferences?: {
    "favorite-shortcuts"?: string[];
    "workflow-patterns"?: Record<string, string[]>;
  };
};

export async function enrichShortcutsWithAnnotations(
  shortcuts: ShortcutsMap,
): Promise<ShortcutsMap> {
  const profile = await loadUserProfile();
  if (!profile.annotations) return shortcuts;

  const enriched: ShortcutsMap = { ...shortcuts };
  for (const [name, entry] of Object.entries(enriched)) {
    const annotation = profile.annotations[name];
    if (annotation?.purposes?.length) {
      enriched[name] = { ...entry, purposes: annotation.purposes };
    }
  }
  return enriched;
}

export async function ensureDataDirectory() {
  try {
    await mkdir(DATA_DIRECTORY, { recursive: true });
    await mkdir(EXECUTIONS, { recursive: true });

    if (!(await isFile(STATISTICS))) {
      await writeFile(STATISTICS, "{}");
    }
    if (!(await isFile(USER_PROFILE))) {
      await writeFile(USER_PROFILE, "{}");
    }

    logger.info("Data directory initialized");
  } catch (error) {
    logger.error({ error: String(error) }, "Failed to create data directory");
    throw error;
  }
}

export async function getShortcutsList(): Promise<ShortcutsMap> {
  if (await isFile(SHORTCUTS_CACHE)) {
    try {
      const raw = await readFile(SHORTCUTS_CACHE, "utf8");
      const cache = JSON.parse(raw) as {
        shortcuts: ShortcutsMap;
        timestamp: string;
      };
      if (!isOlderThan24Hrs(cache.timestamp)) {
        return await enrichShortcutsWithAnnotations(cache.shortcuts);
      }
    } catch {
      logger.info("Cache unreadable, refreshing");
    }
  }

  logger.info("Refreshing shortcuts cache");

  await ensureDataDirectory();
  const cliOutput = await listShortcuts();
  const shortcuts = parseShortcutsList(cliOutput);
  const cache = { shortcuts, timestamp: new Date().toISOString() };
  await writeFile(SHORTCUTS_CACHE, JSON.stringify(cache));
  return await enrichShortcutsWithAnnotations(shortcuts);
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

export async function load<T = unknown>(filePath: string, defaultValue: T) {
  if (await isFile(filePath)) {
    const file = await readFile(filePath, "utf8");

    try {
      return JSON.parse(file) as T;
    } catch (error) {
      logger.error(
        { error: String(error), path: filePath },
        "JSON file corrupted",
      );
      throw new Error(`File at ${filePath} corrupted - please reset`, {
        cause: error,
      });
    }
  }

  await ensureDataDirectory();
  return defaultValue;
}

export async function loadExecutions() {
  if (!(await isDirectory(EXECUTIONS))) {
    await ensureDataDirectory();
    return { days: 0, executions: [] };
  }

  const files = await readdir(EXECUTIONS);
  const jsonFiles = files
    .filter((f) => DATED_FILE.test(f))
    .sort((a, b) => b.localeCompare(a));

  const executions: ShortcutExecution[] = [];

  for (const file of jsonFiles) {
    try {
      const content = await readFile(path.join(EXECUTIONS, file), "utf8");
      const parsed = JSON.parse(content);

      if (Array.isArray(parsed)) {
        executions.push(...parsed);
      } else {
        logger.warn({ file }, "Execution file is not an array, skipping");
      }
    } catch (err) {
      logger.warn(
        { error: String(err), file },
        "Skipping unreadable execution file",
      );
    }
  }

  return { days: jsonFiles.length, executions };
}

export async function loadStatistics() {
  return await load<ShortCutStatistics>(STATISTICS, {});
}

export async function loadUserProfile() {
  return await load<UserProfile>(USER_PROFILE, {});
}

export function parseShortcutsList(cliOutput: string): ShortcutsMap {
  const map: ShortcutsMap = {};
  for (const line of cliOutput.split("\n")) {
    const match = line.match(/^(.+?)\s+\(([^)]+)\)\s*$/);
    if (match) {
      map[match[1]] = { id: match[2] };
    }
  }
  return map;
}

export async function recordExecution({
  duration = 0,
  shortcut = "null",
  success = false,
}) {
  const timestamp = new Date().toISOString();
  const dateString = timestamp.split("T")[0]; // "2025-08-02"
  const filename = `${dateString}.json`;
  const filePath = `${EXECUTIONS}${filename}`;

  const execution: ShortcutExecution = {
    duration,
    shortcut,
    success,
    timestamp,
  };

  const executions = await load<ShortcutExecution[]>(filePath, []);
  executions.push(execution);
  await writeFile(filePath, JSON.stringify(executions));
  logger.debug({ shortcut, success }, "Execution recorded");
}

const PURPOSE_CAP = 8;

export async function recordPurpose({
  purpose,
  shortcut,
}: {
  purpose: string;
  shortcut: string;
}) {
  const profile = await loadUserProfile();
  const annotation = profile.annotations?.[shortcut] ?? { purposes: [] };

  if (isDuplicatePurpose(purpose, annotation.purposes)) {
    logger.debug({ purpose, shortcut }, "Duplicate purpose, skipping");
    return;
  }

  annotation.purposes.push(purpose);

  if (annotation.purposes.length > PURPOSE_CAP) {
    annotation.purposes = annotation.purposes.slice(-PURPOSE_CAP);
  }

  profile.annotations = {
    ...profile.annotations,
    [shortcut]: { purposes: annotation.purposes },
  };
  await writeFile(USER_PROFILE, JSON.stringify(profile));
  logger.debug({ purpose, shortcut }, "Purpose recorded");
}

export async function saveStatistics(data: ShortCutStatistics) {
  data.generatedAt = new Date().toISOString();
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
