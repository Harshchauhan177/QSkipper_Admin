import Foundation
import Combine
import SwiftUI
import Supabase

/// Supabase-powered order API
/// Replaces the old OrderApi that used URLSession + custom endpoints
class SupabaseOrderApi: ObservableObject {
    static let shared = SupabaseOrderApi()
    
    // MARK: - Published Properties
    @Published var orders: [SupabaseOrder] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    // MARK: - Private
    private let client = SupabaseConfig.client
    
    private init() {
        DebugLogger.shared.log("SupabaseOrderApi initialized", category: .app)
    }
    
    // MARK: - Fetch All Orders
    
    /// Fetch all orders for the current restaurant
    @MainActor
    func getAllOrders(restaurantId: String? = nil) async throws -> [SupabaseOrder] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Get restaurant ID
        let targetId = restaurantId
            ?? SupabaseAuthService.shared.getRestaurantId()
            ?? UserDefaults.standard.string(forKey: "restaurant_id")
            ?? ""
        
        guard !targetId.isEmpty else {
            DebugLogger.shared.log("No restaurant ID found, cannot fetch orders", category: .network)
            return []
        }
        
        // Fetch orders with nested order_items
        let result: [SupabaseOrder] = try await client
            .from(SupabaseConfig.Tables.orders)
            .select("*, order_items(*)")
            .eq("restaurant_id", value: targetId)
            .order("order_time", ascending: false)
            .execute()
            .value
        
        self.orders = result
        
        DebugLogger.shared.log("Fetched \(result.count) orders for restaurant: \(targetId)", category: .network)
        return result
    }
    
    // MARK: - Get Single Order
    
    /// Fetch a single order by ID
    func getOrder(orderId: String) async throws -> SupabaseOrder? {
        let result: [SupabaseOrder] = try await client
            .from(SupabaseConfig.Tables.orders)
            .select("*, order_items(*)")
            .eq("id", value: orderId)
            .execute()
            .value
        
        return result.first
    }
    
    // MARK: - Update Order Status
    
    /// Update the status of an order (e.g., pending → preparing → ready → completed)
    @MainActor
    func updateOrderStatus(orderId: String, newStatus: String) async throws -> Bool {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        let updateData = UpdateOrderStatus(status: newStatus)
        
        try await client
            .from(SupabaseConfig.Tables.orders)
            .update(updateData)
            .eq("id", value: orderId)
            .execute()
        
        // Update local array
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            orders[index].status = newStatus
        }
        
        DebugLogger.shared.log("Order \(orderId) status updated to: \(newStatus)", category: .network)
        return true
    }
    
    // MARK: - Complete Order
    
    /// Mark an order as completed
    @MainActor
    func completeOrder(orderId: String) async throws -> Bool {
        return try await updateOrderStatus(orderId: orderId, newStatus: "completed")
    }
    
    // MARK: - Cancel Order
    
    /// Cancel an order
    @MainActor
    func cancelOrder(orderId: String) async throws -> Bool {
        return try await updateOrderStatus(orderId: orderId, newStatus: "cancelled")
    }
    
    // MARK: - Accept Order
    
    /// Accept a pending order
    @MainActor
    func acceptOrder(orderId: String) async throws -> Bool {
        return try await updateOrderStatus(orderId: orderId, newStatus: "preparing")
    }
    
    // MARK: - Mark Order Ready
    
    /// Mark an order as ready for pickup
    @MainActor
    func markOrderReady(orderId: String) async throws -> Bool {
        return try await updateOrderStatus(orderId: orderId, newStatus: "ready")
    }
    
    // MARK: - Get Orders by Status
    
    /// Get orders filtered by status
    @MainActor
    func getOrdersByStatus(status: String) async throws -> [SupabaseOrder] {
        let targetId = SupabaseAuthService.shared.getRestaurantId()
            ?? UserDefaults.standard.string(forKey: "restaurant_id")
            ?? ""
        
        guard !targetId.isEmpty else { return [] }
        
        let result: [SupabaseOrder] = try await client
            .from(SupabaseConfig.Tables.orders)
            .select("*, order_items(*)")
            .eq("restaurant_id", value: targetId)
            .eq("status", value: status)
            .order("order_time", ascending: false)
            .execute()
            .value
        
        return result
    }
    
    // MARK: - Order Statistics
    
    /// Get count of orders by status
    func getOrderCounts() async -> (pending: Int, preparing: Int, ready: Int, completed: Int) {
        do {
            let allOrders = try await getAllOrders()
            
            let pending = allOrders.filter { $0.status.lowercased() == "pending" || $0.status.lowercased() == "placed" }.count
            let preparing = allOrders.filter { $0.status.lowercased() == "preparing" }.count
            let ready = allOrders.filter { $0.status.lowercased() == "ready" }.count
            let completed = allOrders.filter { $0.status.lowercased() == "completed" }.count
            
            return (pending, preparing, ready, completed)
        } catch {
            DebugLogger.shared.logError(error, tag: "ORDER_COUNTS")
            return (0, 0, 0, 0)
        }
    }
}
