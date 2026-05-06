import SwiftUI

// MARK: - Profile UI View
struct ProfileUIView: View {
    @ObservedObject var viewModel: ProfileControllerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header with background
                ZStack {
                    // Background gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.primaryGreen.opacity(0.7),
                                    AppColors.primaryGreen
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                    
                    // Restaurant image and name
                    VStack(spacing: 16) {
                        // Restaurant image (use default icon)
                        Image(systemName: "building.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryGreen.opacity(0.3))
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        
                        // Restaurant name
                        Text(viewModel.restaurant.restaurantName?.isEmpty ?? true ? "Your Restaurant" : viewModel.restaurant.restaurantName ?? "Your Restaurant")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                    }
                    .padding(.top, 20)
                }
                
                // Content
                VStack(spacing: 32) {
                    // Info cards
                    if horizontalSizeClass == .regular {
                        // Side by side on iPad
                        HStack(spacing: 20) {
                            contactInfoCard
                            restaurantInfoCard
                        }
                        .padding(.horizontal)
                    } else {
                        // Stacked on iPhone
                        VStack(spacing: 20) {
                            contactInfoCard
                            restaurantInfoCard
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 32)
            }
        }
        .background(AppColors.backgroundWhite)
        .edgesIgnoringSafeArea(.top)
    }
    
    // MARK: - Components
    
    // Contact info card
    private var contactInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Card title
            Text("Contact Information")
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.darkGray)
                .padding(.bottom, 8)
            
            // Divider
            Rectangle()
                .fill(AppColors.lightGray)
                .frame(height: 1)
                .padding(.bottom, 16)
            
            // Contact info rows
            infoRow(icon: "person.fill", title: "Name", value: viewModel.restaurant.name)
            infoRow(icon: "envelope.fill", title: "Email", value: viewModel.restaurant.email)
            infoRow(icon: "phone.fill", title: "Phone", value: viewModel.restaurant.phone ?? "Not provided")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Restaurant info card
    private var restaurantInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Card title
            Text("Restaurant Details")
                .font(AppFonts.sectionTitle)
                .foregroundColor(AppColors.darkGray)
                .padding(.bottom, 8)
            
            // Divider
            Rectangle()
                .fill(AppColors.lightGray)
                .frame(height: 1)
                .padding(.bottom, 16)
            
            // Restaurant info rows
            infoRow(icon: "building.2.fill", title: "Name", value: viewModel.restaurant.restaurantName ?? "Not provided")
            infoRow(icon: "mappin.and.ellipse", title: "Address", value: viewModel.restaurant.restaurantAddress ?? "Not provided")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Helper for creating info rows
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryGreen)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                // Value
                Text(value)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.darkGray)
            }
        }
        .padding(.bottom, 16)
    }
} 