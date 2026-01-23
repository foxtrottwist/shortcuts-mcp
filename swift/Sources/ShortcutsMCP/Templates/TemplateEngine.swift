// SPDX-License-Identifier: MIT
// TemplateEngine.swift - Engine for registering and generating from templates

import Foundation

// MARK: - Template Engine

/// Engine for managing and generating shortcuts from templates.
///
/// The template engine provides:
/// - Registration of template types
/// - Parameter validation against template requirements
/// - Shortcut generation from templates with parameters
/// - Discovery of available templates
///
/// ## Example Usage
///
/// ```swift
/// let engine = TemplateEngine()
///
/// // Register templates
/// engine.register(HelloWorldTemplate.self)
/// engine.register(APIFetchTemplate.self)
///
/// // List available templates
/// let templates = engine.listTemplates()
///
/// // Generate from template
/// let actions = try engine.generate(
///     templateName: "hello-world",
///     parameters: ["greeting": .string("Hi there!")]
/// )
///
/// // Or generate directly to a file
/// let result = try await engine.generateShortcut(
///     templateName: "api-fetch",
///     parameters: ["url": .url("https://api.example.com/data")],
///     configuration: .menuBar(name: "Fetch Data")
/// )
/// ```
public actor TemplateEngine {
    // MARK: - Types

    /// A registered template with its factory function
    private struct RegisteredTemplate: Sendable {
        let info: TemplateInfo
        let factory: @Sendable () -> any Template
    }

    // MARK: - Properties

    /// Registered templates by name
    private var templates: [String: RegisteredTemplate] = [:]

    // MARK: - Initialization

    /// Creates a new template engine.
    public init() {}

    // MARK: - Registration

    /// Registers a template type with the engine.
    /// - Parameter templateType: The template type to register
    public func register<T: Template>(_ templateType: T.Type) {
        let info = TemplateInfo(from: templateType)
        templates[T.name] = RegisteredTemplate(
            info: info,
            factory: { T.init() }
        )
    }

    /// Registers a template instance factory with the engine.
    /// - Parameters:
    ///   - name: Unique template identifier
    ///   - displayName: Human-readable name
    ///   - description: Template description
    ///   - parameters: Parameter definitions
    ///   - factory: Factory function that creates template instances
    public func register(
        name: String,
        displayName: String,
        description: String,
        parameters: [TemplateParameter],
        factory: @escaping @Sendable () -> any Template
    ) {
        let info = TemplateInfo(
            name: name,
            displayName: displayName,
            description: description,
            parameters: parameters
        )
        templates[name] = RegisteredTemplate(info: info, factory: factory)
    }

    /// Unregisters a template by name.
    /// - Parameter name: The template name to remove
    /// - Returns: True if a template was removed
    @discardableResult
    public func unregister(name: String) -> Bool {
        templates.removeValue(forKey: name) != nil
    }

    /// Checks if a template is registered.
    /// - Parameter name: The template name to check
    /// - Returns: True if the template is registered
    public func isRegistered(name: String) -> Bool {
        templates[name] != nil
    }

    // MARK: - Discovery

    /// Returns information about all registered templates.
    public func listTemplates() -> [TemplateInfo] {
        templates.values.map(\.info).sorted { $0.name < $1.name }
    }

    /// Returns information about a specific template.
    /// - Parameter name: The template name
    /// - Returns: Template info, or nil if not found
    public func getTemplateInfo(name: String) -> TemplateInfo? {
        templates[name]?.info
    }

    /// Returns the number of registered templates.
    public var templateCount: Int {
        templates.count
    }

    // MARK: - Validation

    /// Validates parameters against a template's requirements.
    /// - Parameters:
    ///   - templateName: The template to validate against
    ///   - parameters: The parameters to validate
    /// - Throws: `TemplateError` if validation fails
    public func validateParameters(
        templateName: String,
        parameters: [String: TemplateParameterValue]
    ) throws {
        guard let registered = templates[templateName] else {
            throw TemplateError.templateNotFound(name: templateName)
        }

        try validateParameters(parameters, against: registered.info.parameters)
    }

    /// Validates parameters against parameter definitions.
    /// - Parameters:
    ///   - parameters: The parameters to validate
    ///   - definitions: The parameter definitions
    /// - Throws: `TemplateError` if validation fails
    public func validateParameters(
        _ parameters: [String: TemplateParameterValue],
        against definitions: [TemplateParameter]
    ) throws {
        for definition in definitions {
            if let value = parameters[definition.name] {
                // Validate type compatibility
                try validateTypeCompatibility(
                    value: value,
                    expectedType: definition.type,
                    parameterName: definition.name
                )

                // Validate choice options
                if definition.type == .choice, let options = definition.options {
                    if let choiceValue = value.choiceValue, !options.contains(choiceValue) {
                        throw TemplateError.invalidChoiceValue(
                            name: definition.name,
                            value: choiceValue,
                            options: options
                        )
                    }
                }
            } else if definition.required && definition.defaultValue == nil {
                throw TemplateError.missingRequiredParameter(name: definition.name)
            }
        }
    }

    /// Validates that a value is compatible with an expected type.
    private func validateTypeCompatibility(
        value: TemplateParameterValue,
        expectedType: TemplateParameterType,
        parameterName: String
    ) throws {
        let isCompatible: Bool
        let actualType: String

        switch (value, expectedType) {
        case (.string, .string), (.string, .url):
            isCompatible = true
            actualType = "string"
        case (.url, .url), (.url, .string):
            isCompatible = true
            actualType = "url"
        case (.number, .number):
            isCompatible = true
            actualType = "number"
        case (.boolean, .boolean):
            isCompatible = true
            actualType = "boolean"
        case (.choice, .choice), (.string, .choice), (.choice, .string):
            isCompatible = true
            actualType = "choice"
        default:
            isCompatible = false
            actualType = describeValueType(value)
        }

        if !isCompatible {
            throw TemplateError.invalidParameterType(
                name: parameterName,
                expected: expectedType,
                got: actualType
            )
        }
    }

    /// Returns a description of the value type.
    private func describeValueType(_ value: TemplateParameterValue) -> String {
        switch value {
        case .string: return "string"
        case .url: return "url"
        case .number: return "number"
        case .boolean: return "boolean"
        case .choice: return "choice"
        }
    }

    // MARK: - Generation

    /// Generates actions from a template with the given parameters.
    /// - Parameters:
    ///   - templateName: The template to use
    ///   - parameters: Parameter values for generation
    /// - Returns: Array of generated shortcut actions
    /// - Throws: `TemplateError` if the template is not found, validation fails, or generation fails
    public func generate(
        templateName: String,
        parameters: [String: TemplateParameterValue]
    ) throws -> [any ShortcutAction] {
        guard let registered = templates[templateName] else {
            throw TemplateError.templateNotFound(name: templateName)
        }

        // Merge defaults with provided parameters
        let mergedParameters = mergeWithDefaults(
            parameters: parameters,
            definitions: registered.info.parameters
        )

        // Validate parameters
        try validateParameters(mergedParameters, against: registered.info.parameters)

        // Create template instance and generate
        let template = registered.factory()
        do {
            return try template.generate(with: mergedParameters)
        } catch let error as TemplateError {
            throw error
        } catch {
            throw TemplateError.generationFailed(reason: error.localizedDescription)
        }
    }

    /// Generates a shortcut file from a template.
    /// - Parameters:
    ///   - templateName: The template to use
    ///   - parameters: Parameter values for generation
    ///   - configuration: Shortcut generator configuration
    ///   - outputDirectory: Output directory for the file
    /// - Returns: Generation result with file path and metadata
    /// - Throws: `TemplateError` or `ShortcutGenerator.GenerationError`
    public func generateShortcut(
        templateName: String,
        parameters: [String: TemplateParameterValue],
        configuration: ShortcutGenerator.Configuration = ShortcutGenerator.Configuration(),
        outputDirectory: URL? = nil
    ) async throws -> ShortcutGenerator.GenerationResult {
        let actions = try generate(templateName: templateName, parameters: parameters)

        let generator = ShortcutGenerator(
            configuration: configuration,
            outputDirectory: outputDirectory
        )

        return try await generator.generate(actions: actions)
    }

    /// Merges provided parameters with default values.
    private func mergeWithDefaults(
        parameters: [String: TemplateParameterValue],
        definitions: [TemplateParameter]
    ) -> [String: TemplateParameterValue] {
        var merged = parameters

        for definition in definitions {
            if merged[definition.name] == nil, let defaultValue = definition.defaultValue {
                merged[definition.name] = defaultValue
            }
        }

        return merged
    }
}

// MARK: - Convenience Extensions

extension TemplateEngine {
    /// Generates actions and builds a Shortcut struct without writing to disk.
    /// - Parameters:
    ///   - templateName: The template to use
    ///   - parameters: Parameter values for generation
    ///   - configuration: Shortcut generator configuration
    /// - Returns: The built Shortcut
    /// - Throws: `TemplateError` if generation fails
    public func buildShortcut(
        templateName: String,
        parameters: [String: TemplateParameterValue],
        configuration: ShortcutGenerator.Configuration = ShortcutGenerator.Configuration()
    ) async throws -> Shortcut {
        let actions = try generate(templateName: templateName, parameters: parameters)
        let generator = ShortcutGenerator(configuration: configuration)
        return await generator.buildShortcut(actions: actions)
    }
}

