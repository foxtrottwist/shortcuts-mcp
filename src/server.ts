import { Content, FastMCP } from "fastmcp";
import { z } from "zod";

import { runShortcut, viewShortcut } from "./shortcuts.js";
import {
  getShortcutsList,
  getSystemState,
  loadRecents,
  loadUserProfile,
  saveUserProfile,
} from "./user-context.js";

const server = new FastMCP({
  name: "Shortcuts",
  version: "1.0.0",
});

server.addTool({
  annotations: {
    openWorldHint: true,
    readOnlyHint: false,
    title: "Run Shortcut",
  },
  description: "Execute a macOS Shortcut by name with optional input",
  async execute(args, { log }) {
    log.info("Tool execution started", {
      hasInput: !!args.input,
      shortcutName: args.name,
      tool: "run_shortcut",
    });

    return {
      content: [
        {
          text: await runShortcut(log, args.name, args.input),
          type: "text",
        },
        {
          resource: await server.embedded("shortcuts://available"),
          type: "resource",
        },
        {
          resource: await server.embedded("shortcuts://runs/recent"),
          type: "resource",
        },
        {
          resource: await server.embedded("context://system/current"),
          type: "resource",
        },
        {
          resource: await server.embedded("context://user/profile"),
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
    title: "User Context",
  },
  description: "Read, update and add to the User's Profile",
  async execute(args, { log }) {
    const { action, data = {} } = args;

    log.info("User context operation started", {
      action,
      hasData: Object.keys(data).length > 0,
    });

    const resources: Record<"content", Content[]> = {
      content: [
        {
          resource: await server.embedded("shortcuts://available"),
          type: "resource",
        },
        {
          resource: await server.embedded("shortcuts://runs/recent"),
          type: "resource",
        },
        {
          resource: await server.embedded("context://system/current"),
          type: "resource",
        },
        {
          resource: await server.embedded("context://user/profile"),
          type: "resource",
        },
      ],
    };

    switch (action) {
      case "read": {
        const profile = await loadUserProfile();
        log.info("User profile loaded", {
          hasContext: !!profile.context,
          hasPreferences: !!profile.preferences,
        });

        resources.content.push({ text: JSON.stringify(profile), type: "text" });
        return resources;
      }
      case "update": {
        const profile = await saveUserProfile(data);
        log.info("User profile updated", {
          updatedFields: Object.keys(data),
        });

        resources.content.push({ text: JSON.stringify(profile), type: "text" });
        return resources;
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
  }),
});

server.addTool({
  annotations: {
    openWorldHint: true,
    readOnlyHint: true,
    title: "View Shortcut",
  },
  description: "Open a macOS Shortcut in the Shortcuts editor",
  async execute(args, { log }) {
    return String(await viewShortcut(log, args.name));
  },
  name: "view_shortcut",
  parameters: z.object({
    name: z.string().describe("The name of the Shortcut to view"),
  }),
});

server.addResource({
  async load() {
    return {
      text: await getShortcutsList(),
    };
  },
  mimeType: "text/plain",
  name: "Current shortcuts list",
  uri: "shortcuts://available",
});

server.addResource({
  async load() {
    return {
      text: JSON.stringify(await loadRecents()),
    };
  },
  mimeType: "application/json",
  name: "Recent execution history",
  uri: "shortcuts://runs/recent",
});

server.addResourceTemplate({
  arguments: [{ description: "Shortcut name", name: "name", required: true }],
  async load(args) {
    return { text: args.name };
  },
  mimeType: "text/plain",
  name: "Per-shortcut execution data",
  uriTemplate: "shortcuts://runs/{name}",
});

server.addResource({
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
    "Recommend the best shortcut for a specific task based on available shortcuts",
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
