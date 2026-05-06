import UIKit
import SwiftUI
import Combine

class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    private var profileView: UIHostingController<ProfileControllerView>!
    private var viewModel = ProfileControllerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupUI()
        setupNavigation()
        
        // Load user data on load
        viewModel.loadProfile()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set background color
        view.backgroundColor = UIColor(AppColors.backgroundWhite)
        
        // Create SwiftUI view
        let swiftUIView = ProfileControllerView(viewModel: viewModel)
        profileView = UIHostingController(rootView: swiftUIView)
        
        // Add as child view controller
        addChild(profileView)
        view.addSubview(profileView.view)
        profileView.didMove(toParent: self)
        
        // Set constraints
        profileView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileView.view.topAnchor.constraint(equalTo: view.topAnchor),
            profileView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigation() {
        // Set title
        title = "Profile"
        
        // Customize navigation appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = UIColor(AppColors.primaryGreen)
        
        // Hide back button title
        navigationItem.backButtonDisplayMode = .minimal
        
        // Add edit button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
    }
    
    private func setupBindings() {
        // Navigate to edit profile
        viewModel.$navigateToEditProfile
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.navigateToEditProfile()
                // Reset the flag
                self?.viewModel.navigateToEditProfile = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    private func navigateToEditProfile() {
        // Create and present the edit profile screen
        let editProfileVC = EditProfileViewController()
        editProfileVC.currentUser = viewModel.restaurant
        navigationController?.pushViewController(editProfileVC, animated: true)
    }
    
    // MARK: - Actions
    @objc private func editButtonTapped() {
        let editProfileVC = EditProfileViewController()
        editProfileVC.currentUser = viewModel.restaurant
        navigationController?.pushViewController(editProfileVC, animated: true)
    }
}

// MARK: - SwiftUI View
struct ProfileControllerView: View {
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
                        // Restaurant image (use default icon since User doesn't have image property)
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
                
                // Content area
                VStack(spacing: 24) {
                    // Restaurant Info Card
                    profileCard(
                        title: "Restaurant Information",
                        icon: "building.2"
                    ) {
                        restaurantInfoContent
                    }
                    
                    // Account Info Card
                    profileCard(
                        title: "Account Information",
                        icon: "person.circle"
                    ) {
                        accountInfoContent
                    }
                    
                    // App Info Card
                    profileCard(
                        title: "App Information",
                        icon: "gear"
                    ) {
                        appInfoContent
                    }
                    
                    // Edit Profile Button
                    Button(action: {
                        viewModel.navigateToEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGreen)
                        .cornerRadius(10)
                    }
                    .padding(.top, 16)
                    
                    // Logout Button
                    Button(action: {
                        viewModel.logout()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Logout")
                        }
                        .font(AppFonts.buttonText)
                        .foregroundColor(AppColors.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.errorRed, lineWidth: 2)
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
                .padding(.horizontal, horizontalSizeClass == .regular ? 20 : 0)
                .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(AppColors.backgroundWhite)
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.loadProfile()
        }
    }
    
    // MARK: - Component Builders
    private func profileCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primaryGreen)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(AppFonts.sectionTitle)
                    .foregroundColor(AppColors.darkGray)
            }
            
            // Card content
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var restaurantInfoContent: some View {
        VStack(spacing: 16) {
            infoRow(title: "Restaurant Name", value: viewModel.restaurant.restaurantName)
            infoRow(title: "Address", value: viewModel.restaurant.restaurantAddress)
            infoRow(title: "Phone", value: viewModel.restaurant.phone)
        }
    }
    
    private var accountInfoContent: some View {
        VStack(spacing: 16) {
            infoRow(title: "Name", value: viewModel.restaurant.name)
            infoRow(title: "Email", value: viewModel.restaurant.email)
            infoRow(title: "User ID", value: viewModel.restaurant.id)
        }
    }
    
    private var appInfoContent: some View {
        VStack(spacing: 16) {
            infoRow(
                title: "App Version",
                value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
            )
            
            infoRow(
                title: "Platform",
                value: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
            )
        }
    }
    
    private func infoRow(title: String, value: String?) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.mediumGray)
                .frame(width: 120, alignment: .leading)
            
            Text(value?.isEmpty ?? true ? "Not provided" : value!)
                .font(AppFonts.body)
                .foregroundColor(AppColors.darkGray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel
class ProfileControllerViewModel: ObservableObject {
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
            // Convert UserRestaurantProfile to User
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
            // Show empty state or error if no user found
            self.errorMessage = "Unable to load profile. Please log in again."
            self.showErrorAlert = true
        }
    }
    
    // Logout function
    func logout() {
        AuthService.shared.logout()
    }
} 