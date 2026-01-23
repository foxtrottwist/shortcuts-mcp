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

    // MARK: - SaveFileAction Tests

    @Test("SaveFileAction creates action with document picker prompt")
    func testSaveFileActionWithPicker() throws {
        let action = SaveFileAction()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.documentpicker.save")
        #expect(workflowAction.parameters["WFFileStorageService"] == .string("iCloud Drive"))
        #expect(workflowAction.parameters["WFAskWhereToSave"] == .bool(true))
    }

    @Test("SaveFileAction creates action with specific destination path")
    func testSaveFileActionWithPath() throws {
        let action = SaveFileAction(
            service: .iCloudDrive,
            destinationPath: "/Shortcuts/data.json",
            overwriteIfExists: true
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.documentpicker.save")
        #expect(workflowAction.parameters["WFFileStorageService"] == .string("iCloud Drive"))
        #expect(workflowAction.parameters["WFAskWhereToSave"] == .bool(false))
        #expect(workflowAction.parameters["WFFileDestinationPath"] == .string("/Shortcuts/data.json"))
        #expect(workflowAction.parameters["WFSaveFileOverwrite"] == .bool(true))
    }

    @Test("SaveFileAction supports Dropbox storage")
    func testSaveFileActionDropbox() throws {
        let action = SaveFileAction.toDropbox(path: "/backup/file.txt", overwrite: false)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFFileStorageService"] == .string("Dropbox"))
        #expect(workflowAction.parameters["WFFileDestinationPath"] == .string("/backup/file.txt"))
    }

    @Test("SaveFileAction convenience method askWhereToSave")
    func testSaveFileActionAskWhereToSave() throws {
        let action = SaveFileAction.askWhereToSave(service: .dropbox)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFFileStorageService"] == .string("Dropbox"))
        #expect(workflowAction.parameters["WFAskWhereToSave"] == .bool(true))
    }

    @Test("SaveFileAction with UUID and custom output name")
    func testSaveFileActionWithUUID() throws {
        let action = SaveFileAction(
            service: .iCloudDrive,
            uuid: "save-file-uuid",
            customOutputName: "SavedFile"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "save-file-uuid")
        #expect(workflowAction.customOutputName == "SavedFile")
    }

    @Test("SaveFileAction supports variable destination path")
    func testSaveFileActionWithVariablePath() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "path-uuid", outputName: "Path")
        let action = SaveFileAction(
            service: .iCloudDrive,
            destinationPath: .attachment(attachment),
            overwriteIfExists: true
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFFileDestinationPath"] else {
            Issue.record("Expected WFFileDestinationPath dictionary")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    // MARK: - GetFileAction Tests

    @Test("GetFileAction creates action with document picker")
    func testGetFileActionWithPicker() throws {
        let action = GetFileAction()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.documentpicker.open")
        #expect(workflowAction.parameters["WFFileStorageService"] == .string("iCloud Drive"))
        #expect(workflowAction.parameters["WFShowFilePicker"] == .bool(true))
    }

    @Test("GetFileAction creates action with specific file path")
    func testGetFileActionWithPath() throws {
        let action = GetFileAction(
            service: .iCloudDrive,
            filePath: "/Shortcuts/config.json",
            errorIfNotFound: true
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.documentpicker.open")
        #expect(workflowAction.parameters["WFShowFilePicker"] == .bool(false))
        #expect(workflowAction.parameters["WFGetFilePath"] == .string("/Shortcuts/config.json"))
        #expect(workflowAction.parameters["WFFileErrorIfNotFound"] == .bool(true))
    }

    @Test("GetFileAction supports multiple file selection")
    func testGetFileActionSelectMultiple() throws {
        let action = GetFileAction(service: .iCloudDrive, selectMultiple: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFShowFilePicker"] == .bool(true))
        #expect(workflowAction.parameters["SelectMultiple"] == .bool(true))
    }

    @Test("GetFileAction convenience method selectFile")
    func testGetFileActionSelectFile() throws {
        let action = GetFileAction.selectFile(service: .dropbox)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFFileStorageService"] == .string("Dropbox"))
        #expect(workflowAction.parameters["WFShowFilePicker"] == .bool(true))
        #expect(workflowAction.parameters["SelectMultiple"] == .bool(false))
    }

    @Test("GetFileAction convenience method selectFiles")
    func testGetFileActionSelectFiles() throws {
        let action = GetFileAction.selectFiles()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["SelectMultiple"] == .bool(true))
    }

    @Test("GetFileAction convenience method fromICloud")
    func testGetFileActionFromICloud() throws {
        let action = GetFileAction.fromICloud(path: "/data/file.txt", errorIfNotFound: false)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFFileStorageService"] == .string("iCloud Drive"))
        #expect(workflowAction.parameters["WFGetFilePath"] == .string("/data/file.txt"))
        #expect(workflowAction.parameters["WFFileErrorIfNotFound"] == .bool(false))
    }

    @Test("GetFileAction convenience method fromDropbox")
    func testGetFileActionFromDropbox() throws {
        let action = GetFileAction.fromDropbox(path: "/backup/data.json")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFFileStorageService"] == .string("Dropbox"))
        #expect(workflowAction.parameters["WFGetFilePath"] == .string("/backup/data.json"))
    }

    @Test("GetFileAction with UUID and custom output name")
    func testGetFileActionWithUUID() throws {
        let action = GetFileAction(
            service: .iCloudDrive,
            uuid: "get-file-uuid",
            customOutputName: "SelectedFile"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "get-file-uuid")
        #expect(workflowAction.customOutputName == "SelectedFile")
    }

    @Test("GetFileAction supports variable file path")
    func testGetFileActionWithVariablePath() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "path-uuid", outputName: "FilePath")
        let action = GetFileAction(
            service: .iCloudDrive,
            filePath: .attachment(attachment),
            errorIfNotFound: true
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFGetFilePath"] else {
            Issue.record("Expected WFGetFilePath dictionary")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    // MARK: - SelectFileAction Tests

    @Test("SelectFileAction is alias for GetFileAction")
    func testSelectFileActionAlias() throws {
        let action: SelectFileAction = GetFileAction.selectFile()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.documentpicker.open")
        #expect(workflowAction.parameters["WFShowFilePicker"] == .bool(true))
    }

    // MARK: - SelectFolderAction Tests

    @Test("SelectFolderAction creates action with folder picker")
    func testSelectFolderAction() throws {
        let action = SelectFolderAction()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.file.select")
        #expect(workflowAction.parameters["WFPickingMode"] == .string("Folders"))
    }

    @Test("SelectFolderAction supports multiple selection")
    func testSelectFolderActionMultiple() throws {
        let action = SelectFolderAction(selectMultiple: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["SelectMultiple"] == .bool(true))
    }

    @Test("SelectFolderAction with UUID and custom output name")
    func testSelectFolderActionWithUUID() throws {
        let action = SelectFolderAction(
            selectMultiple: false,
            uuid: "folder-uuid",
            customOutputName: "SelectedFolder"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "folder-uuid")
        #expect(workflowAction.customOutputName == "SelectedFolder")
    }

    // MARK: - GetFolderContentsAction Tests

    @Test("GetFolderContentsAction creates action")
    func testGetFolderContentsAction() throws {
        let action = GetFolderContentsAction()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.file.getfoldercontents")
        // Non-recursive should not have the parameter set
        #expect(workflowAction.parameters["Recursive"] == nil)
    }

    @Test("GetFolderContentsAction supports recursive mode")
    func testGetFolderContentsActionRecursive() throws {
        let action = GetFolderContentsAction(recursive: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["Recursive"] == .bool(true))
    }

    @Test("GetFolderContentsAction with UUID and custom output name")
    func testGetFolderContentsActionWithUUID() throws {
        let action = GetFolderContentsAction(
            recursive: false,
            uuid: "contents-uuid",
            customOutputName: "FolderFiles"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "contents-uuid")
        #expect(workflowAction.customOutputName == "FolderFiles")
    }

    // MARK: - FileStorageService Tests

    @Test("FileStorageService has all required cases")
    func testFileStorageServiceCases() throws {
        let services = FileStorageService.allCases
        #expect(services.count == 2)
        #expect(services.contains(.iCloudDrive))
        #expect(services.contains(.dropbox))
    }

    @Test("FileStorageService raw values are correct")
    func testFileStorageServiceRawValues() throws {
        #expect(FileStorageService.iCloudDrive.rawValue == "iCloud Drive")
        #expect(FileStorageService.dropbox.rawValue == "Dropbox")
    }

    // MARK: - File Action Shortcut Integration Tests

    @Test("Can create shortcut with save file action")
    func testSaveFileShortcut() throws {
        let textUUID = UUID().uuidString
        let textAction = TextAction("Hello, this is test content.", uuid: textUUID)
        let saveAction = SaveFileAction.toICloud(
            path: "/Shortcuts/test.txt",
            overwrite: true
        )

        let shortcut = Shortcut(
            name: "Save Text to File",
            actions: [
                textAction.toWorkflowAction(),
                saveAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.documentpicker.save")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 2)
    }

    @Test("Can create shortcut with get file and show result")
    func testGetFileShortcut() throws {
        let getFileUUID = UUID().uuidString
        let getAction = GetFileAction.fromICloud(
            path: "/Shortcuts/config.json",
            uuid: getFileUUID
        )
        let showAction = ShowResultAction(
            fromActionWithUUID: getFileUUID,
            outputName: "File"
        )

        let shortcut = Shortcut(
            name: "Read Config File",
            actions: [
                getAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.documentpicker.open")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    @Test("Can create shortcut with file picker")
    func testFilePickerShortcut() throws {
        let selectUUID = UUID().uuidString
        let selectAction = GetFileAction.selectFiles(uuid: selectUUID)
        let showAction = ShowResultAction(
            fromActionWithUUID: selectUUID,
            outputName: "Files"
        )

        let shortcut = Shortcut(
            name: "Select and Show Files",
            actions: [
                selectAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].parameters["SelectMultiple"] == .bool(true))
    }

    // MARK: - ReplaceTextAction Tests

    @Test("ReplaceTextAction creates action with plain strings")
    func testReplaceTextActionPlainStrings() throws {
        let action = ReplaceTextAction(find: "hello", replaceWith: "world")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.text.replace")
        #expect(workflowAction.parameters["WFReplaceTextFind"] == .string("hello"))
        #expect(workflowAction.parameters["WFReplaceTextReplace"] == .string("world"))
        // Default case sensitive, so should not be in parameters
        #expect(workflowAction.parameters["WFReplaceTextCaseSensitive"] == nil)
        // Default no regex, so should not be in parameters
        #expect(workflowAction.parameters["WFReplaceTextRegularExpression"] == nil)
    }

    @Test("ReplaceTextAction with case insensitive option")
    func testReplaceTextActionCaseInsensitive() throws {
        let action = ReplaceTextAction(find: "Hello", replaceWith: "Hi", caseSensitive: false)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFReplaceTextCaseSensitive"] == .bool(false))
    }

    @Test("ReplaceTextAction with regex option")
    func testReplaceTextActionRegex() throws {
        let action = ReplaceTextAction(
            find: "[0-9]+",
            replaceWith: "###",
            regularExpression: true
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFReplaceTextFind"] == .string("[0-9]+"))
        #expect(workflowAction.parameters["WFReplaceTextRegularExpression"] == .bool(true))
    }

    @Test("ReplaceTextAction with variable reference")
    func testReplaceTextActionWithVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "find-uuid", outputName: "Pattern")
        let action = ReplaceTextAction(
            find: .attachment(attachment),
            replaceWith: .string("replacement")
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFReplaceTextFind"] else {
            Issue.record("Expected dictionary parameter")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("ReplaceTextAction with UUID and custom output name")
    func testReplaceTextActionWithUUID() throws {
        let action = ReplaceTextAction(
            find: "old",
            replaceWith: "new",
            uuid: "replace-uuid",
            customOutputName: "ReplacedText"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "replace-uuid")
        #expect(workflowAction.customOutputName == "ReplacedText")
    }

    // MARK: - SplitTextAction Tests

    @Test("SplitTextAction creates action with new lines separator")
    func testSplitTextActionNewLines() throws {
        let action = SplitTextAction(separator: .newLines)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.text.split")
        #expect(workflowAction.parameters["WFTextSeparator"] == .string("New Lines"))
        #expect(workflowAction.parameters["WFTextCustomSeparator"] == nil)
    }

    @Test("SplitTextAction creates action with spaces separator")
    func testSplitTextActionSpaces() throws {
        let action = SplitTextAction(separator: .spaces)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFTextSeparator"] == .string("Spaces"))
    }

    @Test("SplitTextAction creates action with every character separator")
    func testSplitTextActionEveryCharacter() throws {
        let action = SplitTextAction(separator: .everyCharacter)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFTextSeparator"] == .string("Every Character"))
    }

    @Test("SplitTextAction creates action with custom separator")
    func testSplitTextActionCustom() throws {
        let action = SplitTextAction(customSeparator: ",")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFTextSeparator"] == .string("Custom"))
        #expect(workflowAction.parameters["WFTextCustomSeparator"] == .string(","))
    }

    @Test("SplitTextAction with UUID and custom output name")
    func testSplitTextActionWithUUID() throws {
        let action = SplitTextAction(
            separator: .newLines,
            uuid: "split-uuid",
            customOutputName: "SplitItems"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "split-uuid")
        #expect(workflowAction.customOutputName == "SplitItems")
    }

    // MARK: - CombineTextAction Tests

    @Test("CombineTextAction creates action with new lines separator")
    func testCombineTextActionNewLines() throws {
        let action = CombineTextAction(separator: .newLines)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.text.combine")
        #expect(workflowAction.parameters["WFTextSeparator"] == .string("New Lines"))
    }

    @Test("CombineTextAction creates action with custom separator")
    func testCombineTextActionCustom() throws {
        let action = CombineTextAction(customSeparator: " | ")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFTextSeparator"] == .string("Custom"))
        #expect(workflowAction.parameters["WFTextCustomSeparator"] == .string(" | "))
    }

    @Test("CombineTextAction with UUID and custom output name")
    func testCombineTextActionWithUUID() throws {
        let action = CombineTextAction(
            separator: .spaces,
            uuid: "combine-uuid",
            customOutputName: "CombinedText"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "combine-uuid")
        #expect(workflowAction.customOutputName == "CombinedText")
    }

    // MARK: - MatchTextAction Tests

    @Test("MatchTextAction creates action with regex pattern")
    func testMatchTextActionPattern() throws {
        let action = MatchTextAction(pattern: "[0-9]+")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.text.match")
        #expect(workflowAction.parameters["WFMatchTextPattern"] == .string("[0-9]+"))
        // Default case sensitive, so should not be in parameters
        #expect(workflowAction.parameters["WFMatchTextCaseSensitive"] == nil)
    }

    @Test("MatchTextAction with case insensitive option")
    func testMatchTextActionCaseInsensitive() throws {
        let action = MatchTextAction(pattern: "[a-z]+", caseSensitive: false)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFMatchTextCaseSensitive"] == .bool(false))
    }

    @Test("MatchTextAction with variable pattern")
    func testMatchTextActionWithVariablePattern() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "pattern-uuid", outputName: "Regex")
        let action = MatchTextAction(pattern: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFMatchTextPattern"] else {
            Issue.record("Expected dictionary parameter")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("MatchTextAction with UUID and custom output name")
    func testMatchTextActionWithUUID() throws {
        let action = MatchTextAction(
            pattern: "\\d+",
            uuid: "match-uuid",
            customOutputName: "Matches"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "match-uuid")
        #expect(workflowAction.customOutputName == "Matches")
    }

    // MARK: - ChangeCaseAction Tests

    @Test("ChangeCaseAction creates action with uppercase")
    func testChangeCaseActionUppercase() throws {
        let action = ChangeCaseAction(textCase: .uppercase)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.text.changecase")
        #expect(workflowAction.parameters["WFCaseType"] == .string("UPPERCASE"))
    }

    @Test("ChangeCaseAction creates action with lowercase")
    func testChangeCaseActionLowercase() throws {
        let action = ChangeCaseAction(textCase: .lowercase)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFCaseType"] == .string("lowercase"))
    }

    @Test("ChangeCaseAction creates action with capitalize every word")
    func testChangeCaseActionCapitalizeEveryWord() throws {
        let action = ChangeCaseAction(textCase: .capitalizeEveryWord)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFCaseType"] == .string("Capitalize Every Word"))
    }

    @Test("ChangeCaseAction creates action with title case")
    func testChangeCaseActionTitleCase() throws {
        let action = ChangeCaseAction(textCase: .titleCase)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFCaseType"] == .string("Capitalize with Title Case"))
    }

    @Test("ChangeCaseAction creates action with sentence case")
    func testChangeCaseActionSentenceCase() throws {
        let action = ChangeCaseAction(textCase: .sentenceCase)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFCaseType"] == .string("Capitalize with sentence case"))
    }

    @Test("ChangeCaseAction creates action with alternating case")
    func testChangeCaseActionAlternatingCase() throws {
        let action = ChangeCaseAction(textCase: .alternatingCase)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFCaseType"] == .string("cApItAlIzE wItH aLtErNaTiNg CaSe"))
    }

    @Test("ChangeCaseAction with UUID and custom output name")
    func testChangeCaseActionWithUUID() throws {
        let action = ChangeCaseAction(
            textCase: .uppercase,
            uuid: "case-uuid",
            customOutputName: "UppercaseText"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "case-uuid")
        #expect(workflowAction.customOutputName == "UppercaseText")
    }

    @Test("TextCase enum has all required cases")
    func testTextCaseCases() throws {
        #expect(TextCase.uppercase.rawValue == "UPPERCASE")
        #expect(TextCase.lowercase.rawValue == "lowercase")
        #expect(TextCase.capitalizeEveryWord.rawValue == "Capitalize Every Word")
        #expect(TextCase.titleCase.rawValue == "Capitalize with Title Case")
        #expect(TextCase.sentenceCase.rawValue == "Capitalize with sentence case")
        #expect(TextCase.alternatingCase.rawValue == "cApItAlIzE wItH aLtErNaTiNg CaSe")
    }

    @Test("TextSeparator enum has all required cases")
    func testTextSeparatorCases() throws {
        #expect(TextSeparator.newLines.rawValue == "New Lines")
        #expect(TextSeparator.spaces.rawValue == "Spaces")
        #expect(TextSeparator.everyCharacter.rawValue == "Every Character")
        #expect(TextSeparator.custom(",").rawValue == "Custom")
    }

    // MARK: - Text Manipulation Shortcut Integration Test

    @Test("Can create text processing pipeline shortcut")
    func testTextProcessingPipelineShortcut() throws {
        // Create a shortcut that:
        // 1. Creates some text
        // 2. Changes case to uppercase
        // 3. Replaces a pattern
        // 4. Splits by spaces
        // 5. Combines with commas

        let textUUID = UUID().uuidString
        let textAction = TextAction("Hello World", uuid: textUUID)

        let caseAction = ChangeCaseAction(textCase: .uppercase)
        let replaceAction = ReplaceTextAction(find: "WORLD", replaceWith: "SWIFT")
        let splitAction = SplitTextAction(separator: .spaces)
        let combineAction = CombineTextAction(customSeparator: ", ")

        let shortcut = Shortcut(
            name: "Text Processing Pipeline",
            actions: [
                textAction.toWorkflowAction(),
                caseAction.toWorkflowAction(),
                replaceAction.toWorkflowAction(),
                splitAction.toWorkflowAction(),
                combineAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 5)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.text.changecase")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.text.replace")
        #expect(shortcut.actions[3].identifier == "is.workflow.actions.text.split")
        #expect(shortcut.actions[4].identifier == "is.workflow.actions.text.combine")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 5)
    }

    @Test("Can create regex matching shortcut")
    func testRegexMatchingShortcut() throws {
        let textUUID = UUID().uuidString
        let textAction = TextAction("Phone: 555-1234, Email: test@example.com", uuid: textUUID)

        let matchAction = MatchTextAction(
            pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
            caseSensitive: false,
            uuid: UUID().uuidString,
            customOutputName: "EmailMatches"
        )

        let shortcut = Shortcut(
            name: "Email Extractor",
            actions: [
                textAction.toWorkflowAction(),
                matchAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.text.match")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    // MARK: - ShowNotificationAction Tests

    @Test("ShowNotificationAction creates action with plain string body")
    func testShowNotificationActionPlainString() throws {
        let action = ShowNotificationAction("Hello World")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.notification")
        #expect(workflowAction.parameters["WFNotificationActionBody"] == .string("Hello World"))
        // Sound defaults to true, so should not be set
        #expect(workflowAction.parameters["WFNotificationActionSound"] == nil)
    }

    @Test("ShowNotificationAction creates action with title")
    func testShowNotificationActionWithTitle() throws {
        let action = ShowNotificationAction("Body text", title: "My Title")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFNotificationActionBody"] == .string("Body text"))
        #expect(workflowAction.parameters["WFNotificationActionTitle"] == .string("My Title"))
    }

    @Test("ShowNotificationAction creates action with sound disabled")
    func testShowNotificationActionNoSound() throws {
        let action = ShowNotificationAction("Silent notification", playSound: false)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFNotificationActionSound"] == .bool(false))
    }

    @Test("ShowNotificationAction supports magic variable body")
    func testShowNotificationActionWithMagicVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "source-uuid", outputName: "Text")
        let action = ShowNotificationAction(body: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFNotificationActionBody"]
        else {
            Issue.record("Expected dictionary parameter")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("ShowNotificationAction with attachment")
    func testShowNotificationActionWithAttachment() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "image-uuid", outputName: "Image")
        let action = ShowNotificationAction("Check this out!", attachment: attachment)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFNotificationActionBody"] == .string("Check this out!"))
        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    // MARK: - ShowAlertAction Tests

    @Test("ShowAlertAction creates action with plain string message")
    func testShowAlertActionPlainString() throws {
        let action = ShowAlertAction("Are you sure?")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.alert")
        #expect(workflowAction.parameters["WFAlertActionMessage"] == .string("Are you sure?"))
        // Cancel button defaults to false, so should not be set
        #expect(workflowAction.parameters["WFAlertActionCancelButtonShown"] == nil)
    }

    @Test("ShowAlertAction creates action with title")
    func testShowAlertActionWithTitle() throws {
        let action = ShowAlertAction("Message text", title: "Alert Title")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFAlertActionMessage"] == .string("Message text"))
        #expect(workflowAction.parameters["WFAlertActionTitle"] == .string("Alert Title"))
    }

    @Test("ShowAlertAction creates action with cancel button")
    func testShowAlertActionWithCancelButton() throws {
        let action = ShowAlertAction("Confirm action?", showCancelButton: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFAlertActionCancelButtonShown"] == .bool(true))
    }

    @Test("ShowAlertAction.confirm creates confirmation alert")
    func testShowAlertActionConfirm() throws {
        let action = ShowAlertAction.confirm("Delete this item?", title: "Confirm Delete")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFAlertActionMessage"] == .string("Delete this item?"))
        #expect(workflowAction.parameters["WFAlertActionTitle"] == .string("Confirm Delete"))
        #expect(workflowAction.parameters["WFAlertActionCancelButtonShown"] == .bool(true))
    }

    @Test("ShowAlertAction supports magic variable message")
    func testShowAlertActionWithMagicVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "msg-uuid", outputName: "Message")
        let action = ShowAlertAction(message: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFAlertActionMessage"] else {
            Issue.record("Expected dictionary parameter")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    // MARK: - ChooseFromMenuAction Tests

    @Test("ChooseFromMenuAction creates start action with prompt and items")
    func testChooseFromMenuActionStart() throws {
        let action = ChooseFromMenuAction(
            prompt: "Choose an option",
            items: ["Option 1", "Option 2", "Option 3"],
            groupingIdentifier: "menu-123"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.choosefrommenu")
        #expect(workflowAction.parameters["WFControlFlowMode"] == .int(0))
        #expect(workflowAction.parameters["WFMenuPrompt"] == .string("Choose an option"))
        #expect(
            workflowAction.parameters["WFMenuItems"] == .array([
                .string("Option 1"),
                .string("Option 2"),
                .string("Option 3"),
            ]))
        #expect(workflowAction.groupingIdentifier == "menu-123")
    }

    @Test("ChooseFromMenuAction creates menu item action")
    func testChooseFromMenuActionItem() throws {
        let action = ChooseFromMenuAction(
            itemTitle: "Option 1",
            groupingIdentifier: "menu-123"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFControlFlowMode"] == .int(1))
        #expect(workflowAction.parameters["WFMenuItemTitle"] == .string("Option 1"))
        #expect(workflowAction.groupingIdentifier == "menu-123")
    }

    @Test("ChooseFromMenuAction creates end action")
    func testChooseFromMenuActionEnd() throws {
        let action = ChooseFromMenuAction(
            endMenuWithGroupingIdentifier: "menu-123"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFControlFlowMode"] == .int(2))
        #expect(workflowAction.groupingIdentifier == "menu-123")
    }

    @Test("ChooseFromMenuAction.buildMenu creates complete menu structure")
    func testChooseFromMenuActionBuildMenu() throws {
        let menuActions = ChooseFromMenuAction.buildMenu(
            prompt: "Select color",
            items: ["Red", "Green", "Blue"],
            groupingIdentifier: "color-menu"
        )

        // Should have: 1 start + 3 items + 1 end = 5 actions
        #expect(menuActions.count == 5)

        // Verify start action
        let startAction = menuActions[0].toWorkflowAction()
        #expect(startAction.parameters["WFControlFlowMode"] == .int(0))
        #expect(startAction.parameters["WFMenuPrompt"] == .string("Select color"))

        // Verify item actions
        for i in 1...3 {
            let itemAction = menuActions[i].toWorkflowAction()
            #expect(itemAction.parameters["WFControlFlowMode"] == .int(1))
        }

        // Verify end action
        let endAction = menuActions[4].toWorkflowAction()
        #expect(endAction.parameters["WFControlFlowMode"] == .int(2))

        // All should share the same grouping identifier
        for menuAction in menuActions {
            #expect(menuAction.groupingIdentifier == "color-menu")
        }
    }

    // MARK: - AskForInputAction Tests

    @Test("AskForInputAction creates action with plain string prompt")
    func testAskForInputActionPlainString() throws {
        let action = AskForInputAction("Enter your name")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.ask")
        #expect(workflowAction.parameters["WFAskActionPrompt"] == .string("Enter your name"))
        // Text is default, so should not be set
        #expect(workflowAction.parameters["WFInputType"] == nil)
    }

    @Test("AskForInputAction creates action with number input type")
    func testAskForInputActionNumber() throws {
        let action = AskForInputAction("Enter your age", inputType: .number)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("Number"))
    }

    @Test("AskForInputAction creates action with default answer")
    func testAskForInputActionWithDefault() throws {
        let action = AskForInputAction("Enter your name", defaultAnswer: "John Doe")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFAskActionDefaultAnswer"] == .string("John Doe"))
    }

    @Test("AskForInputAction with UUID and custom output name")
    func testAskForInputActionWithUUID() throws {
        let action = AskForInputAction(
            "Enter data",
            uuid: "ask-uuid",
            customOutputName: "UserInput"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "ask-uuid")
        #expect(workflowAction.customOutputName == "UserInput")
    }

    @Test("AskForInputAction.askForNumber convenience method")
    func testAskForInputActionAskForNumber() throws {
        let action = AskForInputAction.askForNumber("Enter quantity", defaultAnswer: "1")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("Number"))
        #expect(workflowAction.parameters["WFAskActionDefaultAnswer"] == .string("1"))
    }

    @Test("AskForInputAction.askForURL convenience method")
    func testAskForInputActionAskForURL() throws {
        let action = AskForInputAction.askForURL("Enter website")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("URL"))
    }

    @Test("AskForInputAction.askForDate convenience method")
    func testAskForInputActionAskForDate() throws {
        let action = AskForInputAction.askForDate("Select date")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("Date"))
    }

    @Test("AskForInputAction.askForTime convenience method")
    func testAskForInputActionAskForTime() throws {
        let action = AskForInputAction.askForTime("Select time")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("Time"))
    }

    @Test("AskForInputAction.askForDateTime convenience method")
    func testAskForInputActionAskForDateTime() throws {
        let action = AskForInputAction.askForDateTime("Select date and time")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFInputType"] == .string("Date and Time"))
    }

    @Test("AskInputType has all required cases")
    func testAskInputTypeCases() throws {
        let types = AskInputType.allCases
        #expect(types.count == 6)
        #expect(types.contains(.text))
        #expect(types.contains(.number))
        #expect(types.contains(.url))
        #expect(types.contains(.date))
        #expect(types.contains(.time))
        #expect(types.contains(.dateAndTime))
    }

    // MARK: - ChooseFromListAction Tests

    @Test("ChooseFromListAction creates basic action")
    func testChooseFromListActionBasic() throws {
        let action = ChooseFromListAction()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.choosefromlist")
        // No prompt set
        #expect(workflowAction.parameters["WFChooseFromListActionPrompt"] == nil)
        // Multiple selection defaults to false
        #expect(workflowAction.parameters["WFChooseFromListActionSelectMultiple"] == nil)
    }

    @Test("ChooseFromListAction creates action with prompt")
    func testChooseFromListActionWithPrompt() throws {
        let action = ChooseFromListAction(prompt: "Choose an item")
        let workflowAction = action.toWorkflowAction()

        #expect(
            workflowAction.parameters["WFChooseFromListActionPrompt"] == .string("Choose an item"))
    }

    @Test("ChooseFromListAction creates action with multiple selection")
    func testChooseFromListActionMultipleSelection() throws {
        let action = ChooseFromListAction(selectMultiple: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFChooseFromListActionSelectMultiple"] == .bool(true))
    }

    @Test("ChooseFromListAction creates action with select all")
    func testChooseFromListActionSelectAll() throws {
        let action = ChooseFromListAction(selectMultiple: true, selectAll: true)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFChooseFromListActionSelectMultiple"] == .bool(true))
        #expect(workflowAction.parameters["WFChooseFromListActionSelectAll"] == .bool(true))
    }

    @Test("ChooseFromListAction with action output input")
    func testChooseFromListActionFromActionOutput() throws {
        let action = ChooseFromListAction(
            fromActionWithUUID: "list-uuid",
            outputName: "Items",
            prompt: "Select items"
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }

        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["OutputUUID"] == .string("list-uuid"))
        #expect(valueDict["OutputName"] == .string("Items"))
    }

    @Test("ChooseFromListAction.fromShortcutInput convenience method")
    func testChooseFromListActionFromShortcutInput() throws {
        let action = ChooseFromListAction.fromShortcutInput(prompt: "Choose from input")
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }

        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["Type"] == .string("ExtensionInput"))
    }

    @Test("ChooseFromListAction.fromVariable convenience method")
    func testChooseFromListActionFromVariable() throws {
        let action = ChooseFromListAction.fromVariable("MyList", prompt: "Choose from list")
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }

        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["Type"] == .string("Variable"))
        #expect(valueDict["VariableName"] == .string("MyList"))
    }

    @Test("ChooseFromListAction with UUID and custom output name")
    func testChooseFromListActionWithUUID() throws {
        let action = ChooseFromListAction(
            uuid: "choose-uuid",
            customOutputName: "SelectedItem"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "choose-uuid")
        #expect(workflowAction.customOutputName == "SelectedItem")
    }

    // MARK: - UI Actions Shortcut Integration Tests

    @Test("Can create notification shortcut")
    func testNotificationShortcut() throws {
        let textUUID = UUID().uuidString
        let textAction = TextAction("Important message!", uuid: textUUID)
        let notifyAction = ShowNotificationAction(
            body: .attachment(.actionOutput(uuid: textUUID, outputName: "Text")),
            title: .string("Alert")
        )

        let shortcut = Shortcut(
            name: "Send Notification",
            actions: [
                textAction.toWorkflowAction(),
                notifyAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.notification")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 2)
    }

    @Test("Can create input prompt shortcut")
    func testInputPromptShortcut() throws {
        let askUUID = UUID().uuidString
        let askAction = AskForInputAction(
            "What is your name?",
            defaultAnswer: "Guest",
            uuid: askUUID,
            customOutputName: "Name"
        )
        let showAction = ShowResultAction(
            fromActionWithUUID: askUUID,
            outputName: "Name"
        )

        let shortcut = Shortcut(
            name: "Greet User",
            actions: [
                askAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.ask")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    @Test("Can create menu shortcut with all menu actions")
    func testMenuShortcut() throws {
        let groupId = UUID().uuidString
        let menuActions = ChooseFromMenuAction.buildMenu(
            prompt: "Choose a color",
            items: ["Red", "Blue"],
            groupingIdentifier: groupId
        )

        let shortcut = Shortcut(
            name: "Color Picker",
            actions: menuActions.map { $0.toWorkflowAction() }
        )

        // 1 start + 2 items + 1 end = 4 actions
        #expect(shortcut.actions.count == 4)

        // All actions should be choosefrommenu
        for action in shortcut.actions {
            #expect(action.identifier == "is.workflow.actions.choosefrommenu")
            #expect(action.groupingIdentifier == groupId)
        }

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    // MARK: - SetVariableAction Tests

    @Test("SetVariableAction creates action with variable name")
    func testSetVariableActionBasic() throws {
        let action = SetVariableAction("myVar")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.setvariable")
        #expect(workflowAction.parameters["WFVariableName"] == .string("myVar"))
        // No explicit value, uses previous action's output
        #expect(workflowAction.parameters["WFInput"] == nil)
    }

    @Test("SetVariableAction creates action with string value")
    func testSetVariableActionWithStringValue() throws {
        let action = SetVariableAction("myVar", stringValue: "Hello World")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFVariableName"] == .string("myVar"))
        #expect(workflowAction.parameters["WFInput"] == .string("Hello World"))
    }

    @Test("SetVariableAction creates action with magic variable value")
    func testSetVariableActionWithMagicVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "source-uuid", outputName: "Output")
        let action = SetVariableAction("myVar", value: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("SetVariableAction with UUID and custom output name")
    func testSetVariableActionWithUUID() throws {
        let action = SetVariableAction(
            "myVar",
            uuid: "setvar-uuid",
            customOutputName: "StoredValue"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "setvar-uuid")
        #expect(workflowAction.customOutputName == "StoredValue")
    }

    // MARK: - GetVariableAction Tests

    @Test("GetVariableAction creates action for named variable")
    func testGetVariableActionNamed() throws {
        let action = GetVariableAction(named: "myVar")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.getvariable")
        guard case .dictionary(let dict) = workflowAction.parameters["WFVariable"] else {
            Issue.record("Expected WFVariable dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["Type"] == .string("Variable"))
        #expect(valueDict["VariableName"] == .string("myVar"))
    }

    @Test("GetVariableAction.magicVariable creates action for action output")
    func testGetVariableActionMagicVariable() throws {
        let action = GetVariableAction.magicVariable(
            actionUUID: "text-action-uuid",
            outputName: "Text"
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFVariable"] else {
            Issue.record("Expected WFVariable dictionary")
            return
        }
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["Type"] == .string("ActionOutput"))
        #expect(valueDict["OutputUUID"] == .string("text-action-uuid"))
        #expect(valueDict["OutputName"] == .string("Text"))
    }

    @Test("GetVariableAction.shortcutInput creates action for shortcut input")
    func testGetVariableActionShortcutInput() throws {
        let action = GetVariableAction.shortcutInput()
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFVariable"] else {
            Issue.record("Expected WFVariable dictionary")
            return
        }
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["Type"] == .string("ExtensionInput"))
    }

    @Test("GetVariableAction.clipboard creates action for clipboard")
    func testGetVariableActionClipboard() throws {
        let action = GetVariableAction.clipboard()
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFVariable"] else {
            Issue.record("Expected WFVariable dictionary")
            return
        }
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["Type"] == .string("Clipboard"))
    }

    @Test("GetVariableAction.currentDate creates action for current date")
    func testGetVariableActionCurrentDate() throws {
        let action = GetVariableAction.currentDate()
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFVariable"] else {
            Issue.record("Expected WFVariable dictionary")
            return
        }
        guard case .dictionary(let valueDict) = dict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        #expect(valueDict["Type"] == .string("CurrentDate"))
    }

    @Test("GetVariableAction with UUID and custom output name")
    func testGetVariableActionWithUUID() throws {
        let action = GetVariableAction(
            named: "myVar",
            uuid: "getvar-uuid",
            customOutputName: "RetrievedValue"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "getvar-uuid")
        #expect(workflowAction.customOutputName == "RetrievedValue")
    }

    // MARK: - AppendToVariableAction Tests

    @Test("AppendToVariableAction creates action with variable name")
    func testAppendToVariableActionBasic() throws {
        let action = AppendToVariableAction("myList")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.appendvariable")
        #expect(workflowAction.parameters["WFVariableName"] == .string("myList"))
        // No explicit value, uses previous action's output
        #expect(workflowAction.parameters["WFInput"] == nil)
    }

    @Test("AppendToVariableAction creates action with string value")
    func testAppendToVariableActionWithStringValue() throws {
        let action = AppendToVariableAction("myList", stringValue: "New Item")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFVariableName"] == .string("myList"))
        #expect(workflowAction.parameters["WFInput"] == .string("New Item"))
    }

    @Test("AppendToVariableAction creates action with magic variable value")
    func testAppendToVariableActionWithMagicVariable() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "item-uuid", outputName: "Item")
        let action = AppendToVariableAction("myList", value: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFInput"] else {
            Issue.record("Expected WFInput dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("AppendToVariableAction with UUID and custom output name")
    func testAppendToVariableActionWithUUID() throws {
        let action = AppendToVariableAction(
            "myList",
            uuid: "append-uuid",
            customOutputName: "UpdatedList"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "append-uuid")
        #expect(workflowAction.customOutputName == "UpdatedList")
    }

    // MARK: - MagicVariable Tests

    @Test("MagicVariable creates reference to action output")
    func testMagicVariableBasic() throws {
        let magicVar = MagicVariable(sourceActionUUID: "action-uuid", outputName: "Result")
        let attachment = magicVar.toAttachment()

        #expect(attachment.type == .actionOutput)
        #expect(attachment.outputUUID == "action-uuid")
        #expect(attachment.outputName == "Result")
    }

    @Test("MagicVariable supports property access")
    func testMagicVariablePropertyAccess() throws {
        let magicVar = MagicVariable(sourceActionUUID: "file-uuid", outputName: "File")
        let nameVar = magicVar.name
        let attachment = nameVar.toAttachment()

        #expect(attachment.aggrandizements?.count == 1)
        #expect(attachment.aggrandizements?[0].type == .property)
        #expect(attachment.aggrandizements?[0].propertyName == "Name")
    }

    @Test("MagicVariable supports type coercion")
    func testMagicVariableTypeCoercion() throws {
        let magicVar = MagicVariable(sourceActionUUID: "input-uuid", outputName: "Input")
        let textVar = magicVar.asText
        let attachment = textVar.toAttachment()

        #expect(attachment.aggrandizements?.count == 1)
        #expect(attachment.aggrandizements?[0].type == .coercion)
        #expect(attachment.aggrandizements?[0].coercionClass == "WFStringContentItem")
    }

    @Test("MagicVariable supports chained property access")
    func testMagicVariableChainedAccess() throws {
        let magicVar = MagicVariable(sourceActionUUID: "file-uuid", outputName: "File")
        let sizeVar = magicVar.fileSize
        let attachment = sizeVar.toAttachment()

        #expect(attachment.aggrandizements?.count == 1)
        #expect(attachment.aggrandizements?[0].propertyName == "File Size")
    }

    @Test("MagicVariable converts to TextTokenValue")
    func testMagicVariableToTokenValue() throws {
        let magicVar = MagicVariable(sourceActionUUID: "uuid-123", outputName: "Output")
        let tokenValue = magicVar.toTokenValue()

        guard case .attachment(let attachment) = tokenValue else {
            Issue.record("Expected attachment token value")
            return
        }
        #expect(attachment.outputUUID == "uuid-123")
    }

    // MARK: - NamedVariable Tests

    @Test("NamedVariable creates reference by name")
    func testNamedVariableBasic() throws {
        let namedVar = NamedVariable("myVariable")
        let attachment = namedVar.toAttachment()

        #expect(attachment.type == .variable)
        #expect(attachment.variableName == "myVariable")
    }

    @Test("NamedVariable supports property access")
    func testNamedVariablePropertyAccess() throws {
        let namedVar = NamedVariable("myFile")
        let nameVar = namedVar.getName
        let attachment = nameVar.toAttachment()

        #expect(attachment.aggrandizements?.count == 1)
        #expect(attachment.aggrandizements?[0].propertyName == "Name")
    }

    @Test("NamedVariable supports type coercion")
    func testNamedVariableTypeCoercion() throws {
        let namedVar = NamedVariable("myValue")
        let numberVar = namedVar.asNumber
        let attachment = numberVar.toAttachment()

        #expect(attachment.aggrandizements?.count == 1)
        #expect(attachment.aggrandizements?[0].coercionClass == "WFNumberContentItem")
    }

    // MARK: - Variable Builder Tests

    @Test("Variable.named creates NamedVariable")
    func testVariableBuilderNamed() throws {
        let namedVar = Variable.named("testVar")

        #expect(namedVar.name == "testVar")
    }

    @Test("Variable.magicVariable creates MagicVariable")
    func testVariableBuilderMagicVariable() throws {
        let magicVar = Variable.magicVariable(uuid: "action-uuid", outputName: "Result")

        #expect(magicVar.sourceActionUUID == "action-uuid")
        #expect(magicVar.outputName == "Result")
    }

    @Test("Variable.shortcutInput creates shortcut input reference")
    func testVariableBuilderShortcutInput() throws {
        let inputRef = Variable.shortcutInput

        #expect(inputRef.type == .extensionInput)
    }

    @Test("Variable.clipboard creates clipboard reference")
    func testVariableBuilderClipboard() throws {
        let clipboardRef = Variable.clipboard

        #expect(clipboardRef.type == .clipboard)
    }

    @Test("Variable.currentDate creates current date reference")
    func testVariableBuilderCurrentDate() throws {
        let dateRef = Variable.currentDate

        #expect(dateRef.type == .currentDate)
    }

    @Test("Variable.ask creates ask reference")
    func testVariableBuilderAsk() throws {
        let askRef = Variable.ask

        #expect(askRef.type == .ask)
    }

    // MARK: - ContentItemClass Constants Tests

    @Test("ContentItemClass has all required constants")
    func testContentItemClassConstants() throws {
        #expect(ContentItemClass.string == "WFStringContentItem")
        #expect(ContentItemClass.number == "WFNumberContentItem")
        #expect(ContentItemClass.date == "WFDateContentItem")
        #expect(ContentItemClass.url == "WFURLContentItem")
        #expect(ContentItemClass.file == "WFFileContentItem")
        #expect(ContentItemClass.image == "WFImageContentItem")
        #expect(ContentItemClass.dictionary == "WFDictionaryContentItem")
    }

    // MARK: - PropertyName Constants Tests

    @Test("PropertyName has all required constants")
    func testPropertyNameConstants() throws {
        #expect(PropertyName.name == "Name")
        #expect(PropertyName.fileExtension == "File Extension")
        #expect(PropertyName.fileSize == "File Size")
        #expect(PropertyName.filePath == "File Path")
        #expect(PropertyName.creationDate == "Creation Date")
        #expect(PropertyName.lastModifiedDate == "Last Modified Date")
    }

    // MARK: - Variable Flow Integration Tests

    @Test("Can create shortcut with set and get variable")
    func testSetGetVariableShortcut() throws {
        // Create text, set it to a variable, get the variable, show result
        let textUUID = UUID().uuidString
        let textAction = TextAction("Hello from variable!", uuid: textUUID)
        let setAction = SetVariableAction("greeting")
        let getAction = GetVariableAction(named: "greeting", uuid: UUID().uuidString)
        let showAction = ShowResultAction(
            fromActionWithUUID: getAction.uuid!,
            outputName: "Variable"
        )

        let shortcut = Shortcut(
            name: "Variable Test",
            actions: [
                textAction.toWorkflowAction(),
                setAction.toWorkflowAction(),
                getAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 4)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.setvariable")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.getvariable")
        #expect(shortcut.actions[3].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 4)
    }

    @Test("Can create shortcut with append to variable for list building")
    func testAppendToVariableShortcut() throws {
        // Build a list by appending multiple items
        let text1UUID = UUID().uuidString
        let text1Action = TextAction("Item 1", uuid: text1UUID)
        let append1Action = AppendToVariableAction("myList")

        let text2UUID = UUID().uuidString
        let text2Action = TextAction("Item 2", uuid: text2UUID)
        let append2Action = AppendToVariableAction("myList")

        let getAction = GetVariableAction(named: "myList", uuid: UUID().uuidString)
        let showAction = ShowResultAction(
            fromActionWithUUID: getAction.uuid!,
            outputName: "Variable"
        )

        let shortcut = Shortcut(
            name: "List Builder",
            actions: [
                text1Action.toWorkflowAction(),
                append1Action.toWorkflowAction(),
                text2Action.toWorkflowAction(),
                append2Action.toWorkflowAction(),
                getAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 6)
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.appendvariable")
        #expect(shortcut.actions[3].identifier == "is.workflow.actions.appendvariable")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    @Test("Can create shortcut with magic variable property access")
    func testMagicVariablePropertyAccessShortcut() throws {
        // Get a file, then get its name property
        let fileUUID = UUID().uuidString
        let fileAction = GetFileAction(
            service: .iCloudDrive,
            uuid: fileUUID,
            customOutputName: "SelectedFile"
        )

        // Create a text action that uses the file's name property
        let fileMagicVar = MagicVariable(sourceActionUUID: fileUUID, outputName: "SelectedFile")
        let fileNameVar = fileMagicVar.name

        let showAction = ShowResultAction(fileNameVar.toTokenValue())

        let shortcut = Shortcut(
            name: "Show File Name",
            actions: [
                fileAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 2)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.documentpicker.open")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.showresult")

        // Verify the show result action references the file with a name property
        let showWorkflowAction = shortcut.actions[1]
        guard case .dictionary(let textDict) = showWorkflowAction.parameters["Text"] else {
            Issue.record("Expected Text dictionary")
            return
        }

        guard case .dictionary(let valueDict) = textDict["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }

        #expect(valueDict["OutputUUID"] == ActionParameterValue.string(fileUUID))

        // Verify aggrandizements exist for property access
        guard case .array(let aggrandizements) = valueDict["Aggrandizements"] else {
            Issue.record("Expected Aggrandizements array")
            return
        }

        #expect(aggrandizements.count == 1)
    }

    @Test("Aggrandizement encodes property access correctly")
    func testAggrandizementPropertyEncoding() throws {
        let aggrandizement = Aggrandizement.getProperty("File Extension")
        let value = aggrandizement.toDictionaryValue()

        guard case .dictionary(let dict) = value else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["Type"] == .string("WFPropertyVariableAggrandizement"))
        #expect(dict["PropertyName"] == .string("File Extension"))
    }

    @Test("Aggrandizement encodes type coercion correctly")
    func testAggrandizementCoercionEncoding() throws {
        let aggrandizement = Aggrandizement.coerce(to: "WFStringContentItem")
        let value = aggrandizement.toDictionaryValue()

        guard case .dictionary(let dict) = value else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["Type"] == .string("WFCoercionVariableAggrandizement"))
        #expect(dict["CoercionItemClass"] == .string("WFStringContentItem"))
    }

    // MARK: - GetDictionaryValueAction Tests

    @Test("GetDictionaryValueAction creates action to get value for key")
    func testGetDictionaryValueActionForKey() throws {
        let action = GetDictionaryValueAction(key: "username")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.getvalueforkey")
        #expect(workflowAction.parameters["WFGetDictionaryValueType"] == .string("Value"))
        #expect(workflowAction.parameters["WFDictionaryKey"] == .string("username"))
    }

    @Test("GetDictionaryValueAction creates action with dot notation key path")
    func testGetDictionaryValueActionWithDotNotation() throws {
        let action = GetDictionaryValueAction(key: "user.address.city")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFDictionaryKey"] == .string("user.address.city"))
    }

    @Test("GetDictionaryValueAction creates action to get all keys")
    func testGetDictionaryValueActionAllKeys() throws {
        let action = GetDictionaryValueAction.getAllKeys()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFGetDictionaryValueType"] == .string("All Keys"))
        // Key should not be set for all keys mode
        #expect(workflowAction.parameters["WFDictionaryKey"] == nil)
    }

    @Test("GetDictionaryValueAction creates action to get all values")
    func testGetDictionaryValueActionAllValues() throws {
        let action = GetDictionaryValueAction.getAllValues()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFGetDictionaryValueType"] == .string("All Values"))
        // Key should not be set for all values mode
        #expect(workflowAction.parameters["WFDictionaryKey"] == nil)
    }

    @Test("GetDictionaryValueAction supports variable key")
    func testGetDictionaryValueActionWithVariableKey() throws {
        let attachment = TextTokenAttachment.actionOutput(uuid: "key-uuid", outputName: "Key")
        let action = GetDictionaryValueAction(key: .attachment(attachment))
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFDictionaryKey"] else {
            Issue.record("Expected WFDictionaryKey dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("GetDictionaryValueAction with UUID and custom output name")
    func testGetDictionaryValueActionWithUUID() throws {
        let action = GetDictionaryValueAction(
            key: "value",
            uuid: "dict-uuid",
            customOutputName: "ExtractedValue"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "dict-uuid")
        #expect(workflowAction.customOutputName == "ExtractedValue")
    }

    @Test("GetDictionaryValueAction convenience method getValue")
    func testGetDictionaryValueActionGetValue() throws {
        let action = GetDictionaryValueAction.getValue(forKey: "name")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFGetDictionaryValueType"] == .string("Value"))
        #expect(workflowAction.parameters["WFDictionaryKey"] == .string("name"))
    }

    @Test("DictionaryValueType has all required cases")
    func testDictionaryValueTypeCases() throws {
        let types = DictionaryValueType.allCases
        #expect(types.count == 3)
        #expect(types.contains(.value))
        #expect(types.contains(.allKeys))
        #expect(types.contains(.allValues))
    }

    // MARK: - SetDictionaryValueAction Tests

    @Test("SetDictionaryValueAction creates action with plain strings")
    func testSetDictionaryValueActionPlainStrings() throws {
        let action = SetDictionaryValueAction(key: "name", value: "John Doe")
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.setvalueforkey")
        #expect(workflowAction.parameters["WFDictionaryKey"] == .string("name"))
        #expect(workflowAction.parameters["WFDictionaryValue"] == .string("John Doe"))
    }

    @Test("SetDictionaryValueAction supports variable key")
    func testSetDictionaryValueActionWithVariableKey() throws {
        let keyAttachment = TextTokenAttachment.actionOutput(uuid: "key-uuid", outputName: "Key")
        let action = SetDictionaryValueAction(
            key: .attachment(keyAttachment),
            value: .string("value")
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFDictionaryKey"] else {
            Issue.record("Expected WFDictionaryKey dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("SetDictionaryValueAction supports variable value")
    func testSetDictionaryValueActionWithVariableValue() throws {
        let valueAttachment = TextTokenAttachment.actionOutput(uuid: "value-uuid", outputName: "Value")
        let action = SetDictionaryValueAction(
            key: .string("myKey"),
            value: .attachment(valueAttachment)
        )
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let dict) = workflowAction.parameters["WFDictionaryValue"] else {
            Issue.record("Expected WFDictionaryValue dictionary")
            return
        }
        #expect(dict["WFSerializationType"] == .string("WFTextTokenAttachment"))
    }

    @Test("SetDictionaryValueAction with UUID and custom output name")
    func testSetDictionaryValueActionWithUUID() throws {
        let action = SetDictionaryValueAction(
            key: "key",
            value: "value",
            uuid: "setdict-uuid",
            customOutputName: "UpdatedDict"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "setdict-uuid")
        #expect(workflowAction.customOutputName == "UpdatedDict")
    }

    // MARK: - GetItemFromListAction Tests

    @Test("GetItemFromListAction creates action to get first item")
    func testGetItemFromListActionFirstItem() throws {
        let action = GetItemFromListAction(specifier: .firstItem)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.getitemfromlist")
        #expect(workflowAction.parameters["WFItemSpecifier"] == .string("First Item"))
    }

    @Test("GetItemFromListAction creates action to get last item")
    func testGetItemFromListActionLastItem() throws {
        let action = GetItemFromListAction.lastItem()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFItemSpecifier"] == .string("Last Item"))
    }

    @Test("GetItemFromListAction creates action to get random item")
    func testGetItemFromListActionRandomItem() throws {
        let action = GetItemFromListAction.randomItem()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFItemSpecifier"] == .string("Random Item"))
    }

    @Test("GetItemFromListAction creates action to get item at index")
    func testGetItemFromListActionAtIndex() throws {
        let action = GetItemFromListAction.itemAtIndex(3)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFItemSpecifier"] == .string("Item At Index"))
        #expect(workflowAction.parameters["WFItemIndex"] == .int(3))
    }

    @Test("GetItemFromListAction creates action to get items in range")
    func testGetItemFromListActionRange() throws {
        let action = GetItemFromListAction.itemsInRange(from: 2, to: 5)
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.parameters["WFItemSpecifier"] == .string("Items in Range"))
        #expect(workflowAction.parameters["WFItemRangeStart"] == .int(2))
        #expect(workflowAction.parameters["WFItemRangeEnd"] == .int(5))
    }

    @Test("GetItemFromListAction with UUID and custom output name")
    func testGetItemFromListActionWithUUID() throws {
        let action = GetItemFromListAction(
            specifier: .firstItem,
            uuid: "list-uuid",
            customOutputName: "FirstItem"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "list-uuid")
        #expect(workflowAction.customOutputName == "FirstItem")
    }

    @Test("ListItemSpecifier has correct raw values")
    func testListItemSpecifierRawValues() throws {
        #expect(ListItemSpecifier.firstItem.rawValue == "First Item")
        #expect(ListItemSpecifier.lastItem.rawValue == "Last Item")
        #expect(ListItemSpecifier.randomItem.rawValue == "Random Item")
        #expect(ListItemSpecifier.itemAtIndex(1).rawValue == "Item At Index")
        #expect(ListItemSpecifier.itemsInRange(start: 1, end: 3).rawValue == "Items in Range")
    }

    // MARK: - DictionaryAction Tests

    @Test("DictionaryAction creates action with string items")
    func testDictionaryActionWithStringItems() throws {
        let action = DictionaryAction(stringItems: [
            "name": "John",
            "city": "Boston",
        ])
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.dictionary")
        guard case .dictionary(let wfItems) = workflowAction.parameters["WFItems"] else {
            Issue.record("Expected WFItems dictionary")
            return
        }
        #expect(wfItems["WFSerializationType"] == .string("WFDictionaryFieldValue"))
    }

    @Test("DictionaryAction creates action with mixed value types")
    func testDictionaryActionWithMixedTypes() throws {
        let action = DictionaryAction(items: [
            "name": .string("John"),
            "age": .int(30),
            "active": .bool(true),
        ])
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.dictionary")
        guard case .dictionary(let wfItems) = workflowAction.parameters["WFItems"] else {
            Issue.record("Expected WFItems dictionary")
            return
        }
        guard case .dictionary(let valueDict) = wfItems["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        guard case .array(let fieldItems) = valueDict["WFDictionaryFieldValueItems"] else {
            Issue.record("Expected WFDictionaryFieldValueItems array")
            return
        }
        #expect(fieldItems.count == 3)
    }

    @Test("DictionaryAction.empty creates empty dictionary")
    func testDictionaryActionEmpty() throws {
        let action = DictionaryAction.empty()
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.identifier == "is.workflow.actions.dictionary")
        guard case .dictionary(let wfItems) = workflowAction.parameters["WFItems"] else {
            Issue.record("Expected WFItems dictionary")
            return
        }
        guard case .dictionary(let valueDict) = wfItems["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        guard case .array(let fieldItems) = valueDict["WFDictionaryFieldValueItems"] else {
            Issue.record("Expected WFDictionaryFieldValueItems array")
            return
        }
        #expect(fieldItems.isEmpty)
    }

    @Test("DictionaryAction.from creates dictionary from pairs")
    func testDictionaryActionFrom() throws {
        let action = DictionaryAction.from([
            ("key1", .string("value1")),
            ("key2", .int(42)),
        ])
        let workflowAction = action.toWorkflowAction()

        guard case .dictionary(let wfItems) = workflowAction.parameters["WFItems"] else {
            Issue.record("Expected WFItems dictionary")
            return
        }
        guard case .dictionary(let valueDict) = wfItems["Value"] else {
            Issue.record("Expected Value dictionary")
            return
        }
        guard case .array(let fieldItems) = valueDict["WFDictionaryFieldValueItems"] else {
            Issue.record("Expected WFDictionaryFieldValueItems array")
            return
        }
        #expect(fieldItems.count == 2)
    }

    @Test("DictionaryAction with UUID and custom output name")
    func testDictionaryActionWithUUID() throws {
        let action = DictionaryAction(
            stringItems: ["key": "value"],
            uuid: "dict-create-uuid",
            customOutputName: "MyDictionary"
        )
        let workflowAction = action.toWorkflowAction()

        #expect(workflowAction.uuid == "dict-create-uuid")
        #expect(workflowAction.customOutputName == "MyDictionary")
    }

    // MARK: - JSON Actions Integration Tests

    @Test("Can create shortcut to parse JSON and extract value")
    func testJSONParsingShortcut() throws {
        // Fetch JSON from URL, get a specific value, show result
        let urlUUID = UUID().uuidString
        let urlAction = URLAction(
            "https://api.example.com/user",
            uuid: urlUUID,
            customOutputName: "Response"
        )

        let getValue = GetDictionaryValueAction(
            key: "user.name",
            uuid: UUID().uuidString,
            customOutputName: "UserName"
        )

        let showAction = ShowResultAction(
            fromActionWithUUID: getValue.uuid!,
            outputName: "UserName"
        )

        let shortcut = Shortcut(
            name: "Get User Name",
            actions: [
                urlAction.toWorkflowAction(),
                getValue.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 3)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.downloadurl")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.getvalueforkey")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)

        let decoded = try Shortcut.decode(from: plistData)
        #expect(decoded.actions.count == 3)
    }

    @Test("Can create shortcut to build and modify dictionary")
    func testDictionaryBuildingShortcut() throws {
        // Create dictionary, set a value, get all keys, show result
        let dictUUID = UUID().uuidString
        let dictAction = DictionaryAction(
            stringItems: [
                "name": "John",
                "email": "john@example.com",
            ],
            uuid: dictUUID,
            customOutputName: "UserData"
        )

        let setValueUUID = UUID().uuidString
        let setValueAction = SetDictionaryValueAction(
            key: "phone",
            value: "555-1234",
            uuid: setValueUUID,
            customOutputName: "UpdatedData"
        )

        let getKeysAction = GetDictionaryValueAction.getAllKeys(uuid: UUID().uuidString)

        let showAction = ShowResultAction(
            fromActionWithUUID: getKeysAction.uuid!,
            outputName: "Dictionary Value"
        )

        let shortcut = Shortcut(
            name: "Dictionary Operations",
            actions: [
                dictAction.toWorkflowAction(),
                setValueAction.toWorkflowAction(),
                getKeysAction.toWorkflowAction(),
                showAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 4)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.dictionary")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.setvalueforkey")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.getvalueforkey")
        #expect(shortcut.actions[3].identifier == "is.workflow.actions.showresult")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }

    @Test("Can create shortcut to process list items")
    func testListProcessingShortcut() throws {
        // Split text into list, get first item, get item at index, show results
        let textUUID = UUID().uuidString
        let textAction = TextAction(
            "apple,banana,cherry,date",
            uuid: textUUID,
            customOutputName: "FruitList"
        )

        let splitAction = SplitTextAction(
            customSeparator: ",",
            uuid: UUID().uuidString,
            customOutputName: "Items"
        )

        let firstItemAction = GetItemFromListAction.firstItem(uuid: UUID().uuidString)
        let thirdItemAction = GetItemFromListAction.itemAtIndex(3, uuid: UUID().uuidString)

        let shortcut = Shortcut(
            name: "List Processing",
            actions: [
                textAction.toWorkflowAction(),
                splitAction.toWorkflowAction(),
                firstItemAction.toWorkflowAction(),
                thirdItemAction.toWorkflowAction(),
            ]
        )

        #expect(shortcut.actions.count == 4)
        #expect(shortcut.actions[0].identifier == "is.workflow.actions.gettext")
        #expect(shortcut.actions[1].identifier == "is.workflow.actions.text.split")
        #expect(shortcut.actions[2].identifier == "is.workflow.actions.getitemfromlist")
        #expect(shortcut.actions[3].identifier == "is.workflow.actions.getitemfromlist")

        // Verify encoding works
        let plistData = try shortcut.encodeToPlist()
        #expect(!plistData.isEmpty)
    }
}
