import { FastMCP } from "fastmcp";
import { z } from "zod";

import { listShortcuts, runShortcut, viewShortcut } from "./shortcuts.js";

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
  execute: async (args) => {
    return String(runShortcut(args.name, args.input));
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
  execute: async (args) => {
    return String(viewShortcut(args.name));
  },
  name: "view_shortcut",
  parameters: z.object({
    name: z.string().describe("The name of the Shortcut to view"),
  }),
});

server.addResource({
  async load() {
    return {
      text: await listShortcuts(),
    };
  },
  mimeType: "text/plain",
  name: "Available Shortcuts",
  uri: "shortcuts://available",
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

First, check the Available Shortcuts resource to see what shortcuts exist.

Then analyze which shortcut(s) would best accomplish this task:
1. Look for exact matches first
2. Consider shortcuts that could be adapted
3. If no perfect match exists, suggest the closest alternatives
4. Explain why you're recommending specific shortcuts
5. Provide usage guidance for the recommended shortcut(s)

Be specific about which shortcut to use and how to use it effectively.`;
  },
  name: "recommend-shortcut",
});

server.start({
  transportType: "stdio",
});
