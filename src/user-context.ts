import { deepmerge } from "@fastify/deepmerge";
import { mkdir, readFile, writeFile } from "fs/promises";

import { isDirectory, isFile } from "./helpers.js";

const STORAGE = `${process.env.HOME}/.shortcuts-mcp/`;
const USER_PROFILE = `${STORAGE}/user-profile.json`;
const EXECUTIONS = `${STORAGE}/executions/`;
const SHORTCUTS = `${STORAGE}/shortcuts/`;

export type ShortCutStatistics = {
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
};

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
  if (await isDirectory(STORAGE)) {
    return;
  }

  await mkdir(STORAGE, { recursive: true });
  await mkdir(EXECUTIONS, { recursive: true });
  await mkdir(SHORTCUTS, { recursive: true });
  await writeFile(USER_PROFILE, JSON.stringify({}));
}

export async function loadUserProfile() {
  if (await isFile(USER_PROFILE)) {
    const userProfile = await readFile(USER_PROFILE, "utf8");

    try {
      return JSON.parse(userProfile) as UserProfile;
    } catch {
      throw new Error("User profile corrupted - please reset");
    }
  }

  await ensureDataDirectory();
  return {};
}

export async function saveUserProfile(data: UserProfile) {
  const profile = await loadUserProfile();
  const updatedProfile = deepmerge()(profile, data);
  await writeFile(USER_PROFILE, JSON.stringify(updatedProfile));
  return updatedProfile;
}
