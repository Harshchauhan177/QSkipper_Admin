import SwiftUI

struct OrderCardView: View {
    let order: APIOrder
    let themeColor: Color
    var onCompleteOrder: () -> Void
    var isProcessing: Bool = false
    
    // Default parameter for backward compatibility
    init(order: APIOrder, themeColor: Color = .blue, isProcessing: Bool = false, onCompleteOrder: @escaping () -> Void) {
        self.order = order
        self.themeColor = themeColor
        self.isProcessing = isProcessing
        self.onCompleteOrder = onCompleteOrder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with order ID and status
            HStack {
                Text("Order #\(order.id.suffix(6))")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Status pill
                Text(order.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(getStatusColor().opacity(0.2))
                    .foregroundColor(getStatusColor())
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Date and takeaway info
            if order.isScheduled {
                // Special prominent display for scheduled orders
                HStack(alignment: .top) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(themeColor)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(themeColor)
                            .fontWeight(.bold)
                        
                        Text(order.formattedOrderTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Show time remaining
                        if let timeRemaining = order.timeUntilScheduled {
                            Text(timeRemaining)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    if order.takeAway {
                        Label("Takeaway", systemImage: "bag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("Dine-in", systemImage: "fork.knife")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(themeColor.opacity(0.1))
                .cornerRadius(8)
            } else {
                // Regular display for non-scheduled orders
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                
                Text(order.formattedDate)
                    .font(.subheadline)
                
                Spacer()
                
                if order.takeAway {
                    Label("Takeaway", systemImage: "bag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Label("Dine-in", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            // Cook time
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                
                Text("\(order.cookTime) min cook time")
                    .font(.subheadline)
            }
            
            Divider()
            
            // Order items
            VStack(alignment: .leading, spacing: 8) {
                Text("Items")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(order.items) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(item.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("₹\(item.price)")
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            // Total amount
            HStack {
                Text("Total")
                    .font(.headline)
                
                Spacer()
                
                Text(order.totalAmountFormatted)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            // Action button (with processing state)
            if order.status.lowercased() != "completed" {
                Button(action: onCompleteOrder) {
                    HStack {
                        Spacer()
                        
                        if isProcessing {
                            // Show loading indicator when processing
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        }
                        
                        Text(isProcessing ? "Processing..." : "Mark as Completed")
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(isProcessing ? themeColor.opacity(0.7) : themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(order.isScheduled ? themeColor.opacity(0.5) : Color.clear, lineWidth: order.isScheduled ? 2 : 0)
        )
        // Apply a faded look if the order is being processed
        .opacity(isProcessing ? 0.9 : 1.0)
    }
    
    // Override the status color based on status and theme
    private func getStatusColor() -> Color {
        switch order.status.lowercased() {
        case "placed", "pending":
            return .orange
        case "schedule", "scheduled":
            return themeColor
        case "preparing":
            return .purple
        case "ready":
            return themeColor
        case "completed":
            return .gray
        case "cancelled":
            return .red
        default:
            return .primary
        }
    }
}

#if DEBUG
struct OrderCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleOrder = APIOrder(
            id: "6829e56298cf46b5a6c7d1e0",
                            restaurantId: "",
            userId: "67f3c28f88bf68596e89b7af",
            items: [
                APIOrderProduct(
                    id: "6829e56298cf46b5a6c7d1e1",
                    name: "Pav Bhaji",
                    quantity: 1,
                    price: 80
                )
            ],
            totalAmount: "83",
            status: "Schedule",
            cookTime: 30,
            takeAway: false,
            scheduleDate: "2025-05-19T11:30:00.000Z",
            orderTime: "2025-05-18T13:49:22.235Z"
        )
        
        return Group {
            OrderCardView(order: sampleOrder, themeColor: .green, onCompleteOrder: {})
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.light)
            
            OrderCardView(order: sampleOrder, themeColor: .green, isProcessing: true, onCompleteOrder: {})
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
#endif 