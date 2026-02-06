import { FastMCPSession } from "fastmcp";

import { isOlderThan24Hrs, tryJSONParse } from "./helpers.js";
import { logger } from "./logger.js";
import {
  loadExecutions,
  loadStatistics,
  saveStatistics,
} from "./shortcuts-usage.js";

type ContextMap = {
  STATISTICS: unknown[];
};

type MessageTemplates = { [K in SamplingTask]: (arg: ContextMap[K]) => string };
type SamplingContext<T extends SamplingTask> = ContextMap[T];
type SamplingTask = keyof ContextMap;

export const SAMPLING_MESSAGE_TEMPLATES: MessageTemplates = {
  STATISTICS: (
    executionData: unknown[],
  ) => `Generate execution statistics for macOS Shortcuts usage analysis. Return JSON with execution counts, success rates, timing metrics, and per-shortcut breakdowns.

Required format:
{
  "executions": { "total": number, "successes": number, "failures": number },
  "timing": { "average": number, "min": number, "max": number },
  "per-shortcut": { 
    "shortcut-name": { "count": number, "success-rate": number, "avg-duration": number }
  }
}

Calculate for ALL shortcuts in the data. Use actual shortcut names as keys.

Data: ${JSON.stringify(executionData)}`,
};

export const SAMPLING_SYSTEM_PROMPTS: Record<SamplingTask, string> = {
  STATISTICS:
    "Return only valid JSON with no additional text. Calculate statistics for ALL shortcuts found in the data.",
};

export const SAMPLING_OPTIONS = {
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
      logger.error({ error, task }, errorMessage);
      throw new Error(errorMessage);
    });
}

export async function requestStatistics(session: FastMCPSession) {
  let stats = await loadStatistics();
  if (!isOlderThan24Hrs(stats?.generatedAt)) {
    return stats;
  }

  const { days, executions } = await loadExecutions();
  if (
    session.clientCapabilities?.sampling &&
    days >= 3 &&
    executions.length >= 20
  ) {
    const res = await buildRequest(session, "STATISTICS", executions).catch(
      logger.error,
    );
    if (res && res.content.type === "text") {
      stats = tryJSONParse(res.content.text, logger.error);
      if (stats && typeof stats === "object" && !Array.isArray(stats)) {
        await saveStatistics(stats);
        return stats;
      }
    }
  }

  return stats ?? {};
}
