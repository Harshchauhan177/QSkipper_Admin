//
//  ContentView.swift
//  QSkipperAdmin
//
//  Created by Keshav Lohiya on 19/05/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Always use our SwiftUI MainView with the 5-tab sidebar
                MainView()
                    .environmentObject(authService)
                    .environmentObject(DataController.shared)
                    .transition(.opacity)
            } else {
                // Use LoginViewController from QSkipperAdminApp.swift
                LoginViewControllerRepresentable()
                    .edgesIgnoringSafeArea(.all)
                    .statusBar(hidden: false)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
    }
}
