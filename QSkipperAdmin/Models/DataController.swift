import Foundation
import UIKit
import Combine

// A singleton class to handle data persistence and app-wide state
class DataController: ObservableObject {
    static let shared = DataController()
    
    // Main user/restaurant data
    @Published var currentUser: User
    @Published var restaurant: RestaurantInfo
    
    // Notifications
    static let userDidLoginNotification = Notification.Name("QSkipperUserDidLogin")
    static let userDidLogoutNotification = Notification.Name("QSkipperUserDidLogout")
    
    private init() {
        // Initialize with empty models
        self.currentUser = User(
            id: "",
            name: "",
            email: "",
            restaurantName: nil,
            restaurantAddress: nil,
            phone: nil,
            restaurantId: nil
        )
        
        self.restaurant = RestaurantInfo(
            id: "",
            name: "",
            email: "",
            address: "",
            phone: "",
            categories: []
        )
        
        // Try to load saved data
        loadSavedData()
    }
    
    // MARK: - User Authentication
    
    func setCurrentUser(from userResponse: UserResponse) {
        // Clear previous data first
        clearData()
        
        if let user = userResponse.user {
            self.currentUser = user
            DebugLogger.shared.log("Set current user from user object: \(user.id)", category: .auth)
        } else {
            // Create a user from the individual fields
            let userId = userResponse.id ?? ""
            let name = userResponse.username ?? ""
            let email = ""  // Email might not be returned, but we'd need to save it separately
            
            // Get the restaurant ID from the response or fall back to user ID
            let restaurantId = userResponse.restaurantId ?? userId
            
            self.currentUser = User(
                id: userId,
                name: name,
                email: email,
                restaurantName: userResponse.restaurantName,
                restaurantAddress: nil,
                phone: nil,
                restaurantId: restaurantId
            )
            
            DebugLogger.shared.log("Set current user from response fields: \(userId) with restaurant ID: \(restaurantId)", category: .auth)
        }
        
        // Also set restaurant data if available
        if let restaurantId = userResponse.restaurantId {
            self.restaurant = RestaurantInfo(
                id: restaurantId,
                name: userResponse.restaurantName ?? "",
                email: self.currentUser.email,
                address: "",
                phone: "",
                categories: []
            )
            
            // Save the restaurant ID separately as well for easy access
            UserDefaults.standard.set(restaurantId, forKey: "restaurant_id")
            
            DebugLogger.shared.log("Set restaurant data with ID: \(restaurantId)", category: .auth)
        } else if let userId = userResponse.id {
            // Fallback to user ID if we don't have a specific restaurant ID
            self.restaurant = RestaurantInfo(
                id: userId,
                name: userResponse.restaurantName ?? "",
                email: self.currentUser.email,
                address: "",
                phone: "",
                categories: []
            )
            
            DebugLogger.shared.log("Set restaurant data using user ID: \(userId) (fallback)", category: .auth)
        }
        
        // Save data
        saveData()
        
        // Post notification
        NotificationCenter.default.post(name: DataController.userDidLoginNotification, object: nil)
    }
    
    func setCurrentUser(from user: User) {
        // Clear previous data first
        clearData()
        
        self.currentUser = user
        
        // If there's a restaurant ID, update restaurant data
        if let restaurantId = user.restaurantId {
            self.restaurant.id = restaurantId
            
            // If there's a restaurant name, update it as well
            if let restaurantName = user.restaurantName {
                self.restaurant.name = restaurantName
            }
            
            self.restaurant.email = user.email
        }
        
        saveData()
        
        // Post notification
        NotificationCenter.default.post(name: DataController.userDidLoginNotification, object: nil)
        DebugLogger.shared.log("Set current user directly: \(user.id)", category: .auth)
    }
    
    func logout() {
        // Ensure we're on the main thread for @Published property updates
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.logout()
            }
            return
        }
        
        // Clear auth token
        NetworkManager.shared.clearAuthToken()
        
        // Reset in-memory models and clear UserDefaults
        clearData()
        
        // Post notification
        NotificationCenter.default.post(name: DataController.userDidLogoutNotification, object: nil)
        DebugLogger.shared.log("User logged out, all data cleared", category: .auth)
    }
    
    /// Clear all data in the DataController
    func clearData() {
        // Ensure we're on the main thread for @Published property updates
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.clearData()
            }
            return
        }
        
        // Reset in-memory models
        self.currentUser = User(
            id: "",
            name: "",
            email: "",
            restaurantName: nil,
            restaurantAddress: nil,
            phone: nil,
            restaurantId: nil
        )
        
        self.restaurant = RestaurantInfo(
            id: "",
            name: "",
            email: "",
            address: "",
            phone: "",
            categories: []
        )
        
        // Clear any cached data
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "restaurantData")
        UserDefaults.standard.removeObject(forKey: "restaurant_id")
        UserDefaults.standard.removeObject(forKey: "restaurant_data")
        UserDefaults.standard.removeObject(forKey: "restaurant_raw_data")
        
        // Force UserDefaults to synchronize
        UserDefaults.standard.synchronize()
        
        DebugLogger.shared.log("DataController data completely cleared", category: .auth)
    }
    
    func isLoggedIn() -> Bool {
        return !currentUser.id.isEmpty
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        // Save user data
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "userData")
            DebugLogger.shared.log("User data saved to UserDefaults", category: .auth)
        }
        
        // Save restaurant data
        if let restaurantData = try? JSONEncoder().encode(restaurant) {
            UserDefaults.standard.set(restaurantData, forKey: "restaurantData")
            DebugLogger.shared.log("Restaurant data saved to UserDefaults", category: .auth)
        }
    }
    
    private func loadSavedData() {
        // Try to get the restaurant ID directly from UserDefaults first
        let directRestaurantId = UserDefaults.standard.string(forKey: "restaurant_id")
        if let directRestaurantId = directRestaurantId, !directRestaurantId.isEmpty {
            DebugLogger.shared.log("Found direct restaurant ID in UserDefaults: \(directRestaurantId)", category: .auth)
            self.restaurant.id = directRestaurantId
        }
        
        // Load user data
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = decodedUser
            DebugLogger.shared.log("Loaded user data from UserDefaults: \(decodedUser.id)", category: .auth)
            
            // If we have a restaurant ID in the user data and no direct ID, use it
            if directRestaurantId == nil, let restaurantId = decodedUser.restaurantId, !restaurantId.isEmpty {
                self.restaurant.id = restaurantId
                DebugLogger.shared.log("Using restaurant ID from user data: \(restaurantId)", category: .auth)
            }
        }
        
        // Load restaurant data
        if let restaurantData = UserDefaults.standard.data(forKey: "restaurantData"),
           let decodedRestaurant = try? JSONDecoder().decode(RestaurantInfo.self, from: restaurantData) {
            
            // Create a mutable copy to work with
            var updatedRestaurant = decodedRestaurant
            DebugLogger.shared.log("Loaded restaurant data from UserDefaults: \(decodedRestaurant.id)", category: .auth)
            
            // Always prioritize direct restaurant ID if we have it
            if let directId = directRestaurantId, !directId.isEmpty {
                updatedRestaurant.id = directId
                DebugLogger.shared.log("Overriding restaurant ID with direct ID: \(directId)", category: .auth)
            }
            
            // Apply our updated restaurant data
            self.restaurant = updatedRestaurant
            
            // Check if we have raw restaurant data which might contain more details
            if let rawRestaurantData = UserDefaults.standard.data(forKey: "restaurant_raw_data"),
               let restaurantInfo = try? JSONSerialization.jsonObject(with: rawRestaurantData) as? [String: Any] {
                
                if let restaurantId = restaurantInfo["restaurantid"] as? String, !restaurantId.isEmpty {
                    self.restaurant.id = restaurantId
                    DebugLogger.shared.log("Updated restaurant ID from raw data: \(restaurantId)", category: .auth)
                }
                
                if let restaurantName = restaurantInfo["restaurantName"] as? String, !restaurantName.isEmpty {
                    self.restaurant.name = restaurantName
                    DebugLogger.shared.log("Updated restaurant name from raw data: \(restaurantName)", category: .auth)
                }
            }
        } else if directRestaurantId != nil {
            // If we don't have restaurant data but we do have a direct restaurant ID,
            // try to load additional restaurant details from raw data
            if let restaurantRawData = UserDefaults.standard.data(forKey: "restaurant_data"),
               let restaurantDict = try? JSONSerialization.jsonObject(with: restaurantRawData) as? [String: Any],
               let name = restaurantDict["name"] as? String {
                
                self.restaurant.name = name
                DebugLogger.shared.log("Set restaurant name from raw data: \(name)", category: .auth)
            }
        }
    }
    
    // MARK: - Restaurant Data Management

    /// Set restaurant data directly from a restaurant object
    /// - Parameter restaurantData: Dictionary containing restaurant data
    func setRestaurantData(from restaurantData: [String: Any]) {
        if let restaurantId = restaurantData["restaurantid"] as? String, !restaurantId.isEmpty {
            self.restaurant.id = restaurantId
            DebugLogger.shared.log("Set restaurant ID: \(restaurantId)", category: .auth)
        }
        
        if let restaurantName = restaurantData["restaurantName"] as? String, !restaurantName.isEmpty {
            self.restaurant.name = restaurantName
            DebugLogger.shared.log("Set restaurant name: \(restaurantName)", category: .auth)
        }
        
        // Store the raw data for future reference
        if let rawData = try? JSONSerialization.data(withJSONObject: restaurantData) {
            UserDefaults.standard.set(rawData, forKey: "restaurant_raw_data")
            DebugLogger.shared.log("Saved raw restaurant data to UserDefaults", category: .auth)
        }
        
        // Save to user defaults
        if let restaurantData = try? JSONEncoder().encode(restaurant) {
            UserDefaults.standard.set(restaurantData, forKey: "restaurantData")
            DebugLogger.shared.log("Restaurant data saved to UserDefaults", category: .auth)
        }
    }
}

// Simple Restaurant model for internal use
struct RestaurantInfo: Codable {
    var id: String
    var name: String
    var email: String
    var address: String
    var phone: String
    var categories: [String]
    
    // Additional restaurant properties can be added as needed
} 