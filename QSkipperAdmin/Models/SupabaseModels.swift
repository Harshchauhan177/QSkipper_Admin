import Foundation
import UIKit

// ============================================
// MARK: - Database Models (match Supabase tables)
// ============================================

/// Restaurant model matching the `restaurants` Supabase table
struct SupabaseRestaurant: Codable, Identifiable {
    var id: String?
    var ownerId: String?
    var name: String
    var cuisine: String
    var estimatedTime: Int
    var bannerImageUrl: String?
    var rating: Double?
    var isActive: Bool?
    var createdAt: String?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case cuisine
        case estimatedTime = "estimated_time"
        case bannerImageUrl = "banner_image_url"
        case rating
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Product model matching the `products` Supabase table
struct SupabaseProduct: Codable, Identifiable {
    var id: String?
    var restaurantId: String
    var name: String
    var price: Double
    var category: String
    var description: String
    var extraTime: Int
    var rating: Double?
    var isAvailable: Bool
    var isActive: Bool
    var isFeatured: Bool
    var imageUrl: String?
    var quantity: Int
    var topPicks: Bool
    var createdAt: String?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case name
        case price
        case category
        case description
        case extraTime = "extra_time"
        case rating
        case isAvailable = "is_available"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case imageUrl = "image_url"
        case quantity
        case topPicks = "top_picks"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Default initializer
    init(
        id: String? = nil,
        restaurantId: String,
        name: String = "",
        price: Double = 0,
        category: String = "",
        description: String = "",
        extraTime: Int = 0,
        rating: Double? = nil,
        isAvailable: Bool = true,
        isActive: Bool = true,
        isFeatured: Bool = false,
        imageUrl: String? = nil,
        quantity: Int = 0,
        topPicks: Bool = false,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.name = name
        self.price = price
        self.category = category
        self.description = description
        self.extraTime = extraTime
        self.rating = rating
        self.isAvailable = isAvailable
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.imageUrl = imageUrl
        self.quantity = quantity
        self.topPicks = topPicks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Order model matching the `orders` Supabase table
struct SupabaseOrder: Codable, Identifiable {
    var id: String?
    var restaurantId: String
    var userId: String
    var totalAmount: Double
    var status: String
    var cookTime: Int
    var takeAway: Bool
    var scheduleDate: String?
    var orderTime: String?
    var createdAt: String?
    var updatedAt: String?
    
    // Nested order items (loaded via join)
    var orderItems: [SupabaseOrderItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case userId = "user_id"
        case totalAmount = "total_amount"
        case status
        case cookTime = "cook_time"
        case takeAway = "take_away"
        case scheduleDate = "schedule_date"
        case orderTime = "order_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case orderItems = "order_items"
    }
    
    // MARK: - Computed Properties for UI
    
    var statusColor: String {
        switch status.lowercased() {
        case "placed", "pending": return "orange"
        case "schedule", "scheduled": return "green"
        case "preparing": return "purple"
        case "ready": return "green"
        case "completed": return "gray"
        case "cancelled": return "red"
        default: return "primary"
        }
    }
    
    var isScheduled: Bool {
        return scheduleDate != nil || status.lowercased().contains("schedule")
    }
    
    var totalAmountFormatted: String {
        return String(format: "₹%.2f", totalAmount)
    }
    
    var formattedDate: String {
        guard let orderTime = orderTime else { return "Recent order" }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: orderTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: orderTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Recent order"
    }
}

/// Order item model matching the `order_items` Supabase table
struct SupabaseOrderItem: Codable, Identifiable {
    var id: String?
    var orderId: String?
    var productId: String?
    var name: String
    var quantity: Int
    var price: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case name
        case quantity
        case price
    }
}

// ============================================
// MARK: - Insert Models (for creating new records, without id)
// ============================================

/// Used when inserting a new restaurant (id is auto-generated)
struct InsertRestaurant: Codable {
    let ownerId: String
    let name: String
    let cuisine: String
    let estimatedTime: Int
    let bannerImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case name
        case cuisine
        case estimatedTime = "estimated_time"
        case bannerImageUrl = "banner_image_url"
    }
}

/// Used when updating a restaurant
struct UpdateRestaurant: Codable {
    let name: String?
    let cuisine: String?
    let estimatedTime: Int?
    let bannerImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case cuisine
        case estimatedTime = "estimated_time"
        case bannerImageUrl = "banner_image_url"
    }
}

/// Used when inserting a new product (id is auto-generated)
struct InsertProduct: Codable {
    let restaurantId: String
    let name: String
    let price: Double
    let category: String
    let description: String
    let extraTime: Int
    let isAvailable: Bool
    let isFeatured: Bool
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case name
        case price
        case category
        case description
        case extraTime = "extra_time"
        case isAvailable = "is_available"
        case isFeatured = "is_featured"
        case imageUrl = "image_url"
    }
}

/// Used when updating a product
struct UpdateProduct: Codable {
    let name: String?
    let price: Double?
    let category: String?
    let description: String?
    let extraTime: Int?
    let isAvailable: Bool?
    let isFeatured: Bool?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case price
        case category
        case description
        case extraTime = "extra_time"
        case isAvailable = "is_available"
        case isFeatured = "is_featured"
        case imageUrl = "image_url"
    }
}

/// Used when updating order status
struct UpdateOrderStatus: Codable {
    let status: String
}
