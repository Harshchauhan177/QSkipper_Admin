import SwiftUI

struct DashboardView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @StateObject private var orderService = OrderService()
    // Use ProductApi directly instead of ProductService
    @State private var products: [Product] = []
    @State private var isLoadingProducts = false
    
    // State
    @State private var selectedTab = 0
    @State private var showProfileModal = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Orders Tab
            ModernOrdersView()
                .tabItem {
                    Label("Orders", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Menu Tab
            MenuView(products: products, isLoading: isLoadingProducts)
                .tabItem {
                    Label("Menu", systemImage: "fork.knife")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(Color(AppColors.primaryGreen))
        .onAppear {
            // First try to get restaurant ID from UserDefaults
            if let storedRestaurantId = UserDefaults.standard.string(forKey: "restaurant_id"), !storedRestaurantId.isEmpty {
                DebugLogger.shared.log("Found restaurant ID in UserDefaults: \(storedRestaurantId)", category: .app)
                loadData(restaurantId: storedRestaurantId)
            }
            // Then try from current user if available
            else if let currentUser = authService.currentUser,
                   !currentUser.restaurantId.isEmpty {
                loadData(restaurantId: currentUser.restaurantId)
            } 
            // Finally check if we need to show profile setup
            else {
                showProfileModal = true
            }
        }
        .sheet(isPresented: $showProfileModal) {
            RestaurantSetupView(isPresented: $showProfileModal)
                .environmentObject(authService)
        }
    }
    
    private func loadData(restaurantId: String) {
        // Try to get the restaurant ID from UserDefaults first
        var targetRestaurantId = restaurantId
        
        if let storedRestaurantId = UserDefaults.standard.string(forKey: "restaurant_id"), !storedRestaurantId.isEmpty {
            targetRestaurantId = storedRestaurantId
            DebugLogger.shared.log("Using restaurant ID from UserDefaults: \(targetRestaurantId)", category: .app)
        }
        
        // Load orders
        orderService.fetchRestaurantOrders(restaurantId: targetRestaurantId)
        
        // Load products directly using ProductApi
        isLoadingProducts = true
        Task {
            do {
                let fetchedProducts = try await ProductApi.shared.getAllProducts(restaurantId: targetRestaurantId)
                DispatchQueue.main.async {
                    self.products = fetchedProducts
                    self.isLoadingProducts = false
                }
            } catch {
                print("Error loading products: \(error.localizedDescription)")
                DebugLogger.shared.log("Error loading products: \(error.localizedDescription)", category: .error)
                DispatchQueue.main.async {
                    self.isLoadingProducts = false
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AuthService())
    }
}

// MARK: - Orders View
struct DashboardOrdersView: View {
    @EnvironmentObject private var orderService: OrderService
    
    var body: some View {
        NavigationView {
            ZStack {
                if orderService.isLoading {
                    ProgressView()
                } else if let error = orderService.error {
                    VStack {
                        Text("Error loading orders")
                            .font(AppFonts.body)
                            .foregroundColor(Color(AppColors.errorRed))
                        
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(Color(AppColors.mediumGray))
                            .padding(.top, 4)
                        
                        Button("Retry") {
                            // This will be called when we have a restaurant ID
                        }
                        .padding(.top, 16)
                    }
                } else if orderService.orders.isEmpty {
                    Text("No orders yet")
                        .font(AppFonts.body)
                        .foregroundColor(Color(AppColors.mediumGray))
                } else {
                    List {
                        ForEach(orderService.orders) { order in
                            // Using the order row view without navigation for now
                            OrderRowView(order: order)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        // This will be called when we have a restaurant ID
                    }
                }
            }
            .navigationTitle("Orders")
        }
    }
}

// MARK: - Menu View
struct MenuView: View {
    // Data passed from parent
    var products: [Product]
    var isLoading: Bool
    
    @State private var showAddProduct = false
    @State private var errorMessage: String? = nil
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    VStack {
                        Text("Error loading menu")
                            .font(AppFonts.body)
                            .foregroundColor(Color(AppColors.errorRed))
                        
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(Color(AppColors.mediumGray))
                            .padding(.top, 4)
                        
                        Button("Retry") {
                            // This would reload products from parent
                        }
                        .padding(.top, 16)
                    }
                } else if products.isEmpty {
                    VStack {
                        Text("No menu items yet")
                            .font(AppFonts.body)
                            .foregroundColor(Color(AppColors.mediumGray))
                        
                        Button(action: {
                            showAddProduct = true
                        }) {
                            Text("Add Product")
                                .font(AppFonts.buttonText)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(AppColors.primaryGreen))
                                .cornerRadius(10)
                        }
                        .padding(.top, 16)
                    }
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ProductRowView(product: product)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        // This would reload products from parent
                    }
                    .searchable(text: $searchText, prompt: "Search menu items")
                }
            }
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddProduct = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddProduct) {
                // This will need to be updated to not use ProductService
                ProductFormView(isPresented: $showAddProduct)
            }
        }
    }
    
    // Filter products based on search text
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText) ||
                product.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profile")) {
                    if let user = authService.currentUser {
                        NavigationLink(destination: ProfileEditView()) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.restaurantName)
                                        .font(AppFonts.body)
                                    Text(user.cuisine)
                                        .font(AppFonts.caption)
                                        .foregroundColor(Color(AppColors.mediumGray))
                                }
                                
                                Spacer()
                                
                                if let image = user.restaurantImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color(AppColors.mediumGray))
                                        .padding(10)
                                        .background(Color(AppColors.lightGray))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("App")) {
                    Button(action: {
                        authService.logout()
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(Color(AppColors.errorRed))
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color(AppColors.errorRed))
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Color(AppColors.mediumGray))
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Order Row
struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Order #\(order.id.suffix(6))")
                    .font(AppFonts.body.bold())
                
                Text("\(order.items.count) items • $\(order.totalAmount)")
                    .font(AppFonts.caption)
                    .foregroundColor(Color(AppColors.mediumGray))
            }
            
            Spacer()
            
            // Status indicator
            if let status = Order.Status(rawValue: order.status) {
                Text(status.displayName)
                    .font(AppFonts.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: UIColor(hex: status.color) ?? .systemGray).opacity(0.2))
                    .foregroundColor(Color(uiColor: UIColor(hex: status.color) ?? .systemGray))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Product Row
struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        HStack {
            // Product image
            if let image = product.productPhoto {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(AppColors.mediumGray))
                    .frame(width: 60, height: 60)
                    .background(Color(AppColors.lightGray))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(AppFonts.body.bold())
                
                Text(product.category)
                    .font(AppFonts.caption)
                    .foregroundColor(Color(AppColors.mediumGray))
                
                Text("$\(product.price)")
                    .font(AppFonts.caption.bold())
            }
            
            Spacer()
            
            // Availability toggle
            Circle()
                .fill(product.isAvailable ? Color(AppColors.primaryGreen) : Color(AppColors.mediumGray))
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
} 