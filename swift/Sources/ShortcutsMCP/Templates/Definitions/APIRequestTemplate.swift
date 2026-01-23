// SPDX-License-Identifier: MIT
// APIRequestTemplate.swift - Template for creating API request shortcuts

import Foundation

/// Template for creating shortcuts that make HTTP API requests.
///
/// This template generates a shortcut that:
/// 1. Makes an HTTP request using URLAction
/// 2. Optionally extracts a value from the JSON response using GetDictionaryValueAction
/// 3. Displays the result using ShowResultAction
///
/// ## Example Usage
///
/// ```swift
/// let engine = TemplateEngine()
/// engine.register(APIRequestTemplate.self)
///
/// // Simple GET request
/// let actions = try engine.generate(
///     templateName: "api-request",
///     parameters: [
///         "url": .url("https://api.example.com/users")
///     ]
/// )
///
/// // POST request with auth and JSON path
/// let actions = try engine.generate(
///     templateName: "api-request",
///     parameters: [
///         "url": .url("https://api.example.com/data"),
///         "method": .choice("POST"),
///         "authHeader": .string("Bearer my-token"),
///         "jsonPath": .string("data.items")
///     ]
/// )
/// ```
public struct APIRequestTemplate: Template {
    // MARK: - Template Metadata

    public static let name = "api-request"
    public static let displayName = "API Request"
    public static let description =
        "Makes an HTTP request to an API endpoint, optionally extracts data from the JSON response, and displays the result"

    public static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "url",
            label: "API URL",
            type: .url,
            required: true,
            description: "The URL of the API endpoint to request"
        ),
        TemplateParameter(
            name: "method",
            label: "HTTP Method",
            type: .choice,
            required: false,
            defaultValue: .choice("GET"),
            options: ["GET", "POST", "PUT", "DELETE"],
            description: "The HTTP method to use for the request"
        ),
        TemplateParameter(
            name: "authHeader",
            label: "Authorization Header",
            type: .string,
            required: false,
            description:
                "Optional authorization header value (e.g., 'Bearer token' or 'Basic credentials')"
        ),
        TemplateParameter(
            name: "jsonPath",
            label: "JSON Path",
            type: .string,
            required: false,
            description:
                "Optional dot-notation path to extract from the JSON response (e.g., 'data.items' or 'user.name')"
        ),
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Generation

    public func generate(with parameters: [String: TemplateParameterValue]) throws -> [any
        ShortcutAction]
    {
        // Extract URL (required)
        guard let urlValue = parameters["url"]?.urlValue else {
            throw TemplateError.missingRequiredParameter(name: "url")
        }

        // Extract method (optional, defaults to GET)
        let methodString = parameters["method"]?.choiceValue ?? "GET"
        let method: HTTPMethod =
            switch methodString {
            case "POST": .post
            case "PUT": .put
            case "DELETE": .delete
            default: .get
            }

        // Extract auth header (optional)
        let authHeader = parameters["authHeader"]?.stringValue

        // Extract JSON path (optional)
        let jsonPath = parameters["jsonPath"]?.stringValue

        // Generate UUIDs for action references
        let urlActionUUID = UUID().uuidString
        let extractActionUUID = UUID().uuidString

        var actions: [any ShortcutAction] = []

        // 1. URLAction - Make the HTTP request
        var headers: [String: String]? = nil
        if let auth = authHeader, !auth.isEmpty {
            headers = ["Authorization": auth]
        }

        let urlAction = URLAction(
            method: method,
            url: .string(urlValue),
            headers: headers,
            uuid: urlActionUUID,
            customOutputName: "API Response"
        )
        actions.append(urlAction)

        // 2. GetDictionaryValueAction - Extract data if jsonPath is provided
        let resultSourceUUID: String
        let resultSourceName: String

        if let path = jsonPath, !path.isEmpty {
            let extractAction = GetDictionaryValueAction(
                key: path,
                uuid: extractActionUUID,
                customOutputName: "Extracted Data"
            )
            actions.append(extractAction)
            resultSourceUUID = extractActionUUID
            resultSourceName = "Dictionary Value"
        } else {
            resultSourceUUID = urlActionUUID
            resultSourceName = "Contents of URL"
        }

        // 3. ShowResultAction - Display the result
        let showResultAction = ShowResultAction(
            fromActionWithUUID: resultSourceUUID,
            outputName: resultSourceName
        )
        actions.append(showResultAction)

        return actions
    }
}
