// SPDX-License-Identifier: MIT
// TemplateEngineTests.swift - Tests for template engine

import Foundation
import Testing

@testable import ShortcutsMCP

// MARK: - Test Templates

/// Simple test template that creates a greeting shortcut.
struct HelloWorldTestTemplate: Template {
    static let name = "hello-world"
    static let displayName = "Hello World"
    static let description = "Creates a simple shortcut that displays a greeting"
    static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "greeting",
            label: "Greeting Text",
            type: .string,
            required: false,
            defaultValue: .string("Hello, World!"),
            description: "The greeting message to display"
        )
    ]

    init() {}

    func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction] {
        let greeting = parameters["greeting"]?.stringValue ?? "Hello, World!"
        let textUUID = UUID().uuidString
        return [
            TextAction(greeting, uuid: textUUID),
            ShowResultAction(fromActionWithUUID: textUUID, outputName: "Text"),
        ]
    }
}

/// Template with required parameters for testing validation.
struct RequiredParamTestTemplate: Template {
    static let name = "required-param"
    static let displayName = "Required Parameter Test"
    static let description = "Template that requires a URL parameter"
    static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "url",
            label: "API URL",
            type: .url,
            required: true,
            description: "The URL to fetch"
        ),
        TemplateParameter(
            name: "showResult",
            label: "Show Result",
            type: .boolean,
            required: false,
            defaultValue: .boolean(true),
            description: "Whether to display the result"
        ),
    ]

    init() {}

    func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction] {
        guard let url = parameters["url"]?.urlValue else {
            throw TemplateError.missingRequiredParameter(name: "url")
        }

        let urlUUID = UUID().uuidString
        var actions: [any ShortcutAction] = [
            URLAction.get(url, uuid: urlUUID)
        ]

        if parameters["showResult"]?.boolValue != false {
            actions.append(
                ShowResultAction(fromActionWithUUID: urlUUID, outputName: "Contents of URL")
            )
        }

        return actions
    }
}

/// Template with choice parameters for testing validation.
struct ChoiceParamTestTemplate: Template {
    static let name = "choice-param"
    static let displayName = "Choice Parameter Test"
    static let description = "Template with a choice parameter"
    static let parameters: [TemplateParameter] = [
        TemplateParameter(
            name: "method",
            label: "HTTP Method",
            type: .choice,
            required: true,
            options: ["GET", "POST", "PUT", "DELETE"],
            description: "The HTTP method to use"
        )
    ]

    init() {}

    func generate(with parameters: [String: TemplateParameterValue]) throws -> [any ShortcutAction] {
        guard let method = parameters["method"]?.choiceValue else {
            throw TemplateError.missingRequiredParameter(name: "method")
        }
        return [
            TextAction("Using method: \(method)")
        ]
    }
}

// MARK: - Template Parameter Tests

@Suite("TemplateParameter Tests")
struct TemplateParameterTests {
    @Test("Creates parameter with required properties")
    func parameterWithRequiredProperties() {
        let param = TemplateParameter(
            name: "url",
            label: "URL",
            type: .url,
            required: true
        )

        #expect(param.name == "url")
        #expect(param.label == "URL")
        #expect(param.type == .url)
        #expect(param.required == true)
        #expect(param.defaultValue == nil)
        #expect(param.options == nil)
    }

    @Test("Creates parameter with all properties")
    func parameterWithAllProperties() {
        let param = TemplateParameter(
            name: "method",
            label: "HTTP Method",
            type: .choice,
            required: false,
            defaultValue: .choice("GET"),
            options: ["GET", "POST", "PUT"],
            description: "The HTTP method"
        )

        #expect(param.name == "method")
        #expect(param.label == "HTTP Method")
        #expect(param.type == .choice)
        #expect(param.required == false)
        #expect(param.defaultValue == .choice("GET"))
        #expect(param.options == ["GET", "POST", "PUT"])
        #expect(param.parameterDescription == "The HTTP method")
    }

    @Test("Parameter encodes to JSON")
    func parameterEncodesToJSON() throws {
        let param = TemplateParameter(
            name: "count",
            label: "Count",
            type: .number,
            required: false,
            defaultValue: .number(10),
            description: "Number of items"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(param)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"name\":\"count\""))
        #expect(json.contains("\"label\":\"Count\""))
        #expect(json.contains("\"type\":\"number\""))
        #expect(json.contains("\"required\":false"))
        #expect(json.contains("\"description\":\"Number of items\""))
    }

    @Test("Parameter decodes from JSON")
    func parameterDecodesFromJSON() throws {
        let json = """
            {
                "name": "enabled",
                "label": "Enabled",
                "type": "boolean",
                "required": true,
                "default_value": {"type": "boolean", "value": true}
            }
            """

        let decoder = JSONDecoder()
        let param = try decoder.decode(TemplateParameter.self, from: json.data(using: .utf8)!)

        #expect(param.name == "enabled")
        #expect(param.label == "Enabled")
        #expect(param.type == .boolean)
        #expect(param.required == true)
        #expect(param.defaultValue == .boolean(true))
    }
}

// MARK: - Template Parameter Type Tests

@Suite("TemplateParameterType Tests")
struct TemplateParameterTypeTests {
    @Test("All parameter types exist")
    func allTypesExist() {
        let types = TemplateParameterType.allCases
        #expect(types.count == 5)
        #expect(types.contains(.string))
        #expect(types.contains(.url))
        #expect(types.contains(.number))
        #expect(types.contains(.boolean))
        #expect(types.contains(.choice))
    }

    @Test("Parameter types have raw values")
    func typesHaveRawValues() {
        #expect(TemplateParameterType.string.rawValue == "string")
        #expect(TemplateParameterType.url.rawValue == "url")
        #expect(TemplateParameterType.number.rawValue == "number")
        #expect(TemplateParameterType.boolean.rawValue == "boolean")
        #expect(TemplateParameterType.choice.rawValue == "choice")
    }
}

// MARK: - Template Parameter Value Tests

@Suite("TemplateParameterValue Tests")
struct TemplateParameterValueTests {
    @Test("String value accessors")
    func stringValueAccessors() {
        let value = TemplateParameterValue.string("hello")
        #expect(value.stringValue == "hello")
        #expect(value.urlValue == "hello")
        #expect(value.numberValue == nil)
        #expect(value.boolValue == false)
    }

    @Test("URL value accessors")
    func urlValueAccessors() {
        let value = TemplateParameterValue.url("https://example.com")
        #expect(value.stringValue == "https://example.com")
        #expect(value.urlValue == "https://example.com")
    }

    @Test("Number value accessors")
    func numberValueAccessors() {
        let value = TemplateParameterValue.number(42.5)
        #expect(value.numberValue == 42.5)
        #expect(value.intValue == 42)
        #expect(value.stringValue == "42.5")
    }

    @Test("Boolean value accessors")
    func booleanValueAccessors() {
        #expect(TemplateParameterValue.boolean(true).boolValue == true)
        #expect(TemplateParameterValue.boolean(false).boolValue == false)
        #expect(TemplateParameterValue.string("true").boolValue == true)
        #expect(TemplateParameterValue.string("yes").boolValue == true)
        #expect(TemplateParameterValue.string("1").boolValue == true)
        #expect(TemplateParameterValue.string("false").boolValue == false)
        #expect(TemplateParameterValue.number(1).boolValue == true)
        #expect(TemplateParameterValue.number(0).boolValue == false)
    }

    @Test("Choice value accessors")
    func choiceValueAccessors() {
        let value = TemplateParameterValue.choice("GET")
        #expect(value.choiceValue == "GET")
        #expect(value.stringValue == "GET")
    }

    @Test("Value encodes to JSON")
    func valueEncodesToJSON() throws {
        let values: [TemplateParameterValue] = [
            .string("test"),
            .url("https://example.com"),
            .number(42),
            .boolean(true),
            .choice("option1"),
        ]

        let encoder = JSONEncoder()
        for value in values {
            let data = try encoder.encode(value)
            #expect(data.count > 0)
        }
    }

    @Test("Value roundtrips through JSON")
    func valueRoundtrips() throws {
        let original = TemplateParameterValue.string("hello")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TemplateParameterValue.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - Template Info Tests

@Suite("TemplateInfo Tests")
struct TemplateInfoTests {
    @Test("Creates template info from Template type")
    func createsFromTemplateType() {
        let info = TemplateInfo(from: HelloWorldTestTemplate.self)

        #expect(info.name == "hello-world")
        #expect(info.displayName == "Hello World")
        #expect(info.description == "Creates a simple shortcut that displays a greeting")
        #expect(info.parameters.count == 1)
        #expect(info.parameters[0].name == "greeting")
    }

    @Test("Template info encodes to JSON with snake_case")
    func encodesToJSONWithSnakeCase() throws {
        let info = TemplateInfo(
            name: "test",
            displayName: "Test Template",
            description: "A test",
            parameters: []
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(info)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"display_name\":\"Test Template\""))
        #expect(json.contains("\"name\":\"test\""))
    }
}

// MARK: - Template Error Tests

@Suite("TemplateError Tests")
struct TemplateErrorTests {
    @Test("Missing required parameter error has descriptive message")
    func missingRequiredParameterError() {
        let error = TemplateError.missingRequiredParameter(name: "url")
        #expect(error.errorDescription?.contains("Missing required parameter") == true)
        #expect(error.errorDescription?.contains("url") == true)
    }

    @Test("Invalid parameter type error has descriptive message")
    func invalidParameterTypeError() {
        let error = TemplateError.invalidParameterType(
            name: "count",
            expected: .number,
            got: "string"
        )
        #expect(error.errorDescription?.contains("count") == true)
        #expect(error.errorDescription?.contains("number") == true)
        #expect(error.errorDescription?.contains("string") == true)
    }

    @Test("Invalid choice value error has descriptive message")
    func invalidChoiceValueError() {
        let error = TemplateError.invalidChoiceValue(
            name: "method",
            value: "INVALID",
            options: ["GET", "POST"]
        )
        #expect(error.errorDescription?.contains("method") == true)
        #expect(error.errorDescription?.contains("INVALID") == true)
        #expect(error.errorDescription?.contains("GET") == true)
    }

    @Test("Template not found error has descriptive message")
    func templateNotFoundError() {
        let error = TemplateError.templateNotFound(name: "unknown")
        #expect(error.errorDescription?.contains("Template not found") == true)
        #expect(error.errorDescription?.contains("unknown") == true)
    }

    @Test("Generation failed error has descriptive message")
    func generationFailedError() {
        let error = TemplateError.generationFailed(reason: "Something went wrong")
        #expect(error.errorDescription?.contains("Template generation failed") == true)
        #expect(error.errorDescription?.contains("Something went wrong") == true)
    }
}

// MARK: - Template Engine Tests

@Suite("TemplateEngine Tests")
struct TemplateEngineTests {
    @Test("Engine starts empty")
    func engineStartsEmpty() async {
        let engine = TemplateEngine()
        let templates = await engine.listTemplates()
        #expect(templates.isEmpty)
        #expect(await engine.templateCount == 0)
    }

    @Test("Registers template type")
    func registersTemplateType() async {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)

        let templates = await engine.listTemplates()
        #expect(templates.count == 1)
        #expect(templates[0].name == "hello-world")
        #expect(await engine.isRegistered(name: "hello-world"))
    }

    @Test("Registers multiple templates")
    func registersMultipleTemplates() async {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)
        await engine.register(RequiredParamTestTemplate.self)
        await engine.register(ChoiceParamTestTemplate.self)

        let templates = await engine.listTemplates()
        #expect(templates.count == 3)
        #expect(await engine.templateCount == 3)
    }

    @Test("Lists templates sorted by name")
    func listsTemplatesSorted() async {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)  // "required-param"
        await engine.register(HelloWorldTestTemplate.self)  // "hello-world"
        await engine.register(ChoiceParamTestTemplate.self)  // "choice-param"

        let templates = await engine.listTemplates()
        #expect(templates[0].name == "choice-param")
        #expect(templates[1].name == "hello-world")
        #expect(templates[2].name == "required-param")
    }

    @Test("Gets template info by name")
    func getsTemplateInfo() async {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)

        let info = await engine.getTemplateInfo(name: "hello-world")
        #expect(info != nil)
        #expect(info?.displayName == "Hello World")
        #expect(info?.parameters.count == 1)
    }

    @Test("Returns nil for unknown template")
    func returnsNilForUnknown() async {
        let engine = TemplateEngine()
        let info = await engine.getTemplateInfo(name: "unknown")
        #expect(info == nil)
        #expect(await engine.isRegistered(name: "unknown") == false)
    }

    @Test("Unregisters template")
    func unregistersTemplate() async {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)
        #expect(await engine.isRegistered(name: "hello-world"))

        let removed = await engine.unregister(name: "hello-world")
        #expect(removed)
        #expect(await engine.isRegistered(name: "hello-world") == false)

        let removedAgain = await engine.unregister(name: "hello-world")
        #expect(removedAgain == false)
    }
}

// MARK: - Template Engine Validation Tests

@Suite("TemplateEngine Validation Tests")
struct TemplateEngineValidationTests {
    @Test("Validates required parameter presence")
    func validatesRequiredParameter() async {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "required-param",
                parameters: [:]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "url"))
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Validates with provided required parameter")
    func validatesWithProvidedRequired() async throws {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        try await engine.validateParameters(
            templateName: "required-param",
            parameters: ["url": .url("https://example.com")]
        )
    }

    @Test("Validates choice parameter options")
    func validatesChoiceOptions() async {
        let engine = TemplateEngine()
        await engine.register(ChoiceParamTestTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "choice-param",
                parameters: ["method": .choice("INVALID")]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .invalidChoiceValue(let name, let value, _) = error {
                #expect(name == "method")
                #expect(value == "INVALID")
            } else {
                #expect(Bool(false), "Wrong error case")
            }
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Validates choice parameter with valid option")
    func validatesChoiceWithValidOption() async throws {
        let engine = TemplateEngine()
        await engine.register(ChoiceParamTestTemplate.self)

        try await engine.validateParameters(
            templateName: "choice-param",
            parameters: ["method": .choice("POST")]
        )
    }

    @Test("Validates type compatibility")
    func validatesTypeCompatibility() async {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "required-param",
                parameters: ["url": .boolean(true)]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .invalidParameterType(let name, let expected, _) = error {
                #expect(name == "url")
                #expect(expected == .url)
            } else {
                #expect(Bool(false), "Wrong error case")
            }
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("String compatible with URL type")
    func stringCompatibleWithURL() async throws {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        // String should work for URL type
        try await engine.validateParameters(
            templateName: "required-param",
            parameters: ["url": .string("https://example.com")]
        )
    }

    @Test("Validates unknown template")
    func validatesUnknownTemplate() async {
        let engine = TemplateEngine()

        do {
            try await engine.validateParameters(
                templateName: "unknown",
                parameters: [:]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .templateNotFound(name: "unknown"))
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }
}

// MARK: - Template Engine Generation Tests

@Suite("TemplateEngine Generation Tests")
struct TemplateEngineGenerationTests {
    @Test("Generates actions from template with defaults")
    func generatesWithDefaults() async throws {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)

        let actions = try await engine.generate(
            templateName: "hello-world",
            parameters: [:]
        )

        #expect(actions.count == 2)

        // First action should be TextAction
        let textAction = actions[0].toWorkflowAction()
        #expect(textAction.identifier == "is.workflow.actions.gettext")

        // Second should be ShowResultAction
        let showAction = actions[1].toWorkflowAction()
        #expect(showAction.identifier == "is.workflow.actions.showresult")
    }

    @Test("Generates actions with custom parameters")
    func generatesWithCustomParameters() async throws {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)

        let actions = try await engine.generate(
            templateName: "hello-world",
            parameters: ["greeting": .string("Hi there!")]
        )

        #expect(actions.count == 2)
    }

    @Test("Generates actions from required param template")
    func generatesFromRequiredParam() async throws {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        let actions = try await engine.generate(
            templateName: "required-param",
            parameters: ["url": .url("https://api.example.com")]
        )

        #expect(actions.count == 2)

        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")
    }

    @Test("Generates with showResult false")
    func generatesWithShowResultFalse() async throws {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        let actions = try await engine.generate(
            templateName: "required-param",
            parameters: [
                "url": .url("https://api.example.com"),
                "showResult": .boolean(false),
            ]
        )

        #expect(actions.count == 1)
    }

    @Test("Throws for missing required parameter during generation")
    func throwsForMissingRequired() async {
        let engine = TemplateEngine()
        await engine.register(RequiredParamTestTemplate.self)

        do {
            _ = try await engine.generate(
                templateName: "required-param",
                parameters: [:]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "url"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for unknown template during generation")
    func throwsForUnknownTemplate() async {
        let engine = TemplateEngine()

        do {
            _ = try await engine.generate(
                templateName: "unknown",
                parameters: [:]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .templateNotFound(name: "unknown"))
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Builds shortcut from template")
    func buildsShortcut() async throws {
        let engine = TemplateEngine()
        await engine.register(HelloWorldTestTemplate.self)

        let shortcut = try await engine.buildShortcut(
            templateName: "hello-world",
            parameters: ["greeting": .string("Built shortcut!")],
            configuration: .init(name: "Built Test")
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.name == "Built Test")
    }
}

// MARK: - Integration Tests

@Suite("Template Engine Integration Tests")
struct TemplateEngineIntegrationTests {
    @Test("Full workflow: register, validate, generate")
    func fullWorkflow() async throws {
        let engine = TemplateEngine()

        // Register
        await engine.register(HelloWorldTestTemplate.self)
        await engine.register(RequiredParamTestTemplate.self)

        // List
        let templates = await engine.listTemplates()
        #expect(templates.count == 2)

        // Get info
        let info = await engine.getTemplateInfo(name: "hello-world")
        #expect(info != nil)

        // Validate
        try await engine.validateParameters(
            templateName: "hello-world",
            parameters: [:]
        )

        // Generate
        let actions = try await engine.generate(
            templateName: "hello-world",
            parameters: ["greeting": .string("Integration test!")]
        )
        #expect(actions.count == 2)

        // Build shortcut
        let shortcut = try await engine.buildShortcut(
            templateName: "hello-world",
            parameters: [:],
            configuration: .menuBar(name: "Test Shortcut")
        )
        #expect(shortcut.actions.count == 2)
        #expect(shortcut.types.contains("MenuBar"))
    }

    @Test("Template with choice generates correct action")
    func choiceTemplateGenerates() async throws {
        let engine = TemplateEngine()
        await engine.register(ChoiceParamTestTemplate.self)

        let actions = try await engine.generate(
            templateName: "choice-param",
            parameters: ["method": .choice("DELETE")]
        )

        #expect(actions.count == 1)
        let action = actions[0].toWorkflowAction()
        #expect(action.identifier == "is.workflow.actions.gettext")
    }
}
