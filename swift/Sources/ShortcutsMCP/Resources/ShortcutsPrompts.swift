import Foundation
import MCP

/// Registry of all prompts exposed by the Shortcuts MCP server.
///
/// Prompts provide structured templates for LLM interactions,
/// helping with shortcut discovery and recommendations.
public enum ShortcutsPrompts {
    /// All available prompt definitions
    public static let all: [Prompt] = [
        recommendShortcut,
    ]

    // MARK: - Prompt Definitions

    /// Recommend the best shortcut for a specific task based on available shortcuts and user preferences.
    public static let recommendShortcut = Prompt(
        name: "Recommend a Shortcut",
        description: "Recommend the best shortcut for a specific task based on available shortcuts and user preferences.",
        arguments: [
            Prompt.Argument(
                name: "task_description",
                description: "What the user wants to accomplish",
                required: true
            ),
            Prompt.Argument(
                name: "context",
                description: "Additional context (input type, desired output, etc.)",
                required: false
            ),
        ]
    )

    // MARK: - Prompt Loading

    /// Gets the messages for a prompt with the given arguments
    /// - Parameters:
    ///   - name: The prompt name
    ///   - arguments: The prompt arguments
    /// - Returns: The prompt result with messages, or nil if not found
    public static func get(name: String, arguments: [String: Value]?) -> GetPrompt.Result? {
        switch name {
        case recommendShortcut.name:
            return getRecommendShortcut(arguments: arguments)
        default:
            return nil
        }
    }

    // MARK: - Private Prompt Getters

    private static func getRecommendShortcut(arguments: [String: Value]?) -> GetPrompt.Result {
        let taskDescription: String
        let context: String?

        // Extract task_description argument
        if let args = arguments,
           case let .string(task) = args["task_description"]
        {
            taskDescription = task
        } else {
            taskDescription = "[Task not specified]"
        }

        // Extract optional context argument
        if let args = arguments,
           case let .string(ctx) = args["context"]
        {
            context = ctx
        } else {
            context = nil
        }

        // Build the prompt text
        var promptText = "Task: \(taskDescription)"
        if let ctx = context {
            promptText += "\nContext: \(ctx)"
        }
        promptText += """


            Analyze available shortcuts and recommend the best match. Consider exact matches first, then adaptable alternatives.

            Since shortcut names may not clearly indicate their function, if multiple shortcuts could potentially match or if the task description is unclear, ask clarifying questions to help identify the best option.

            Use exact shortcut names from the list and provide usage guidance.
            """

        return GetPrompt.Result(
            description: recommendShortcut.description,
            messages: [
                .user(.text(text: promptText)),
            ]
        )
    }
}
