import Foundation
import UIKit
import Combine

/// NetworkUtils - A utility class for network operations and debugging
class NetworkUtils {
    static let shared = NetworkUtils()
    
    private let apiClient = APIClient.shared
    private init() {
        DebugLogger.shared.log("NetworkUtils initialized", category: .app)
    }
    
    /// Fetch product menu for a restaurant
    /// - Parameter restaurantId: The restaurant ID
    /// - Returns: Array of products
    func fetchProducts(for restaurantId: String) async throws -> [Product] {
        DebugLogger.shared.log("📡 NetworkUtils: Delegating fetchMenu to APIClient for restaurant: \(restaurantId)", category: .network, tag: "NETWORK_UTILS_FETCH")
        
        // Log the request details more verbosely
        let requestUrl = "\(NetworkManager.baseURL)/get_all_product/\(restaurantId)"
        DebugLogger.shared.log("📡 Full URL: \(requestUrl) (Server: \(URL(string: requestUrl)?.host ?? "unknown"))", category: .network, tag: "FETCH_PRODUCTS_REQUEST")
        
        // Instead of using the ProductApi directly, we'll add an intercept through APIClient
        return try await APIClient.shared.fetchProducts(restaurantId: restaurantId)
    }
    
    /// Create a new product
    /// - Parameters:
    ///   - product: The product to create
    ///   - image: Optional product image
    /// - Returns: Created product
    func createProduct(product: Product, image: UIImage? = nil) async throws -> Product {
        DebugLogger.shared.log("📡 NetworkUtils: Delegating createProduct to APIClient for restaurant: \(product.restaurantId)", category: .network, tag: "NETWORK_UTILS_CREATE")
        
        // Complete request details
        let requestUrl = "\(NetworkManager.baseURL)/create-product"
        DebugLogger.shared.log("📡 CREATE URL: \(requestUrl)", category: .network, tag: "CREATE_PRODUCT_REQUEST")
        
        // Dump entire product object for debugging
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let productJson = try? encoder.encode(product),
           let jsonString = String(data: productJson, encoding: .utf8) {
            DebugLogger.shared.log("📡 Product payload: \(jsonString)", category: .network, tag: "CREATE_PRODUCT_PAYLOAD")
        }
        
        return try await APIClient.shared.createProduct(product: product, image: image)
    }
    
    /// Register a new restaurant
    /// - Parameter restaurant: Restaurant data
    /// - Returns: Registered restaurant
    func registerRestaurant(restaurant: Restaurant) async throws -> Restaurant {
        DebugLogger.shared.log("📡 NetworkUtils: Delegating registerRestaurant to APIClient", category: .network, tag: "NETWORK_UTILS_REGISTER")
        
        // Log the restaurant details
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let restaurantJson = try? encoder.encode(restaurant),
           let jsonString = String(data: restaurantJson, encoding: .utf8) {
            DebugLogger.shared.log("📡 Restaurant payload: \(jsonString)", category: .network, tag: "REGISTER_RESTAURANT_PAYLOAD")
        }
        
        return try await APIClient.shared.registerRestaurant(restaurant: restaurant)
    }
    
    /// Login a restaurant
    /// - Parameters:
    ///   - email: Restaurant email
    ///   - password: Restaurant password
    /// - Returns: UserResponse
    func loginRestaurant(email: String, password: String) async throws -> UserResponse {
        DebugLogger.shared.log("📡 NetworkUtils: Delegating loginRestaurant to APIClient", category: .network, tag: "NETWORK_UTILS_LOGIN")
        
        // Log login details (without password)
        DebugLogger.shared.log("📡 Login attempt for: \(email)", category: .network, tag: "LOGIN_REQUEST")
        
        return try await APIClient.shared.loginRestaurant(email: email, password: password)
    }
} 