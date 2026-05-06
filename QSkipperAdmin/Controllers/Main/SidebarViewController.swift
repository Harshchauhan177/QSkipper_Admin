import UIKit
import SwiftUI

// MARK: - Sidebar Menu Items
enum SidebarMenuItem: Int, CaseIterable {
    case menu
    case orders
    case logout
    
    var title: String {
        switch self {
        case .menu:
            return "Menu"
        case .orders:
            return "Orders"
        case .logout:
            return "Logout"
        }
    }
    
    var icon: String {
        switch self {
        case .menu:
            return "fork.knife"
        case .orders:
            return "bag"
        case .logout:
            return "arrow.right.square"
        }
    }
    
    var color: Color {
        switch self {
        case .menu, .orders:
            return AppColors.darkGray
        case .logout:
            return AppColors.errorRed
        }
    }
    
    var selectedColor: Color {
        switch self {
        case .menu, .orders:
            return AppColors.primaryGreen
        case .logout:
            return AppColors.errorRed
        }
    }
}

// MARK: - Delegate Protocol
protocol SidebarViewControllerDelegate: AnyObject {
    func didSelectMenuOption(_ option: SidebarMenuItem)
}

class SidebarViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: SidebarViewControllerDelegate?
    
    private var sidebarView: UIHostingController<SidebarView>!
    public var viewModel = SidebarViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Set title
        title = AppConstants.appName
        
        // Configure navigation bar for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            
            // Set navigation bar appearance for iPad
            if #available(iOS 15.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(AppColors.backgroundWhite)
                appearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.darkGray)]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.darkGray)]
                
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
                navigationController?.navigationBar.compactAppearance = appearance
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Configure hosting controller
        sidebarView = UIHostingController(rootView: SidebarView(viewModel: viewModel))
        
        // Remove background for seamless integration
        sidebarView.view.backgroundColor = .clear
        
        // Add as child view controller
        addChild(sidebarView)
        view.addSubview(sidebarView.view)
        sidebarView.didMove(toParent: self)
        
        // Setup constraints
        sidebarView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sidebarView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sidebarView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebarView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sidebarView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.onSelectItem = { [weak self] menuItem in
            self?.delegate?.didSelectMenuOption(menuItem)
        }
    }
}

// MARK: - SwiftUI View
struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Restaurant data
    @State private var restaurantName = "Restaurant Name"
    @State private var userName = "Restaurant Owner"
    @State private var restaurantImage: UIImage? = nil
    
    // Alert state
    @State private var showLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with restaurant info
            VStack(spacing: 20) {
                // Restaurant image
                Group {
                    if let image = restaurantImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        Image(systemName: "building.2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding(20)
                            .foregroundColor(AppColors.primaryGreen)
                            .background(Circle().fill(AppColors.lightGray))
                    }
                }
                .padding(.top, 16)
                
                // Restaurant info
                VStack(spacing: 4) {
                    Text(restaurantName)
                        .font(AppFonts.sectionTitle)
                        .foregroundColor(AppColors.darkGray)
                        .multilineTextAlignment(.center)
                    
                    Text(userName)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black.opacity(0.1) : AppColors.backgroundWhite)
            
            // Divider
            Rectangle()
                .fill(AppColors.lightGray)
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Menu items
            List {
                ForEach(SidebarMenuItem.allCases, id: \.rawValue) { item in
                    Button(action: {
                        if item == .logout {
                            // Show confirmation alert for logout
                            showLogoutAlert = true
                        } else {
                            // Select other items directly
                            viewModel.selectItem(item)
                            
                            // Add haptic feedback for item selection
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Icon with background for selected state
                            ZStack {
                                Circle()
                                    .fill(viewModel.selectedItem == item ? 
                                          item.selectedColor.opacity(0.1) : 
                                          Color.clear)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: viewModel.selectedItem == item ? .bold : .regular))
                                    .foregroundColor(viewModel.selectedItem == item ? 
                                                     item.selectedColor : 
                                                     item.color)
                            }
                            
                            // Title with selected state
                            Text(item.title)
                                .font(viewModel.selectedItem == item ? AppFonts.body.bold() : AppFonts.body)
                                .foregroundColor(viewModel.selectedItem == item ? 
                                                item.selectedColor :
                                                item.color)
                            
                            Spacer()
                            
                            // Show indicator for selected item
                            if viewModel.selectedItem == item {
                                Circle()
                                    .fill(item.selectedColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle()) // Improve tap area
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(viewModel.selectedItem == item ? 
                        (colorScheme == .dark ? Color.white.opacity(0.05) : AppColors.lightGray.opacity(0.5)) : 
                        Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(PlainListStyle())
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Confirm Logout"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Logout")) {
                        // Perform the logout action
                        viewModel.selectItem(.logout)
                        
                        // Add haptic feedback for confirmation
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    },
                    secondaryButton: .cancel()
                )
            }
            
            // App version at bottom
            Text("Version 1.0.0")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.mediumGray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
        }
        .onAppear {
            // Load user data on appear
            loadUserData()
        }
    }
    
    private func loadUserData() {
        Task {
            do {
                let authState = try AuthService.shared.getAuthState()
                
                // Try to get restaurant info from different sources
                DispatchQueue.main.async {
                    // Option 1: Check if we have data in DataController
                    if DataController.shared.restaurant.id.isEmpty == false {
                        self.restaurantName = DataController.shared.restaurant.name.isEmpty ? 
                            "Your Restaurant" : DataController.shared.restaurant.name
                        
                        DebugLogger.shared.log("Loaded restaurant name from DataController: \(self.restaurantName)", category: .auth)
                    } 
                    // Option 2: Check if we have a current user with restaurant data
                    else if let currentUser = AuthService.shared.currentUser {
                        self.restaurantName = currentUser.restaurantName.isEmpty ? 
                            "Your Restaurant" : currentUser.restaurantName
                        self.restaurantImage = currentUser.restaurantImage
                        
                        DebugLogger.shared.log("Loaded restaurant name from AuthService: \(self.restaurantName)", category: .auth)
                    } 
                    // Option 3: Try to get from UserDefaults
                    else if let restaurantData = UserDefaults.standard.data(forKey: "restaurant_data"),
                       let restaurantDict = try? JSONSerialization.jsonObject(with: restaurantData) as? [String: Any],
                       let resName = restaurantDict["name"] as? String {
                        
                        self.restaurantName = resName
                        DebugLogger.shared.log("Loaded restaurant name from UserDefaults: \(self.restaurantName)", category: .auth)
                    } 
                    // Fallback
                    else {
                        self.restaurantName = "Your Restaurant"
                        DebugLogger.shared.log("Using default restaurant name", category: .auth)
                    }
                    
                    // Set owner name
                    if let userId = AuthService.shared.getUserId() {
                        self.userName = "Owner ID: \(String(userId.prefix(8)))..."
                        
                        // Try to load restaurant image from server if it's not already set
                        if self.restaurantImage == nil {
                            RestaurantService.shared.fetchRestaurantImage(restaurantId: userId) { image in
                                if let image = image {
                                    DispatchQueue.main.async {
                                        self.restaurantImage = image
                                        DebugLogger.shared.log("Successfully loaded restaurant image in sidebar", category: .network, tag: "SIDEBAR_IMAGE")
                                    }
                                }
                            }
                        }
                    } else {
                        self.userName = "Restaurant Owner"
                    }
                }
            } catch {
                DebugLogger.shared.logError(error, tag: "SIDEBAR_LOAD_DATA")
                
                // Fallback values if there's an error
                DispatchQueue.main.async {
                    self.restaurantName = "Your Restaurant"
                    self.userName = "Restaurant Owner"
                }
            }
        }
    }
}

// MARK: - ViewModel
class SidebarViewModel: ObservableObject {
    @Published var selectedItem: SidebarMenuItem = .menu
    
    var onSelectItem: ((SidebarMenuItem) -> Void)?
    
    func selectItem(_ item: SidebarMenuItem) {
        selectedItem = item
        onSelectItem?(item)
    }
} 