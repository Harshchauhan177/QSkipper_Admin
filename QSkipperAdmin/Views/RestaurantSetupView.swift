import SwiftUI
import PhotosUI

struct RestaurantSetupView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @Binding var isPresented: Bool
    
    // State
    @State private var restaurantName = ""
    @State private var cuisine = CuisineTypes.list[0]
    @State private var estimatedTime = 30
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                    .disabled(restaurantName.isEmpty || isLoading)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(Color(AppColors.errorRed))
                            .font(AppFonts.caption)
                    }
                }
                
                if isLoading {
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
            errorMessage = "Please enter a restaurant name"
            return
        }
        
        guard let userId = authService.getUserId() else {
            errorMessage = "User ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await SupabaseRestaurantService.shared.registerRestaurant(
                    name: restaurantName,
                    cuisine: cuisine,
                    estimatedTime: estimatedTime,
                    bannerImage: selectedImage
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    // Update UserDefaults
                    let restaurantId = result.id ?? userId
                    UserDefaults.standard.set(restaurantId, forKey: "restaurant_id")
                    UserDefaults.standard.set(true, forKey: "is_restaurant_registered")
                    
                    // Update auth service with restaurant info
                    if let currentUser = authService.currentUser {
                        let updatedUser = UserRestaurantProfile(
                            id: currentUser.id,
                            restaurantId: restaurantId,
                            restaurantName: restaurantName,
                            estimatedTime: estimatedTime,
                            cuisine: cuisine,
                            restaurantImage: selectedImage
                        )
                        authService.currentUser = updatedUser
                    }
                    
                    // Close modal
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
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