// SPDX-License-Identifier: MIT
// FileDownloadTemplate.swift - Template for downloading files from URLs

import Foundation

/// Template that creates a shortcut for downloading files from a URL.
///
/// This template generates a shortcut that:
/// 1. Downloads the file from the specified URL using a GET request
/// 2. Saves the file (either prompting for location or using the specified filename)
/// 3. Optionally shows a notification confirming the download completed
///
/// ## Parameters
///
/// - `url` (required): The URL to download the file from
/// - `filename` (optional): The filename to save as (if not provided, prompts user for location)
/// - `showConfirmation` (optional, default: true): Whether to show a notification when download completes
///
/// ## Example Usage
///
/// ```swift
/// let engine = TemplateEngine()
/// engine.register(FileDownloadTemplate.self)
///
/// let actions = try engine.generate(
///     templateName: "file-download",
///     parameters: [
///         "url": .url("https://example.com/file.pdf"),
///         "filename": .string("/Downloads/file.pdf"),
///         "showConfirmation": .boolean(true)
///     ]
/// )
/// ```
public struct FileDownloadTemplate: Template {
    /// Unique identifier for this template
    public static let name = "file-download"

    /// Human-readable display name
    public static let displayName = "File Download"

    /// Description of what this template creates
    public static let description =
        "Downloads a file from a URL and saves it to a specified location or prompts for save location"

    /// Parameters accepted by this template
    public static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "url",
            label: "Download URL",
            type: .url,
            required: true,
            description: "The URL to download the file from"
        ),
        TemplateParameter(
            name: "filename",
            label: "Filename",
            type: .string,
            required: false,
            description:
                "The path to save the file to (e.g., '/Downloads/file.pdf'). If not provided, prompts user for location."
        ),
        TemplateParameter(
            name: "showConfirmation",
            label: "Show Confirmation",
            type: .boolean,
            required: false,
            defaultValue: .boolean(true),
            description: "Whether to show a notification when the download completes"
        ),
    ]

    /// Required initializer
    public init() {}

    /// Generates actions for the file download shortcut.
    /// - Parameter parameters: Dictionary of parameter values
    /// - Returns: Array of shortcut actions
    /// - Throws: `TemplateError` if required parameters are missing
    public func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction]
    {
        // Get required URL parameter
        guard let urlString = parameters["url"]?.urlValue else {
            throw TemplateError.missingRequiredParameter(name: "url")
        }

        // Get optional filename parameter
        let filename = parameters["filename"]?.stringValue

        // Get showConfirmation parameter (defaults to true)
        let showConfirmation = parameters["showConfirmation"]?.boolValue ?? true

        // Generate UUIDs for action references
        let downloadUUID = UUID().uuidString
        let saveUUID = UUID().uuidString

        var actions: [any ShortcutAction] = []

        // 1. URLAction to download the file (GET request)
        actions.append(
            URLAction.get(urlString, uuid: downloadUUID)
        )

        // 2. SaveFileAction to save the downloaded content
        if let filename = filename {
            // Save to specific path
            actions.append(
                SaveFileAction(
                    service: .iCloudDrive,
                    destinationPath: filename,
                    overwriteIfExists: true,
                    uuid: saveUUID
                )
            )
        } else {
            // Prompt user for save location
            actions.append(
                SaveFileAction(
                    service: .iCloudDrive,
                    uuid: saveUUID
                )
            )
        }

        // 3. ShowNotificationAction if showConfirmation is true
        if showConfirmation {
            actions.append(
                ShowNotificationAction(
                    "File downloaded successfully!",
                    title: "Download Complete"
                )
            )
        }

        return actions
    }
}
