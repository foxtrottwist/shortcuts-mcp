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

// MARK: - APIRequestTemplate Tests

@Suite("APIRequestTemplate Tests")
struct APIRequestTemplateTests {
    @Test("Template has correct metadata")
    func templateHasCorrectMetadata() {
        #expect(APIRequestTemplate.name == "api-request")
        #expect(APIRequestTemplate.displayName == "API Request")
        #expect(APIRequestTemplate.description.contains("HTTP request"))
        #expect(APIRequestTemplate.parameters.count == 4)
    }

    @Test("Template has correct parameters")
    func templateHasCorrectParameters() {
        let params = APIRequestTemplate.parameters

        // url parameter
        let urlParam = params.first { $0.name == "url" }
        #expect(urlParam?.type == .url)
        #expect(urlParam?.required == true)

        // method parameter
        let methodParam = params.first { $0.name == "method" }
        #expect(methodParam?.type == .choice)
        #expect(methodParam?.required == false)
        #expect(methodParam?.defaultValue == .choice("GET"))
        #expect(methodParam?.options == ["GET", "POST", "PUT", "DELETE"])

        // authHeader parameter
        let authParam = params.first { $0.name == "authHeader" }
        #expect(authParam?.type == .string)
        #expect(authParam?.required == false)

        // jsonPath parameter
        let jsonPathParam = params.first { $0.name == "jsonPath" }
        #expect(jsonPathParam?.type == .string)
        #expect(jsonPathParam?.required == false)
    }

    @Test("Generates simple GET request")
    func generatesSimpleGETRequest() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data")
        ])

        // Should have 2 actions: URLAction and ShowResultAction
        #expect(actions.count == 2)

        // First action should be URLAction
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")
        #expect(urlAction.parameters["WFURL"] == .string("https://api.example.com/data"))
        #expect(urlAction.uuid != nil)

        // Second action should be ShowResultAction
        let showAction = actions[1].toWorkflowAction()
        #expect(showAction.identifier == "is.workflow.actions.showresult")
    }

    @Test("Generates POST request")
    func generatesPOSTRequest() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "method": .choice("POST"),
        ])

        // First action should be URLAction with POST method
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")
        #expect(urlAction.parameters["WFHTTPMethod"] == .string("POST"))
        #expect(urlAction.parameters["Advanced"] == .bool(true))
    }

    @Test("Generates PUT request")
    func generatesPUTRequest() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "method": .choice("PUT"),
        ])

        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.parameters["WFHTTPMethod"] == .string("PUT"))
    }

    @Test("Generates DELETE request")
    func generatesDELETERequest() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data/123"),
            "method": .choice("DELETE"),
        ])

        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.parameters["WFHTTPMethod"] == .string("DELETE"))
    }

    @Test("Generates request with authorization header")
    func generatesRequestWithAuthHeader() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "authHeader": .string("Bearer my-secret-token"),
        ])

        let urlAction = actions[0].toWorkflowAction()

        // Check headers
        if case .dictionary(let headers) = urlAction.parameters["WFHTTPHeaders"] {
            #expect(headers["Authorization"] == .string("Bearer my-secret-token"))
        } else {
            #expect(Bool(false), "Expected headers dictionary")
        }

        #expect(urlAction.parameters["ShowHeaders"] == .bool(true))
    }

    @Test("Generates request with JSON path extraction")
    func generatesRequestWithJSONPath() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/users"),
            "jsonPath": .string("data.users"),
        ])

        // Should have 3 actions: URLAction, GetDictionaryValueAction, ShowResultAction
        #expect(actions.count == 3)

        // First action: URLAction
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")

        // Second action: GetDictionaryValueAction
        let extractAction = actions[1].toWorkflowAction()
        #expect(extractAction.identifier == "is.workflow.actions.getvalueforkey")
        #expect(extractAction.parameters["WFDictionaryKey"] == .string("data.users"))

        // Third action: ShowResultAction
        let showAction = actions[2].toWorkflowAction()
        #expect(showAction.identifier == "is.workflow.actions.showresult")
    }

    @Test("Generates full API request with all options")
    func generatesFullAPIRequest() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "method": .choice("POST"),
            "authHeader": .string("Basic dXNlcjpwYXNz"),
            "jsonPath": .string("result.items"),
        ])

        // Should have 3 actions
        #expect(actions.count == 3)

        // URLAction
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.parameters["WFHTTPMethod"] == .string("POST"))
        if case .dictionary(let headers) = urlAction.parameters["WFHTTPHeaders"] {
            #expect(headers["Authorization"] == .string("Basic dXNlcjpwYXNz"))
        } else {
            #expect(Bool(false), "Expected headers dictionary")
        }

        // GetDictionaryValueAction
        let extractAction = actions[1].toWorkflowAction()
        #expect(extractAction.parameters["WFDictionaryKey"] == .string("result.items"))

        // ShowResultAction
        let showAction = actions[2].toWorkflowAction()
        #expect(showAction.identifier == "is.workflow.actions.showresult")
    }

    @Test("Throws error when URL is missing")
    func throwsErrorWhenURLMissing() {
        let template = APIRequestTemplate()

        do {
            _ = try template.generate(with: [:])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "url"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Empty auth header is ignored")
    func emptyAuthHeaderIsIgnored() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "authHeader": .string(""),
        ])

        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.parameters["WFHTTPHeaders"] == nil)
        #expect(urlAction.parameters["ShowHeaders"] == nil)
    }

    @Test("Empty JSON path is ignored")
    func emptyJSONPathIsIgnored() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "jsonPath": .string(""),
        ])

        // Should only have 2 actions (no GetDictionaryValueAction)
        #expect(actions.count == 2)
    }

    @Test("Integrates with TemplateEngine")
    func integratesWithTemplateEngine() async throws {
        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        // Check registration
        #expect(await engine.isRegistered(name: "api-request"))

        // Get info
        let info = await engine.getTemplateInfo(name: "api-request")
        #expect(info?.displayName == "API Request")

        // Validate parameters
        try await engine.validateParameters(
            templateName: "api-request",
            parameters: [
                "url": .url("https://api.example.com"),
                "method": .choice("GET"),
            ]
        )

        // Generate actions
        let actions = try await engine.generate(
            templateName: "api-request",
            parameters: [
                "url": .url("https://api.example.com/users"),
                "jsonPath": .string("data"),
            ]
        )
        #expect(actions.count == 3)
    }

    @Test("Validates method choice parameter")
    func validatesMethodChoice() async {
        let engine = TemplateEngine()
        await engine.register(APIRequestTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "api-request",
                parameters: [
                    "url": .url("https://api.example.com"),
                    "method": .choice("PATCH"),  // Not in allowed options
                ]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .invalidChoiceValue(let name, let value, _) = error {
                #expect(name == "method")
                #expect(value == "PATCH")
            } else {
                #expect(Bool(false), "Wrong error case")
            }
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Actions have proper UUID linking")
    func actionsHaveProperUUIDLinking() throws {
        let template = APIRequestTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://api.example.com/data"),
            "jsonPath": .string("items"),
        ])

        let urlAction = actions[0].toWorkflowAction()
        let extractAction = actions[1].toWorkflowAction()
        let showAction = actions[2].toWorkflowAction()

        // URLAction should have UUID
        #expect(urlAction.uuid != nil)

        // GetDictionaryValueAction should have UUID
        #expect(extractAction.uuid != nil)

        // ShowResultAction should reference the extract action's UUID
        if case .dictionary(let textDict) = showAction.parameters["Text"],
            case .dictionary(let valueDict) = textDict["Value"],
            case .string(let outputUUID) = valueDict["OutputUUID"]
        {
            #expect(outputUUID == extractAction.uuid)
        } else {
            #expect(Bool(false), "ShowResultAction should reference extract action UUID")
        }
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

// MARK: - FileDownloadTemplate Tests

@Suite("FileDownloadTemplate Tests")
struct FileDownloadTemplateTests {
    @Test("Template has correct metadata")
    func templateMetadata() {
        #expect(FileDownloadTemplate.name == "file-download")
        #expect(FileDownloadTemplate.displayName == "File Download")
        #expect(FileDownloadTemplate.description.contains("Downloads a file"))
        #expect(FileDownloadTemplate.parameters.count == 3)
    }

    @Test("Template parameters are defined correctly")
    func templateParameters() {
        let params = FileDownloadTemplate.parameters

        // URL parameter
        let urlParam = params.first { $0.name == "url" }
        #expect(urlParam != nil)
        #expect(urlParam?.type == .url)
        #expect(urlParam?.required == true)

        // Filename parameter
        let filenameParam = params.first { $0.name == "filename" }
        #expect(filenameParam != nil)
        #expect(filenameParam?.type == .string)
        #expect(filenameParam?.required == false)

        // ShowConfirmation parameter
        let confirmParam = params.first { $0.name == "showConfirmation" }
        #expect(confirmParam != nil)
        #expect(confirmParam?.type == .boolean)
        #expect(confirmParam?.required == false)
        #expect(confirmParam?.defaultValue == .boolean(true))
    }

    @Test("Generates actions with URL only")
    func generatesWithURLOnly() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/file.pdf")
        ])

        // Should have 3 actions: URLAction, SaveFileAction (ask where), ShowNotificationAction
        #expect(actions.count == 3)

        // First action should be URLAction (GET request)
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")
        #expect(urlAction.parameters["WFURL"] == .string("https://example.com/file.pdf"))

        // Second action should be SaveFileAction (ask where to save)
        let saveAction = actions[1].toWorkflowAction()
        #expect(saveAction.identifier == "is.workflow.actions.documentpicker.save")
        #expect(saveAction.parameters["WFAskWhereToSave"] == .bool(true))

        // Third action should be ShowNotificationAction
        let notificationAction = actions[2].toWorkflowAction()
        #expect(notificationAction.identifier == "is.workflow.actions.notification")
        #expect(notificationAction.parameters["WFNotificationActionTitle"] == .string("Download Complete"))
    }

    @Test("Generates actions with filename specified")
    func generatesWithFilename() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/file.pdf"),
            "filename": .string("/Downloads/myfile.pdf"),
        ])

        // Should have 3 actions: URLAction, SaveFileAction (specific path), ShowNotificationAction
        #expect(actions.count == 3)

        // Second action should be SaveFileAction with specific path
        let saveAction = actions[1].toWorkflowAction()
        #expect(saveAction.identifier == "is.workflow.actions.documentpicker.save")
        #expect(saveAction.parameters["WFAskWhereToSave"] == .bool(false))
        #expect(saveAction.parameters["WFFileDestinationPath"] == .string("/Downloads/myfile.pdf"))
        #expect(saveAction.parameters["WFSaveFileOverwrite"] == .bool(true))
    }

    @Test("Generates actions without confirmation")
    func generatesWithoutConfirmation() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/file.pdf"),
            "showConfirmation": .boolean(false),
        ])

        // Should have only 2 actions: URLAction, SaveFileAction (no notification)
        #expect(actions.count == 2)

        // Verify no notification action
        for action in actions {
            let workflowAction = action.toWorkflowAction()
            #expect(workflowAction.identifier != "is.workflow.actions.notification")
        }
    }

    @Test("Generates actions with all parameters")
    func generatesWithAllParameters() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/report.pdf"),
            "filename": .string("/Reports/quarterly-report.pdf"),
            "showConfirmation": .boolean(true),
        ])

        // Should have 3 actions
        #expect(actions.count == 3)

        // Verify all actions are present with correct identifiers
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.identifier == "is.workflow.actions.downloadurl")

        let saveAction = actions[1].toWorkflowAction()
        #expect(saveAction.identifier == "is.workflow.actions.documentpicker.save")
        #expect(saveAction.parameters["WFFileDestinationPath"] == .string("/Reports/quarterly-report.pdf"))

        let notificationAction = actions[2].toWorkflowAction()
        #expect(notificationAction.identifier == "is.workflow.actions.notification")
    }

    @Test("Throws error when URL is missing")
    func throwsForMissingURL() {
        let template = FileDownloadTemplate()

        do {
            _ = try template.generate(with: [:])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "url"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Registers with TemplateEngine")
    func registersWithEngine() async {
        let engine = TemplateEngine()
        await engine.register(FileDownloadTemplate.self)

        #expect(await engine.isRegistered(name: "file-download"))

        let info = await engine.getTemplateInfo(name: "file-download")
        #expect(info?.displayName == "File Download")
        #expect(info?.parameters.count == 3)
    }

    @Test("Generates through TemplateEngine")
    func generatesThroughEngine() async throws {
        let engine = TemplateEngine()
        await engine.register(FileDownloadTemplate.self)

        let actions = try await engine.generate(
            templateName: "file-download",
            parameters: [
                "url": .url("https://example.com/data.json")
            ]
        )

        #expect(actions.count == 3)
    }

    @Test("Builds complete shortcut through TemplateEngine")
    func buildsCompleteShortcut() async throws {
        let engine = TemplateEngine()
        await engine.register(FileDownloadTemplate.self)

        let shortcut = try await engine.buildShortcut(
            templateName: "file-download",
            parameters: [
                "url": .url("https://example.com/image.png"),
                "filename": .string("/Pictures/downloaded-image.png"),
            ],
            configuration: .menuBar(name: "Download Image")
        )

        #expect(shortcut.name == "Download Image")
        #expect(shortcut.actions.count == 3)
        #expect(shortcut.types.contains("MenuBar"))
    }

    @Test("URLAction has correct UUID for chaining")
    func urlActionHasUUID() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/file.txt")
        ])

        // URLAction should have a UUID
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.uuid != nil)
        #expect(!urlAction.uuid!.isEmpty)
    }

    @Test("SaveFileAction has correct UUID")
    func saveFileActionHasUUID() throws {
        let template = FileDownloadTemplate()
        let actions = try template.generate(with: [
            "url": .url("https://example.com/file.txt")
        ])

        // SaveFileAction should have a UUID
        let saveAction = actions[1].toWorkflowAction()
        #expect(saveAction.uuid != nil)
        #expect(!saveAction.uuid!.isEmpty)
    }

    @Test("Works with string URL parameter")
    func worksWithStringURL() throws {
        let template = FileDownloadTemplate()

        // String should be accepted for URL type (type compatibility)
        let actions = try template.generate(with: [
            "url": .string("https://example.com/archive.zip")
        ])

        #expect(actions.count == 3)
        let urlAction = actions[0].toWorkflowAction()
        #expect(urlAction.parameters["WFURL"] == .string("https://example.com/archive.zip"))
    }
}
