import SwiftUI
import Combine

class EditProfileViewModel: ObservableObject {
    // User info
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    
    // Restaurant info
    @Published var restaurantName: String = ""
    @Published var restaurantAddress: String = ""
    
    // UI state
    @Published var isUpdating: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSuccess: Bool = false
    
    // Store original user data
    private var originalUserRestaurantProfile: UserRestaurantProfile?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with user data from User type
    func initializeWithUser(_ user: User) {
        self.name = user.name
        self.email = user.email
        self.phone = user.phone ?? ""
        self.restaurantName = user.restaurantName ?? ""
        self.restaurantAddress = user.restaurantAddress ?? ""
    }
    
    // Initialize with UserRestaurantProfile
    func initializeWithUserProfile(_ profile: UserRestaurantProfile) {
        self.originalUserRestaurantProfile = profile
        // Only restaurant name is available in UserRestaurantProfile
        self.restaurantName = profile.restaurantName
        // Setting other fields with empty values since they're not in UserRestaurantProfile
        self.name = ""
        self.email = ""
        self.phone = ""
        self.restaurantAddress = ""
    }
    
    // Update profile
    func updateProfile() {
        // Validate fields
        if restaurantName.isEmpty {
            errorMessage = "Please fill in restaurant name"
            return
        }
        
        // Set updating state
        isUpdating = true
        
        if let profile = originalUserRestaurantProfile {
            // Create updated user for UserRestaurantProfile
            let updatedProfile = UserRestaurantProfile(
                id: profile.id,
                restaurantId: profile.restaurantId,
                restaurantName: restaurantName,
                estimatedTime: profile.estimatedTime,
                cuisine: profile.cuisine,
                restaurantImage: profile.restaurantImage
            )
            
            // TODO: Call a proper update method for UserRestaurantProfile
            // For now, we'll use the existing updateUserData as a placeholder
            
            // Call Auth Service to update user
            AuthService.shared.updateUserData(User(
                id: profile.id,
                name: name,
                email: email,
                restaurantName: restaurantName
            ))
        } else {
            // Create updated user for User type
            let updatedUser = User(
                id: AuthService.shared.currentUser?.id ?? "",
                name: name,
                email: email,
                restaurantName: restaurantName,
                restaurantAddress: restaurantAddress,
                phone: phone
            )
            
            // Call Auth Service to update user
            AuthService.shared.updateUserData(updatedUser)
        }
        
        // Wait a bit to simulate network request and then show success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isUpdating = false
            self?.isSuccess = true
            
            // Reset success after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isSuccess = false
            }
        }
    }
} 