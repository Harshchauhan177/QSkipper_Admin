import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    // Form inputs
    @Published var email: String = ""
    @Published var password: String = ""
    
    // UI states
    @Published var isLoggingIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var navigateToRegister: Bool = false
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor auth service errors
        authService.$error
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.showErrorAlert = !errorMessage.isEmpty
                self?.isLoggingIn = false
            }
            .store(in: &cancellables)
    }
    
    func login() {
        // Form validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            showErrorAlert = true
            return
        }
        
        isLoggingIn = true
        
        // Call auth service
        authService.login(email: email, password: password)
    }
} 