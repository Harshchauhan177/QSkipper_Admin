import Foundation
import Combine

class OrderService: ObservableObject {
    // Shared instance
    static let shared = OrderService()
    
    // Published properties
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    // API endpoints
    private struct Endpoints {
        static let baseURL = NetworkManager.baseURL
        static let orders = "\(baseURL)/orders"
        static let restaurant = "\(baseURL)/orders/restaurant"
    }
    
    // Cache for orders
    private var cachedOrders: [Order]?
    private var lastCacheTime: Date?
    private let cacheValidityInterval: TimeInterval = 60 // 1 minute cache validity
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Fetch all orders for a restaurant
    /// - Parameter restaurantId: The restaurant ID
    func fetchRestaurantOrders(restaurantId: String) {
        isLoading = true
        error = nil
        
        // Try to get the correct restaurant ID
        var targetRestaurantId = restaurantId
        
        // If empty, try to get from UserDefaults
        if targetRestaurantId.isEmpty, 
           let storedRestaurantId = UserDefaults.standard.string(forKey: "restaurant_id"), 
           !storedRestaurantId.isEmpty {
            targetRestaurantId = storedRestaurantId
            DebugLogger.shared.log("Using restaurant ID from UserDefaults: \(targetRestaurantId)", category: .network)
        }
        
        // Ensure we have a restaurant ID
        if targetRestaurantId.isEmpty {
            self.error = "Restaurant ID not found"
            self.isLoading = false
            DebugLogger.shared.log("No restaurant ID found, cannot fetch orders", category: .network)
            return
        }
        
        let url = URL(string: "\(Endpoints.restaurant)/\(targetRestaurantId)")!
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OrderResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = "Failed to load orders: \(err.localizedDescription)"
                    print("Error fetching orders: \(err)")
                }
            } receiveValue: { [weak self] response in
                self?.orders = response.orders
                
                // Update cache
                self?.cachedOrders = response.orders
                self?.lastCacheTime = Date()
            }
            .store(in: &cancellables)
    }
    
    /// Update order status
    /// - Parameters:
    ///   - orderId: The order ID
    ///   - status: The new status
    ///   - completion: Completion handler with result
    func updateOrderStatus(orderId: String, status: String, completion: @escaping (Result<Order, Error>) -> Void) {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(Endpoints.orders)/\(orderId)/status") else {
            error = "Invalid URL"
            completion(.failure(NSError(domain: "OrderService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create body
        let body: [String: Any] = [
            "status": status
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.error = "Failed to encode status update: \(error.localizedDescription)"
            completion(.failure(error))
            return
        }
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: OrderResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = "Failed to update order: \(err.localizedDescription)"
                    print("Error updating order: \(err)")
                }
            } receiveValue: { [weak self] response in
                if let updatedOrder = response.orders.first {
                    if let index = self?.orders.firstIndex(where: { $0.id == updatedOrder.id }) {
                        self?.orders[index] = updatedOrder
                    }
                    completion(.success(updatedOrder))
                    
                    // Update cache
                    if let cachedOrders = self?.cachedOrders,
                       let index = cachedOrders.firstIndex(where: { $0.id == updatedOrder.id }) {
                        var updatedCache = cachedOrders
                        updatedCache[index] = updatedOrder
                        self?.cachedOrders = updatedCache
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Get order details
    /// - Parameters:
    ///   - orderId: The order ID
    ///   - completion: Completion handler with result
    func getOrderDetails(orderId: String, completion: @escaping (Result<Order, Error>) -> Void) {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(Endpoints.orders)/\(orderId)") else {
            error = "Invalid URL"
            completion(.failure(NSError(domain: "OrderService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SingleOrderResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let err):
                    self?.error = "Failed to get order details: \(err.localizedDescription)"
                    print("Error getting order details: \(err)")
                case .finished:
                    break
                }
            } receiveValue: { response in
                if let order = response.order {
                    completion(.success(order))
                } else {
                    completion(.failure(NSError(domain: "OrderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Order not found"])))
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Compatibility with Old OrderService Implementation
    
    /// Get orders from the server or cache
    /// - Returns: Array of orders
    func getOrders() async throws -> [Order] {
        // Check authentication state directly from the shared instance
        guard AuthService.shared.isAuthenticated else {
            DebugLogger.shared.log("User is not authenticated in getOrders()", category: .auth)
            throw NSError(domain: "OrderService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get the user ID
        guard let userId = AuthService.shared.getUserId() else {
            DebugLogger.shared.log("No user ID found in getOrders()", category: .auth) 
            throw NSError(domain: "OrderService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
        }
        
        do {
            let response: OrderResponse = try await NetworkManager.shared.performRequest(
                endpoint: "/get-order/\(userId)",
                method: "GET"
            )
            
            // Update our published property and cache
            DispatchQueue.main.async { [weak self] in
                self?.orders = response.orders
                self?.cachedOrders = response.orders
                self?.lastCacheTime = Date()
            }
            
            return response.orders
        } catch {
            throw error
        }
    }
    
    /// Get cached orders if available and still valid
    /// - Returns: Array of cached orders
    func getCachedOrders() async throws -> [Order] {
        // If we have a valid cache, return it
        if let cachedOrders = cachedOrders,
           let lastCacheTime = lastCacheTime,
           Date().timeIntervalSince(lastCacheTime) < cacheValidityInterval {
            return cachedOrders
        }
        
        // Otherwise fetch new data
        return try await getOrders()
    }
    
    /// Invalidate the order cache
    func invalidateOrderCache() {
        cachedOrders = nil
        lastCacheTime = nil
    }
    
    /// Complete an order
    /// - Parameter orderId: The order ID
    /// - Returns: Success boolean
    func completeOrder(orderId: String) async throws -> Bool {
        do {
            let response: CompleteOrderResponse = try await NetworkManager.shared.performRequest(
                endpoint: "/order-complete/\(orderId)",
                method: "POST"
            )
            
            // If successful, update our cache
            if response.success {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Update the order in our list
                    if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                        var updatedOrder = self.orders[index]
                        updatedOrder.status = "completed"
                        self.orders[index] = updatedOrder
                    }
                    
                    // Update cache if needed
                    if let cachedOrders = self.cachedOrders,
                       let index = cachedOrders.firstIndex(where: { $0.id == orderId }) {
                        var updatedCache = cachedOrders
                        var updatedOrder = updatedCache[index]
                        updatedOrder.status = "completed"
                        updatedCache[index] = updatedOrder
                        self.cachedOrders = updatedCache
                    }
                }
            }
            
            return response.success
        } catch {
            throw error
        }
    }
}

// MARK: - Response Models
struct OrderResponse: Codable {
    var orders: [Order]
}

// Response for a single order
struct SingleOrderResponse: Codable {
    var order: Order?
} 