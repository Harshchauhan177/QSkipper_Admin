import SwiftUI

// This is the wrapper for our new OrdersView implementation
// which uses the API directly rather than the older OrderService
struct SwiftUIOrdersView: View {
    var body: some View {
        ModernOrdersView()
            .navigationViewStyle(StackNavigationViewStyle()) // Force full-width view
    }
}

#if DEBUG
struct SwiftUIOrdersView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIOrdersView()
    }
}
#endif 