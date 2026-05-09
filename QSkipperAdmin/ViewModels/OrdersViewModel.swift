import Foundation
import SwiftUI
import Combine

// Modern version of OrdersViewModel used with ModernOrdersView
class ModernOrdersViewModel: ObservableObject {
    // Published properties
    @Published var orders: [APIOrder] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    @Published var selectedFilter: OrderFilter = .all
    @Published var completionSuccess: Bool = false
    @Published var processingOrderId: String? = nil
    
    // Order filter options
    enum OrderFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case scheduled = "Scheduled"
        case completed = "Completed"
        
        var id: String { self.rawValue }
    }
    
    // Filtered orders based on selection
    var filteredOrders: [APIOrder] {
        let filtered: [APIOrder]
        switch selectedFilter {
        case .all:
            filtered = orders
        case .pending:
            filtered = orders.filter { $0.status.lowercased() == "placed" || $0.status.lowercased() == "pending" }
        case .scheduled:
            filtered = orders.filter { $0.status.lowercased() == "schedule" || $0.status.lowercased() == "scheduled" }
        case .completed:
            filtered = orders.filter { $0.status.lowercased() == "completed" }
        }
        
        // Log the filter results for debugging
        DebugLogger.shared.log("Filter: \(selectedFilter.rawValue), Total orders: \(orders.count), Filtered count: \(filtered.count)", category: .app)
        if orders.count > 0 {
            let statusCounts = Dictionary(grouping: orders, by: { $0.status.lowercased() })
                .mapValues { $0.count }
            DebugLogger.shared.log("Status distribution: \(statusCounts)", category: .app)
        }
        
        return filtered
    }
    
    // Sort orders by date (most recent first)
    var sortedOrders: [APIOrder] {
        return filteredOrders.sorted { (order1, order2) -> Bool in
            // First sort scheduled orders to the top
            let isScheduled1 = order1.isScheduled
            let isScheduled2 = order2.isScheduled
            
            if isScheduled1 && !isScheduled2 {
                return true
            } else if !isScheduled1 && isScheduled2 {
                return false
            }
            
            // Then sort by date
            if let date1 = getOrderDate(order1),
               let date2 = getOrderDate(order2) {
                return date1 > date2
            }
            return false
        }
    }
    
    // Helper to get the appropriate date from an order
    private func getOrderDate(_ order: APIOrder) -> Date? {
        // If it's a scheduled order, use schedule date
        if let scheduleString = order.scheduleDate {
            return order.parseISODateString(scheduleString)
        }
        
        // Otherwise use order time
        return order.parseISODateString(order.orderTime)
    }
    
    // MARK: - Lifecycle
    
    init() {
        // Load orders immediately
        Task {
            await loadOrders()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load all orders from Supabase
    func loadOrders() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let supabaseOrders = try await SupabaseOrderApi.shared.getAllOrders()
            
            // Convert SupabaseOrder to APIOrder for view compatibility
            let convertedOrders = supabaseOrders.map { self.convertToAPIOrder($0) }
            
            await MainActor.run {
                self.orders = convertedOrders
                self.isLoading = false
                DebugLogger.shared.log("Loaded \(convertedOrders.count) orders from Supabase", category: .app)
                if !convertedOrders.isEmpty {
                    DebugLogger.shared.log("Sample order status: \(convertedOrders[0].status)", category: .app)
                }
            }
        } catch {
            await MainActor.run {
                self.orders = []
                self.errorMessage = error.localizedDescription
                
                if error.localizedDescription.contains("not found") || 
                   error.localizedDescription.contains("No orders") ||
                   error.localizedDescription.contains("0 rows") {
                    self.showError = false
                    DebugLogger.shared.log("No orders found (handled gracefully)", category: .app)
                } else {
                    self.showError = true
                    DebugLogger.shared.log("Error loading orders: \(error.localizedDescription)", category: .error)
                }
                
                self.isLoading = false
            }
        }
    }
    
    /// Convert SupabaseOrder to APIOrder for view compatibility
    private func convertToAPIOrder(_ order: SupabaseOrder) -> APIOrder {
        let items = (order.orderItems ?? []).map { item in
            APIOrderProduct(
                id: item.id ?? "",
                name: item.name,
                quantity: item.quantity,
                price: Int(item.price)
            )
        }
        
        return APIOrder(
            id: order.id ?? "",
            restaurantId: order.restaurantId,
            userId: order.userId,
            items: items,
            totalAmount: String(format: "%.2f", order.totalAmount),
            status: order.status,
            cookTime: order.cookTime,
            takeAway: order.takeAway,
            scheduleDate: order.scheduleDate,
            orderTime: order.orderTime ?? ""
        )
    }
    
    /// Mark an order as complete
    /// - Parameter order: The order to complete
    func completeOrder(_ order: APIOrder) async {
        // To prevent double completion, check if we're already processing this order
        if processingOrderId == order.id {
            return
        }
        
        await MainActor.run {
            // Indicate we're processing this specific order (for the button)
            processingOrderId = order.id
            
            // Update the order status immediately in UI for better user experience
            if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
                // Make a copy, update it, and replace it to ensure SwiftUI picks up the change
                var updatedOrder = self.orders[index]
                updatedOrder.status = "Completed"
                self.orders[index] = updatedOrder
            }
        }
        
        do {
            let success = try await SupabaseOrderApi.shared.completeOrder(orderId: order.id)
            
            await MainActor.run {
                // Clear processing state
                self.processingOrderId = nil
            
            if success {
                    // Show success notification
                    self.completionSuccess = true
                    
                    // Schedule hiding the notification
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.completionSuccess = false
                    }
                    
                    DebugLogger.shared.log("Order \(order.id) marked as completed", category: .app)
                } else {
                    // If the API call failed, revert the order status
                    if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
                        var revertedOrder = self.orders[index]
                        revertedOrder.status = order.status // Original status
                        self.orders[index] = revertedOrder
                    }
                    
                    self.errorMessage = "Failed to complete order. Please try again."
                    self.showError = true
                    DebugLogger.shared.log("Failed to complete order: API returned false", category: .error)
                }
            }
        } catch {
            await MainActor.run {
                // Clear processing state
                self.processingOrderId = nil
                
                // Revert order status if the API call failed
                if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
                    var revertedOrder = self.orders[index]
                    revertedOrder.status = order.status // Original status
                    self.orders[index] = revertedOrder
                }
                
                self.errorMessage = "Failed to complete order: \(error.localizedDescription)"
                self.showError = true
                DebugLogger.shared.log("Error completing order: \(error.localizedDescription)", category: .error)
            }
        }
    }
    
    /// Check if an order is currently being processed
    func isProcessing(_ order: APIOrder) -> Bool {
        return processingOrderId == order.id
    }
    
    /// Reload orders (for pull-to-refresh)
    func refreshOrders() async {
        await loadOrders()
    }
    
    /// Debug the date format for orders
    /// - Parameter orderId: Optional - The ID of the order to debug. If nil, will debug all orders.
    func debugOrderDateFormat(orderId: String? = nil) {
        // Debug function - no longer needed with Supabase
        Task {
            DebugLogger.shared.log("Debug order dates - using Supabase, dates are ISO 8601", category: .app)
        }
    }
} 