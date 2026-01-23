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

    // MARK: - URLAction Tests

    @Test("URLAction creates simple GET request")
    func testURLActionSimpleGet() throws {
        let action = URLAction("https://api.example.com/data")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.downloadurl")
        #expect(workflowAction.parameters["WFURL"] == .string("https://api.example.com/data"))
        // Simple GET should not show advanced options
        #expect(workflowAction.parameters["Advanced"] == nil)
    }

    @Test("URLAction creates GET request with method specified")
    func testURLActionGetWithMethod() throws {
        let action = URLAction(method: .get, url: "https://api.example.com/data")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.downloadurl")
        #expect(workflowAction.parameters["WFURL"] == .string("https://api.example.com/data"))
        // GET with explicit method should not show advanced
        #expect(workflowAction.parameters["Advanced"] == nil)
    }

    @Test("URLAction creates POST request")
    func testURLActionPost() throws {
        let action = URLAction(method: .post, url: "https://api.example.com/data")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.downloadurl")
        #expect(workflowAction.parameters["Advanced"] == .bool(true))
        #expect(workflowAction.parameters["WFHTTPMethod"] == .string("POST"))
    }

    @Test("URLAction creates POST request with JSON body")
    func testURLActionPostJSON() throws {
        let action = URLAction.postJSON(
            "https://api.example.com/users",
            json: [
                "name": .string("John Doe"),
                "age": .int(30),
                "active": .bool(true),
            ]
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["Advanced"] == .bool(true))
        #expect(workflowAction.parameters["WFHTTPMethod"] == .string("POST"))
        #expect(workflowAction.parameters["WFHTTPBodyType"] == .string("0"))  // JSON

        guard case .dictionary(let jsonDict) = workflowAction.parameters["WFJSONValues"] else {
            Issue.record("Expected WFJSONValues dictionary")
            return
        }

        #expect(jsonDict["name"] == .string("John Doe"))
        #expect(jsonDict["age"] == .int(30))
        #expect(jsonDict["active"] == .bool(true))
    }

    @Test("URLAction creates POST request with form body")
    func testURLActionPostForm() throws {
        let action = URLAction.postForm(
            "https://api.example.com/login",
            form: [
                "username": "admin",
                "password": "secret",
            ]
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFHTTPBodyType"] == .string("1"))  // Form

        guard case .dictionary(let formDict) = workflowAction.parameters["WFFormValues"] else {
            Issue.record("Expected WFFormValues dictionary")
            return
        }

        #expect(formDict["username"] == .string("admin"))
        #expect(formDict["password"] == .string("secret"))
    }

    @Test("URLAction creates request with custom headers")
    func testURLActionWithHeaders() throws {
        let action = URLAction.get(
            "https://api.example.com/data",
            headers: [
                "Authorization": "Bearer token123",
                "Content-Type": "application/json",
            ]
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["ShowHeaders"] == .bool(true))

        guard case .dictionary(let headersDict) = workflowAction.parameters["WFHTTPHeaders"] else {
            Issue.record("Expected WFHTTPHeaders dictionary")
            return
        }

        #expect(headersDict["Authorization"] == .string("Bearer token123"))
        #expect(headersDict["Content-Type"] == .string("application/json"))
    }

    @Test("URLAction creates PUT request")
    func testURLActionPut() throws {
        let action = URLAction.putJSON(
            "https://api.example.com/users/1",
            json: ["name": .string("Jane Doe")]
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFHTTPMethod"] == .string("PUT"))
        #expect(workflowAction.parameters["WFHTTPBodyType"] == .string("0"))
    }

    @Test("URLAction creates PATCH request")
    func testURLActionPatch() throws {
        let action = URLAction.patchJSON(
            "https://api.example.com/users/1",
            json: ["status": .string("active")]
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFHTTPMethod"] == .string("PATCH"))
    }

    @Test("URLAction creates DELETE request")
    func testURLActionDelete() throws {
        let action = URLAction.delete("https://api.example.com/users/1")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFHTTPMethod"] == .string("DELETE"))
    }

    @Test("URLAction supports variable URL reference")
    func testURLActionWithVariableURL() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "url-uuid", outputName: "URL")
        let action = URLAction(url: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFURL"] else {
            Issue.record("Expected WFURL dictionary")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("URLAction with UUID and custom output name")
    func testURLActionWithUUIDAndOutputName() throws {
        let action = URLAction(
            "https://api.example.com/data",
            uuid: "url-action-uuid",
            customOutputName: "APIResponse"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "url-action-uuid")
        #expect(workflowAction.customOutputName == "APIResponse")
    }

    @Test("URLAction creates full API request shortcut")
    func testAPIRequestShortcut() throws {
        let urlActionUUID = UUID().uuidString
        let urlAction = URLAction.postJSON(
            "https://api.example.com/data",
            json: ["message": .string("Hello API")],
            headers: ["Authorization": "Bearer token"],
            uuid: urlActionUUID
        )
        let showAction = ShowResultAction(
            fromActionWithUUID: urlActionUUID, outputName: "Contents of URL")

        let shortcut = Shortcut(
            name: "API Request Test",
            actions: [
                urlAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 2)
    }

    @Test("GetContentsOfURLAction is alias for URLAction")
    func testGetContentsOfURLActionAlias() throws {
        let action: GetContentsOfURLAction = URLAction("https://example.com")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.downloadurl")
    }

    @Test("HTTPMethod has all required cases")
    func testHTTPMethodCases() throws {
        let methods = HTTPMethod.allCases
        #expect(methods.count == 5)
        #expect(methods.contains(.get))
        #expect(methods.contains(.post))
        #expect(methods.contains(.put))
        #expect(methods.contains(.patch))
        #expect(methods.contains(.delete))
    }
}
