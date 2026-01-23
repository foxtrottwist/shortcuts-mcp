// SPDX-License-Identifier: MIT
// FileActions.swift - File actions for saving, getting, and selecting files in Shortcuts

import Foundation

// MARK: - File Storage Service

/// Storage services available for file operations.
public enum FileStorageService: String, Sendable, CaseIterable {
    case iCloudDrive = "iCloud Drive"
    case dropbox = "Dropbox"
}

// MARK: - SaveFileAction

/// Represents a "Save File" action in Shortcuts.
/// This action saves data to iCloud Drive or Dropbox.
///
/// Identifier: `is.workflow.actions.documentpicker.save`
public struct SaveFileAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.documentpicker.save"

    /// Storage service (iCloud Drive or Dropbox)
    public var service: FileStorageService

    /// Whether to prompt user for save location
    public var askWhereToSave: Bool

    /// Destination path (only used when askWhereToSave is false)
    public var destinationPath: TextTokenValue?

    /// Whether to overwrite existing files (only used when askWhereToSave is false)
    public var overwriteIfExists: Bool?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a save file action that prompts the user for the save location.
    /// - Parameters:
    ///   - service: The storage service to save to
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.askWhereToSave = true
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a save file action with a specific destination path.
    /// - Parameters:
    ///   - service: The storage service to save to
    ///   - destinationPath: The file path to save to (e.g., "/folder/filename.txt")
    ///   - overwriteIfExists: Whether to overwrite if file exists
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        destinationPath: String,
        overwriteIfExists: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.askWhereToSave = false
        self.destinationPath = .string(destinationPath)
        self.overwriteIfExists = overwriteIfExists
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a save file action with a variable destination path.
    /// - Parameters:
    ///   - service: The storage service to save to
    ///   - destinationPath: The file path as a token value
    ///   - overwriteIfExists: Whether to overwrite if file exists
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        destinationPath: TextTokenValue,
        overwriteIfExists: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.askWhereToSave = false
        self.destinationPath = destinationPath
        self.overwriteIfExists = overwriteIfExists
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFFileStorageService": .string(service.rawValue),
            "WFAskWhereToSave": .bool(askWhereToSave),
        ]

        if !askWhereToSave {
            if let destinationPath {
                switch destinationPath {
                case .string(let str):
                    parameters["WFFileDestinationPath"] = .string(str)
                case .tokenString(let tokenString):
                    parameters["WFFileDestinationPath"] = tokenString.toParameterValue()
                case .attachment(let attachment):
                    parameters["WFFileDestinationPath"] = attachment.toParameterValue()
                }
            }

            if let overwriteIfExists {
                parameters["WFSaveFileOverwrite"] = .bool(overwriteIfExists)
            }
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Convenience Extensions

extension SaveFileAction {
    /// Creates a save file action that prompts the user to choose the location.
    /// - Parameters:
    ///   - service: The storage service to save to
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured SaveFileAction
    public static func askWhereToSave(
        service: FileStorageService = .iCloudDrive,
        uuid: String? = nil
    ) -> SaveFileAction {
        SaveFileAction(service: service, uuid: uuid)
    }

    /// Creates a save file action with a specific iCloud Drive path.
    /// - Parameters:
    ///   - path: The file path (e.g., "/Shortcuts/myfile.txt")
    ///   - overwrite: Whether to overwrite existing files
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured SaveFileAction
    public static func toICloud(
        path: String,
        overwrite: Bool = false,
        uuid: String? = nil
    ) -> SaveFileAction {
        SaveFileAction(
            service: .iCloudDrive,
            destinationPath: path,
            overwriteIfExists: overwrite,
            uuid: uuid
        )
    }

    /// Creates a save file action with a specific Dropbox path.
    /// - Parameters:
    ///   - path: The file path
    ///   - overwrite: Whether to overwrite existing files
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured SaveFileAction
    public static func toDropbox(
        path: String,
        overwrite: Bool = false,
        uuid: String? = nil
    ) -> SaveFileAction {
        SaveFileAction(
            service: .dropbox,
            destinationPath: path,
            overwriteIfExists: overwrite,
            uuid: uuid
        )
    }
}

// MARK: - GetFileAction

/// Represents a "Get File" action in Shortcuts.
/// This action retrieves files from iCloud Drive or Dropbox.
///
/// Identifier: `is.workflow.actions.documentpicker.open`
public struct GetFileAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.documentpicker.open"

    /// Storage service (iCloud Drive or Dropbox)
    public var service: FileStorageService

    /// Whether to show the document picker UI
    public var showDocumentPicker: Bool

    /// Whether to allow selecting multiple files (only when showDocumentPicker is true)
    public var selectMultiple: Bool?

    /// File path to retrieve (only when showDocumentPicker is false)
    public var filePath: TextTokenValue?

    /// Whether to error if file not found (only when showDocumentPicker is false)
    public var errorIfNotFound: Bool?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a get file action that shows the document picker.
    /// - Parameters:
    ///   - service: The storage service to browse
    ///   - selectMultiple: Whether to allow selecting multiple files
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        selectMultiple: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.showDocumentPicker = true
        self.selectMultiple = selectMultiple
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get file action that retrieves from a specific path.
    /// - Parameters:
    ///   - service: The storage service to retrieve from
    ///   - filePath: The file path to retrieve
    ///   - errorIfNotFound: Whether to error if the file is not found
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        filePath: String,
        errorIfNotFound: Bool = true,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.showDocumentPicker = false
        self.filePath = .string(filePath)
        self.errorIfNotFound = errorIfNotFound
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a get file action that retrieves from a variable path.
    /// - Parameters:
    ///   - service: The storage service to retrieve from
    ///   - filePath: The file path as a token value
    ///   - errorIfNotFound: Whether to error if the file is not found
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        service: FileStorageService = .iCloudDrive,
        filePath: TextTokenValue,
        errorIfNotFound: Bool = true,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.service = service
        self.showDocumentPicker = false
        self.filePath = filePath
        self.errorIfNotFound = errorIfNotFound
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFFileStorageService": .string(service.rawValue),
            "WFShowFilePicker": .bool(showDocumentPicker),
        ]

        if showDocumentPicker {
            if let selectMultiple {
                parameters["SelectMultiple"] = .bool(selectMultiple)
            }
        } else {
            if let filePath {
                switch filePath {
                case .string(let str):
                    parameters["WFGetFilePath"] = .string(str)
                case .tokenString(let tokenString):
                    parameters["WFGetFilePath"] = tokenString.toParameterValue()
                case .attachment(let attachment):
                    parameters["WFGetFilePath"] = attachment.toParameterValue()
                }
            }

            if let errorIfNotFound {
                parameters["WFFileErrorIfNotFound"] = .bool(errorIfNotFound)
            }
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - Convenience Extensions

extension GetFileAction {
    /// Creates a file picker that allows selecting a single file.
    /// - Parameters:
    ///   - service: The storage service to browse
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetFileAction
    public static func selectFile(
        service: FileStorageService = .iCloudDrive,
        uuid: String? = nil
    ) -> GetFileAction {
        GetFileAction(service: service, selectMultiple: false, uuid: uuid)
    }

    /// Creates a file picker that allows selecting multiple files.
    /// - Parameters:
    ///   - service: The storage service to browse
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetFileAction
    public static func selectFiles(
        service: FileStorageService = .iCloudDrive,
        uuid: String? = nil
    ) -> GetFileAction {
        GetFileAction(service: service, selectMultiple: true, uuid: uuid)
    }

    /// Creates an action that retrieves a file from a specific iCloud Drive path.
    /// - Parameters:
    ///   - path: The file path (e.g., "/Shortcuts/myfile.txt")
    ///   - errorIfNotFound: Whether to error if file not found
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetFileAction
    public static func fromICloud(
        path: String,
        errorIfNotFound: Bool = true,
        uuid: String? = nil
    ) -> GetFileAction {
        GetFileAction(
            service: .iCloudDrive,
            filePath: path,
            errorIfNotFound: errorIfNotFound,
            uuid: uuid
        )
    }

    /// Creates an action that retrieves a file from a specific Dropbox path.
    /// - Parameters:
    ///   - path: The file path
    ///   - errorIfNotFound: Whether to error if file not found
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured GetFileAction
    public static func fromDropbox(
        path: String,
        errorIfNotFound: Bool = true,
        uuid: String? = nil
    ) -> GetFileAction {
        GetFileAction(
            service: .dropbox,
            filePath: path,
            errorIfNotFound: errorIfNotFound,
            uuid: uuid
        )
    }
}

// MARK: - SelectFileAction (Alias)

/// Alias for GetFileAction when used as a file picker.
/// "Select File" shows the document picker UI.
public typealias SelectFileAction = GetFileAction

// MARK: - SelectFolderAction

/// Represents a "Select Folder" action in Shortcuts.
/// This action prompts the user to select a folder.
///
/// Identifier: `is.workflow.actions.file.select`
public struct SelectFolderAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.file.select"

    /// Whether to allow selecting multiple folders
    public var selectMultiple: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a select folder action.
    /// - Parameters:
    ///   - selectMultiple: Whether to allow selecting multiple folders
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        selectMultiple: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.selectMultiple = selectMultiple
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [
            "WFPickingMode": .string("Folders"),
        ]

        if selectMultiple {
            parameters["SelectMultiple"] = .bool(true)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}

// MARK: - GetFolderContentsAction

/// Represents a "Get Contents of Folder" action in Shortcuts.
/// This action retrieves the contents of a folder.
///
/// Identifier: `is.workflow.actions.file.getfoldercontents`
public struct GetFolderContentsAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.file.getfoldercontents"

    /// Whether to get contents recursively (including subfolders)
    public var recursive: Bool

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    /// Creates a get folder contents action.
    /// - Parameters:
    ///   - recursive: Whether to include contents of subfolders
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        recursive: Bool = false,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.recursive = recursive
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        if recursive {
            parameters["Recursive"] = .bool(true)
        }

        return WorkflowAction(
            identifier: Self.identifier,
            parameters: parameters,
            uuid: uuid,
            customOutputName: customOutputName
        )
    }
}
