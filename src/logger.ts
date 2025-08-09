import { pino } from "pino";

export const logger = pino(
  {
    level: process.env.LOG_LEVEL || "info",
    timestamp: pino.stdTimeFunctions.isoTime,
  },
  pino.destination({ dest: 2, sync: false }),
);
