import SwiftUI
import Combine

struct ModernOrdersView: View {
    @StateObject private var viewModel = ModernOrdersViewModel()
    @State private var refreshing = false
    @State private var selectedOrder: APIOrder?
    @State private var showOrderDetail = false
    
    // App theme colors
    private let themeColor = Color.green
    private let accentColor = Color.green.opacity(0.8)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundLayer
                
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    loadingView
                } else if viewModel.orders.isEmpty {
                    emptyStateView
                } else {
                    orderListView
                }
                
                // Success notification
                if viewModel.completionSuccess {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            
                            Text("Order marked as completed")
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(themeColor)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                    }
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $viewModel.selectedFilter) {
                            ForEach(ModernOrdersViewModel.OrderFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .foregroundColor(themeColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshOrders()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("New Orders")
                                .font(AppFonts.buttonText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .frame(height: 36)
                    }
                }
            }
            .alert(isPresented: $viewModel.showError, content: {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "Unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            })
            .sheet(isPresented: $showOrderDetail, content: {
                if let order = selectedOrder {
                    OrderDetailView(order: order, themeColor: themeColor, onCompleteOrder: {
                        Task {
                            await viewModel.completeOrder(order)
                            // Dismiss the sheet after marking as completed
                            showOrderDetail = false 
                        }
                    })
                }
            })
            .animation(.easeInOut(duration: 0.3), value: viewModel.completionSuccess)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force full width in iPad
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeColor)
            
            Text("Loading Orders...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(themeColor.opacity(0.7))
            
            Text("No Orders Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("New orders will appear here once customers place them")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await viewModel.refreshOrders()
                }
            }) {
                Text("Refresh")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    // MARK: - Order List View
    private var orderListView: some View {
        ScrollView {
            // Filter indicator
            if viewModel.selectedFilter != .all {
                HStack {
                    Text("Showing \(viewModel.selectedFilter.rawValue) Orders")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        viewModel.selectedFilter = .all
                    } label: {
                        Text("Clear Filter")
                            .font(.subheadline)
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Order count and debug info
            HStack {
                Text("\(viewModel.sortedOrders.count) orders")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Show how many scheduled orders
                let scheduledCount = viewModel.sortedOrders.filter { $0.isScheduled }.count
                if scheduledCount > 0 {
                    Text("\(scheduledCount) scheduled")
                        .font(.caption)
                        .foregroundColor(themeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sortedOrders) { order in
                    OrderCardView(
                        order: order,
                        themeColor: themeColor,
                        isProcessing: viewModel.isProcessing(order),
                        onCompleteOrder: {
                        completeOrder(order)
                    }
                    )
                    .padding(.horizontal)
                    .onTapGesture {
                        // Don't open details for processing orders
                        if !viewModel.isProcessing(order) {
                        selectedOrder = order
                        showOrderDetail = true
                        }
                    }
                    // Add a subtle animation when status changes
                    .animation(.easeInOut(duration: 0.2), value: order.status)
                    .transition(.opacity)
                }
            }
            .padding(.vertical)
            .refreshable {
                await viewModel.refreshOrders()
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading && !viewModel.orders.isEmpty {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
            }
        )
    }
    
    // MARK: - Actions
    private func completeOrder(_ order: APIOrder) {
        // Don't try to complete if already processing
        guard !viewModel.isProcessing(order) else { return }
        
        // Use a Task for async work
        Task {
            await viewModel.completeOrder(order)
        }
    }
}

#if DEBUG
struct ModernOrdersView_Previews: PreviewProvider {
    static var previews: some View {
        ModernOrdersView()
    }
}
#endif 