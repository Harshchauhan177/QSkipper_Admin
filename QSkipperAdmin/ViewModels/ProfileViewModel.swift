import SwiftUI
import Combine

// MARK: - ViewModel
class ProfileUIViewModel: ObservableObject {
    @Published var restaurant: User = User(
        id: "",
        name: "",
        email: "",
        restaurantName: "",
        restaurantAddress: "",
        phone: ""
    )
    
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var navigateToEditProfile: Bool = false
    
    // Load profile data
    func loadProfile() {
        if let currentUser = AuthService.shared.currentUser {
            self.restaurant = User(
                id: currentUser.id,
                name: "", // UserRestaurantProfile doesn't have this field
                email: "", // UserRestaurantProfile doesn't have this field
                restaurantName: currentUser.restaurantName,
                restaurantAddress: "", // UserRestaurantProfile doesn't have this field
                phone: "", // UserRestaurantProfile doesn't have this field
                restaurantId: currentUser.restaurantId
            )
        } else {
            self.errorMessage = "No user data found"
            self.showErrorAlert = true
        }
    }
} 