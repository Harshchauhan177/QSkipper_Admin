import Foundation
import Combine
import Supabase
import UIKit

/// Supabase-powered authentication service
/// Replaces the old custom JWT approach with Supabase Auth
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var currentUserId: String?
    @Published var currentRestaurant: SupabaseRestaurant?
    
    // MARK: - Private
    private let client = SupabaseConfig.client
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        DebugLogger.shared.log("SupabaseAuthService initialized", category: .app)
        
        // Check if user is already logged in
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Check
    
    /// Check if user has an active session
    @MainActor
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUserId = session.user.id.uuidString
            self.isAuthenticated = true
            
            // Ensure UserDefaults are synced for legacy code compatibility
            UserDefaults.standard.set(session.user.id.uuidString, forKey: "user_id")
            UserDefaults.standard.set(session.user.id.uuidString, forKey: "qskipper_user_id")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            
            DebugLogger.shared.log("Active session found for user: \(session.user.id)", category: .auth)
            
            // Load restaurant data
            await loadMyRestaurant()
        } catch {
            self.isAuthenticated = false
            self.currentUserId = nil
            DebugLogger.shared.log("No active session", category: .auth)
        }
    }
    
    // MARK: - Sign Up (Register)
    
    /// Register a new restaurant owner account
    @MainActor
    func signUp(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            self.currentUserId = response.user.id.uuidString
            self.isAuthenticated = true
            
            // Save to UserDefaults for compatibility with existing code
            UserDefaults.standard.set(response.user.id.uuidString, forKey: "user_id")
            UserDefaults.standard.set(response.user.id.uuidString, forKey: "qskipper_user_id")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            
            DebugLogger.shared.log("Sign up successful for: \(email)", category: .auth)
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.shared.logError(error, tag: "SUPABASE_SIGNUP")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sign In (Login)
    
    /// Login with email and password
    @MainActor
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUserId = session.user.id.uuidString
            self.isAuthenticated = true
            
            // Save to UserDefaults for compatibility
            UserDefaults.standard.set(session.user.id.uuidString, forKey: "user_id")
            UserDefaults.standard.set(session.user.id.uuidString, forKey: "qskipper_user_id")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            
            DebugLogger.shared.log("Sign in successful for: \(email)", category: .auth)
            
            // Load restaurant data after login
            await loadMyRestaurant()
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
            DebugLogger.shared.logError(error, tag: "SUPABASE_SIGNIN")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sign Out (Logout)
    
    /// Logout the current user
    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            
            self.isAuthenticated = false
            self.currentUserId = nil
            self.currentRestaurant = nil
            
            // Clear UserDefaults
            UserDefaults.standard.removeObject(forKey: "user_id")
            UserDefaults.standard.removeObject(forKey: "qskipper_user_id")
            UserDefaults.standard.removeObject(forKey: "restaurant_id")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.set(false, forKey: "is_restaurant_registered")
            UserDefaults.standard.removeObject(forKey: "restaurant_data")
            UserDefaults.standard.removeObject(forKey: "restaurant_raw_data")
            UserDefaults.standard.removeObject(forKey: "userData")
            UserDefaults.standard.removeObject(forKey: "restaurantData")
            
            DebugLogger.shared.log("Sign out successful", category: .auth)
            
        } catch {
            DebugLogger.shared.logError(error, tag: "SUPABASE_SIGNOUT")
        }
    }
    
    // MARK: - Restaurant Data
    
    /// Load the restaurant owned by the current user
    @MainActor
    func loadMyRestaurant() async {
        guard let userId = currentUserId else { return }
        
        do {
            let restaurants: [SupabaseRestaurant] = try await client
                .from(SupabaseConfig.Tables.restaurants)
                .select()
                .eq("owner_id", value: userId)
                .execute()
                .value
            
            if let restaurant = restaurants.first {
                self.currentRestaurant = restaurant
                
                // Save to UserDefaults for compatibility
                if let restaurantId = restaurant.id {
                    UserDefaults.standard.set(restaurantId, forKey: "restaurant_id")
                    UserDefaults.standard.set(true, forKey: "is_restaurant_registered")
                }
                
                DebugLogger.shared.log("Loaded restaurant: \(restaurant.name)", category: .auth)
            } else {
                self.currentRestaurant = nil
                UserDefaults.standard.set(false, forKey: "is_restaurant_registered")
                DebugLogger.shared.log("No restaurant found for user", category: .auth)
            }
            
        } catch {
            DebugLogger.shared.logError(error, tag: "LOAD_RESTAURANT")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the current user ID
    func getUserId() -> String? {
        return currentUserId
    }
    
    /// Get the current restaurant ID
    func getRestaurantId() -> String? {
        return currentRestaurant?.id
    }
    
    /// Check if restaurant is registered
    func isRestaurantRegistered() -> Bool {
        return currentRestaurant != nil
    }
    
    /// Get auth token for any legacy API calls
    func getToken() async -> String? {
        do {
            let session = try await client.auth.session
            return session.accessToken
        } catch {
            return nil
        }
    }
}
