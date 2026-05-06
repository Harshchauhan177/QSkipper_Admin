import UIKit
import SwiftUI
import Combine

class OrdersViewController: UIViewController {
    
    // MARK: - Properties
    private var ordersView: UIHostingController<OrdersUIView>!
    private var viewModel = OrdersViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupUI()
        setupNavigation()
        
        // Load data
        viewModel.loadOrders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data when view appears
        viewModel.loadOrders()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Create SwiftUI view
        let swiftUIView = OrdersUIView(viewModel: viewModel)
        
        // Create hosting controller for SwiftUI view
        ordersView = UIHostingController(rootView: swiftUIView)
        
        // Add as child view controller
        addChild(ordersView)
        view.addSubview(ordersView.view)
        ordersView.didMove(toParent: self)
        
        // Setup constraints
        ordersView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ordersView.view.topAnchor.constraint(equalTo: view.topAnchor),
            ordersView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ordersView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ordersView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigation() {
        title = "Orders"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Refresh button
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupBindings() {
        viewModel.$selectedOrder
            .compactMap { $0 }
            .sink { [weak self] order in
                self?.presentOrderDetailsSheet(order: order)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func refreshButtonTapped() {
        viewModel.loadOrders()
    }
    
    private func presentOrderDetailsSheet(order: Order) {
        let orderDetailsController = UIHostingController(rootView: OrderDetailsView(
            viewModel: OrderDetailsViewModel(order: order) { [weak self] in
                self?.viewModel.loadOrders()
                self?.dismiss(animated: true)
            }
        ))
        
        if let sheet = orderDetailsController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(orderDetailsController, animated: true) {
            self.viewModel.selectedOrder = nil
        }
    }
}

// MARK: - SwiftUI View
struct OrdersUIView: View {
    @ObservedObject var viewModel: OrdersViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading orders...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.orders.isEmpty {
                emptyStateView
            } else {
                orderListView
            }
            
            if viewModel.showErrorAlert && !viewModel.errorMessage.contains("not authenticated") {
                Text(viewModel.errorMessage)
                    .font(AppFonts.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppColors.errorRed)
                    .cornerRadius(8)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                viewModel.showErrorAlert = false
                            }
                        }
                    }
                    .zIndex(1)
            }
        }
        .refreshable {
            await viewModel.refreshOrders()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(AppColors.mediumGray)
            
            Text("No Orders")
                .font(AppFonts.title)
                .foregroundColor(AppColors.darkGray)
            
            Text("You don't have any orders yet")
                .font(AppFonts.body)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
            
            SecondaryButton(title: "Refresh", action: {
                viewModel.loadOrders()
            })
            .frame(width: 200)
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var orderListView: some View {
        List {
            ForEach(viewModel.filteredOrders) { order in
                OrderCell(order: order, onSelect: {
                    viewModel.selectOrder(order)
                })
            }
        }
        .listStyle(PlainListStyle())
        .searchable(text: $viewModel.searchText, prompt: "Search orders")
    }
}

// MARK: - Order Cell
struct OrderCell: View {
    let order: Order
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Order #\(order.id.suffix(6))")
                        .font(AppFonts.sectionTitle)
                        .foregroundColor(AppColors.darkGray)
                    
                    Spacer()
                    
                    orderStatusBadge
                }
                
                Text("\(itemsCount) items · $\(String(format: "%.2f", Double(order.totalAmount)))")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.darkGray)
                
                Text("Ordered on \(order.formattedDate)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Compute items count based on available data
    private var itemsCount: Int {
        if !order.products.isEmpty {
            return order.products.count
        } else {
            return order.items.count
        }
    }
    
    private var orderStatusBadge: some View {
        Text(order.status.capitalized)
            .font(AppFonts.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch order.status.lowercased() {
        case "pending":
            return Color.orange
        case "completed":
            return AppColors.primaryGreen
        case "cancelled":
            return AppColors.errorRed
        default:
            return AppColors.mediumGray
        }
    }
}

// MARK: - ViewModel
class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    
    @Published var selectedOrder: Order? = nil
    
    // Timer for auto-refresh
    private var refreshTimer: Timer?
    
    init() {
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func setupAutoRefresh() {
        // Refresh orders every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.loadOrders()
        }
    }
    
    // Computed property for filtered orders
    var filteredOrders: [Order] {
        if searchText.isEmpty {
            return orders.sorted { $0.createdAt > $1.createdAt }
        } else {
            return orders.filter { order in
                let orderIdMatch = order.id.localizedCaseInsensitiveContains(searchText)
                let statusMatch = order.status.localizedCaseInsensitiveContains(searchText)
                let dateMatch = order.formattedDate.localizedCaseInsensitiveContains(searchText)
                
                return orderIdMatch || statusMatch || dateMatch
            }
            .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // Load orders from API
    func loadOrders() {
        isLoading = true
        
        Task {
            do {
                let fetchedOrders = try await OrderService.shared.getCachedOrders()
                
                DispatchQueue.main.async { [weak self] in
                    self?.orders = fetchedOrders
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                }
            }
        }
    }
    
    // Refresh orders (for pull-to-refresh)
    func refreshOrders() async {
        do {
            // Force a fresh fetch by invalidating cache
            OrderService.shared.invalidateOrderCache()
            let fetchedOrders = try await OrderService.shared.getOrders()
            
            DispatchQueue.main.async { [weak self] in
                self?.orders = fetchedOrders
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = error.localizedDescription
                self?.showErrorAlert = true
            }
        }
    }
    
    // Select order for detail view
    func selectOrder(_ order: Order) {
        selectedOrder = order
    }
} 