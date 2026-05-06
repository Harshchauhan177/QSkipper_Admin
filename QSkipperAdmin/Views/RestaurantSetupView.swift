import SwiftUI
import PhotosUI

struct RestaurantSetupView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @StateObject private var restaurantService = RestaurantService()
    @Binding var isPresented: Bool
    
    // State
    @State private var restaurantName = ""
    @State private var cuisine = CuisineTypes.list[0]
    @State private var estimatedTime = 30
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Restaurant Information")) {
                    TextField("Restaurant Name", text: $restaurantName)
                    
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(CuisineTypes.list, id: \.self) { cuisine in
                            Text(cuisine)
                        }
                    }
                    
                    Stepper("Estimated Time: \(estimatedTime) mins", value: $estimatedTime, in: 10...120, step: 5)
                }
                
                Section(header: Text("Restaurant Image")) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Text("Select Image")
                            Spacer()
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(Color(AppColors.mediumGray))
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveRestaurant) {
                        Text("Save Restaurant")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(AppColors.primaryGreen))
                    .disabled(restaurantName.isEmpty || restaurantService.isLoading)
                }
                
                if let error = restaurantService.error {
                    Section {
                        Text(error)
                            .foregroundColor(Color(AppColors.errorRed))
                            .font(AppFonts.caption)
                    }
                }
                
                if restaurantService.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Setup Restaurant")
            .sheet(isPresented: $showImagePicker) {
                UIKitImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func saveRestaurant() {
        guard !restaurantName.isEmpty else {
            restaurantService.error = "Please enter a restaurant name"
            return
        }
        
        guard let userId = authService.getUserId() else {
            restaurantService.error = "User ID not found"
            return
        }
        
        // Create restaurant model
        var restaurant = Restaurant(
            restaurantId: userId,
            restaurantName: restaurantName,
            cuisine: cuisine,
            estimatedTime: estimatedTime,
            bannerPhoto: selectedImage
        )
        
        // Save restaurant
        restaurantService.createRestaurant(restaurant: restaurant) { result in
            switch result {
            case .success(let createdRestaurant):
                // Update auth service with restaurant info
                if let currentUser = authService.currentUser {
                    let updatedUser = UserRestaurantProfile(
                        id: currentUser.id,
                        restaurantId: createdRestaurant.id,
                        restaurantName: createdRestaurant.restaurantName,
                        estimatedTime: createdRestaurant.estimatedTime,
                        cuisine: createdRestaurant.cuisine,
                        restaurantImage: createdRestaurant.bannerPhoto
                    )
                    authService.currentUser = updatedUser
                }
                
                // Close modal
                isPresented = false
                
            case .failure(let error):
                restaurantService.error = error.localizedDescription
            }
        }
    }
}

struct RestaurantSetupView_Previews: PreviewProvider {
    static var previews: some View {
        RestaurantSetupView(isPresented: .constant(true))
            .environmentObject(AuthService())
    }
}

// ImagePicker is now imported from Components/ImagePicker.swift 