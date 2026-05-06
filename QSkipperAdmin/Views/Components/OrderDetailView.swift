import SwiftUI

struct OrderDetailView: View {
    let order: APIOrder
    let themeColor: Color
    var onCompleteOrder: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    // Default parameter for backward compatibility
    init(order: APIOrder, themeColor: Color = .blue, onCompleteOrder: (() -> Void)? = nil) {
        self.order = order
        self.themeColor = themeColor
        self.onCompleteOrder = onCompleteOrder
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Order ID and dismiss button
                HStack {
                    Text("Order Details")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Scheduled Time Alert (Priority box for scheduled orders)
                if order.isScheduled, let timeRemaining = order.timeUntilScheduled {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Scheduled Order")
                                .font(.headline)
                                .foregroundColor(themeColor)
                        }
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(themeColor)
                            Text(order.formattedDate)
                                .font(.headline)
                                .foregroundColor(themeColor)
                        }
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text(timeRemaining)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeColor.opacity(0.15))
                    .cornerRadius(12)
                }
                
                // Order ID and Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order #\(order.id.suffix(6))")
                        .font(.headline)
                    
                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        
                        Text(order.status.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(getStatusColor().opacity(0.2))
                            .foregroundColor(getStatusColor())
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(order.isScheduled ? themeColor.opacity(0.5) : Color.clear, lineWidth: order.isScheduled ? 2 : 0)
                )
                
                // Order Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Information")
                        .font(.headline)
                    
                    Divider()
                    
                    if order.isScheduled {
                        infoRow(
                            label: "Delivery Time", 
                            value: order.scheduledDateTime.displayString,
                            isHighlighted: true
                        )
                        infoRow(label: "Order Placed", value: order.orderDateTime.displayString)
                    } else {
                        infoRow(label: "Order Time", value: order.orderDateTime.displayString)
                    }
                    
                    infoRow(label: "Cook Time", value: "\(order.cookTime) minutes")
                    infoRow(label: "Order Type", value: order.takeAway ? "Takeaway" : "Dine-in")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Items Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Items")
                        .font(.headline)
                    
                    Divider()
                    
                    ForEach(order.items) { item in
                        HStack(alignment: .top) {
                            Text("\(item.quantity)x")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.subheadline)
                                
                                if let notes = item.name.components(separatedBy: " - ").last, notes != item.name {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("₹\(item.price)")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                        
                        if order.items.last?.id != item.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Pricing Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Summary")
                        .font(.headline)
                    
                    Divider()
                    
                    // Subtotal
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(order.totalAmountFormatted)
                    }
                    
                    // Tax and fees (estimated)
                    if let amount = Double(order.totalAmount), amount > 0 {
                        let tax = amount * 0.05 // Assuming 5% tax
                        
                        HStack {
                            Text("Tax & Fees")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "₹%.2f", tax))
                        }
                        
                        Divider()
                        
                        // Total
                        HStack {
                            Text("Total")
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(String(format: "₹%.2f", amount + tax))
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Button
                if order.status.lowercased() != "completed" && onCompleteOrder != nil {
                    Button {
                        isProcessing = true
                        // Use DispatchQueue to create a slight delay to ensure UI updates
                        DispatchQueue.main.async {
                        onCompleteOrder?()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            }
                            
                            Text(isProcessing ? "Processing..." : "Mark as Completed")
                            .fontWeight(.semibold)
                            
                            Spacer()
                        }
                            .frame(maxWidth: .infinity)
                            .padding()
                        .background(isProcessing ? themeColor.opacity(0.7) : themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                    .disabled(isProcessing)
                }
            }
            .padding()
            .disabled(isProcessing)
            .overlay(
                ZStack {
                    if isProcessing {
                        Color.black.opacity(0.05)
                            .ignoresSafeArea()
                    }
                }
            )
        }
    }
    
    private func infoRow(label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(isHighlighted ? themeColor : .primary)
        }
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
struct OrderDetailView_Previews: PreviewProvider {
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
                ),
                APIOrderProduct(
                    id: "6829e56298cf46b5a6c7d1e2",
                    name: "Samosa - Extra spicy",
                    quantity: 2,
                    price: 30
                )
            ],
            totalAmount: "140",
            status: "Schedule",
            cookTime: 30,
            takeAway: false,
            scheduleDate: "2025-05-19T11:30:00.000Z",
            orderTime: "2025-05-18T13:49:22.235Z"
        )
        
        OrderDetailView(order: sampleOrder, themeColor: .green, onCompleteOrder: {})
            .preferredColorScheme(.light)
    }
}
#endif 