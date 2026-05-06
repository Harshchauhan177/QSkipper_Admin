import UIKit
import SwiftUI

class RootSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    // MARK: - Properties
    private var sidebarController: SidebarViewController!
    private var menuController: MenuViewController!
    private var ordersController: OrdersViewController!
    private var defaultDetailController: UIViewController!
    
    // MARK: - Initializers
    // Add a convenience initializer for pre-iOS 14
    convenience init() {
        if #available(iOS 14.0, *) {
            self.init(style: .doubleColumn)
        } else {
            self.init(nibName: nil, bundle: nil)
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure split view controller for iPad
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
        presentsWithGesture = true
        
        // Set a better background color
        view.backgroundColor = UIColor(AppColors.backgroundWhite)
        
        // Configure for modern iPads
        if #available(iOS 14.0, *) {
            preferredSplitBehavior = .tile
            displayModeButtonVisibility = .always
            
            // Set preferred column widths for iPad
            preferredPrimaryColumnWidth = 320
            minimumPrimaryColumnWidth = 280
            maximumPrimaryColumnWidth = 380
        }
        
        setupViewControllers()
        
        // Default to orders view on launch
        if let primaryNav = viewControllers.first as? UINavigationController,
            let sidebarVC = primaryNav.topViewController as? SidebarViewController {
            DispatchQueue.main.async {
                sidebarVC.viewModel.selectItem(.orders)
            }
        }
    }
    
    // MARK: - Setup
    private func setupViewControllers() {
        // Create sidebar (primary)
        sidebarController = SidebarViewController()
        sidebarController.delegate = self
        
        // Create menu controller
        menuController = MenuViewController()
        
        // Create orders controller
        ordersController = OrdersViewController()
        
        // Create default detail view
        defaultDetailController = createDefaultDetailController()
        
        // Set up navigation controllers with properly styled appearance
        let primaryNav = createStyledNavigationController(root: sidebarController)
        let detailNav = createStyledNavigationController(root: defaultDetailController)
        
        // Set the view controllers
        self.viewControllers = [primaryNav, detailNav]
    }
    
    private func createStyledNavigationController(root: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: root)
        
        // Style for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.navigationBar.prefersLargeTitles = true
            
            if #available(iOS 15.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(AppColors.backgroundWhite)
                appearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.darkGray)]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.darkGray)]
                
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
                navigationController.navigationBar.compactAppearance = appearance
            }
        }
        
        return navigationController
    }
    
    private func createDefaultDetailController() -> UIViewController {
        // Use SwiftUI for a more modern welcome screen
        let hostingController = UIHostingController(rootView: WelcomeDetailView())
        hostingController.view.backgroundColor = UIColor(AppColors.backgroundWhite)
        return hostingController
    }
    
    // MARK: - SplitViewController Delegate
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior
        return true
    }
    
    // Support rotation and size classes properly
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Adjust layout for different orientations
        if UIDevice.current.userInterfaceIdiom == .pad {
            // In landscape, show sidebar; in portrait on smaller iPads, collapse if needed
            let isLandscape = size.width > size.height
            preferredDisplayMode = isLandscape ? .oneBesideSecondary : .automatic
        }
    }
}

// MARK: - SidebarViewController Delegate
extension RootSplitViewController: SidebarViewControllerDelegate {
    func didSelectMenuOption(_ option: SidebarMenuItem) {
        var detailViewController: UIViewController
        
        switch option {
        case .menu:
            detailViewController = menuController
        case .orders:
            detailViewController = ordersController
        case .logout:
            logout()
            return
        }
        
        // Create a styled navigation controller
        let navigationController = createStyledNavigationController(root: detailViewController)
        
        // Add a subtle animation when switching views
        UIView.transition(with: view, duration: AppConstants.defaultAnimationDuration, options: .transitionCrossDissolve, animations: {
            self.showDetailViewController(navigationController, sender: self)
        })
    }
    
    private func logout() {
        // Logout from the auth service
        AuthService.shared.logout()
        
        // Get a reference to the window scene
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        // Create a new ContentView with the updated auth state
        let contentView = ContentView()
            .environmentObject(AuthService.shared)
            .environmentObject(DataController.shared)
            .modifier(DeviceAdaptiveModifier())
        
        // Create a hosting controller for the ContentView
        let hostingController = UIHostingController(rootView: contentView)
        
        // Add subtle animation for logout transition
        UIView.transition(with: window!, 
                         duration: 0.5, 
                         options: .transitionCrossDissolve, 
                         animations: {
            // Set the root view controller directly
            window?.rootViewController = hostingController
            DebugLogger.shared.log("Logged out, returning to ContentView", category: .navigation)
        })
    }
}

// MARK: - Welcome View (SwiftUI)
struct WelcomeDetailView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primaryGreen)
                .padding(.bottom, 10)
            
            // Welcome text
            Text("Welcome to \(AppConstants.appName)")
                .font(AppFonts.title)
                .foregroundColor(AppColors.darkGray)
                .multilineTextAlignment(.center)
            
            Text("Please select an option from the sidebar")
                .font(AppFonts.body)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Quick action buttons
            VStack(spacing: 16) {
                QuickLinkButton(icon: "bag", title: "View Orders", subtitle: "Manage customer orders")
                
                QuickLinkButton(icon: "fork.knife", title: "Manage Menu", subtitle: "Add, edit or remove menu items")
                
                QuickLinkButton(icon: "person.circle", title: "Profile", subtitle: "Edit restaurant information")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // App version
            Text("Version 1.0.0")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.mediumGray)
                .padding(.bottom, 20)
        }
        .padding()
        .frame(maxWidth: 500) // Constrain width for large iPad screens
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center in available space
    }
}

// Quick link button for welcome screen
struct QuickLinkButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppColors.primaryGreen)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppColors.primaryGreen.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body.bold())
                    .foregroundColor(AppColors.darkGray)
                
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.mediumGray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
} 