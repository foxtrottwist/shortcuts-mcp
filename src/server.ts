import { Content, FastMCP } from "fastmcp";
import { z } from "zod";

import { getVersion, resolveShortcutName } from "./helpers.js";
import { logger } from "./logger.js";
import { requestStatistics } from "./sampling.js";
import {
  getShortcutsList,
  getSystemState,
  loadUserProfile,
  recordPurpose,
  saveUserProfile,
} from "./shortcuts-usage.js";
import { runShortcut, viewShortcut } from "./shortcuts.js";

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
    "Execute a macOS Shortcut by name with optional input. Names resolve case-insensitively. If unsure which shortcut to run, call shortcuts_usage with resources: ['shortcuts'] to browse available shortcuts with purpose annotations. Error 1743 means the user must grant automation access in System Settings > Privacy & Security > Automation.",
  async execute(args, { log }) {
    const { input, name, purpose } = args;

    const shortcuts = await getShortcutsList();
    const { canonical, resolved } = resolveShortcutName(name, shortcuts);

    log.info("Tool execution started", {
      hasInput: !!input,
      resolved,
      shortcut: canonical,
      tool: "run_shortcut",
    });

    let text = await runShortcut(canonical, input);

    if (resolved) {
      text = `[Resolved "${name}" -> "${canonical}"]\n${text}`;
    }

    if (purpose) {
      await recordPurpose({ purpose, shortcut: canonical });
    }

    return {
      content: [
        { text, type: "text" },
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
    purpose: z
      .string()
      .optional()
      .describe(
        "Always include. Brief phrase describing the user's goal (e.g. 'check weather forecast', 'start focus timer'). Builds annotations that make shortcuts discoverable across sessions.",
      ),
  }),
});

server.addTool({
  annotations: {
    openWorldHint: false,
    readOnlyHint: false,
    title: "Shortcuts Usage & Analytics",
  },
  description:
    "Access shortcut usage history, execution patterns, and user preferences. Before asking the user which shortcut to use, load the shortcuts resource (resources: ['shortcuts']) — entries with 'purposes' describe what shortcuts do, enabling intent matching without prompting.",
  async execute(args, { log }) {
    const { action, data = {}, resources = [] } = args;

    log.info("Shortcuts usage operation started", {
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
  name: "shortcuts_usage",
  parameters: z.object({
    action: z.enum(["read", "update"]),
    data: z
      .object({
        annotations: z
          .record(z.string(), z.object({ purposes: z.array(z.string()) }))
          .optional(),
        context: z
          .object({
            "current-projects": z.array(z.string()).optional(),
            "focus-areas": z.array(z.string()).optional(),
          })
          .optional(),
        preferences: z
          .object({
            "favorite-shortcuts": z.array(z.string()).optional(),
            "workflow-patterns": z
              .record(z.string(), z.array(z.string()))
              .optional(),
          })
          .optional(),
      })
      .optional(),
    resources: z
      .array(z.enum(["profile", "shortcuts", "statistics"]))
      .optional()
      .describe(
        "Contextual resources to include. 'shortcuts' for available shortcuts with purpose annotations, 'profile' for user preferences and workflow patterns, 'statistics' for execution analytics.",
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
    "Open a macOS Shortcut in the Shortcuts editor for viewing or editing. Use for shortcuts requiring interactive UI (file pickers, dialogs, prompts) since MCP cannot display their interface.",
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
    "JSON map of available shortcuts keyed by name, each with an ID and optional 'purposes' array from prior usage. Cache refreshes every 24 hours.",
  async load() {
    const shortcuts = await getShortcutsList();
    return {
      text: JSON.stringify(shortcuts, null, 2),
    };
  },
  mimeType: "application/json",
  name: "Current shortcuts list",
  uri: "shortcuts://available",
});

server.addResourceTemplate({
  arguments: [{ description: "Shortcut name", name: "name", required: true }],
  description:
    "Execution history for a specific shortcut including success rates, timing patterns, and usage frequency.",
  async load(args) {
    return { text: args.name };
  },
  mimeType: "text/plain",
  name: "Per-shortcut execution data",
  uriTemplate: "shortcuts://runs/{name}",
});

server.addResource({
  description:
    "Current system time, timezone, and timestamp for time-based analysis.",
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
    "AI-generated execution statistics including success rates, timing analysis, and per-shortcut performance data.",
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
    "User preferences including favorite shortcuts, workflow patterns, and contextual information.",
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
    "Recommend the best shortcut for a specific task based on available shortcuts and user preferences.",
  load: async (args) => {
    return `Task: ${args.task_description}
${args.context ? `Context: ${args.context}` : ""}

Analyze available shortcuts and recommend the best match. Consider exact matches first, then adaptable alternatives. 

Since shortcut names may not clearly indicate their function, if multiple shortcuts could potentially match or if the task description is unclear, ask clarifying questions to help identify the best option.

Use exact shortcut names from the list and provide usage guidance.`;
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
