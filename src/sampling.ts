import { FastMCPSession } from "fastmcp";

import { logger } from "./logger.js";
import { ShortcutExecution } from "./user-context.js";

type ContextMap = { CONTEXT_DECISION: ExecutionContext; STATISTICS: unknown[] };

type ExecutionContext = {
  duration: number;
  input?: string;
  output: string;
  shortcut: string;
  success: boolean;
  timestamp: string;
  userGoal?: string; // From conversation context
};

type MessageTemplates = { [K in SamplingTask]: (arg: ContextMap[K]) => string };
type SamplingContext<T extends SamplingTask> = ContextMap[T];
type SamplingTask = keyof ContextMap;

export const SAMPLING_MESSAGE_TEMPLATES: MessageTemplates = {
  CONTEXT_DECISION: (
    executionContext: ExecutionContext,
  ) => `Based on this shortcut execution, determine what additional context would be helpful:

Execution: ${JSON.stringify(executionContext)}

Consider: user patterns, success/failure history, shortcut complexity.
Return: JSON with resources to include.`,

  STATISTICS: (
    executionData: unknown[],
  ) => `Analyze the following shortcut execution data and return structured statistics in JSON format:

{
  "executions": {
    "total": number,
    "successes": number, 
    "failures": number
  },
  "timing": {
    "average": number,
    "min": number,
    "max": number
  },
  "per-shortcut": {
    "shortcut-name": {
      "count": number,
      "success-rate": number,
      "avg-duration": number
    }
  }
}

Raw execution data: ${JSON.stringify(executionData)}`,
};

export const SAMPLING_SYSTEM_PROMPTS: Record<SamplingTask, string> = {
  CONTEXT_DECISION:
    "You are a macOS Shortcuts execution analyst. Determine what additional context would be helpful based on execution results and user goals. Consider success patterns, failure history, and user workflow needs.",

  STATISTICS:
    "You are a data analyst. Transform raw execution data into structured statistics. Return only valid JSON with no additional text.",
};

export const SAMPLING_OPTIONS = {
  CONTEXT_DECISION: {
    includeContext: "thisServer",
    maxTokens: 500,
    temperature: 0.3,
  },

  STATISTICS: {
    includeContext: "thisServer",
    maxTokens: 1000,
    temperature: 0.1,
  },
} as const;

export async function buildRequest<T extends SamplingTask>(
  session: FastMCPSession,
  task: T,
  context: SamplingContext<T>,
) {
  return session
    .requestSampling({
      messages: [
        {
          content: {
            text: SAMPLING_MESSAGE_TEMPLATES[task](context),
            type: "text",
          },
          role: "user",
        },
      ],
      systemPrompt: SAMPLING_SYSTEM_PROMPTS[task],
      ...SAMPLING_OPTIONS[task],
    })
    .catch((error) => {
      const errorMessage = `Sampling failed for task ${task}: ${error.message || String(error)}`;
      logger.error(errorMessage, { error, task });
      throw new Error(errorMessage);
    });
}

export async function requestContextDecision(
  session: FastMCPSession,
  context: ExecutionContext,
) {
  return buildRequest(session, "CONTEXT_DECISION", context);
}

export async function requestStatitics(
  session: FastMCPSession,
  data: ShortcutExecution[],
) {
  return buildRequest(session, "STATISTICS", data);
}
