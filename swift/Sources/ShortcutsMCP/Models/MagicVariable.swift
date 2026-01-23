// SPDX-License-Identifier: MIT
// MagicVariable.swift - Magic variable support for Shortcuts

import Foundation

// MARK: - Magic Variable

/// A magic variable is a reference to a previous action's output in a Shortcuts workflow.
///
/// Magic variables allow actions to reference and use the output of any previous action
/// in the workflow, not just the immediately preceding one. They can also access specific
/// properties of the output and coerce it to different types.
///
/// This type provides a convenient wrapper around `TextTokenAttachment` specifically for
/// the common case of referencing action outputs.
public struct MagicVariable: Sendable, Equatable {
    /// The UUID of the source action
    public var sourceActionUUID: String

    /// The name of the output (e.g., "Text", "URL", "File", "Result")
    public var outputName: String

    /// Optional aggrandizements (property access or type coercion)
    public var aggrandizements: [Aggrandizement]

    /// Creates a magic variable reference.
    /// - Parameters:
    ///   - sourceActionUUID: The UUID of the action whose output to reference
    ///   - outputName: The name of the output (defaults to action identifier based)
    ///   - aggrandizements: Optional property access or type coercion
    public init(
        sourceActionUUID: String,
        outputName: String = "Output",
        aggrandizements: [Aggrandizement] = []
    ) {
        self.sourceActionUUID = sourceActionUUID
        self.outputName = outputName
        self.aggrandizements = aggrandizements
    }

    // MARK: - Property Access

    /// Returns a new magic variable that accesses a property of this variable's value.
    /// - Parameter propertyName: The property to access (e.g., "Name", "File Extension")
    /// - Returns: A new magic variable with the property aggrandizement
    public func property(_ propertyName: String) -> MagicVariable {
        var newVar = self
        newVar.aggrandizements.append(.getProperty(propertyName))
        return newVar
    }

    /// Accesses the "Name" property of the variable.
    public var name: MagicVariable {
        property("Name")
    }

    /// Accesses the "File Extension" property of the variable.
    public var fileExtension: MagicVariable {
        property("File Extension")
    }

    /// Accesses the "File Size" property of the variable.
    public var fileSize: MagicVariable {
        property("File Size")
    }

    /// Accesses the "Creation Date" property of the variable.
    public var creationDate: MagicVariable {
        property("Creation Date")
    }

    /// Accesses the "Last Modified Date" property of the variable.
    public var lastModifiedDate: MagicVariable {
        property("Last Modified Date")
    }

    /// Accesses the "File Path" property of the variable.
    public var filePath: MagicVariable {
        property("File Path")
    }

    // MARK: - Type Coercion

    /// Returns a new magic variable that coerces this variable's value to a type.
    /// - Parameter itemClass: The class to coerce to (e.g., "WFStringContentItem")
    /// - Returns: A new magic variable with the coercion aggrandizement
    public func coerce(to itemClass: String) -> MagicVariable {
        var newVar = self
        newVar.aggrandizements.append(.coerce(to: itemClass))
        return newVar
    }

    /// Coerces the variable to text.
    public var asText: MagicVariable {
        coerce(to: "WFStringContentItem")
    }

    /// Coerces the variable to a number.
    public var asNumber: MagicVariable {
        coerce(to: "WFNumberContentItem")
    }

    /// Coerces the variable to a date.
    public var asDate: MagicVariable {
        coerce(to: "WFDateContentItem")
    }

    /// Coerces the variable to a URL.
    public var asURL: MagicVariable {
        coerce(to: "WFURLContentItem")
    }

    /// Coerces the variable to a file.
    public var asFile: MagicVariable {
        coerce(to: "WFFileContentItem")
    }

    /// Coerces the variable to an image.
    public var asImage: MagicVariable {
        coerce(to: "WFImageContentItem")
    }

    /// Coerces the variable to a dictionary.
    public var asDictionary: MagicVariable {
        coerce(to: "WFDictionaryContentItem")
    }

    // MARK: - Conversion

    /// Converts this magic variable to a TextTokenAttachment.
    public func toAttachment() -> TextTokenAttachment {
        TextTokenAttachment(
            type: .actionOutput,
            outputUUID: sourceActionUUID,
            outputName: outputName,
            variableName: nil,
            aggrandizements: aggrandizements.isEmpty ? nil : aggrandizements
        )
    }

    /// Converts this magic variable to a TextTokenValue.
    public func toTokenValue() -> TextTokenValue {
        .attachment(toAttachment())
    }
}

// MARK: - Named Variable

/// A named variable that can be set and retrieved in a Shortcuts workflow.
///
/// Named variables are stored by name and can be accessed from any point in the
/// workflow after they are set. Unlike magic variables (which reference specific
/// action outputs by UUID), named variables are referenced by their string name.
public struct NamedVariable: Sendable, Equatable {
    /// The name of the variable
    public var name: String

    /// Optional aggrandizements (property access or type coercion)
    public var aggrandizements: [Aggrandizement]

    /// Creates a named variable reference.
    /// - Parameters:
    ///   - name: The name of the variable
    ///   - aggrandizements: Optional property access or type coercion
    public init(_ name: String, aggrandizements: [Aggrandizement] = []) {
        self.name = name
        self.aggrandizements = aggrandizements
    }

    // MARK: - Property Access

    /// Returns a new named variable that accesses a property of this variable's value.
    /// - Parameter propertyName: The property to access
    /// - Returns: A new named variable with the property aggrandizement
    public func property(_ propertyName: String) -> NamedVariable {
        var newVar = self
        newVar.aggrandizements.append(.getProperty(propertyName))
        return newVar
    }

    /// Accesses the "Name" property of the variable.
    public var getName: NamedVariable {
        property("Name")
    }

    /// Accesses the "File Extension" property of the variable.
    public var getFileExtension: NamedVariable {
        property("File Extension")
    }

    // MARK: - Type Coercion

    /// Returns a new named variable that coerces this variable's value to a type.
    /// - Parameter itemClass: The class to coerce to
    /// - Returns: A new named variable with the coercion aggrandizement
    public func coerce(to itemClass: String) -> NamedVariable {
        var newVar = self
        newVar.aggrandizements.append(.coerce(to: itemClass))
        return newVar
    }

    /// Coerces the variable to text.
    public var asText: NamedVariable {
        coerce(to: "WFStringContentItem")
    }

    /// Coerces the variable to a number.
    public var asNumber: NamedVariable {
        coerce(to: "WFNumberContentItem")
    }

    // MARK: - Conversion

    /// Converts this named variable to a TextTokenAttachment.
    public func toAttachment() -> TextTokenAttachment {
        TextTokenAttachment(
            type: .variable,
            outputUUID: nil,
            outputName: nil,
            variableName: name,
            aggrandizements: aggrandizements.isEmpty ? nil : aggrandizements
        )
    }

    /// Converts this named variable to a TextTokenValue.
    public func toTokenValue() -> TextTokenValue {
        .attachment(toAttachment())
    }
}

// MARK: - Variable Builder

/// A builder for constructing variable references with fluent syntax.
///
/// Example usage:
/// ```swift
/// let textVar = Variable.named("MyText")
/// let fileName = Variable.magicVariable(uuid: actionUUID, outputName: "File").name
/// let input = Variable.shortcutInput
/// ```
public enum Variable {
    /// Creates a named variable reference.
    /// - Parameter name: The name of the variable
    /// - Returns: A NamedVariable
    public static func named(_ name: String) -> NamedVariable {
        NamedVariable(name)
    }

    /// Creates a magic variable reference to an action's output.
    /// - Parameters:
    ///   - uuid: The UUID of the source action
    ///   - outputName: The name of the output
    /// - Returns: A MagicVariable
    public static func magicVariable(uuid: String, outputName: String = "Output") -> MagicVariable {
        MagicVariable(sourceActionUUID: uuid, outputName: outputName)
    }

    /// Creates a reference to the shortcut input.
    public static var shortcutInput: TextTokenAttachment {
        TextTokenAttachment.shortcutInput()
    }

    /// Creates a reference to the clipboard.
    public static var clipboard: TextTokenAttachment {
        TextTokenAttachment(type: .clipboard)
    }

    /// Creates a reference to the current date.
    public static var currentDate: TextTokenAttachment {
        TextTokenAttachment(type: .currentDate)
    }

    /// Creates a reference that asks for input when run.
    public static var ask: TextTokenAttachment {
        TextTokenAttachment(type: .ask)
    }
}

// MARK: - Content Item Classes

/// Common content item class identifiers used for type coercion.
public enum ContentItemClass {
    /// Text/String content
    public static let string = "WFStringContentItem"

    /// Number content
    public static let number = "WFNumberContentItem"

    /// Boolean content
    public static let boolean = "WFBooleanContentItem"

    /// Date content
    public static let date = "WFDateContentItem"

    /// URL content
    public static let url = "WFURLContentItem"

    /// File content
    public static let file = "WFFileContentItem"

    /// Image content
    public static let image = "WFImageContentItem"

    /// Rich text content
    public static let richText = "WFRichTextContentItem"

    /// Dictionary content
    public static let dictionary = "WFDictionaryContentItem"

    /// App Store app content
    public static let appStoreApp = "WFAppStoreAppContentItem"

    /// Contact content
    public static let contact = "WFContactContentItem"

    /// Location content
    public static let location = "WFLocationContentItem"

    /// Media content (photo, video, audio)
    public static let media = "WFAVAssetContentItem"

    /// PDF content
    public static let pdf = "WFPDFContentItem"

    /// Phone number content
    public static let phoneNumber = "WFPhoneNumberContentItem"

    /// Email address content
    public static let emailAddress = "WFEmailAddressContentItem"

    /// Calendar event content
    public static let calendarEvent = "WFCalendarEventContentItem"

    /// Measurement content
    public static let measurement = "WFMeasurementContentItem"
}

// MARK: - Property Names

/// Common property names used with aggrandizements.
public enum PropertyName {
    /// The name of the item
    public static let name = "Name"

    /// The file extension
    public static let fileExtension = "File Extension"

    /// The file size
    public static let fileSize = "File Size"

    /// The file path
    public static let filePath = "File Path"

    /// The creation date
    public static let creationDate = "Creation Date"

    /// The last modified date
    public static let lastModifiedDate = "Last Modified Date"

    /// The MIME type
    public static let mimeType = "MIME Type"

    /// The album artist (for media)
    public static let albumArtist = "Album Artist"

    /// The artist (for media)
    public static let artist = "Artist"

    /// The album (for media)
    public static let album = "Album"

    /// The genre (for media)
    public static let genre = "Genre"

    /// The duration (for media)
    public static let duration = "Duration"

    /// The width (for images/media)
    public static let width = "Width"

    /// The height (for images/media)
    public static let height = "Height"
}
