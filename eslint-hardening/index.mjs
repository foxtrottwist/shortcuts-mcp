/**
 * eslint-config-hardening — flat-config ESLint preset
 *
 * Design decision: flat config only (ESLint >=9). Legacy .eslintrc is not
 * supported. Flat config is the ESLint upstream standard going forward and
 * avoids the cascading/override complexity of the legacy format.
 *
 * Usage in consumer's eslint.config.mjs:
 *   import hardening from "harden-configs/eslint";
 *   export default [...hardening, ...yourOwnRules];
 *
 * Peer dependencies required in the consuming project:
 *   eslint >=9
 *   eslint-plugin-security >=3
 */

import security from "eslint-plugin-security";

/** @type {import("eslint").Linter.FlatConfig[]} */
const hardeningConfig = [
  // ── 1. eslint-plugin-security (Apache-2.0) ────────────────────────────────
  // Spread the recommended flat-config, then override the one rule that
  // produces too many false positives in typical application code.
  {
    ...security.configs.recommended,
    rules: {
      ...security.configs.recommended.rules,

      // Disabled: triggers on every obj[variable] access, which is idiomatic
      // in many legitimate patterns (e.g., i18n lookups, config maps).
      // Consumers with untrusted input paths should re-enable per-file.
      "security/detect-object-injection": "off",
    },
  },

  // ── 2. Shell-execution ban ────────────────────────────────────────────────
  {
    rules: {
      // Ban exec() and execSync() — prefer execFile() / execFileSync() which
      // do not spawn a shell and are therefore not vulnerable to command
      // injection via interpolated strings.
      "no-restricted-syntax": [
        "error",
        {
          message:
            "exec/execSync spawn a shell and are vulnerable to command injection. Use execFile/execFileSync instead.",
          selector: "CallExpression[callee.name=/^(exec|execSync)$/]",
        },
        {
          message:
            "exec/execSync spawn a shell and are vulnerable to command injection. Use execFile/execFileSync instead.",
          // Also catch member forms: child_process.exec(...)
          selector: "CallExpression[callee.property.name=/^(exec|execSync)$/]",
        },
      ],
    },
  },

  // ── 3. Banned globals ─────────────────────────────────────────────────────
  {
    rules: {
      // eval() and the Function constructor both execute arbitrary strings as
      // code — primary vectors for XSS and code injection.
      "no-restricted-globals": [
        "error",
        {
          message:
            "eval() executes arbitrary code. Refactor to avoid dynamic evaluation.",
          name: "eval",
        },
        {
          message:
            "The Function constructor executes arbitrary strings. Use a named function instead.",
          name: "Function",
        },
      ],
    },
  },

  // ── 4. Banned imports inside providers ───────────────────────────────────
  {
    files: ["**/providers/**"],
    rules: {
      // HTTP clients inside provider modules must go through the project's
      // canonical fetch abstraction (enforces logging, retry, auth injection).
      // Bare http/https bypass TLS validation hooks; node-fetch/axios/got
      // create parallel request paths that skip centralised observability.
      "no-restricted-imports": [
        "error",
        {
          message: "Use the project's fetch abstraction, not bare http.",
          name: "http",
        },
        {
          message: "Use the project's fetch abstraction, not bare https.",
          name: "https",
        },
        {
          message: "Use the project's fetch abstraction instead of node-fetch.",
          name: "node-fetch",
        },
        {
          message: "Use the project's fetch abstraction instead of axios.",
          name: "axios",
        },
        {
          message: "Use the project's fetch abstraction instead of got.",
          name: "got",
        },
      ],
    },
  },

  // ── 5. Banned vm properties ───────────────────────────────────────────────
  {
    rules: {
      // vm.runInNewContext and vm.runInThisContext execute arbitrary code in a
      // V8 context. Neither provides real sandboxing. Use isolated-vm or a
      // subprocess worker if you need genuine isolation.
      "no-restricted-properties": [
        "error",
        {
          message:
            "vm.runInNewContext does not sandbox untrusted code. Use isolated-vm or a subprocess worker.",
          object: "vm",
          property: "runInNewContext",
        },
        {
          message:
            "vm.runInThisContext executes code in the current context with no isolation. Avoid.",
          object: "vm",
          property: "runInThisContext",
        },
      ],
    },
  },
];

export default hardeningConfig;
