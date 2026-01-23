// SPDX-License-Identifier: MIT
// Shortcut.swift - Core Codable model for .shortcut plist files

import Foundation

/// Represents a complete macOS/iOS Shortcut workflow.
/// Encodes to and decodes from the .shortcut plist format.
public struct Shortcut: Codable, Sendable {
    // MARK: - Version Information

    /// Minimum client version string (e.g., "900" for iOS 15+)
    public var minimumClientVersionString: String

    /// Minimum client version as integer
    public var minimumClientVersion: Int

    /// Client version that created/last modified this shortcut
    public var clientVersion: Int

    /// Client release semantic version (e.g., "2.0.0")
    public var clientRelease: String?

    // MARK: - Metadata

    /// Optional shortcut name (filename is used if absent)
    public var name: String?

    /// Visual appearance of the shortcut
    public var icon: WorkflowIcon

    // MARK: - Functional Configuration

    /// Accepted input types (e.g., WFStringContentItem, WFURLContentItem)
    public var inputContentItemClasses: [String]

    /// Usage contexts (e.g., MenuBar, QuickActions, NCWidget)
    public var types: [String]

    /// Import questions shown when user imports the shortcut
    public var importQuestions: [ImportQuestion]?

    // MARK: - Actions

    /// The workflow actions that make up this shortcut
    public var actions: [WorkflowAction]

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case minimumClientVersionString = "WFWorkflowMinimumClientVersionString"
        case minimumClientVersion = "WFWorkflowMinimumClientVersion"
        case clientVersion = "WFWorkflowClientVersion"
        case clientRelease = "WFWorkflowClientRelease"
        case name = "WFWorkflowName"
        case icon = "WFWorkflowIcon"
        case inputContentItemClasses = "WFWorkflowInputContentItemClasses"
        case types = "WFWorkflowTypes"
        case importQuestions = "WFWorkflowImportQuestions"
        case actions = "WFWorkflowActions"
    }

    // MARK: - Initialization

    /// Creates a new shortcut with the specified configuration.
    /// - Parameters:
    ///   - name: Optional display name
    ///   - icon: Visual appearance (defaults to blue with magic wand glyph)
    ///   - actions: The workflow actions
    ///   - inputContentItemClasses: Accepted input types (defaults to none)
    ///   - types: Usage contexts (defaults to empty)
    ///   - minimumClientVersion: Minimum required app version (defaults to 900 for iOS 15)
    ///   - clientVersion: Client version (defaults to 2614 for recent macOS)
    public init(
        name: String? = nil,
        icon: WorkflowIcon = .default,
        actions: [WorkflowAction] = [],
        inputContentItemClasses: [String] = [],
        types: [String] = [],
        minimumClientVersion: Int = 900,
        minimumClientVersionString: String = "900",
        clientVersion: Int = 2614,
        clientRelease: String? = nil,
        importQuestions: [ImportQuestion]? = nil
    ) {
        self.name = name
        self.icon = icon
        self.actions = actions
        self.inputContentItemClasses = inputContentItemClasses
        self.types = types
        self.minimumClientVersion = minimumClientVersion
        self.minimumClientVersionString = minimumClientVersionString
        self.clientVersion = clientVersion
        self.clientRelease = clientRelease
        self.importQuestions = importQuestions
    }

    // MARK: - Encoding

    /// Encodes this shortcut to plist data.
    /// - Returns: Binary plist data suitable for writing to a .shortcut file
    public func encodeToPlist() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(self)
    }

    /// Encodes this shortcut to XML plist data (useful for debugging).
    /// - Returns: XML plist data
    public func encodeToXMLPlist() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        return try encoder.encode(self)
    }

    // MARK: - Decoding

    /// Decodes a shortcut from plist data.
    /// - Parameter data: Plist data (binary or XML format)
    /// - Returns: The decoded Shortcut
    public static func decode(from data: Data) throws -> Shortcut {
        let decoder = PropertyListDecoder()
        return try decoder.decode(Shortcut.self, from: data)
    }
}

// MARK: - WorkflowIcon

/// Visual appearance of a shortcut.
public struct WorkflowIcon: Codable, Sendable, Equatable {
    /// Glyph number (SF Symbol identifier as integer)
    public var glyphNumber: Int

    /// Start color as RGBA-8 integer (format: RRGGBBAA)
    public var startColor: Int

    /// Optional image data for custom icon
    public var imageData: Data?

    private enum CodingKeys: String, CodingKey {
        case glyphNumber = "WFWorkflowIconGlyphNumber"
        case startColor = "WFWorkflowIconStartColor"
        case imageData = "WFWorkflowIconImageData"
    }

    /// Creates a workflow icon.
    /// - Parameters:
    ///   - glyphNumber: Glyph identifier
    ///   - startColor: RGBA-8 color value
    ///   - imageData: Optional custom image data
    public init(glyphNumber: Int, startColor: Int, imageData: Data? = nil) {
        self.glyphNumber = glyphNumber
        self.startColor = startColor
        self.imageData = imageData
    }

    /// Default icon: blue color with magic wand glyph
    public static let `default` = WorkflowIcon(
        glyphNumber: 59771,  // Magic wand glyph
        startColor: 463_140_863  // Blue color (0x1B9AF7FF)
    )

    /// Creates an icon with a specific color.
    /// - Parameters:
    ///   - red: Red component (0-255)
    ///   - green: Green component (0-255)
    ///   - blue: Blue component (0-255)
    ///   - alpha: Alpha component (0-255, defaults to 255)
    ///   - glyphNumber: Glyph identifier (defaults to magic wand)
    /// - Returns: A WorkflowIcon with the specified color
    public static func withColor(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8 = 255,
        glyphNumber: Int = 59771
    ) -> WorkflowIcon {
        let color = (Int(red) << 24) | (Int(green) << 16) | (Int(blue) << 8) | Int(alpha)
        return WorkflowIcon(glyphNumber: glyphNumber, startColor: color)
    }
}

// MARK: - ImportQuestion

/// A question shown to the user when importing a shortcut.
public struct ImportQuestion: Codable, Sendable {
    /// Index of the action this question applies to
    public var actionIndex: Int

    /// The parameter key in the action
    public var parameterKey: String

    /// Category of the question
    public var category: String?

    /// Default value for the parameter
    public var defaultValue: String?

    /// Display text for the question
    public var text: String?

    private enum CodingKeys: String, CodingKey {
        case actionIndex = "ActionIndex"
        case parameterKey = "ParameterKey"
        case category = "Category"
        case defaultValue = "DefaultValue"
        case text = "Text"
    }

    public init(
        actionIndex: Int,
        parameterKey: String,
        category: String? = nil,
        defaultValue: String? = nil,
        text: String? = nil
    ) {
        self.actionIndex = actionIndex
        self.parameterKey = parameterKey
        self.category = category
        self.defaultValue = defaultValue
        self.text = text
    }
}

// MARK: - Common Input Content Item Classes

/// Common content item class identifiers for shortcut input.
public enum InputContentItemClass: String, Sendable {
    case string = "WFStringContentItem"
    case url = "WFURLContentItem"
    case image = "WFImageContentItem"
    case pdf = "WFPDFContentItem"
    case richText = "WFRichTextContentItem"
    case file = "WFGenericFileContentItem"
    case contact = "WFContactContentItem"
    case location = "WFLocationContentItem"
    case date = "WFDateContentItem"
    case phoneNumber = "WFPhoneNumberContentItem"
    case emailAddress = "WFEmailAddressContentItem"
    case mapLink = "WFMKMapItemContentItem"
    case appStoreApp = "WFAppStoreAppContentItem"
    case article = "WFArticleContentItem"
    case media = "WFAVAssetContentItem"
    case safariWebPage = "WFSafariWebPageContentItem"
}

// MARK: - Common Workflow Types

/// Common workflow type identifiers for shortcut visibility.
public enum WorkflowType: String, Sendable {
    case menuBar = "MenuBar"
    case quickActions = "QuickActions"
    case actionExtension = "ActionExtension"
    case notificationCenter = "NCWidget"
    case watch = "Watch"
    case sleep = "Sleep"
    case automations = "WatchKit"
}
