import SwiftUI

struct MainView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var dataController: DataController
    
    // State
    @State private var selectedTab: SidebarTab = .restaurant
    @State private var showLogoutAlert = false
    
    enum SidebarTab {
        case restaurant
        case products
        case orders
        case about
        case help
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            sidebarView
                .frame(minWidth: 220)
                .background(Color.green.opacity(0.1))
            
            // Content area
            contentView
                .frame(minWidth: 600, maxWidth: .infinity)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .alert("Confirm Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 5) {
                if let profile = authService.currentUser {
                    Text(profile.restaurantName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.05))
            
            // Menu items
            ScrollView {
                VStack(spacing: 0) {
                    sidebarButton(
                        title: "Restaurant",
                        icon: "building.2.fill",
                        tab: .restaurant
                    )
                    
                    sidebarButton(
                        title: "Products",
                        icon: "cube.fill",
                        tab: .products
                    )
                    
                    sidebarButton(
                        title: "Orders",
                        icon: "bag.fill",
                        tab: .orders
                    )
                    
                    sidebarButton(
                        title: "About",
                        icon: "info.circle",
                        tab: .about
                    )
                    
                    sidebarButton(
                        title: "Help",
                        icon: "questionmark.circle",
                        tab: .help
                    )
                }
            }
            
            Spacer()
            
            // Logout button at the bottom
            Button(action: {
                showLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .foregroundColor(.red)
                    Text("Logout")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func sidebarButton(title: String, icon: String, tab: SidebarTab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(selectedTab == tab ? .green : .gray)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundColor(selectedTab == tab ? .primary : .gray)
                
                Spacer()
                
                if selectedTab == tab {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(selectedTab == tab ? Color.green.opacity(0.15) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Dynamic content based on selected tab
            Group {
                switch selectedTab {
                case .restaurant:
                    RestaurantManagementView()
                        .environmentObject(authService)
                        .environmentObject(dataController)
                case .products:
                    ProductsView()
                case .orders:
                    SwiftUIOrdersView()
                case .about:
                    AboutView()
                case .help:
                    HelpView()
                }
            }
        }
    }
} 