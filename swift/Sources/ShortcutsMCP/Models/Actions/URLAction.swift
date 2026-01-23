// SPDX-License-Identifier: MIT
// URLAction.swift - URL/network actions for making HTTP requests in Shortcuts

import Foundation

/// HTTP methods supported by the Get Contents of URL action.
public enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Body type for HTTP requests.
public enum HTTPBodyType: String, Sendable {
    case json = "0"
    case form = "1"
    case file = "2"
}

/// Represents a "Get Contents of URL" action in Shortcuts.
/// This action makes HTTP requests and returns the response.
///
/// Identifier: `is.workflow.actions.downloadurl`
public struct URLAction: ShortcutAction {
    /// The action identifier
    public static let identifier = "is.workflow.actions.downloadurl"

    /// The URL to request (can be a string or variable reference)
    public var url: TextTokenValue

    /// The HTTP method (defaults to GET)
    public var method: HTTPMethod

    /// Whether to show advanced options (method, headers, body)
    public var showAdvanced: Bool

    /// Custom HTTP headers
    public var headers: [String: String]?

    /// Whether to show headers section
    public var showHeaders: Bool

    /// Body type for POST/PUT/PATCH requests
    public var bodyType: HTTPBodyType?

    /// JSON body data (for bodyType = json)
    public var jsonBody: [String: ActionParameterValue]?

    /// Form body data (for bodyType = form)
    public var formBody: [String: String]?

    /// Variable reference for file body (for bodyType = file)
    public var fileBody: TextTokenAttachment?

    /// Optional UUID for this action instance
    public var uuid: String?

    /// Optional custom output name for magic variable reference
    public var customOutputName: String?

    // MARK: - Initializers

    /// Creates a simple GET request.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        _ url: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.url = .string(url)
        self.method = .get
        self.showAdvanced = false
        self.showHeaders = false
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a URL request with a variable reference.
    /// - Parameters:
    ///   - url: The URL as a token value
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        url: TextTokenValue,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.url = url
        self.method = .get
        self.showAdvanced = false
        self.showHeaders = false
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a URL request with specified method.
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - url: The URL to request
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        method: HTTPMethod,
        url: String,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.url = .string(url)
        self.method = method
        self.showAdvanced = method != .get
        self.showHeaders = false
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Creates a full URL request with all options.
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - url: The URL to request (as token value)
    ///   - headers: Custom HTTP headers
    ///   - bodyType: Body type for POST/PUT/PATCH
    ///   - jsonBody: JSON body data
    ///   - formBody: Form body data
    ///   - fileBody: File body variable reference
    ///   - uuid: Optional UUID for this action
    ///   - customOutputName: Optional name for the output variable
    public init(
        method: HTTPMethod,
        url: TextTokenValue,
        headers: [String: String]? = nil,
        bodyType: HTTPBodyType? = nil,
        jsonBody: [String: ActionParameterValue]? = nil,
        formBody: [String: String]? = nil,
        fileBody: TextTokenAttachment? = nil,
        uuid: String? = nil,
        customOutputName: String? = nil
    ) {
        self.url = url
        self.method = method
        self.showAdvanced = method != .get || headers != nil || bodyType != nil
        self.headers = headers
        self.showHeaders = headers != nil
        self.bodyType = bodyType
        self.jsonBody = jsonBody
        self.formBody = formBody
        self.fileBody = fileBody
        self.uuid = uuid
        self.customOutputName = customOutputName
    }

    /// Converts to a generic WorkflowAction.
    public func toWorkflowAction() -> WorkflowAction {
        var parameters: [String: ActionParameterValue] = [:]

        // Set URL parameter
        switch url {
        case .string(let str):
            parameters["WFURL"] = .string(str)
        case .tokenString(let tokenString):
            parameters["WFURL"] = tokenString.toParameterValue()
        case .attachment(let attachment):
            parameters["WFURL"] = attachment.toParameterValue()
        }

        // Show advanced options if needed
        if showAdvanced {
            parameters["Advanced"] = .bool(true)
            parameters["WFHTTPMethod"] = .string(method.rawValue)
        }

        // Show headers section if needed
        if showHeaders {
            parameters["ShowHeaders"] = .bool(true)
        }

        // Set headers
        if let headers, !headers.isEmpty {
            var headersDict: [String: ActionParameterValue] = [:]
            for (key, value) in headers {
                headersDict[key] = .string(value)
            }
            parameters["WFHTTPHeaders"] = .dictionary(headersDict)
        }

        // Set body type and body data
        if let bodyType {
            parameters["WFHTTPBodyType"] = .string(bodyType.rawValue)

            switch bodyType {
            case .json:
                if let jsonBody, !jsonBody.isEmpty {
                    parameters["WFJSONValues"] = .dictionary(jsonBody)
                }
            case .form:
                if let formBody, !formBody.isEmpty {
                    var formDict: [String: ActionParameterValue] = [:]
                    for (key, value) in formBody {
                        formDict[key] = .string(value)
                    }
                    parameters["WFFormValues"] = .dictionary(formDict)
                }
            case .file:
                if let fileBody {
                    parameters["WFRequestVariable"] = fileBody.toParameterValue()
                }
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

// MARK: - Convenience Factory Methods

extension URLAction {
    /// Creates a GET request.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func get(
        _ url: String,
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .get,
            url: .string(url),
            headers: headers,
            uuid: uuid
        )
    }

    /// Creates a POST request with JSON body.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - json: JSON body data
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func postJSON(
        _ url: String,
        json: [String: ActionParameterValue],
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .post,
            url: .string(url),
            headers: headers,
            bodyType: .json,
            jsonBody: json,
            uuid: uuid
        )
    }

    /// Creates a POST request with form body.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - form: Form body data
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func postForm(
        _ url: String,
        form: [String: String],
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .post,
            url: .string(url),
            headers: headers,
            bodyType: .form,
            formBody: form,
            uuid: uuid
        )
    }

    /// Creates a PUT request with JSON body.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - json: JSON body data
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func putJSON(
        _ url: String,
        json: [String: ActionParameterValue],
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .put,
            url: .string(url),
            headers: headers,
            bodyType: .json,
            jsonBody: json,
            uuid: uuid
        )
    }

    /// Creates a PATCH request with JSON body.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - json: JSON body data
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func patchJSON(
        _ url: String,
        json: [String: ActionParameterValue],
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .patch,
            url: .string(url),
            headers: headers,
            bodyType: .json,
            jsonBody: json,
            uuid: uuid
        )
    }

    /// Creates a DELETE request.
    /// - Parameters:
    ///   - url: The URL to request
    ///   - headers: Optional HTTP headers
    ///   - uuid: Optional UUID for this action
    /// - Returns: A configured URLAction
    public static func delete(
        _ url: String,
        headers: [String: String]? = nil,
        uuid: String? = nil
    ) -> URLAction {
        URLAction(
            method: .delete,
            url: .string(url),
            headers: headers,
            uuid: uuid
        )
    }
}

// MARK: - GetContentsOfURLAction (Alias)

/// Alias for URLAction for clarity.
/// "Get Contents of URL" is the UI name for the downloadurl action.
public typealias GetContentsOfURLAction = URLAction
