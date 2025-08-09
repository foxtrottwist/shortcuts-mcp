import { Content, FastMCP } from "fastmcp";
import { z } from "zod";

import { getVersion } from "./helpers.js";
import { logger } from "./logger.js";
import { requestStatistics } from "./sampling.js";
import { runShortcut, viewShortcut } from "./shortcuts.js";
import {
  getShortcutsList,
  getSystemState,
  loadUserProfile,
  saveUserProfile,
} from "./user-context.js";

const server = new FastMCP({
  name: "Shortcuts",
  version: getVersion(),
});

server.addTool({
  annotations: {
    openWorldHint: true,
    readOnlyHint: false,
    title: "Run Shortcut",
  },
  description:
    "Execute a macOS Shortcut by name with optional input. Use when users want to run any shortcut including interactive workflows with file pickers, dialogs, location services, and system permissions. All shortcut types are supported through AppleScript integration.",
  async execute(args, { log }) {
    const { input, name } = args;
    log.info("Tool execution started", {
      hasInput: !!input,
      shortcut: name,
      tool: "run_shortcut",
    });

    return {
      content: [
        {
          text: await runShortcut(args.name, args.input),
          type: "text",
        },
        {
          resource: await server.embedded("context://system/current"),
          type: "resource",
        },
      ],
    };
  },
  name: "run_shortcut",
  parameters: z.object({
    input: z
      .string()
      .optional()
      .describe("Optional input to pass to the shortcut"),
    name: z.string().describe("The name of the Shortcut to run"),
  }),
});

server.addTool({
  annotations: {
    openWorldHint: false,
    readOnlyHint: false,
    title: "Usage History & Preferences",
  },
  description:
    "Access shortcut usage history, execution patterns, and user preferences. Use for questions like 'What shortcuts have I used this week?', 'Which shortcuts failed recently?', 'Show me my most used shortcuts', or when users want to store preferences like 'Remember I prefer Photo Editor Pro for image work' or 'I use the Morning Routine shortcut daily'.",
  async execute(args, { log }) {
    const { action, data = {}, resources = [] } = args;

    log.info("User context operation started", {
      action,
      hasData: Object.keys(data).length > 0,
    });

    const result: Record<"content", Content[]> = { content: [] };

    for (const resource of resources) {
      switch (resource) {
        case "profile":
          result.content.push({
            resource: await server.embedded("context://user/profile"),
            type: "resource",
          });
          break;
        case "shortcuts":
          result.content.push({
            resource: await server.embedded("shortcuts://available"),
            type: "resource",
          });
          break;
        case "statistics":
          result.content.push({
            resource: await server.embedded("statistics://generated"),
            type: "resource",
          });
          break;
      }
    }

    switch (action) {
      case "read": {
        log.info(`User loaded: ${resources.join(", ")}`);
        return result;
      }
      case "update": {
        const profile = await saveUserProfile(data);

        log.info("User profile updated", {
          updatedFields: Object.keys(data),
        });

        if (!resources.includes("profile")) {
          result.content.push({
            text: JSON.stringify(profile),
            type: "text",
          });
        }
        return result;
      }
    }
  },
  name: "user_context",
  parameters: z.object({
    action: z.enum(["read", "update"]),
    data: z
      .object({
        context: z
          .object({
            "current-projects": z.array(z.string()).optional(),
            "focus-areas": z.array(z.string()).optional(),
          })
          .optional(),
        preferences: z
          .object({
            "favorite-shortcuts": z.array(z.string()).optional(),
            "workflow-patterns": z.record(z.array(z.string())).optional(),
          })
          .optional(),
      })
      .optional(),
    resources: z
      .array(z.enum(["profile", "shortcuts", "statistics"]))
      .optional()
      .describe(
        "Contextual resources to include. Consider time elapsed and conversation needs: 'shortcuts' for discovery/validation, 'recents' for troubleshooting/patterns, 'profile' for personalized recommendations.",
      ),
  }),
});

server.addTool({
  annotations: {
    openWorldHint: true,
    readOnlyHint: true,
    title: "View Shortcut",
  },
  description:
    "Open a macOS Shortcut in the Shortcuts editor for viewing or editing. Use when users want to examine shortcut contents, modify workflows, or troubleshoot shortcut logic. Opens the shortcut directly in the native Shortcuts app.",
  async execute(args) {
    return String(await viewShortcut(args.name));
  },
  name: "view_shortcut",
  parameters: z.object({
    name: z.string().describe("The name of the Shortcut to view"),
  }),
});

server.addResource({
  description:
    "Complete list of available shortcuts with names and identifiers, refreshed every 24 hours. Contains all shortcuts in the user's library for discovery and name validation.",
  async load() {
    return {
      text: await getShortcutsList(),
    };
  },
  mimeType: "text/plain",
  name: "Current shortcuts list",
  uri: "shortcuts://available",
});

server.addResourceTemplate({
  arguments: [{ description: "Shortcut name", name: "name", required: true }],
  description:
    "Execution history for a specific shortcut including success rates, timing patterns, recent failures, and usage frequency. Used for per-shortcut analysis and troubleshooting.",
  async load(args) {
    return { text: args.name };
  },
  mimeType: "text/plain",
  name: "Per-shortcut execution data",
  uriTemplate: "shortcuts://runs/{name}",
});

server.addResource({
  description:
    "Current system time, timezone, day of week, and timestamp. Used for calculating time ranges like 'this week', 'today', 'recently' when analyzing execution history.",
  async load() {
    return {
      text: JSON.stringify(getSystemState()),
    };
  },
  mimeType: "application/json",
  name: "Live system state",
  uri: "context://system/current",
});

server.addResource({
  description:
    "AI-generated statistics from execution history including success rates, timing analysis, and per-shortcut performance data. Refreshed every 24 hours via sampling analysis.",
  async load() {
    const session = server.sessions[0];
    return {
      text: JSON.stringify(await requestStatistics(session)),
    };
  },
  mimeType: "application/json",
  name: "Execution statistics & insights",
  uri: "statistics://generated",
});

server.addResource({
  description:
    "User preferences including favorite shortcuts, workflow patterns, current projects, and focus areas. Contains stored user preferences and contextual information for personalized recommendations.",
  async load() {
    return {
      text: JSON.stringify(await loadUserProfile()),
    };
  },
  mimeType: "text/plain",
  name: "User preferences & usage patterns",
  uri: "context://user/profile",
});

server.addPrompt({
  arguments: [
    {
      description: "What the user wants to accomplish",
      name: "task_description",
      required: true,
    },
    {
      description: "Additional context (input type, desired output, etc.)",
      name: "context",
      required: false,
    },
  ],
  description:
    "Analyze available shortcuts and user context to recommend the best shortcut for a specific task. Use when users describe what they want to accomplish but don't know which shortcut to use. Provides intelligent shortcut discovery based on task description and user preferences.",
  load: async (args) => {
    return `The user wants to: ${args.task_description}
${args.context ? `Context: ${args.context}` : ""}

Analyze the available shortcuts and user context from the embedded resources to recommend the best shortcut for this task.

Then analyze which shortcut(s) would best accomplish this task:
1. Look for exact matches first
2. Consider shortcuts that could be adapted  
3. If no perfect match exists, suggest the closest alternatives
4. Explain why you're recommending specific shortcuts
5. Provide usage guidance for the recommended shortcut(s)

IMPORTANT: When recommending shortcuts:
- Use the EXACT name from the shortcuts list (case-sensitive)
- AppleScript execution (run_shortcut) is more forgiving than CLI commands (view_shortcut)

Be specific about which shortcut to use and how to use it effectively.`;
  },
  name: "Recommend a Shortcut",
});

server.start({
  transportType: "stdio",
});

server.on("connect", async (event) => {
  const session = event.session;
  await requestStatistics(session).catch(logger.error);
});
