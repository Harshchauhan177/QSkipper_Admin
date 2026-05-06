import Foundation

// MARK: - Full Order Response
struct FullOrderResponse: Codable {
    var length: Int
    var orders: [Order]
    
    enum CodingKeys: String, CodingKey {
        case length
        case orders = "all_orders"
    }
}

// MARK: - Order Model
struct Order: Codable, Identifiable {
    var id: String
    var status: String
    var totalAmount: Double
    var items: [OrderItem]
    var products: [OrderProduct]
    var createdAt: Date
    var userId: String
    var restaurantId: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status
        case totalAmount = "totalPrice"
        case items
        case products
        case createdAt = "createdAt"
        case userId
        case restaurantId
    }
    
    // Computed property for formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    // Order statuses
    enum Status: String, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case preparing = "preparing"
        case ready = "ready"
        case completed = "completed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "Accepted"
            case .preparing: return "Preparing"
            case .ready: return "Ready"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "#FFA500" // Orange
            case .accepted: return "#1E90FF" // Blue
            case .preparing: return "#9932CC" // Purple
            case .ready: return "#008000" // Green
            case .completed: return "#006400" // Dark Green
            case .cancelled: return "#FF0000" // Red
            }
        }
    }
    
    // Updated init with proper types and default values
    init(id: String, userId: String, restaurantId: String, products: [OrderProduct], totalAmount: Double, status: String, createdAt: String, updatedAt: String) {
        self.id = id
        self.userId = userId
        self.restaurantId = restaurantId
        self.products = products
        self.totalAmount = totalAmount
        self.status = status
        
        // Default empty array for items since we're using products
        self.items = []
        
        // Parse the date string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAt) {
            self.createdAt = date
        } else {
            // Fallback to simpler formatter if the date string doesn't have fractional seconds
            let simpleFormatter = ISO8601DateFormatter()
            if let date = simpleFormatter.date(from: createdAt) {
                self.createdAt = date
            } else {
                self.createdAt = Date() // Default to current date if parsing fails
            }
        }
    }
    
    // Additional initializer for compatibility with old code
    init(id: String, status: String, totalAmount: Double, items: [OrderItem], products: [OrderProduct] = [], createdAt: Date = Date(), userId: String = "", restaurantId: String = "") {
        self.id = id
        self.status = status
        self.totalAmount = totalAmount
        self.items = items
        self.products = products
        self.createdAt = createdAt
        self.userId = userId
        self.restaurantId = restaurantId
    }
    
    // Decoder init to handle both Int and Double for totalAmount
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(String.self, forKey: .status)
        items = try container.decodeIfPresent([OrderItem].self, forKey: .items) ?? []
        products = try container.decodeIfPresent([OrderProduct].self, forKey: .products) ?? []
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        restaurantId = try container.decodeIfPresent(String.self, forKey: .restaurantId) ?? ""
        
        // Handle createdAt as either Date or String
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try with simpler format
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: dateString) {
                    createdAt = date
                } else {
                    // Last resort: default to current date
                    createdAt = Date()
                }
            }
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        // Handle both Int and Double for totalAmount
        if let intAmount = try? container.decode(Int.self, forKey: .totalAmount) {
            totalAmount = Double(intAmount)
        } else if let doubleAmount = try? container.decode(Double.self, forKey: .totalAmount) {
            totalAmount = doubleAmount
        } else {
            totalAmount = 0.0
        }
    }
}

// MARK: - Order Item
struct OrderItem: Codable, Identifiable {
    var id: String
    var name: String
    var price: Double
    var quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "productId"
        case name = "product_name"
        case price = "product_price"
        case quantity
    }
    
    // Custom decoder to handle price format issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Item"
        
        // Handle price as either Double or Int or String
        if let doublePrice = try? container.decode(Double.self, forKey: .price) {
            price = doublePrice
        } else if let intPrice = try? container.decode(Int.self, forKey: .price) {
            price = Double(intPrice)
        } else if let stringPrice = try? container.decode(String.self, forKey: .price),
                  let doubleValue = Double(stringPrice) {
            price = doubleValue
        } else {
            price = 0.0
        }
        
        // Handle quantity as either Int or String
        if let intQuantity = try? container.decode(Int.self, forKey: .quantity) {
            quantity = intQuantity
        } else if let stringQuantity = try? container.decode(String.self, forKey: .quantity),
                  let intValue = Int(stringQuantity) {
            quantity = intValue
        } else {
            quantity = 0
        }
    }
    
    init(id: String, name: String, price: Double, quantity: Int) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}

// MARK: - Order Product
struct OrderProduct: Codable, Identifiable {
    var id: String
    var productId: String?
    var productName: String
    var price: Double
    var quantity: Int
    var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "productId"
        case productId = "_id"
        case productName = "product_name"
        case price = "product_price"
        case quantity
        case imageUrl = "image_url"
    }
    
    init(id: String, productId: String? = nil, productName: String, price: Double, quantity: Int, imageUrl: String? = nil) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.price = price
        self.quantity = quantity
        self.imageUrl = imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        productName = try container.decodeIfPresent(String.self, forKey: .productName) ?? "Unknown Product"
        
        if let doublePrice = try? container.decode(Double.self, forKey: .price) {
            price = doublePrice
        } else if let stringPrice = try? container.decode(String.self, forKey: .price),
                  let doubleValue = Double(stringPrice) {
            price = doubleValue
        } else if let intPrice = try? container.decode(Int.self, forKey: .price) {
            price = Double(intPrice)
        } else {
            price = 0.0
        }
        
        if let intQuantity = try? container.decode(Int.self, forKey: .quantity) {
            quantity = intQuantity
        } else if let stringQuantity = try? container.decode(String.self, forKey: .quantity),
                  let intValue = Int(stringQuantity) {
            quantity = intValue
        } else {
            quantity = 0
        }
        
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }
}

struct CompleteOrderResponse: Codable {
    let success: Bool
    let message: String
    
    // Add flexible decoding
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode success flag
        if let success = try? container.decode(Bool.self, forKey: .success) {
            self.success = success
        } else if let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
                  let success = try? dataContainer.decode(Bool.self, forKey: .success) {
            self.success = success
        } else {
            self.success = true
        }
        
        // Try to decode message
        if let message = try? container.decode(String.self, forKey: .message) {
            self.message = message
        } else if let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
                  let message = try? dataContainer.decode(String.self, forKey: .message) {
            self.message = message
        } else {
            self.message = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(success, forKey: .success)
        try container.encode(message, forKey: .message)
    }
} 