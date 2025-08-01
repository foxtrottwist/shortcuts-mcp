import { FastMCP } from "fastmcp";
import { z } from "zod";

import { listShortcuts, runShortcut, viewShortcut } from "./shortcuts.js";

const server = new FastMCP({
  name: "Shortcuts",
  version: "1.0.0",
});

server.addTool({
  description: "Execute a macOS Shortcut by name with optional input",
  async execute(args, { log }) {
    log.info("Tool execution started", {
      hasInput: !!args.input,
      shortcutName: args.name,
      tool: "run_shortcut",
    });

    return await runShortcut(log, args.name, args.input);
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

server.addTool({
  annotations: {
    openWorldHint: true,
    readOnlyHint: true,
    title: "List Shortcuts",
  },
  description: "List all available macOS Shortcuts",
  async execute() {
    return String(await listShortcuts());
  },
  name: "list_shortcut",
  parameters: z.object({}),
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

First, use the list_shortcut tool to see all available shortcuts with their exact names and UUIDs.

Then analyze which shortcut(s) would best accomplish this task:
1. Look for exact matches first
2. Consider shortcuts that could be adapted  
3. If no perfect match exists, suggest the closest alternatives
4. Explain why you're recommending specific shortcuts
5. Provide usage guidance for the recommended shortcut(s)

IMPORTANT: When recommending shortcuts:
- Use the EXACT name from the list_shortcut output (case-sensitive)
- If a shortcut name fails, try using its UUID instead (Apple CLI bug workaround)
- AppleScript execution (run_shortcut) is more forgiving than CLI commands (view_shortcut)

Be specific about which shortcut to use and how to use it effectively.`;
  },
  name: "Recommend a Shortcut",
});

server.start({
  transportType: "stdio",
});
