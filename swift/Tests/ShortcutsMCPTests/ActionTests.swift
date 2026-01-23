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
}
