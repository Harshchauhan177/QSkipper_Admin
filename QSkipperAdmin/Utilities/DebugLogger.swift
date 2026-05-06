import Foundation
import UIKit

/// Debug logger utility for troubleshooting
class DebugLogger {
    static let shared = DebugLogger()
    
    enum LogCategory: String {
        case app = "APP"
        case network = "NETWORK"
        case cache = "CACHE"
        case auth = "AUTH"
        case lifecycle = "LIFECYCLE"
        case navigation = "NAVIGATION"
        case error = "ERROR"
        case custom = "CUSTOM"
        case userAction = "USER_ACTION"
        case debug = "DEBUG"
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private var isLoggingEnabled = true
    public var enableLogging: Bool {
        get { return isLoggingEnabled }
        set { isLoggingEnabled = newValue }
    }
    
    private var logQueue = DispatchQueue(label: "com.qskipper.admin.logging", qos: .utility)
    
    private init() {
        log("DebugLogger initialized", category: .app)
    }
    
    /// Log a message with optional tag
    func log(_ message: String, category: LogCategory = .custom, tag: String? = nil) {
        guard isLoggingEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let tagString = tag != nil ? "[\(tag!)] " : ""
        let logMessage = "[\(timestamp)] [\(category.rawValue)] \(tagString)\(message)"
        
        logQueue.async {
            print(logMessage)
            // In a production app, you might want to save logs to a file or remote logging service
        }
    }
    
    /// App Lifecycle Logging
    func logAppDidLaunch() {
        log("Application did finish launching", category: .lifecycle)
    }
    
    func logAppWillTerminate() {
        log("Application will terminate", category: .lifecycle)
    }
    
    func logAppDidEnterBackground() {
        log("Application did enter background", category: .lifecycle)
    }
    
    func logAppWillEnterForeground() {
        log("Application will enter foreground", category: .lifecycle)
    }
    
    /// View Controller Lifecycle Logging
    func logViewDidLoad(viewController: String) {
        log("viewDidLoad: \(viewController)", category: .lifecycle)
    }
    
    func logViewWillAppear(viewController: String) {
        log("viewWillAppear: \(viewController)", category: .lifecycle)
    }
    
    func logViewDidAppear(viewController: String) {
        log("viewDidAppear: \(viewController)", category: .lifecycle)
    }
    
    func logViewWillDisappear(viewController: String) {
        log("viewWillDisappear: \(viewController)", category: .lifecycle)
    }
    
    func logViewDidDisappear(viewController: String) {
        log("viewDidDisappear: \(viewController)", category: .lifecycle)
    }
    
    /// Navigation Logging
    func logNavigation(from: String, to: String) {
        log("Navigation: \(from) -> \(to)", category: .navigation)
    }
    
    /// Network Logging
    func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "UNKNOWN"
        
        var logString = "📤 REQUEST: \(method) \(url)"
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logString += "\nHEADERS: \(headers)"
        }
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logString += "\nBODY: \(bodyString)"
        }
        
        log(logString, category: .network)
    }
    
    func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        var logString = "📥 RESPONSE:"
        
        if let httpResponse = response as? HTTPURLResponse {
            logString += " Status: \(httpResponse.statusCode)"
            
            if !httpResponse.allHeaderFields.isEmpty {
                logString += "\nHEADERS: \(httpResponse.allHeaderFields)"
            }
        }
        
        if let error = error {
            logString += "\nERROR: \(error.localizedDescription)"
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                logString += "\nDATA: \(prettyString)"
            } else if let stringData = String(data: data, encoding: .utf8) {
                logString += "\nDATA: \(stringData)"
            } else {
                logString += "\nDATA: Binary data of size \(data.count) bytes"
            }
        }
        
        log(logString, category: .network)
    }
    
    /// Log an error
    func logError(_ error: Error, tag: String? = nil) {
        let errorMessage = "ERROR: \(error.localizedDescription)"
        
        if let networkError = error as? NetworkError {
            log(errorMessage, category: .network, tag: tag ?? "NETWORK_ERROR")
        } else {
            log(errorMessage, category: .error, tag: tag)
        }
    }
    
    /// Cache Logging
    func logCacheOperation(type: String, key: String, size: Int? = nil) {
        var message = "\(type) - Key: \(key)"
        if let size = size {
            message += ", Size: \(size) bytes"
        }
        log(message, category: .cache)
    }
    
    /// Authentication Logging
    func logAuthEvent(_ event: String, details: String? = nil) {
        var message = event
        if let details = details {
            message += " - \(details)"
        }
        log(message, category: .auth)
    }
    
    /// General purpose custom logging
    func logCustom(_ message: String, tag: String) {
        log(message, category: .custom, tag: tag)
    }
} 