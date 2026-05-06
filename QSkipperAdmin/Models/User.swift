import Foundation
import UIKit

// MARK: - User Model
struct User: Codable, Identifiable {
    var id: String
    var name: String
    var email: String
    var restaurantName: String?
    var restaurantAddress: String?
    var phone: String?
    var restaurantId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case restaurantName
        case restaurantAddress
        case phone
        case restaurantId
    }
    
    init(id: String, name: String, email: String, restaurantName: String? = nil, restaurantAddress: String? = nil, phone: String? = nil, restaurantId: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.restaurantName = restaurantName
        self.restaurantAddress = restaurantAddress
        self.phone = phone
        self.restaurantId = restaurantId
    }
}

// MARK: - User Authentication Model
struct UserAuth: Codable {
    var id: String
    var email: String
    var password: String
    var securityCode: String
    
    init(id: String = "", email: String = "", password: String = "", securityCode: String = "0") {
        self.id = id
        self.email = email
        self.password = password
        self.securityCode = securityCode
    }
}

// MARK: - User Identity Model (Lightweight)
struct UserIdentity: Codable {
    var id: String
    
    init(id: String = "") {
        self.id = id
    }
}

// MARK: - User Restaurant Profile
struct UserRestaurantProfile: Codable {
    var id: String
    var restaurantId: String
    var restaurantName: String
    var estimatedTime: Int
    var cuisine: String
    private var imageData: String?
    
    var restaurantImage: UIImage? {
        get {
            // First try loading from base64 data
            if let imageData = imageData, 
               let data = Data(base64Encoded: imageData),
               let image = UIImage(data: data) {
                return image
            }
            
            // If no image data, try to load from the server asynchronously
            // Prioritize restaurantId since that's the correct one
            let possibleIds = [restaurantId].filter { !$0.isEmpty }
            
            if !possibleIds.isEmpty {
                DebugLogger.shared.log("Attempting to load restaurant image with ID: \(possibleIds.first!)", category: .network, tag: "RESTAURANT_IMAGE")
                DispatchQueue.global().async {
                    for possibleId in possibleIds {
                        // Try with each possible ID
                        RestaurantService.shared.fetchRestaurantImage(restaurantId: possibleId) { image in
                            if let image = image {
                                // Update the imageData property with the fetched image
                                DispatchQueue.main.async {
                                    var mutableSelf = self
                                    mutableSelf.restaurantImage = image
                                    
                                    // Log success
                                    DebugLogger.shared.log("Successfully loaded restaurant image from server for ID: \(possibleId)", category: .network, tag: "RESTAURANT_IMAGE")
                                }
                                return // Stop trying once we get an image
                            }
                        }
                    }
                }
            }
            
            return nil
        }
        set {
            if let newImage = newValue, let data = newImage.jpegData(compressionQuality: 0.7) {
                imageData = data.base64EncodedString()
            } else {
                imageData = nil
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurantid"
        case restaurantName
        case estimatedTime = "resturantEstimateTime"
        case cuisine = "resturantCusine"
        case imageData = "restaurantPhoto64Image"
    }
    
    init(id: String = "", restaurantId: String = "", restaurantName: String = "", 
         estimatedTime: Int = 0, cuisine: String = "", restaurantImage: UIImage? = nil) {
        self.id = id
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.estimatedTime = estimatedTime
        self.cuisine = cuisine
        self.restaurantImage = restaurantImage
    }
}

// MARK: - User Response Model
struct UserResponse: Codable {
    let success: Bool
    let message: String
    let token: String?
    let user: User?
    let id: String?
    let username: String?
    let restaurantId: String?
    let restaurantName: String?
    let estimatedTime: Int?
    let cuisine: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case token
        case user
        case data
        case result
        case id
        case username
        case restaurantId = "restaurantid"
        case restaurantName
        case estimatedTime = "resturantEstimateTime"
        case cuisine = "resturantCusine"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle direct response fields
        if let success = try? container.decode(Bool.self, forKey: .success) {
            self.success = success
        } else {
            self.success = true
        }
        
        if let message = try? container.decode(String.self, forKey: .message) {
            self.message = message
        } else {
            self.message = ""
        }
        
        if let token = try? container.decode(String.self, forKey: .token) {
            self.token = token
        } else {
            self.token = nil
        }
        
        // Handle user object
        if let user = try? container.decode(User.self, forKey: .user) {
            self.user = user
        } else if let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
                  let user = try? dataContainer.decode(User.self, forKey: .user) {
            self.user = user
        } else if let user = try? container.decode(User.self, forKey: .result) {
            self.user = user
        } else if let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
                  let user = try? dataContainer.decode(User.self, forKey: .result) {
            self.user = user
        } else {
            self.user = nil
        }
        
        // Handle direct ID/username fields (for login/verify responses)
        id = try? container.decode(String.self, forKey: .id)
        username = try? container.decode(String.self, forKey: .username)
        
        // Handle restaurant-specific fields (for restaurant login)
        restaurantId = try? container.decode(String.self, forKey: .restaurantId)
        restaurantName = try? container.decode(String.self, forKey: .restaurantName)
        estimatedTime = try? container.decode(Int.self, forKey: .estimatedTime)
        cuisine = try? container.decode(String.self, forKey: .cuisine)
    }
    
    // Custom initializer for manual response creation
    init(success: Bool, message: String, token: String? = nil, user: User? = nil, id: String? = nil, 
         username: String? = nil, restaurantId: String? = nil, restaurantName: String? = nil, 
         estimatedTime: Int? = nil, cuisine: String? = nil) {
        self.success = success
        self.message = message
        self.token = token
        self.user = user
        self.id = id
        self.username = username
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.estimatedTime = estimatedTime
        self.cuisine = cuisine
    }
    
    // Simple initializer for direct restaurant profile response
    static func createFromRestaurantResponse(json: [String: Any]) -> UserResponse {
        let id = json["id"] as? String ?? ""
        let restaurantId = json["restaurantid"] as? String ?? ""
        let restaurantName = json["restaurantName"] as? String ?? ""
        let estimatedTime = json["resturantEstimateTime"] as? Int ?? 0
        let cuisine = json["resturantCusine"] as? String ?? ""
        let token = json["token"] as? String
        
        // Log the extracted data for debugging
        DebugLogger.shared.log("Creating user response from restaurant data:", category: .auth)
        DebugLogger.shared.log("  - ID: \(id)", category: .auth)
        DebugLogger.shared.log("  - Restaurant ID: \(restaurantId)", category: .auth)
        DebugLogger.shared.log("  - Restaurant Name: \(restaurantName)", category: .auth)
        
        // Make sure all restaurant data is saved to UserDefaults for later access
        if !restaurantId.isEmpty {
            UserDefaults.standard.set(restaurantId, forKey: "restaurant_id")
            UserDefaults.standard.set(true, forKey: "is_restaurant_registered")
            DebugLogger.shared.log("Saved restaurant ID to UserDefaults: \(restaurantId)", category: .auth)
        }
        
        return UserResponse(
            success: true,
            message: "Restaurant login successful",
            token: token,
            user: nil,
            id: id,
            username: nil,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            estimatedTime: estimatedTime,
            cuisine: cuisine
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(success, forKey: .success)
        try container.encode(message, forKey: .message)
        
        if let token = token {
            try container.encode(token, forKey: .token)
        }
        
        if let user = user {
            try container.encode(user, forKey: .user)
        }
        
        if let id = id {
            try container.encode(id, forKey: .id)
        }
        
        if let username = username {
            try container.encode(username, forKey: .username)
        }
        
        if let restaurantId = restaurantId {
            try container.encode(restaurantId, forKey: .restaurantId)
        }
        
        if let restaurantName = restaurantName {
            try container.encode(restaurantName, forKey: .restaurantName)
        }
        
        if let estimatedTime = estimatedTime {
            try container.encode(estimatedTime, forKey: .estimatedTime)
        }
        
        if let cuisine = cuisine {
            try container.encode(cuisine, forKey: .cuisine)
        }
    }
}

// Authentication requests
struct LoginRequest: Codable {
    let email: String
    let password: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}

struct VerifyOTPRequest: Codable {
    let email: String
    let otp: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case otp
    }
}

struct AppleLoginRequest: Codable {
    let identityToken: String
    let user: String
    
    enum CodingKeys: String, CodingKey {
        case identityToken
        case user
    }
}

// Authentication state to be stored in Keychain
struct AuthState {
    var token: String
    var userId: String
}

// For backwards compatibility with old network manager
extension UserAuth {
    init(email: String, password: String) {
        self.init(id: "", email: email, password: password, securityCode: "0")
    }
} 