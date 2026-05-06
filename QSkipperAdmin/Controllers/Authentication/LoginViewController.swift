import UIKit
import SwiftUI
import Combine

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private var loginView: UIHostingController<LoginControllerView>!
    private var viewModel = LoginControllerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupUI()
        
        // Set background color
        view.backgroundColor = UIColor(AppColors.backgroundWhite)
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Create SwiftUI view
        let swiftUIView = LoginControllerView(viewModel: viewModel)
        
        // Create hosting controller for SwiftUI view
        loginView = UIHostingController(rootView: swiftUIView)
        loginView.view.backgroundColor = .clear
        
        // Add as child view controller
        addChild(loginView)
        view.addSubview(loginView.view)
        loginView.didMove(toParent: self)
        
        // Setup constraints
        loginView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginView.view.topAnchor.constraint(equalTo: view.topAnchor),
            loginView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loginView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loginView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$navigateToHome
            .dropFirst()
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToHome()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$navigateToRegister
            .dropFirst()
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToRegister()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        // Instead of setting RootSplitViewController, just update AuthService's state
        // This will trigger ContentView to show our new SwiftUI MainView
        DispatchQueue.main.async {
            // The ContentView observes this and will automatically show MainView
            DebugLogger.shared.log("Setting authenticated state to true", category: .navigation)
        }
        
        // Get a reference to the window scene
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        // Create a new ContentView with the updated auth state
        let contentView = ContentView()
            .environmentObject(AuthService.shared)
            .environmentObject(DataController.shared)
            .modifier(DeviceAdaptiveModifier())
        
        // Create a hosting controller for the ContentView
        let hostingController = UIHostingController(rootView: contentView)
        
        // Animate transition
        UIView.transition(with: window!, 
                         duration: 0.4, 
                         options: .transitionCrossDissolve, 
                         animations: {
            // Set the root view controller directly
            window?.rootViewController = hostingController
            DebugLogger.shared.log("Root view controller changed to ContentView", category: .navigation)
        })
    }
    
    private func navigateToRegister() {
        // Instead of presenting/pushing the view controller,
        // post a notification to switch to register view in ContentView
        NotificationCenter.default.post(name: NSNotification.Name("ShowRegisterScreen"), object: nil)
        DebugLogger.shared.log("Posted notification to show register screen", category: .navigation)
    }
}

// MARK: - LoginControllerView
struct LoginControllerView: View {
    @ObservedObject var viewModel: LoginControllerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad {
                // iPad layout - side by side
                HStack(spacing: 0) {
                    // Left side - branding
                    brandingView
                        .frame(width: geometry.size.width * 0.4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.primaryGreen.opacity(0.9),
                                    AppColors.primaryGreen
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Right side - login form
                    ScrollView {
                        VStack(spacing: 32) {
                            // Welcome header
                            VStack(spacing: 12) {
                                Text("Welcome Back")
                                    .font(AppFonts.title)
                                    .foregroundColor(AppColors.darkGray)
                                
                                Text("Sign in to continue")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.mediumGray)
                            }
                            .padding(.top, 60)
                            
                            // Form
                            loginFormView
                                .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                    .frame(width: geometry.size.width * 0.6)
                    .background(AppColors.backgroundWhite)
                }
            } else {
                // iPhone layout - stacked
                ZStack {
                    // Background
                    AppColors.backgroundWhite
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Logo and title
                            VStack(spacing: 16) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(AppColors.primaryGreen)
                                
                                Text(AppConstants.appName)
                                    .font(AppFonts.title)
                                    .foregroundColor(AppColors.darkGray)
                            }
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                            
                            // Form
                            loginFormView
                                .padding(.horizontal, 24)
                            
                            Spacer().frame(height: 40)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
            
            // Error alert
            if viewModel.showErrorAlert {
                VStack {
                    Text(viewModel.errorMessage)
                        .font(AppFonts.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppColors.errorRed)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            // Auto-hide after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    viewModel.showErrorAlert = false
                                }
                            }
                        }
                    
                    Spacer()
                }
            }
        }
        .animation(.easeInOut, value: viewModel.showErrorAlert)
    }
    
    // Branding view for iPad layout
    private var brandingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App logo
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            // App name
            Text(AppConstants.appName)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            // Tagline
            Text("Restaurant Admin Portal")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 60)
            
            Spacer()
            
            // Footer
            Text("© 2025 QSkipper. All rights reserved.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Login form elements
    private var loginFormView: some View {
        VStack(spacing: 24) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Enter your email", text: $viewModel.email)
                    .font(AppFonts.body)
                    .padding()
                    .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(viewModel.isLoading)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                SecureField("Enter your password", text: $viewModel.password)
                    .font(AppFonts.body)
                    .padding()
                    .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05))
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)
                    .textContentType(.none)
            }
            
            // Forgot password
//            HStack {
//                Spacer()
//                
//                Button(action: {
//                    // viewModel.forgotPassword()
//                }) {
//                    Text("Forgot Password?")
//                        .font(AppFonts.caption)
//                        .foregroundColor(AppColors.primaryGreen)
//                }
//            }
            .padding(.top, 4)
            
            // Login button
            Button(action: {
                viewModel.login()
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Sign In")
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(AppColors.primaryGreen)
            .cornerRadius(10)
            .padding(.top, 16)
            .disabled(viewModel.isLoading)
            
            // Register link
            HStack {
                Text("Don't have an account?")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                Button(action: {
                    viewModel.navigateToRegister = true
                }) {
                    Text("Sign Up")
                        .font(AppFonts.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryGreen)
                }
                .onTapGesture {
                    // Add an additional direct post of the notification
                    // This ensures it works even if the view model binding fails
                    NotificationCenter.default.post(name: NSNotification.Name("ShowRegisterScreen"), object: nil)
                    DebugLogger.shared.log("Sign Up button tapped directly", category: .userAction)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - LoginControllerViewModel
class LoginControllerViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    
    @Published var isLoading = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    @Published var navigateToHome = false
    @Published var navigateToRegister = false
    
    // Validation
    private func validateInputs() -> Bool {
        var isValid = true
        
        // Validate email
        if email.isEmpty {
            emailError = "Email is required"
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email"
            isValid = false
        } else {
            emailError = nil
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else {
            passwordError = nil
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // API calls
    func login() {
        // Validate inputs
        guard validateInputs() else {
            return
        }
        
        isLoading = true
        DebugLogger.shared.log("Starting login process with email: \(email)", category: .auth)
        
        Task {
            do {
                // Use restaurant login endpoint directly
                let response = try await AuthService.shared.loginRestaurantDirect(email: email, password: password)
                
                DebugLogger.shared.log("Login completed successfully", category: .auth)
                
                // Update DataController with the response if available
                if let response = response {
                    DispatchQueue.main.async {
                        DataController.shared.setCurrentUser(from: response)
                        DebugLogger.shared.log("DataController updated with user info", category: .auth)
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    
                    // Check if we have a user ID, which confirms successful login
                    if AuthService.shared.getUserId() != nil {
                        self?.navigateToHome = true
                        DebugLogger.shared.log("Login successful, navigating to home", category: .auth)
                    } else {
                        self?.errorMessage = "Failed to get user ID after login"
                        self?.showErrorAlert = true
                        DebugLogger.shared.log("Login failed: No user ID returned", category: .auth)
                    }
                }
            } catch {
                DebugLogger.shared.log("Login error: \(error.localizedDescription)", category: .auth)
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                }
            }
        }
    }
    
    func register() {
        navigateToRegister = true
    }
} 
