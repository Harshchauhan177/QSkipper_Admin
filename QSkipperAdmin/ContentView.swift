//
//  ContentView.swift
//  QSkipperAdmin
//
//  Created by Keshav Lohiya on 19/05/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showRegisterScreen = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Always use our SwiftUI MainView with the 5-tab sidebar
                MainView()
                    .environmentObject(authService)
                    .environmentObject(DataController.shared)
                    .transition(.opacity)
            } else if showRegisterScreen {
                // Use RegisterViewController from QSkipperAdminApp.swift
                RegisterViewControllerRepresentable()
                    .edgesIgnoringSafeArea(.all)
                    .statusBar(hidden: false)
                    .transition(.opacity)
                    .onAppear {
                        // Set up notification for going back to login
                        NotificationCenter.default.addObserver(
                            forName: NSNotification.Name("ShowLoginScreen"),
                            object: nil,
                            queue: .main) { _ in
                                withAnimation(.easeInOut) {
                                    showRegisterScreen = false
                                }
                            }
                    }
            } else {
                // Use LoginViewController from QSkipperAdminApp.swift
                LoginViewControllerRepresentable()
                    .edgesIgnoringSafeArea(.all)
                    .statusBar(hidden: false)
                    .onAppear {
                        // Set up notification for register navigation
                        NotificationCenter.default.addObserver(
                            forName: NSNotification.Name("ShowRegisterScreen"),
                            object: nil,
                            queue: .main) { _ in
                                withAnimation(.easeInOut) {
                                    showRegisterScreen = true
                                }
                            }
                    }
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: showRegisterScreen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
    }
}
