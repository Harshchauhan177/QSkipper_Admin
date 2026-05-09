import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @Environment(\.presentationMode) private var presentationMode
    
    // State
    @State private var restaurantName = ""
    @State private var cuisine = ""
    @State private var estimatedTime = 30
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showSuccessAlert = false
    @State private var userImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Restaurant Profile")) {
                // Restaurant image
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        VStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Color(AppColors.mediumGray))
                                    .frame(width: 100, height: 100)
                                    .background(Color(AppColors.lightGray))
                                    .clipShape(Circle())
                            }
                            
                            Text("Change Image")
                                .font(AppFonts.caption)
                                .foregroundColor(Color(AppColors.primaryGreen))
                                .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                
                // Restaurant name
                TextField("Restaurant Name", text: $restaurantName)
                
                // Cuisine picker
                Picker("Cuisine", selection: $cuisine) {
                    ForEach(CuisineTypes.list, id: \.self) { cuisine in
                        Text(cuisine)
                    }
                }
                
                // Estimated time
                Stepper("Estimated Time: \(estimatedTime) mins", value: $estimatedTime, in: 10...120, step: 5)
            }
            
            Section {
                Button(action: updateProfile) {
                    Text("Save Changes")
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
        .navigationTitle("Edit Profile")
        .onAppear(perform: loadUserProfile)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, onImageSelected: {
                userImage = selectedImage
            })
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Profile Updated"),
                message: Text("Your restaurant profile has been updated successfully."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func loadUserProfile() {
        guard let currentUser = authService.currentUser else { return }
        
        restaurantName = currentUser.restaurantName
        cuisine = currentUser.cuisine
        estimatedTime = currentUser.estimatedTime
        selectedImage = currentUser.restaurantImage
        
        // Load restaurant data from Supabase
        if !currentUser.restaurantId.isEmpty {
            Task {
                if let restaurant = try? await SupabaseRestaurantService.shared.fetchMyRestaurant() {
                    await MainActor.run {
                        restaurantName = restaurant.name
                        cuisine = restaurant.cuisine
                        estimatedTime = restaurant.estimatedTime
                    }
                    // Load banner image
                    if let bannerUrl = restaurant.bannerImageUrl {
                        let image = await SupabaseRestaurantService.shared.fetchRestaurantImage(url: bannerUrl)
                        await MainActor.run {
                            if let image = image {
                                selectedImage = image
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateProfile() {
        guard let currentUser = authService.currentUser,
              !currentUser.restaurantId.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await SupabaseRestaurantService.shared.updateRestaurant(
                    restaurantId: currentUser.restaurantId,
                    name: restaurantName,
                    cuisine: cuisine,
                    estimatedTime: estimatedTime,
                    bannerImage: selectedImage
                )
                
                await MainActor.run {
                    isLoading = false
                    DebugLogger.shared.log("Restaurant profile update successful via Supabase", category: .network)
                    
                    // Update auth service with restaurant info
                    let updatedUser = UserRestaurantProfile(
                        id: currentUser.id,
                        restaurantId: result.id ?? currentUser.restaurantId,
                        restaurantName: restaurantName,
                        estimatedTime: estimatedTime,
                        cuisine: cuisine,
                        restaurantImage: selectedImage
                    )
                    authService.currentUser = updatedUser
                    
                    // Show success alert
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    DebugLogger.shared.logError(error, tag: "RESTAURANT_UPDATE")
                    errorMessage = "Update failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileEditView()
                .environmentObject(AuthService())
        }
    }
}