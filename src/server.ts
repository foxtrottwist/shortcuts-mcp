import { FastMCP } from "fastmcp";
import { z } from "zod";

import { listShortcuts, runShortcut, viewShortcut } from "./shortcuts.js";

const server = new FastMCP({
  name: "Shortcuts",
  version: "1.0.0",
});

server.addTool({
  description: "Execute a macOS Shortcut by name with optional input",
  execute: async (args) => {
    const timeout = (args.timeoutSeconds || 5) * 1000;

    try {
      const result = await Promise.race([
        runShortcut(args.name, args.input),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error("TIMEOUT")), timeout),
        ),
      ]);

      if (result.trim() === "") {
        return `Shortcut "${args.name}" completed successfully (no text output - check clipboard or other apps for results).`;
      }
      return String(result);
    } catch (error) {
      if (error instanceof Error && error.message === "TIMEOUT") {
        return `Shortcut "${args.name}" is likely interactive or provides no output. Check your Mac for results.`;
      }
      throw error;
    }
  },
  name: "run_shortcut",
  parameters: z.object({
    input: z
      .string()
      .optional()
      .describe("Optional input to pass to the shortcut"),
    name: z.string().describe("The name of the Shortcut to run"),
    timeoutSeconds: z
      .number()
      .optional()
      .describe(
        "Timeout in seconds before launching in background (default: 5). Only specify if user requests a specific timeout or for known long-running shortcuts.",
      ),
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
    return String(await viewShortcut(args.name));
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
  name: "Recommend a Shortcut",
});

server.start({
  transportType: "stdio",
});
