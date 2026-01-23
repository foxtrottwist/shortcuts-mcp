// SPDX-License-Identifier: MIT
// TextPipelineTemplateTests.swift - Tests for text processing pipeline template

import Foundation
import Testing

@testable import ShortcutsMCP

// MARK: - Text Pipeline Template Metadata Tests

@Suite("TextPipelineTemplate Metadata Tests")
struct TextPipelineTemplateMetadataTests {
    @Test("Template has correct name")
    func templateHasCorrectName() {
        #expect(TextPipelineTemplate.name == "text-pipeline")
    }

    @Test("Template has correct display name")
    func templateHasCorrectDisplayName() {
        #expect(TextPipelineTemplate.displayName == "Text Processing Pipeline")
    }

    @Test("Template has correct description")
    func templateHasCorrectDescription() {
        #expect(TextPipelineTemplate.description.contains("text"))
        #expect(TextPipelineTemplate.description.contains("transformations"))
    }

    @Test("Template has correct parameters")
    func templateHasCorrectParameters() {
        let params = TextPipelineTemplate.parameters
        #expect(params.count == 3)

        // inputText parameter
        let inputText = params.first { $0.name == "inputText" }
        #expect(inputText != nil)
        #expect(inputText?.required == true)
        #expect(inputText?.type == .string)

        // operations parameter
        let operations = params.first { $0.name == "operations" }
        #expect(operations != nil)
        #expect(operations?.required == true)
        #expect(operations?.type == .string)

        // showResult parameter
        let showResult = params.first { $0.name == "showResult" }
        #expect(showResult != nil)
        #expect(showResult?.required == false)
        #expect(showResult?.type == .boolean)
        #expect(showResult?.defaultValue == .boolean(true))
    }
}

// MARK: - Text Pipeline Template Generation Tests

@Suite("TextPipelineTemplate Generation Tests")
struct TextPipelineTemplateGenerationTests {
    @Test("Generates uppercase transformation")
    func generatesUppercaseTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "uppercase"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello world"),
            "operations": .string(operations),
        ])

        // Should have: TextAction, ChangeCaseAction, ShowResultAction
        #expect(actions.count == 3)

        let textAction = actions[0].toWorkflowAction()
        #expect(textAction.identifier == TextAction.identifier)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.identifier == ChangeCaseAction.identifier)
        #expect(caseAction.parameters["WFCaseType"] == .string("UPPERCASE"))

        let showAction = actions[2].toWorkflowAction()
        #expect(showAction.identifier == ShowResultAction.identifier)
    }

    @Test("Generates lowercase transformation")
    func generatesLowercaseTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "lowercase"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("HELLO"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.parameters["WFCaseType"] == .string("lowercase"))
    }

    @Test("Generates capitalize transformation")
    func generatesCapitalizeTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "capitalize"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello world"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.parameters["WFCaseType"] == .string("Capitalize Every Word"))
    }

    @Test("Generates titlecase transformation")
    func generatesTitlecaseTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "titlecase"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello world"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.parameters["WFCaseType"] == .string("Capitalize with Title Case"))
    }

    @Test("Generates replace transformation")
    func generatesReplaceTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "replace", "find": "old", "replace": "new"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("old text"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let replaceAction = actions[1].toWorkflowAction()
        #expect(replaceAction.identifier == ReplaceTextAction.identifier)
        #expect(replaceAction.parameters["WFReplaceTextFind"] == .string("old"))
        #expect(replaceAction.parameters["WFReplaceTextReplace"] == .string("new"))
    }

    @Test("Generates replace with regex")
    func generatesReplaceWithRegex() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "replace", "find": "\\\\d+", "replace": "NUM", "regex": true}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("test 123"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let replaceAction = actions[1].toWorkflowAction()
        #expect(replaceAction.parameters["WFReplaceTextRegularExpression"] == .bool(true))
    }

    @Test("Generates replace case insensitive")
    func generatesReplaceCaseInsensitive() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "replace", "find": "HELLO", "replace": "hi", "caseSensitive": false}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("Hello World"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let replaceAction = actions[1].toWorkflowAction()
        #expect(replaceAction.parameters["WFReplaceTextCaseSensitive"] == .bool(false))
    }

    @Test("Generates split transformation with default separator")
    func generatesSplitWithDefaultSeparator() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "split"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("line1\nline2"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let splitAction = actions[1].toWorkflowAction()
        #expect(splitAction.identifier == SplitTextAction.identifier)
        #expect(splitAction.parameters["WFTextSeparator"] == .string("New Lines"))
    }

    @Test("Generates split with custom separator")
    func generatesSplitWithCustomSeparator() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "split", "separator": ","}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("a,b,c"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let splitAction = actions[1].toWorkflowAction()
        #expect(splitAction.parameters["WFTextSeparator"] == .string("Custom"))
        #expect(splitAction.parameters["WFTextCustomSeparator"] == .string(","))
    }

    @Test("Generates split with spaces separator")
    func generatesSplitWithSpaces() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "split", "separator": "spaces"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("a b c"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let splitAction = actions[1].toWorkflowAction()
        #expect(splitAction.parameters["WFTextSeparator"] == .string("Spaces"))
    }

    @Test("Generates combine transformation")
    func generatesCombineTransformation() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "combine", "separator": "newlines"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("text"),
            "operations": .string(operations),
        ])

        #expect(actions.count == 3)

        let combineAction = actions[1].toWorkflowAction()
        #expect(combineAction.identifier == CombineTextAction.identifier)
        #expect(combineAction.parameters["WFTextSeparator"] == .string("New Lines"))
    }

    @Test("Generates multiple transformations in sequence")
    func generatesMultipleTransformations() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [
                {"type": "uppercase"},
                {"type": "replace", "find": " ", "replace": "_"}
            ]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello world"),
            "operations": .string(operations),
        ])

        // TextAction + 2 transformations + ShowResultAction
        #expect(actions.count == 4)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.identifier == ChangeCaseAction.identifier)
        #expect(caseAction.parameters["WFCaseType"] == .string("UPPERCASE"))

        let replaceAction = actions[2].toWorkflowAction()
        #expect(replaceAction.identifier == ReplaceTextAction.identifier)
    }

    @Test("Generates without show result when disabled")
    func generatesWithoutShowResult() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "uppercase"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello"),
            "operations": .string(operations),
            "showResult": .boolean(false),
        ])

        // TextAction + ChangeCaseAction (no ShowResultAction)
        #expect(actions.count == 2)

        let lastAction = actions.last!.toWorkflowAction()
        #expect(lastAction.identifier == ChangeCaseAction.identifier)
    }

    @Test("Actions have UUIDs for chaining")
    func actionsHaveUUIDs() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "uppercase"}]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello"),
            "operations": .string(operations),
        ])

        let textAction = actions[0].toWorkflowAction()
        #expect(textAction.uuid != nil)
        #expect(!textAction.uuid!.isEmpty)

        let caseAction = actions[1].toWorkflowAction()
        #expect(caseAction.uuid != nil)
        #expect(!caseAction.uuid!.isEmpty)
    }
}

// MARK: - Text Pipeline Template Error Tests

@Suite("TextPipelineTemplate Error Tests")
struct TextPipelineTemplateErrorTests {
    @Test("Throws for missing inputText")
    func throwsForMissingInputText() {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "uppercase"}]
            """

        do {
            _ = try template.generate(with: [
                "operations": .string(operations)
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "inputText"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for missing operations")
    func throwsForMissingOperations() {
        let template = TextPipelineTemplate()

        do {
            _ = try template.generate(with: [
                "inputText": .string("hello")
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "operations"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for empty operations array")
    func throwsForEmptyOperations() {
        let template = TextPipelineTemplate()

        do {
            _ = try template.generate(with: [
                "inputText": .string("hello"),
                "operations": .string("[]"),
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .generationFailed(let reason) = error {
                #expect(reason.contains("At least one operation"))
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for invalid JSON")
    func throwsForInvalidJSON() {
        let template = TextPipelineTemplate()

        do {
            _ = try template.generate(with: [
                "inputText": .string("hello"),
                "operations": .string("not valid json"),
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .generationFailed(let reason) = error {
                #expect(reason.contains("Failed to parse operations JSON"))
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for unknown operation type")
    func throwsForUnknownOperationType() {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "unknown_operation"}]
            """

        do {
            _ = try template.generate(with: [
                "inputText": .string("hello"),
                "operations": .string(operations),
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .generationFailed(let reason) = error {
                #expect(reason.contains("Unknown operation type"))
                #expect(reason.contains("unknown_operation"))
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    @Test("Throws for replace without find")
    func throwsForReplaceWithoutFind() {
        let template = TextPipelineTemplate()
        let operations = """
            [{"type": "replace", "replace": "new"}]
            """

        do {
            _ = try template.generate(with: [
                "inputText": .string("hello"),
                "operations": .string(operations),
            ])
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            if case .generationFailed(let reason) = error {
                #expect(reason.contains("'find' field"))
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }
}

// MARK: - Text Pipeline Template Engine Integration Tests

@Suite("TextPipelineTemplate Engine Integration Tests")
struct TextPipelineTemplateEngineIntegrationTests {
    @Test("Template can be registered with engine")
    func canRegisterWithEngine() async {
        let engine = TemplateEngine()
        await engine.register(TextPipelineTemplate.self)

        #expect(await engine.isRegistered(name: "text-pipeline"))

        let info = await engine.getTemplateInfo(name: "text-pipeline")
        #expect(info != nil)
        #expect(info?.displayName == "Text Processing Pipeline")
    }

    @Test("Template generates through engine")
    func generatesThoughEngine() async throws {
        let engine = TemplateEngine()
        await engine.register(TextPipelineTemplate.self)

        let operations = """
            [{"type": "uppercase"}, {"type": "replace", "find": " ", "replace": "-"}]
            """

        let actions = try await engine.generate(
            templateName: "text-pipeline",
            parameters: [
                "inputText": .string("hello world"),
                "operations": .string(operations),
            ]
        )

        // TextAction + uppercase + replace + ShowResultAction
        #expect(actions.count == 4)
    }

    @Test("Template builds shortcut through engine")
    func buildsShortcutThroughEngine() async throws {
        let engine = TemplateEngine()
        await engine.register(TextPipelineTemplate.self)

        let operations = """
            [{"type": "uppercase"}]
            """

        let shortcut = try await engine.buildShortcut(
            templateName: "text-pipeline",
            parameters: [
                "inputText": .string("hello"),
                "operations": .string(operations),
            ],
            configuration: .menuBar(name: "Text Pipeline Test")
        )

        #expect(shortcut.actions.count == 3)
        #expect(shortcut.name == "Text Pipeline Test")
        #expect(shortcut.types.contains("MenuBar"))
    }

    @Test("Validation fails for missing required parameters through engine")
    func validationFailsThroughEngine() async {
        let engine = TemplateEngine()
        await engine.register(TextPipelineTemplate.self)

        do {
            try await engine.validateParameters(
                templateName: "text-pipeline",
                parameters: [:]
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as TemplateError {
            #expect(error == .missingRequiredParameter(name: "inputText"))
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }
}

// MARK: - Complex Pipeline Tests

@Suite("TextPipelineTemplate Complex Pipeline Tests")
struct TextPipelineTemplateComplexPipelineTests {
    @Test("Complex multi-step pipeline")
    func complexMultiStepPipeline() throws {
        let template = TextPipelineTemplate()
        let operations = """
            [
                {"type": "replace", "find": "  ", "replace": " "},
                {"type": "uppercase"},
                {"type": "replace", "find": " ", "replace": "_"},
                {"type": "replace", "find": ".", "replace": ""}
            ]
            """

        let actions = try template.generate(with: [
            "inputText": .string("hello  world. test."),
            "operations": .string(operations),
        ])

        // TextAction + 4 transformations + ShowResultAction
        #expect(actions.count == 6)

        // Verify each action type
        #expect(actions[0].toWorkflowAction().identifier == TextAction.identifier)
        #expect(actions[1].toWorkflowAction().identifier == ReplaceTextAction.identifier)
        #expect(actions[2].toWorkflowAction().identifier == ChangeCaseAction.identifier)
        #expect(actions[3].toWorkflowAction().identifier == ReplaceTextAction.identifier)
        #expect(actions[4].toWorkflowAction().identifier == ReplaceTextAction.identifier)
        #expect(actions[5].toWorkflowAction().identifier == ShowResultAction.identifier)
    }

    @Test("All case transformations")
    func allCaseTransformations() throws {
        let template = TextPipelineTemplate()

        let cases = [
            ("uppercase", "UPPERCASE"),
            ("lowercase", "lowercase"),
            ("capitalize", "Capitalize Every Word"),
            ("titlecase", "Capitalize with Title Case"),
            ("sentencecase", "Capitalize with sentence case"),
            ("alternatingcase", "cApItAlIzE wItH aLtErNaTiNg CaSe"),
        ]

        for (opType, expectedValue) in cases {
            let operations = """
                [{"type": "\(opType)"}]
                """

            let actions = try template.generate(with: [
                "inputText": .string("test"),
                "operations": .string(operations),
            ])

            let caseAction = actions[1].toWorkflowAction()
            #expect(
                caseAction.parameters["WFCaseType"] == .string(expectedValue),
                "Expected \(expectedValue) for \(opType)"
            )
        }
    }

    @Test("All separator types for split")
    func allSeparatorTypesForSplit() throws {
        let template = TextPipelineTemplate()

        let separators = [
            ("newlines", "New Lines"),
            ("newline", "New Lines"),
            ("lines", "New Lines"),
            ("spaces", "Spaces"),
            ("space", "Spaces"),
            ("everycharacter", "Every Character"),
            ("character", "Every Character"),
            ("characters", "Every Character"),
        ]

        for (separator, expectedValue) in separators {
            let operations = """
                [{"type": "split", "separator": "\(separator)"}]
                """

            let actions = try template.generate(with: [
                "inputText": .string("test"),
                "operations": .string(operations),
            ])

            let splitAction = actions[1].toWorkflowAction()
            #expect(
                splitAction.parameters["WFTextSeparator"] == .string(expectedValue),
                "Expected \(expectedValue) for separator '\(separator)'"
            )
        }
    }
}
