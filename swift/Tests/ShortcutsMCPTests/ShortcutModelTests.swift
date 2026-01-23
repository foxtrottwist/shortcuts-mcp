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
