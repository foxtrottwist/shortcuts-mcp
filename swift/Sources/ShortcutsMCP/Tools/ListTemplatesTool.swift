// SPDX-License-Identifier: MIT
// ListTemplatesTool.swift - MCP Tool for listing available shortcut templates

import Foundation
import MCP

/// Tool for listing available shortcut templates.
///
/// This tool returns information about all registered templates that can be used
/// with the create_shortcut tool's template mode.
public struct ListTemplatesTool {
    /// Tool name as registered with MCP
    public static let name = "list_templates"

    /// Tool definition for MCP registration
    public static let definition = Tool(
        name: name,
        description: """
            List all available shortcut templates. \
            Templates provide pre-built patterns for creating common shortcuts. \
            Use a template name with create_shortcut's 'template' parameter.
            """,
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "verbose": .object([
                    "type": "boolean",
                    "description":
                        "If true, include full parameter details for each template. Default: false (summary only)."
                ])
            ])
        ]),
        annotations: Tool.Annotations(
            title: "List Templates",
            readOnlyHint: true,
            openWorldHint: false
        )
    )

    /// Execute the list_templates tool
    ///
    /// - Parameter arguments: Optional arguments from the MCP call
    /// - Returns: The tool result with template information
    public static func execute(arguments: [String: Value]?) async throws -> CallTool.Result {
        let verbose = arguments?["verbose"]?.boolValue ?? false

        // Ensure built-in templates are registered
        await CreateShortcutTool.templateEngine.registerBuiltInTemplates()

        // Get all templates
        let templates = await CreateShortcutTool.templateEngine.listTemplates()

        if templates.isEmpty {
            let response: [String: Any] = [
                "count": 0,
                "templates": [],
                "message": "No templates available."
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            return CallTool.Result(content: [.text(jsonString)], isError: false)
        }

        // Build template list
        var templateList: [[String: Any]] = []

        for template in templates {
            if verbose {
                // Full details including parameters
                var templateDict: [String: Any] = [
                    "name": template.name,
                    "displayName": template.displayName,
                    "description": template.description
                ]

                var paramList: [[String: Any]] = []
                for param in template.parameters {
                    var paramDict: [String: Any] = [
                        "name": param.name,
                        "label": param.label,
                        "type": param.type.rawValue,
                        "required": param.required
                    ]

                    if let defaultValue = param.defaultValue {
                        paramDict["defaultValue"] = formatParameterValue(defaultValue)
                    }
                    if let options = param.options {
                        paramDict["options"] = options
                    }
                    if let description = param.parameterDescription {
                        paramDict["description"] = description
                    }

                    paramList.append(paramDict)
                }
                templateDict["parameters"] = paramList

                templateList.append(templateDict)
            } else {
                // Summary only
                let requiredParams = template.parameters.filter { $0.required }.map(\.name)
                let optionalParams =
                    template.parameters.filter { !$0.required || $0.defaultValue != nil }.map(
                        \.name)

                var templateDict: [String: Any] = [
                    "name": template.name,
                    "displayName": template.displayName,
                    "description": template.description,
                    "parameterCount": template.parameters.count
                ]

                if !requiredParams.isEmpty {
                    templateDict["requiredParams"] = requiredParams
                }
                if !optionalParams.isEmpty {
                    templateDict["optionalParams"] = optionalParams
                }

                templateList.append(templateDict)
            }
        }

        let response: [String: Any] = [
            "count": templates.count,
            "templates": templateList,
            "usage":
                "Use create_shortcut with 'template' and 'templateParams' to create a shortcut from a template."
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return CallTool.Result(content: [.text(jsonString)], isError: false)
    }

    /// Format a template parameter value for JSON output
    private static func formatParameterValue(_ value: TemplateParameterValue) -> Any {
        switch value {
        case .string(let s):
            return s
        case .url(let s):
            return s
        case .number(let n):
            return n
        case .boolean(let b):
            return b
        case .choice(let s):
            return s
        }
    }
}
