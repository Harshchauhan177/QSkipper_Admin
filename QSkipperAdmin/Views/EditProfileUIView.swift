import SwiftUI

struct EditProfileUIView: View {
    @ObservedObject var viewModel: EditProfileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Page Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Profile")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.darkGray)
                    
                    Text("Update your restaurant and contact information")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Error message (if any)
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.errorRed)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.errorRed.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if horizontalSizeClass == .regular {
                    // iPad layout (side by side)
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 24) {
                            // Contact Information
                            contactInfoSection
                            
                            // Update Button for Contact
                            Button(action: {
                                viewModel.updateProfile()
                            }) {
                                Text("Update Profile")
                                    .font(AppFonts.buttonText)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.primaryGreen)
                                    .cornerRadius(10)
                            }
                            .disabled(viewModel.isUpdating)
                            .opacity(viewModel.isUpdating ? 0.7 : 1.0)
                            .overlay(
                                Group {
                                    if viewModel.isUpdating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.3)
                                    }
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 24) {
                            // Restaurant Information
                            restaurantInfoSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // iPhone layout (stacked)
                    VStack(spacing: 24) {
                        // Contact Information
                        contactInfoSection
                        
                        // Restaurant Information
                        restaurantInfoSection
                        
                        // Update Button
                        Button(action: {
                            viewModel.updateProfile()
                        }) {
                            Text("Update Profile")
                                .font(AppFonts.buttonText)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primaryGreen)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.isUpdating)
                        .opacity(viewModel.isUpdating ? 0.7 : 1.0)
                        .overlay(
                            Group {
                                if viewModel.isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.3)
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .background(AppColors.backgroundWhite)
    }
    
    // MARK: - Components
    
    // Contact Information Section
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Contact Information")
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.darkGray)
            
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Your name", text: $viewModel.name)
                    .font(AppFonts.body)
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
            }
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Your email", text: $viewModel.email)
                    .font(AppFonts.body)
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Phone field
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Your phone number", text: $viewModel.phone)
                    .font(AppFonts.body)
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
                    .keyboardType(.phonePad)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Restaurant Information Section
    private var restaurantInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Restaurant Information")
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.darkGray)
            
            // Restaurant Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Restaurant Name")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Restaurant name", text: $viewModel.restaurantName)
                    .font(AppFonts.body)
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
            }
            
            // Restaurant Address field
            VStack(alignment: .leading, spacing: 8) {
                Text("Restaurant Address")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Restaurant address", text: $viewModel.restaurantAddress)
                    .font(AppFonts.body)
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
} 