import SwiftUI

struct OrderCardView: View {
    let order: APIOrder
    let themeColor: Color
    var onCompleteOrder: () -> Void
    var onAcceptOrder: (() -> Void)? = nil
    var onRejectOrder: (() -> Void)? = nil
    var onReportFraud: (() -> Void)? = nil
    var isProcessing: Bool = false
    @State private var showFraudConfirmation = false
    
    // Default parameter for backward compatibility
    init(order: APIOrder, themeColor: Color = .blue, isProcessing: Bool = false, onCompleteOrder: @escaping () -> Void, onAcceptOrder: (() -> Void)? = nil, onRejectOrder: (() -> Void)? = nil, onReportFraud: (() -> Void)? = nil) {
        self.order = order
        self.themeColor = themeColor
        self.isProcessing = isProcessing
        self.onCompleteOrder = onCompleteOrder
        self.onAcceptOrder = onAcceptOrder
        self.onRejectOrder = onRejectOrder
        self.onReportFraud = onReportFraud
    }
    
    /// Whether the order is in a pending/not-accepted state
    private var isNotAccepted: Bool {
        let s = order.status.lowercased()
        return s == "placed" || s == "pending"
    }
    
    /// Whether the order can be marked as completed (accepted but not yet completed)
    private var canComplete: Bool {
        let s = order.status.lowercased()
        return s == "processing" || s == "preparing" || s == "ready" || s == "schedule" || s == "scheduled" || s == "accepted"
    }
    
    /// Display label for the status
    private var statusDisplayLabel: String {
        let s = order.status.lowercased()
        switch s {
        case "placed", "pending": return "Not Accepted"
        case "processing": return "Processing"
        case "preparing": return "Preparing"
        case "ready": return "Ready"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        case "rejected": return "Rejected"
        case "fraud": return "Fraud"
        case "schedule", "scheduled": return "Scheduled"
        case "accepted": return "Accepted"
        default: return order.status.capitalized
        }
    }
    
    /// Whether the order is eligible for fraud reporting (completed + 50 mins passed)
    private var canReportFraud: Bool {
        guard order.status.lowercased() == "completed" else { return false }
        guard let updatedAtStr = order.updatedAt else { return false }
        guard let completedDate = order.parseISODateString(updatedAtStr) else { return false }
        return Date().timeIntervalSince(completedDate) >= 50 * 60 // 50 minutes
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
                Text(statusDisplayLabel)
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
            
            // Action buttons
            if isNotAccepted {
                // Accept / Reject buttons for new orders
                HStack(spacing: 12) {
                    // Reject button
                    Button(action: { onRejectOrder?() }) {
                        HStack {
                            Spacer()
                            
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            }
                            
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Reject")
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(isProcessing ? Color.red.opacity(0.5) : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessing)
                    
                    // Accept button
                    Button(action: { onAcceptOrder?() }) {
                        HStack {
                            Spacer()
                            
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            }
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Accept")
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(isProcessing ? themeColor.opacity(0.5) : themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessing)
                }
                .padding(.top, 8)
            } else if canComplete {
                // Mark as Completed button for accepted/processing orders
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
            } else if canReportFraud {
                // Report Fraud button for completed orders after 50 minutes
                Button(action: {
                    showFraudConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                        Text("Report Fraud")
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
                .disabled(isProcessing)
            }
            // No action buttons for cancelled, rejected, fraud orders
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
        .alert("Report Customer as Fraud", isPresented: $showFraudConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Block Customer", role: .destructive) {
                onReportFraud?()
            }
        } message: {
            Text("This customer is fraud/scam. Do you want to block them from the platform? They will not be able to order from any restaurant.")
        }
    }
    
    // Override the status color based on status and theme
    private func getStatusColor() -> Color {
        switch order.status.lowercased() {
        case "placed", "pending":
            return .orange
        case "schedule", "scheduled":
            return themeColor
        case "processing", "preparing":
            return .purple
        case "ready":
            return themeColor
        case "completed":
            return .gray
        case "cancelled", "rejected":
            return .red
        case "fraud":
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
            status: "placed",
            cookTime: 30,
            takeAway: false,
            scheduleDate: nil,
            orderTime: "2025-05-18T13:49:22.235Z"
        )
        
        return Group {
            OrderCardView(order: sampleOrder, themeColor: .green, onCompleteOrder: {}, onAcceptOrder: {}, onRejectOrder: {})
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.light)
                .previewDisplayName("Not Accepted")
            
            OrderCardView(order: sampleOrder, themeColor: .green, isProcessing: true, onCompleteOrder: {}, onAcceptOrder: {}, onRejectOrder: {})
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName("Processing")
        }
    }
}
#endif