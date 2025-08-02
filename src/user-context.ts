import { deepmerge } from "@fastify/deepmerge";
import { mkdir, readFile, writeFile } from "fs/promises";

import { isDirectory, isFile } from "./helpers.js";

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
const STATISTICS = `${EXECUTIONS}statistics.json`;

export type ShortCutExecution = {
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

export type UserProfile = Partial<{
  context: {
    "current-projects": string[];
    "focus-areas": string[];
  };
  preferences: {
    "favorite-shortcuts": string[];
    "workflow-patterns": Record<string, string[]>;
  };
}>;

export async function ensureDataDirectory() {
  if (await isDirectory(DATA_DIRECTORY)) {
    return;
  }

  await mkdir(DATA_DIRECTORY, { recursive: true });
  await mkdir(EXECUTIONS, { recursive: true });
  await writeFile(STATISTICS, JSON.stringify({}));
  await writeFile(USER_PROFILE, JSON.stringify({}));
}

export async function loadExecutions(path: string) {
  if (await isFile(path)) {
    const executions = await readFile(path, "utf8");

    try {
      return JSON.parse(executions) as ShortCutExecution[];
    } catch {
      throw new Error("User executions corrupted - please reset");
    }
  }

  await ensureDataDirectory();
  return [];
}

export async function loadStatistics() {
  if (await isFile(STATISTICS)) {
    const stats = await readFile(STATISTICS, "utf8");

    try {
      return JSON.parse(stats) as ShortCutStatistics;
    } catch {
      throw new Error("User statistics corrupted - please reset");
    }
  }

  await ensureDataDirectory();
  return {};
}

export async function loadUserProfile() {
  if (await isFile(USER_PROFILE)) {
    const profile = await readFile(USER_PROFILE, "utf8");

    try {
      return JSON.parse(profile) as UserProfile;
    } catch {
      throw new Error("User profile corrupted - please reset");
    }
  }

  await ensureDataDirectory();
  return {};
}

export async function recordExecution(
  shortcut = "null",
  input = "",
  output = "null",
  duration = 0,
  success = false,
) {
  const timestamp = new Date().toISOString();
  const dateString = timestamp.split("T")[0]; // "2025-08-02"
  const filename = `${dateString}.json`;
  const path = `${EXECUTIONS}${filename}`;

  const execution: ShortCutExecution = {
    duration,
    input,
    output,
    shortcut,
    success,
    timestamp,
  };

  const executions = await loadExecutions(path);
  executions.push(execution);
  await writeFile(path, JSON.stringify(executions));
}

export async function saveStatistics(data: ShortCutStatistics) {
  const stats = await loadStatistics();
  const updatedStats = deepmerge()(stats, data);
  await writeFile(STATISTICS, JSON.stringify(updatedStats));
  return updatedStats;
}

export async function saveUserProfile(data: UserProfile) {
  const profile = await loadUserProfile();
  const updatedProfile = deepmerge()(profile, data);
  await writeFile(USER_PROFILE, JSON.stringify(updatedProfile));
  return updatedProfile;
}
