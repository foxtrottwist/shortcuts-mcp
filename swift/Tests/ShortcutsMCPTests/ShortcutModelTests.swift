// SPDX-License-Identifier: MIT
// ShortcutModelTests.swift - Tests for Shortcut Codable models

import Foundation
import Testing

@testable import ShortcutsMCP

@Suite("Shortcut Model Tests")
struct ShortcutModelTests {
    @Test("Shortcut encodes to valid plist with required keys")
    func testShortcutEncodesToPlist() throws {
        let shortcut = Shortcut(
            name: "Test Shortcut",
            icon: WorkflowIcon(glyphNumber: 59771, startColor: 463_140_863),
            actions: [
                WorkflowAction.showResult("Hello, World!")
            ],
            inputContentItemClasses: ["WFStringContentItem"],
            types: ["MenuBar", "QuickActions"]
        )

        let plistData = try shortcut.encodeToXMLPlist()
        let plistString = String(data: plistData, encoding: .utf8)!

        // Verify required keys are present
        #expect(plistString.contains("WFWorkflowActions"))
        #expect(plistString.contains("WFWorkflowIcon"))
        #expect(plistString.contains("WFWorkflowMinimumClientVersion"))
        #expect(plistString.contains("WFWorkflowMinimumClientVersionString"))
        #expect(plistString.contains("WFWorkflowClientVersion"))
        #expect(plistString.contains("WFWorkflowInputContentItemClasses"))
        #expect(plistString.contains("WFWorkflowTypes"))

        // Verify icon structure
        #expect(plistString.contains("WFWorkflowIconGlyphNumber"))
        #expect(plistString.contains("WFWorkflowIconStartColor"))

        // Verify action structure
        #expect(plistString.contains("WFWorkflowActionIdentifier"))
        #expect(plistString.contains("WFWorkflowActionParameters"))
        #expect(plistString.contains("is.workflow.actions.showresult"))

        // Verify content
        #expect(plistString.contains("Test Shortcut"))
        #expect(plistString.contains("WFStringContentItem"))
        #expect(plistString.contains("MenuBar"))
        #expect(plistString.contains("QuickActions"))
    }

    @Test("Shortcut roundtrips through plist encoding")
    func testShortcutRoundtrip() throws {
        let original = Shortcut(
            name: "Roundtrip Test",
            icon: .withColor(red: 255, green: 69, blue: 58, glyphNumber: 12345),
            actions: [
                WorkflowAction.text("Hello"),
                WorkflowAction.showResult("Done"),
            ],
            inputContentItemClasses: ["WFURLContentItem", "WFStringContentItem"],
            types: ["ActionExtension"],
            minimumClientVersion: 1000,
            minimumClientVersionString: "1000",
            clientVersion: 2700
        )

        // Encode to plist
        let plistData = try original.encodeToPlist()

        // Decode back
        let decoded = try Shortcut.decode(from: plistData)

        // Verify fields match
        #expect(decoded.name == original.name)
        #expect(decoded.icon == original.icon)
        #expect(decoded.actions.count == original.actions.count)
        #expect(decoded.inputContentItemClasses == original.inputContentItemClasses)
        #expect(decoded.types == original.types)
        #expect(decoded.minimumClientVersion == original.minimumClientVersion)
        #expect(decoded.minimumClientVersionString == original.minimumClientVersionString)
        #expect(decoded.clientVersion == original.clientVersion)
    }

    @Test("WorkflowAction encodes identifier and parameters")
    func testWorkflowActionEncoding() throws {
        let action = WorkflowAction(
            identifier: "is.workflow.actions.showresult",
            parameters: [
                "Text": .string("Hello"),
                "Count": .int(42),
                "Enabled": .bool(true),
            ],
            uuid: "test-uuid-123"
        )

        // Create a shortcut with this action to test encoding
        let shortcut = Shortcut(actions: [action])
        let plistData = try shortcut.encodeToXMLPlist()
        let plistString = String(data: plistData, encoding: .utf8)!

        #expect(plistString.contains("is.workflow.actions.showresult"))
        #expect(plistString.contains("test-uuid-123"))
        #expect(plistString.contains("Hello"))
    }

    @Test("ActionParameterValue supports all types")
    func testActionParameterValueTypes() throws {
        let params: [String: ActionParameterValue] = [
            "string": .string("text"),
            "int": .int(123),
            "double": .double(3.14),
            "bool": .bool(true),
            "array": .array([.string("a"), .int(1)]),
            "dict": .dictionary(["nested": .string("value")]),
        ]

        let action = WorkflowAction(identifier: "test", parameters: params)
        let shortcut = Shortcut(actions: [action])

        // Should encode without error
        let plistData = try shortcut.encodeToXMLPlist()
        let plistString = String(data: plistData, encoding: .utf8)!

        #expect(plistString.contains("text"))
        #expect(plistString.contains("123"))
        #expect(plistString.contains("3.14"))
        #expect(plistString.contains("nested"))
        #expect(plistString.contains("value"))
    }

    @Test("WorkflowIcon color helper creates correct RGBA value")
    func testWorkflowIconColor() {
        // Red: 0xFF, Green: 0x43, Blue: 0x51, Alpha: 0xFF
        // Expected: 0xFF4351FF = 4282601983
        let icon = WorkflowIcon.withColor(red: 0xFF, green: 0x43, blue: 0x51)
        #expect(icon.startColor == 4_282_601_983)
    }

    @Test("Factory methods create correct actions")
    func testActionFactoryMethods() {
        let showResult = WorkflowAction.showResult("Test")
        #expect(showResult.identifier == ActionIdentifier.showResult)
        #expect(showResult.parameters["Text"] == .string("Test"))

        let text = WorkflowAction.text("Content")
        #expect(text.identifier == ActionIdentifier.text)
        #expect(text.parameters["WFTextActionText"] == .string("Content"))

        let notification = WorkflowAction.showNotification(body: "Body", title: "Title")
        #expect(notification.identifier == ActionIdentifier.showNotification)
        #expect(notification.parameters["WFNotificationActionBody"] == .string("Body"))
        #expect(notification.parameters["WFNotificationActionTitle"] == .string("Title"))

        let shell = WorkflowAction.runShellScript("echo hello")
        #expect(shell.identifier == ActionIdentifier.runShellScript)
        #expect(shell.parameters["WFShellScript"] == .string("echo hello"))
    }

    @Test("Default shortcut has valid structure")
    func testDefaultShortcut() throws {
        let shortcut = Shortcut()

        // Should have default values
        #expect(shortcut.minimumClientVersion == 900)
        #expect(shortcut.minimumClientVersionString == "900")
        #expect(shortcut.clientVersion == 2614)
        #expect(shortcut.icon == WorkflowIcon.default)
        #expect(shortcut.actions.isEmpty)
        #expect(shortcut.inputContentItemClasses.isEmpty)
        #expect(shortcut.types.isEmpty)

        // Should still encode correctly
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }
}

// MARK: - ImportQuestion Tests

@Suite("ImportQuestion Tests")
struct ImportQuestionTests {
    @Test("ImportQuestion creates with all fields")
    func testImportQuestionCreation() {
        let question = ImportQuestion(
            actionIndex: 2,
            parameterKey: "WFAPIKey",
            category: "API Key",
            defaultValue: "your-api-key-here",
            text: "Enter your API key"
        )

        #expect(question.actionIndex == 2)
        #expect(question.parameterKey == "WFAPIKey")
        #expect(question.category == "API Key")
        #expect(question.defaultValue == "your-api-key-here")
        #expect(question.text == "Enter your API key")
    }

    @Test("ImportQuestion creates with minimal fields")
    func testImportQuestionMinimal() {
        let question = ImportQuestion(
            actionIndex: 0,
            parameterKey: "WFPassword"
        )

        #expect(question.actionIndex == 0)
        #expect(question.parameterKey == "WFPassword")
        #expect(question.category == nil)
        #expect(question.defaultValue == nil)
        #expect(question.text == nil)
    }

    @Test("ImportQuestion encodes to plist with correct keys")
    func testImportQuestionEncoding() throws {
        let question = ImportQuestion(
            actionIndex: 1,
            parameterKey: "WFSecretToken",
            category: "Credential",
            defaultValue: "default-token",
            text: "Please enter your secret token"
        )

        let shortcut = Shortcut(
            name: "API Shortcut",
            actions: [
                WorkflowAction.text("Setup"),
                WorkflowAction.showResult("Done")
            ],
            importQuestions: [question]
        )

        let plistData = try shortcut.encodeToXMLPlist()
        let plistString = String(data: plistData, encoding: .utf8)!

        // Verify WFWorkflowImportQuestions is present
        #expect(plistString.contains("WFWorkflowImportQuestions"))

        // Verify ImportQuestion keys
        #expect(plistString.contains("ActionIndex"))
        #expect(plistString.contains("ParameterKey"))
        #expect(plistString.contains("Category"))
        #expect(plistString.contains("DefaultValue"))
        #expect(plistString.contains("Text"))

        // Verify values
        #expect(plistString.contains("WFSecretToken"))
        #expect(plistString.contains("Credential"))
        #expect(plistString.contains("default-token"))
        #expect(plistString.contains("Please enter your secret token"))
    }

    @Test("ImportQuestion roundtrips through plist encoding")
    func testImportQuestionRoundtrip() throws {
        let questions = [
            ImportQuestion(
                actionIndex: 0,
                parameterKey: "APIKey",
                category: "API Key",
                defaultValue: "sk-xxx",
                text: "Enter API Key"
            ),
            ImportQuestion(
                actionIndex: 2,
                parameterKey: "BaseURL",
                category: "URL",
                text: "Enter base URL"
            )
        ]

        let original = Shortcut(
            name: "Multi-Question Shortcut",
            actions: [
                WorkflowAction.text("Step 1"),
                WorkflowAction.text("Step 2"),
                WorkflowAction.showResult("Done")
            ],
            importQuestions: questions
        )

        // Encode and decode
        let plistData = try original.encodeToPlist()
        let decoded = try Shortcut.decode(from: plistData)

        // Verify import questions roundtripped
        #expect(decoded.importQuestions != nil)
        #expect(decoded.importQuestions?.count == 2)

        let first = decoded.importQuestions?[0]
        #expect(first?.actionIndex == 0)
        #expect(first?.parameterKey == "APIKey")
        #expect(first?.category == "API Key")
        #expect(first?.defaultValue == "sk-xxx")
        #expect(first?.text == "Enter API Key")

        let second = decoded.importQuestions?[1]
        #expect(second?.actionIndex == 2)
        #expect(second?.parameterKey == "BaseURL")
        #expect(second?.category == "URL")
        #expect(second?.defaultValue == nil)
        #expect(second?.text == "Enter base URL")
    }

    @Test("Shortcut without import questions encodes correctly")
    func testShortcutWithoutImportQuestions() throws {
        let shortcut = Shortcut(
            name: "Simple Shortcut",
            actions: [WorkflowAction.showResult("Hello")]
        )

        let plistData = try shortcut.encodeToXMLPlist()
        let plistString = String(data: plistData, encoding: .utf8)!

        // WFWorkflowImportQuestions should NOT be present when nil
        #expect(!plistString.contains("WFWorkflowImportQuestions"))
    }

    @Test("ImportQuestion common categories")
    func testImportQuestionCategories() {
        // Test common category values used in shortcuts
        let apiKeyQuestion = ImportQuestion(
            actionIndex: 0,
            parameterKey: "WFAPIKey",
            category: "API Key",
            text: "Enter your API key"
        )
        #expect(apiKeyQuestion.category == "API Key")

        let credentialQuestion = ImportQuestion(
            actionIndex: 1,
            parameterKey: "WFPassword",
            category: "Credential",
            text: "Enter password"
        )
        #expect(credentialQuestion.category == "Credential")

        let urlQuestion = ImportQuestion(
            actionIndex: 2,
            parameterKey: "WFBaseURL",
            category: "URL",
            text: "Enter base URL"
        )
        #expect(urlQuestion.category == "URL")
    }
}
