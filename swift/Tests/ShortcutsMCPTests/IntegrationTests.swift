// SPDX-License-Identifier: MIT
// IntegrationTests.swift - Phase 1 Integration Tests for Shortcuts MCP Server

import Foundation
import Testing

@testable import ShortcutsMCP

// MARK: - Server Initialization Tests

@Suite("ShortcutsServer Initialization")
struct ShortcutsServerTests {
    @Test("Server version is set correctly")
    func testServerVersion() {
        #expect(ShortcutsServer.version == "4.0.0")
    }

    @Test("Server configuration has sensible defaults")
    func testDefaultConfiguration() {
        let config = ShortcutsServer.Configuration()

        #expect(config.name == "shortcuts-mcp")
        #expect(config.version == "4.0.0")
        #expect(config.strictMode == false)
        #expect(config.instructions == nil)
    }

    @Test("Server configuration can be customized")
    func testCustomConfiguration() {
        let config = ShortcutsServer.Configuration(
            name: "custom-server",
            version: "1.0.0",
            instructions: "Custom instructions",
            strictMode: true
        )

        #expect(config.name == "custom-server")
        #expect(config.version == "1.0.0")
        #expect(config.instructions == "Custom instructions")
        #expect(config.strictMode == true)
    }

    @Test("Server can be initialized with default configuration")
    func testServerInitialization() async {
        _ = ShortcutsServer()
        // Server should initialize without error
        // Note: We can't fully test the server without a transport, but initialization should work
        #expect(Bool(true))  // Server was created successfully
    }

    @Test("Server can be initialized with custom configuration")
    func testServerInitializationCustom() async {
        let config = ShortcutsServer.Configuration(
            name: "test-server",
            version: "2.0.0"
        )
        _ = ShortcutsServer(configuration: config)
        #expect(Bool(true))  // Server was created successfully
    }
}

// MARK: - Tool Definition Tests

@Suite("Tool Definitions")
struct ToolDefinitionTests {
    @Test("run_shortcut tool has correct name and schema")
    func testRunShortcutToolDefinition() {
        let tool = RunShortcutTool.definition

        #expect(tool.name == "run_shortcut")
        #expect(tool.description?.contains("Execute") == true)
        #expect(tool.description?.contains("macOS Shortcut") == true)

        // Verify annotations
        #expect(tool.annotations.title == "Run Shortcut")
        #expect(tool.annotations.readOnlyHint == false)
        #expect(tool.annotations.openWorldHint == true)
    }

    @Test("list_shortcuts tool has correct name and schema")
    func testListShortcutsToolDefinition() {
        let tool = ListShortcutsTool.definition

        #expect(tool.name == "list_shortcuts")
        #expect(tool.description?.contains("List") == true)
        #expect(tool.description?.contains("Shortcuts") == true)
        #expect(tool.description?.contains("24 hours") == true)  // Cache duration mentioned
    }

    @Test("view_shortcut tool has correct name and schema")
    func testViewShortcutToolDefinition() {
        let tool = ViewShortcutTool.definition

        #expect(tool.name == "view_shortcut")
        #expect(tool.description?.contains("Open") == true || tool.description?.contains("View") == true)
    }

    @Test("shortcuts_usage tool has correct name and schema")
    func testShortcutsUsageToolDefinition() {
        let tool = ShortcutsUsageTool.definition

        #expect(tool.name == "shortcuts_usage")
        #expect(tool.description?.contains("profile") == true || tool.description?.contains("usage") == true)
    }

    @Test("RunShortcutTool.Input can be created with name only")
    func testRunShortcutInputNameOnly() {
        let input = RunShortcutTool.Input(name: "Test Shortcut")

        #expect(input.name == "Test Shortcut")
        #expect(input.input == nil)
    }

    @Test("RunShortcutTool.Input can be created with name and input")
    func testRunShortcutInputWithInput() {
        let input = RunShortcutTool.Input(name: "Test Shortcut", input: "Hello World")

        #expect(input.name == "Test Shortcut")
        #expect(input.input == "Hello World")
    }
}

// MARK: - Resource Definition Tests

@Suite("Resource Definitions")
struct ResourceDefinitionTests {
    @Test("All resources are defined")
    func testAllResourcesDefined() {
        let resources = ShortcutsResources.all

        #expect(resources.count == 4)
    }

    @Test("Available shortcuts resource has correct properties")
    func testAvailableShortcutsResource() {
        let resource = ShortcutsResources.availableShortcuts

        #expect(resource.uri == "shortcuts://available")
        #expect(resource.mimeType == "text/plain")
        #expect(resource.name == "Current shortcuts list")
    }

    @Test("System state resource has correct properties")
    func testSystemStateResource() {
        let resource = ShortcutsResources.systemState

        #expect(resource.uri == "context://system/current")
        #expect(resource.mimeType == "application/json")
        #expect(resource.name == "Live system state")
    }

    @Test("User profile resource has correct properties")
    func testUserProfileResource() {
        let resource = ShortcutsResources.userProfile

        #expect(resource.uri == "context://user/profile")
        #expect(resource.mimeType == "application/json")
        #expect(resource.name == "User preferences & usage patterns")
    }

    @Test("Statistics resource has correct properties")
    func testStatisticsResource() {
        let resource = ShortcutsResources.statistics

        #expect(resource.uri == "statistics://generated")
        #expect(resource.mimeType == "application/json")
        #expect(resource.name == "Execution statistics & insights")
    }

    @Test("Resource templates are defined")
    func testResourceTemplates() {
        let templates = ShortcutsResources.templates

        #expect(templates.count == 1)

        let shortcutRuns = templates[0]
        #expect(shortcutRuns.uriTemplate == "shortcuts://runs/{name}")
        #expect(shortcutRuns.name == "Per-shortcut execution data")
    }
}

// MARK: - Prompt Definition Tests

@Suite("Prompt Definitions")
struct PromptDefinitionTests {
    @Test("All prompts are defined")
    func testAllPromptsDefined() {
        let prompts = ShortcutsPrompts.all

        #expect(prompts.count == 1)
    }

    @Test("Recommend a Shortcut prompt has correct properties")
    func testRecommendShortcutPrompt() {
        let prompt = ShortcutsPrompts.recommendShortcut

        #expect(prompt.name == "Recommend a Shortcut")
        #expect(prompt.description?.contains("Recommend") == true)

        // Verify arguments
        #expect(prompt.arguments?.count == 2)

        let args = prompt.arguments ?? []
        let taskArg = args.first { $0.name == "task_description" }
        let contextArg = args.first { $0.name == "context" }

        #expect(taskArg != nil)
        #expect(taskArg?.required == true)

        #expect(contextArg != nil)
        #expect(contextArg?.required == false)
    }

    @Test("Prompt get returns result with task description")
    func testPromptGetWithTaskDescription() {
        let result = ShortcutsPrompts.get(
            name: "Recommend a Shortcut",
            arguments: [
                "task_description": .string("Send an email")
            ]
        )

        #expect(result != nil)
        #expect(result?.messages.count == 1)
    }

    @Test("Prompt get returns result with context")
    func testPromptGetWithContext() {
        let result = ShortcutsPrompts.get(
            name: "Recommend a Shortcut",
            arguments: [
                "task_description": .string("Send an email"),
                "context": .string("To my team"),
            ]
        )

        #expect(result != nil)
        #expect(result?.messages.count == 1)
    }

    @Test("Prompt get returns nil for unknown prompt")
    func testPromptGetUnknown() {
        let result = ShortcutsPrompts.get(
            name: "Unknown Prompt",
            arguments: nil
        )

        #expect(result == nil)
    }
}

// MARK: - Escaping Function Tests

@Suite("Shell Escape Functions")
struct ShellEscapeTests {
    @Test("ShellEscape.escape handles simple strings")
    func testShellEscapeSimple() {
        let result = ShellEscape.escape("hello")
        #expect(result == "'hello'")
    }

    @Test("ShellEscape.escape handles empty strings")
    func testShellEscapeEmpty() {
        let result = ShellEscape.escape("")
        #expect(result == "''")
    }

    @Test("ShellEscape.escape handles strings with spaces")
    func testShellEscapeSpaces() {
        let result = ShellEscape.escape("hello world")
        #expect(result == "'hello world'")
    }

    @Test("ShellEscape.escape handles strings with single quotes")
    func testShellEscapeSingleQuotes() {
        let result = ShellEscape.escape("it's here")
        #expect(result == "'it'\"'\"'s here'")
    }

    @Test("ShellEscape.escape handles strings with multiple single quotes")
    func testShellEscapeMultipleSingleQuotes() {
        let result = ShellEscape.escape("'test'")
        #expect(result == "''\"'\"'test'\"'\"''")
    }

    @Test("ShellEscape.escape handles strings with special characters")
    func testShellEscapeSpecialChars() {
        let result = ShellEscape.escape("$HOME && rm -rf /")
        // Should be safely wrapped in single quotes
        #expect(result == "'$HOME && rm -rf /'")
    }
}

@Suite("AppleScript Escape Functions")
struct AppleScriptEscapeTests {
    @Test("escapeAppleScriptString handles simple strings")
    func testAppleScriptEscapeSimple() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.escapeAppleScriptString("hello")
        #expect(result == "hello")
    }

    @Test("escapeAppleScriptString handles strings with double quotes")
    func testAppleScriptEscapeDoubleQuotes() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.escapeAppleScriptString("say \"hello\"")
        #expect(result == "say \\\"hello\\\"")
    }

    @Test("escapeAppleScriptString handles strings with backslashes")
    func testAppleScriptEscapeBackslashes() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.escapeAppleScriptString("path\\to\\file")
        #expect(result == "path\\\\to\\\\file")
    }

    @Test("escapeAppleScriptString handles combined escaping")
    func testAppleScriptEscapeCombined() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.escapeAppleScriptString("\"path\\to\"")
        #expect(result == "\\\"path\\\\to\\\"")
    }

    @Test("shellEscape from ShortcutExecutor handles simple strings")
    func testExecutorShellEscapeSimple() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.shellEscape("hello")
        #expect(result == "'hello'")
    }

    @Test("shellEscape from ShortcutExecutor handles single quotes")
    func testExecutorShellEscapeSingleQuotes() async {
        let executor = ShortcutExecutor.shared
        let result = await executor.shellEscape("it's here")
        #expect(result == "'it'\"'\"'s here'")
    }
}

// MARK: - UserProfileManager Tests

@Suite("UserProfileManager Data Models")
struct UserProfileManagerTests {
    @Test("UserProfile can be created with defaults")
    func testUserProfileDefaults() {
        let profile = UserProfileManager.UserProfile()

        #expect(profile.context == nil)
        #expect(profile.preferences == nil)
    }

    @Test("UserProfile.Context can be created")
    func testUserProfileContext() {
        let context = UserProfileManager.UserProfile.Context(
            currentProjects: ["Project A", "Project B"],
            focusAreas: ["Development", "Testing"]
        )

        #expect(context.currentProjects == ["Project A", "Project B"])
        #expect(context.focusAreas == ["Development", "Testing"])
    }

    @Test("UserProfile.Preferences can be created")
    func testUserProfilePreferences() {
        let prefs = UserProfileManager.UserProfile.Preferences(
            favoriteShortcuts: ["Shortcut A", "Shortcut B"],
            workflowPatterns: ["morning": ["Check email", "Review tasks"]]
        )

        #expect(prefs.favoriteShortcuts == ["Shortcut A", "Shortcut B"])
        #expect(prefs.workflowPatterns?["morning"] == ["Check email", "Review tasks"])
    }

    @Test("ShortcutExecution can be created")
    func testShortcutExecution() {
        let execution = UserProfileManager.ShortcutExecution(
            shortcut: "Test Shortcut",
            success: true,
            duration: 1500,
            timestamp: "2024-01-15T10:30:00Z"
        )

        #expect(execution.shortcut == "Test Shortcut")
        #expect(execution.success == true)
        #expect(execution.duration == 1500)
        #expect(execution.timestamp == "2024-01-15T10:30:00Z")
    }

    @Test("ShortcutStatistics can be created with defaults")
    func testShortcutStatisticsDefaults() {
        let stats = UserProfileManager.ShortcutStatistics()

        #expect(stats.generatedAt == nil)
        #expect(stats.executions == nil)
        #expect(stats.timing == nil)
        #expect(stats.perShortcut == nil)
    }

    @Test("ShortcutStatistics.ExecutionCounts can be created")
    func testExecutionCounts() {
        let counts = UserProfileManager.ShortcutStatistics.ExecutionCounts(
            total: 100,
            successes: 90,
            failures: 10,
            unknown: 0
        )

        #expect(counts.total == 100)
        #expect(counts.successes == 90)
        #expect(counts.failures == 10)
        #expect(counts.unknown == 0)
    }

    @Test("ShortcutStatistics.TimingStats can be created")
    func testTimingStats() {
        let timing = UserProfileManager.ShortcutStatistics.TimingStats(
            average: 500,
            min: 100,
            max: 2000
        )

        #expect(timing.average == 500)
        #expect(timing.min == 100)
        #expect(timing.max == 2000)
    }

    @Test("ShortcutStatistics.PerShortcutStats can be created")
    func testPerShortcutStats() {
        let stats = UserProfileManager.ShortcutStatistics.PerShortcutStats(
            count: 50,
            successRate: 0.95,
            avgDuration: 350
        )

        #expect(stats.count == 50)
        #expect(stats.successRate == 0.95)
        #expect(stats.avgDuration == 350)
    }

    @Test("SystemState contains current time info")
    func testSystemState() {
        let state = UserProfileManager.SystemState()

        #expect(!state.timestamp.isEmpty)
        #expect(!state.localTime.isEmpty)
        #expect(!state.timezone.isEmpty)
        #expect(state.hour >= 0 && state.hour <= 23)
        #expect(state.dayOfWeek >= 0 && state.dayOfWeek <= 6)
    }
}

@Suite("UserProfileManager JSON Encoding")
struct UserProfileManagerEncodingTests {
    @Test("UserProfile encodes to JSON with hyphenated keys")
    func testUserProfileEncoding() throws {
        let profile = UserProfileManager.UserProfile(
            context: UserProfileManager.UserProfile.Context(
                currentProjects: ["Project"],
                focusAreas: ["Area"]
            ),
            preferences: UserProfileManager.UserProfile.Preferences(
                favoriteShortcuts: ["Shortcut"]
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        let json = String(data: data, encoding: .utf8)!

        // Verify hyphenated keys are used
        #expect(json.contains("current-projects"))
        #expect(json.contains("focus-areas"))
        #expect(json.contains("favorite-shortcuts"))
    }

    @Test("UserProfile can be decoded from JSON")
    func testUserProfileDecoding() throws {
        let json = """
            {
                "context": {
                    "current-projects": ["Project A"],
                    "focus-areas": ["Development"]
                },
                "preferences": {
                    "favorite-shortcuts": ["My Shortcut"]
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let profile = try decoder.decode(UserProfileManager.UserProfile.self, from: data)

        #expect(profile.context?.currentProjects == ["Project A"])
        #expect(profile.context?.focusAreas == ["Development"])
        #expect(profile.preferences?.favoriteShortcuts == ["My Shortcut"])
    }

    @Test("ShortcutExecution roundtrips through JSON")
    func testShortcutExecutionRoundtrip() throws {
        let original = UserProfileManager.ShortcutExecution(
            shortcut: "Test",
            success: true,
            duration: 1000,
            timestamp: "2024-01-15T10:00:00Z"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfileManager.ShortcutExecution.self, from: data)

        #expect(decoded.shortcut == original.shortcut)
        #expect(decoded.success == original.success)
        #expect(decoded.duration == original.duration)
        #expect(decoded.timestamp == original.timestamp)
    }

    @Test("ShortcutStatistics encodes with hyphenated keys")
    func testShortcutStatisticsEncoding() throws {
        var stats = UserProfileManager.ShortcutStatistics()
        stats.perShortcut = [
            "Test": UserProfileManager.ShortcutStatistics.PerShortcutStats(
                count: 10,
                successRate: 0.9,
                avgDuration: 500
            )
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("per-shortcut"))
        #expect(json.contains("success-rate"))
        #expect(json.contains("avg-duration"))
    }
}

// MARK: - ExecutionError Tests

@Suite("ShortcutExecutor ExecutionError")
struct ExecutionErrorTests {
    @Test("ExecutionError.permissionDenied has descriptive message")
    func testPermissionDeniedError() {
        let error = ShortcutExecutor.ExecutionError.permissionDenied(
            shortcut: "Test Shortcut",
            message: "Access denied"
        )

        let description = error.errorDescription ?? ""
        #expect(description.contains("Test Shortcut"))
        #expect(description.contains("Access denied"))
        #expect(description.contains("Permission") || description.contains("permission"))
    }

    @Test("ExecutionError.executionFailed has descriptive message")
    func testExecutionFailedError() {
        let error = ShortcutExecutor.ExecutionError.executionFailed(
            shortcut: "Test Shortcut",
            message: "Shortcut not found"
        )

        let description = error.errorDescription ?? ""
        #expect(description.contains("Test Shortcut"))
        #expect(description.contains("Shortcut not found") || description.contains("Failed"))
    }

    @Test("ExecutionError.processError has descriptive message")
    func testProcessErrorError() {
        let error = ShortcutExecutor.ExecutionError.processError("Command failed")

        let description = error.errorDescription ?? ""
        #expect(description.contains("Command failed") || description.contains("Process"))
    }
}

// MARK: - ShortcutsCache Tests

@Suite("ShortcutsCache")
struct ShortcutsCacheTests {
    @Test("ShortcutInfo can be created")
    func testShortcutInfoCreation() {
        let info = ShortcutsCache.ShortcutInfo(
            name: "Test Shortcut",
            identifier: "ABC-123"
        )

        #expect(info.name == "Test Shortcut")
        #expect(info.identifier == "ABC-123")
    }

    @Test("ShortcutInfo encodes to JSON correctly")
    func testShortcutInfoEncoding() throws {
        let info = ShortcutsCache.ShortcutInfo(
            name: "My Shortcut",
            identifier: "UUID-123"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(info)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("My Shortcut"))
        #expect(json.contains("UUID-123"))
    }

    @Test("Cache returns nil when empty")
    func testCacheEmptyReturnsNil() async {
        let cache = ShortcutsCache.shared
        await cache.invalidateCache()

        let result = await cache.getCachedShortcuts()
        #expect(result == nil)
    }

    @Test("Cache stores and retrieves shortcuts")
    func testCacheStoreAndRetrieve() async {
        let cache = ShortcutsCache.shared
        await cache.invalidateCache()

        let shortcuts = [
            ShortcutsCache.ShortcutInfo(name: "Test 1", identifier: "ID-1"),
            ShortcutsCache.ShortcutInfo(name: "Test 2", identifier: "ID-2"),
        ]

        await cache.cacheShortcuts(shortcuts)

        let result = await cache.getCachedShortcuts()
        #expect(result != nil)
        #expect(result?.count == 2)
        #expect(result?[0].name == "Test 1")
        #expect(result?[1].name == "Test 2")
    }
}
