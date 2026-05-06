import Foundation
import Combine
import SwiftUI

// MARK: - Order API Errors
enum OrderApiError: Error {
    case invalidURL
    case networkError
    case orderNotFound
    case serverError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL provided"
        case .networkError: return "Network error occurred"
        case .orderNotFound: return "Order not found"
        case .serverError: return "Server error occurred"
        }
    }
}

// MARK: - Order Response Models
struct APIOrderResponse: Codable {
    let length: Int
    let allOrders: [APIOrder]
    
    enum CodingKeys: String, CodingKey {
        case length
        case allOrders = "all_orders"
    }
}

// MARK: - Order Item Model
struct APIOrder: Codable, Identifiable {
    let id: String
    let restaurantId: String
    let userId: String
    let items: [APIOrderProduct]
    let totalAmount: String
    var status: String
    let cookTime: Int
    let takeAway: Bool
    let scheduleDate: String?
    let orderTime: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case restaurantId = "resturant"
        case userId = "userID"
        case items
        case totalAmount
        case status
        case cookTime
        case takeAway
        case scheduleDate
        case orderTime = "Time"
    }
    
    // MARK: - Private Date Parsing Methods
    
    // Helper function to parse ISO date strings flexibly
    func parseISODateString(_ dateString: String) -> Date? {
        // Standard ISO format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try alternative formats
        let alternativeFormatters = [
            // ISO8601 with fractional seconds
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            // Standard format with Z timezone
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                f.timeZone = TimeZone(abbreviation: "UTC")
                return f
            }(),
            // Without milliseconds
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                f.timeZone = TimeZone(abbreviation: "UTC")
                return f
            }(),
            // With timezone offset
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return f
            }(),
            // With timezone offset and milliseconds
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return f
            }(),
            // Simple date only
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f
            }(),
            // Date with time, no timezone
            { () -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                f.timeZone = TimeZone.current
                return f
            }()
        ]
        
        for formatter in alternativeFormatters {
            if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ?? 
                         (formatter as? DateFormatter)?.date(from: dateString) {
                return date
            }
        }
        
        // Log the problematic date string
        DebugLogger.shared.log("Failed to parse date: \(dateString)", category: .error)
        
        return nil
    }
    
    // Helper to format a date for display
    func formatDateForDisplay(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    // Computed properties for UI
    
    // Get scheduled date and time (when the order should be fulfilled)
    var scheduledDateTime: (date: Date?, displayString: String) {
        if let scheduleDateStr = scheduleDate {
            if let date = parseISODateString(scheduleDateStr) {
                return (date, formatDateForDisplay(date))
            }
        }
        return (nil, "Not scheduled")
    }
    
    // Get order time (when the order was placed)
    var orderDateTime: (date: Date?, displayString: String) {
        if let date = parseISODateString(orderTime) {
            return (date, formatDateForDisplay(date))
        }
        return (nil, "Recent order")
    }
    
    // Smart formatted display for the primary date to show
    var formattedDate: String {
        if isScheduled, let date = scheduledDateTime.date {
            // Highlight scheduled date for scheduled orders
            return "Deliver on \(scheduledDateTime.displayString)"
        } else if let date = orderDateTime.date {
            return orderDateTime.displayString
        } else {
            // Log detailed information about the date fields for debugging
            DebugLogger.shared.log("No valid date could be parsed for order \(id)", category: .error)
            DebugLogger.shared.log("Order time string: \(orderTime)", category: .error)
            if let scheduleStr = scheduleDate {
                DebugLogger.shared.log("Schedule date string: \(scheduleStr)", category: .error)
            }
            return "Recent order"
        }
    }
    
    // Formatted string for order time (when placed)
    var formattedOrderTime: String {
        if let date = orderDateTime.date {
            return "Ordered on \(orderDateTime.displayString)"
        } else {
            DebugLogger.shared.log("Could not parse order time for order \(id): \(orderTime)", category: .error)
            return "Recently ordered"
        }
    }
    
    // Formatted string for scheduled time (when to deliver)
    var formattedScheduleTime: String? {
        guard isScheduled else { return nil }
        return "Scheduled for: \(scheduledDateTime.displayString)"
    }
    
    // Time remaining until scheduled delivery
    var timeUntilScheduled: String? {
        guard isScheduled, let scheduleDate = scheduledDateTime.date else { return nil }
        
        let now = Date()
        if scheduleDate < now {
            return "Delivery time passed"
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: scheduleDate)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") until delivery"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") until delivery"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") until delivery"
        }
        
        return "Delivery time now"
    }
    
    var statusColor: Color {
        switch status.lowercased() {
        case "placed", "pending": return .orange
        case "schedule", "scheduled": return .green
        case "preparing": return .purple
        case "ready": return .green
        case "completed": return .gray
        case "cancelled": return .red
        default: return .primary
        }
    }
    
    var isScheduled: Bool {
        return scheduleDate != nil || status.lowercased().contains("schedule")
    }
    
    var totalAmountFormatted: String {
        if let amount = Double(totalAmount) {
            return String(format: "₹%.2f", amount)
        }
        return totalAmount
    }
}

// MARK: - Order Product Model
struct APIOrderProduct: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let price: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case quantity
        case price
    }
}

// MARK: - OrderApi Class
class OrderApi {
    static let shared = OrderApi()
    
    // Base URL
    private let baseUrl = URL(string: NetworkManager.baseURL)!
    
    private init() {}
    
    // MARK: - Fetch Orders
    
    /// Fetch all orders for the restaurant
    /// - Returns: A list of orders
    func getAllOrders() async throws -> [APIOrder] {
        // Try to get the restaurant ID from multiple sources to ensure we're using the correct one
        var restaurantId = ""
        
        // First try to get from UserDefaults since that's most reliable for restaurant ID
        if let storedRestaurantId = UserDefaults.standard.string(forKey: "restaurant_id"), !storedRestaurantId.isEmpty {
            restaurantId = storedRestaurantId
            DebugLogger.shared.log("Using restaurant ID from UserDefaults: \(restaurantId)", category: .network)
        }
        // Then try from DataController
        else if !DataController.shared.restaurant.id.isEmpty {
            restaurantId = DataController.shared.restaurant.id
            DebugLogger.shared.log("Using restaurant ID from DataController: \(restaurantId)", category: .network)
        }
        // Finally try from auth service
        else if let user = AuthService.shared.currentUser, !user.restaurantId.isEmpty {
            restaurantId = user.restaurantId
            DebugLogger.shared.log("Using restaurant ID from auth service: \(restaurantId)", category: .network)
        }
        
        // Ensure we have a restaurant ID
        if restaurantId.isEmpty {
            DebugLogger.shared.log("No restaurant ID found, cannot fetch orders", category: .network)
            throw NSError(domain: "OrderApi", code: 400, userInfo: [NSLocalizedDescriptionKey: "Restaurant ID not found"])
        }
        
        let orderUrl = baseUrl.appendingPathComponent("get-order/\(restaurantId)")
        
        var request = URLRequest(url: orderUrl)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Add auth token if available
        if let token = AuthService.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        DebugLogger.shared.log("Fetching orders for restaurant: \(restaurantId)", category: .network)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let string = String(data: data, encoding: .utf8) {
                DebugLogger.shared.log("Orders response data: \(string.prefix(500))", category: .network)
                
                // Handle HTML error responses
                if string.contains("<!DOCTYPE html>") || string.contains("<html") {
                    // This is an HTML error page, not JSON data
                    DebugLogger.shared.log("Received HTML error page instead of JSON data (likely a server issue)", category: .error)
                    
                    // If it contains something about "Cannot GET", assume the endpoint is incorrect
                    if string.contains("Cannot GET") {
                        DebugLogger.shared.log("Endpoint not found on server: \(orderUrl.absoluteString)", category: .error)
                        // Return empty array instead of throwing an error
                        return []
                    }
                    
                    // For other HTML errors, return empty array - this is more user-friendly
                    // than showing a generic error
                    return []
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OrderApiError.networkError
            }
            
            // Handle 404 (No orders found) as a valid empty array response
            if httpResponse.statusCode == 404 {
                // Check if the response contains "No orders found" message
                if let string = String(data: data, encoding: .utf8),
                   string.contains("No orders found") {
                    DebugLogger.shared.log("No orders found for restaurant (404 response)", category: .network)
                    return [] // Return empty array instead of throwing an error
                }
                
                // Any other 404 response for orders
                DebugLogger.shared.log("404 response for orders endpoint - assuming no orders", category: .network)
                return [] // Return empty array for any 404
            }
            
            guard httpResponse.statusCode == 200 else {
                // For any non-200 status code (that isn't 404), log but return empty array
                // to avoid showing errors to the user when the "No Orders" UI is sufficient
                DebugLogger.shared.log("Unexpected status code: \(httpResponse.statusCode) - returning empty array", category: .error)
                return []
            }
            
            // Now attempt to decode the response
            do {
                let decoder = JSONDecoder()
                let orderResponse = try decoder.decode(APIOrderResponse.self, from: data)
                
                DebugLogger.shared.log("Successfully loaded \(orderResponse.allOrders.count) orders", category: .network)
                return orderResponse.allOrders
            } catch {
                // If we can't decode the response but still got a 200 OK,
                // check if it's a message about no orders
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String,
                   message.contains("No orders") {
                    DebugLogger.shared.log("Message response instead of orders array: \(message)", category: .network)
                    return [] // Return empty array
                }
                
                // Otherwise rethrow the decoding error
                throw error
            }
        } catch {
            // Special handling for JSON decoding errors that might be due to a 404 response
            // that was formatted as a message response rather than our expected order format
            if let decodingError = error as? DecodingError {
                // Try to parse as a simple message response
                if let data = try? await URLSession.shared.data(for: request).0,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String,
                   message.contains("No orders") {
                    DebugLogger.shared.log("No orders found message detected, returning empty array", category: .network)
                    return [] // Return empty array instead of throwing an error
                }
            }
            
            // For URLs that don't exist on the server (like missing trailing slash)
            if let urlError = error as? URLError, urlError.code == .cannotFindHost || urlError.code == .cannotConnectToHost {
                DebugLogger.shared.log("Cannot connect to host or find server: \(urlError.localizedDescription)", category: .error)
                // Return empty array instead of showing an error
                return []
            }
            
            DebugLogger.shared.log("Failed to load orders: \(error.localizedDescription)", category: .error)
            throw error
        }
    }
    
    // MARK: - Complete Order
    
    /// Mark an order as completed
    /// - Parameter orderId: The ID of the order to complete
    /// - Returns: A boolean indicating success
    func completeOrder(orderId: String) async throws -> Bool {
        let orderUrl = baseUrl.appendingPathComponent("order-complete/\(orderId)")
        
        var request = URLRequest(url: orderUrl)
        request.httpMethod = "PUT"
        
        // Add auth token if available
        if let token = AuthService.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        DebugLogger.shared.log("Completing order: \(orderId)", category: .network)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let string = String(data: data, encoding: .utf8) {
                DebugLogger.shared.log("Complete order response: \(string)", category: .network)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OrderApiError.networkError
            }
            
            guard httpResponse.statusCode == 202 || httpResponse.statusCode == 200 else {
                switch httpResponse.statusCode {
                case 404: throw OrderApiError.orderNotFound
                default: throw OrderApiError.serverError
                }
            }
            
            return true
        } catch {
            DebugLogger.shared.log("Failed to complete order: \(error.localizedDescription)", category: .error)
            throw error
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Logs the raw date format from either a specific order or all orders for debugging purposes
    /// - Parameter orderId: Optional - The order ID to inspect. If nil, will debug all orders.
    func debugOrderDateFormat(orderId: String? = nil) async {
        do {
            let orders = try await getAllOrders()
            
            if let orderId = orderId, let order = orders.first(where: { $0.id == orderId }) {
                // Debug a specific order
                logOrderDateDetails(order)
            } else if orderId == nil {
                // Debug all orders
                DebugLogger.shared.log("===== DEBUGGING ALL ORDERS DATE FORMATS =====", category: .debug)
                for order in orders {
                    logOrderDateDetails(order)
                }
                DebugLogger.shared.log("===== END DEBUGGING ALL ORDERS =====", category: .debug)
            } else {
                DebugLogger.shared.log("Order not found for debugging: \(orderId ?? "unknown")", category: .error)
            }
        } catch {
            DebugLogger.shared.log("Error debugging order date format: \(error.localizedDescription)", category: .error)
        }
    }
    
    // Helper to log date details for a specific order
    private func logOrderDateDetails(_ order: APIOrder) {
        DebugLogger.shared.log("===== DEBUG ORDER DATE FORMAT =====", category: .debug)
        DebugLogger.shared.log("Order ID: \(order.id)", category: .debug)
        DebugLogger.shared.log("Raw orderTime: \(order.orderTime)", category: .debug)
        if let scheduleDate = order.scheduleDate {
            DebugLogger.shared.log("Raw scheduleDate: \(scheduleDate)", category: .debug)
        }
        
        // Try to parse with the helper
        if let parsedOrderTime = order.parseISODateString(order.orderTime) {
            DebugLogger.shared.log("Successfully parsed orderTime: \(parsedOrderTime)", category: .debug)
        } else {
            DebugLogger.shared.log("FAILED to parse orderTime", category: .error)
        }
        
        if let scheduleDate = order.scheduleDate, 
           let parsedScheduleDate = order.parseISODateString(scheduleDate) {
            DebugLogger.shared.log("Successfully parsed scheduleDate: \(parsedScheduleDate)", category: .debug)
        } else if order.scheduleDate != nil {
            DebugLogger.shared.log("FAILED to parse scheduleDate", category: .error)
        }
        
        DebugLogger.shared.log("===== END DEBUG =====", category: .debug)
    }
}

// Add Color extension to avoid compiler error
extension Color {
    static var orange: Color { Color(.orange) }
    static var blue: Color { Color(.blue) }
    static var purple: Color { Color(.purple) }
    static var green: Color { Color(.green) }
    static var gray: Color { Color(.gray) }
    static var red: Color { Color(.red) }
    static var primary: Color { Color(.label) }
} 