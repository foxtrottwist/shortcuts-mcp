// SPDX-License-Identifier: MIT
// ActionTests.swift - Tests for TextAction and ShowResultAction

import Foundation
import Testing

@testable import ShortcutsMCP

@Suite("Action Tests")
struct ActionTests {
    // MARK: - TextAction Tests

    @Test("TextAction creates action with plain string")
    func testTextActionPlainString() throws {
        let action = TextAction("Hello World")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.gettext")
        #expect(workflowAction.parameters["WFTextActionText"] == .string("Hello World"))
    }

    @Test("TextAction creates action with UUID and custom output name")
    func testTextActionWithUUIDAndOutputName() throws {
        let action = TextAction("Test", uuid: "test-uuid-123", customOutputName: "MyText")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "test-uuid-123")
        #expect(workflowAction.customOutputName == "MyText")
    }

    @Test("TextAction supports magic variable attachment")
    func testTextActionWithMagicVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "source-uuid", outputName: "Result")
        let action = TextAction(.attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        // Verify the parameter is a dictionary with WFSerializationType
        guard case .dictionary(let dict) = workflowAction.parameters["WFTextActionText"] else {
            Issue.record("Expected dictionary parameter")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["Type"] == .string("ActionOutput"))
        #expect(valueDict["OutputUUID"] == .string("source-uuid"))
        #expect(valueDict["OutputName"] == .string("Result"))
    }

    // MARK: - ShowResultAction Tests

    @Test("ShowResultAction creates action with plain string")
    func testShowResultActionPlainString() throws {
        let action = ShowResultAction("Hello World")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.showresult")
        #expect(workflowAction.parameters["Text"] == .string("Hello World"))
    }

    @Test("ShowResultAction creates action referencing another action's output")
    func testShowResultActionFromActionOutput() throws {
        let action = ShowResultAction(fromActionWithUUID: "text-action-uuid", outputName: "Text")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.showresult")

        guard case .dictionary(let dict) = workflowAction.parameters["Text"] else {
            Issue.record("Expected dictionary parameter")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("ShowResultAction.showInput creates input reference")
    func testShowResultShowInput() throws {
        let action = ShowResultAction.showInput()
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["Text"] else {
            Issue.record("Expected dictionary parameter")
            return
        }

        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["Type"] == .string("ExtensionInput"))
    }

    // MARK: - Hello World Shortcut Test

    @Test("Can create Hello World shortcut with TextAction and ShowResultAction")
    func testHelloWorldShortcut() throws {
        // Create actions
        let textUUID = UUID().uuidString
        let textAction = TextAction("Hello World", uuid: textUUID, customOutputName: "Greeting")
        let showAction = ShowResultAction(
            fromActionWithUUID: textUUID, outputName: "Greeting")

        // Create shortcut
        let shortcut = Shortcut(
            name: "Hello World",
            icon: WorkflowIcon.withColor(red: 0x1B, green: 0x9A, blue: 0xF7, glyphNumber: 59771),
            actions: [
                textAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        // Verify shortcut structure
        #expect(shortcut.name == "Hello World")
        #expect(shortcut.actions.count == 2)

        // Verify first action (Text)
        let firstAction = shortcut.actions[0]
        #expect(firstAction.identifier == "is.workflow.actions.gettext")
        #expect(firstAction.uuid == textUUID)
        #expect(firstAction.customOutputName == "Greeting")

        // Verify second action (Show Result)
        let secondAction = shortcut.actions[1]
        #expect(secondAction.identifier == "is.workflow.actions.showresult")

        // Encode to plist and verify it's valid
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        // Decode back to verify roundtrip
        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.name == "Hello World")
        #expect(decoded.actions.count == 2)
    }

    @Test("Hello World shortcut can be written to file")
    func testHelloWorldShortcutWriteToFile() throws {
        // Create a simple Hello World shortcut
        let textUUID = UUID().uuidString
        let textAction = TextAction("Hello World", uuid: textUUID)
        let showAction = ShowResultAction(fromActionWithUUID: textUUID)

        let shortcut = Shortcut(
            name: "Hello World Test",
            actions: [
                textAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        // Encode to plist
        let plistData = try shortcut.encodeToPlist()

        // Write to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let shortcutURL = tempDir.appendingPathComponent("HelloWorld.shortcut")

        try plistData.write(to: shortcutURL)

        // Verify file exists and has content
        #expect(FileManager.default.fileExists(atPath: shortcutURL.path))

        let fileData = try Data(contentsOf: shortcutURL)
        #expect(fileData == plistData)

        // Clean up
        try FileManager.default.removeItem(at: shortcutURL)
    }

    @Test("Shortcut with text and show result produces valid XML plist")
    func testHelloWorldXMLPlist() throws {
        let textUUID = "12345678-1234-1234-1234-123456789ABC"
        let textAction = TextAction("Hello World", uuid: textUUID)
        let showAction = ShowResultAction(fromActionWithUUID: textUUID)

        let shortcut = Shortcut(
            name: "Hello World",
            actions: [
                textAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        let xmlData = try shortcut.encodeToXMLPlist()
        let xmlString = String(data: xmlData, encoding: .utf8)!

        // Verify structure
        #expect(xmlString.contains("is.workflow.actions.gettext"))
        #expect(xmlString.contains("is.workflow.actions.showresult"))
        #expect(xmlString.contains("WFTextActionText"))
        #expect(xmlString.contains("Hello World"))
        #expect(xmlString.contains("WFSerializationType"))
        #expect(xmlString.contains("WFTextTokenAttachment"))
        #expect(xmlString.contains(textUUID))
    }

    // MARK: - TextTokenString Tests

    @Test("TextTokenString supports inline variable references")
    func testTextTokenStringInlineVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "source-uuid", outputName: "Name")
        let tokenString = TextTokenString(
            string: "Hello, \u{FFFC}!",
            attachmentsByRange: ["{7, 1}": attachment]
        )

        let action = TextAction(.tokenString(tokenString))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFTextActionText"] else {
            Issue.record("Expected dictionary parameter")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenString"))

        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["string"] == .string("Hello, \u{FFFC}!"))

        guard case .dictionary(let attachmentsDict) = valueDict["attachmentsByRange"] else {
            Issue.record("Expected attachmentsByRange dictionary")
            return
        }

        #expect(attachmentsDict["{7, 1}"] != nil)
    }
}
