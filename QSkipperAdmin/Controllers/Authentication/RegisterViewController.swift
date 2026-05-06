import UIKit
import SwiftUI
import Combine

class RegisterViewController: UIViewController {
    
    // MARK: - Properties
    private var registerView: UIHostingController<RegisterView>!
    private var viewModel = RegisterViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        DebugLogger.shared.logViewDidLoad(viewController: "RegisterViewController")
        setupBindings()
        setupUI()
        
        // Configure for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Remove title in iPad form sheet presentation
            title = ""
            
            // Add close button for modal presentation on iPad
            let closeButton = UIBarButtonItem(
                image: UIImage(systemName: "xmark.circle.fill"),
                style: .plain,
                target: self,
                action: #selector(dismissModal)
            )
            closeButton.tintColor = UIColor(AppColors.darkGray)
            navigationItem.leftBarButtonItem = closeButton
        } else {
            // Configure navigation bar for iPhone
            title = "Create Account"
            navigationController?.navigationBar.prefersLargeTitles = true
            
            // Add back button for iPhone
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.left"),
                style: .plain,
                target: self,
                action: #selector(dismissModal)
            )
            backButton.tintColor = UIColor(AppColors.darkGray)
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DebugLogger.shared.logViewWillAppear(viewController: "RegisterViewController")
        
        // Hide navigation bar for iPad to maximize space
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DebugLogger.shared.logViewDidAppear(viewController: "RegisterViewController")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DebugLogger.shared.logViewWillDisappear(viewController: "RegisterViewController")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DebugLogger.shared.logViewDidDisappear(viewController: "RegisterViewController")
    }
    
    // MARK: - Setup
    private func setupUI() {
        DebugLogger.shared.log("Setting up RegisterViewController UI", category: .lifecycle)
        
        // Set background color
        view.backgroundColor = UIColor(AppColors.backgroundWhite)
        
        // Create SwiftUI view
        let swiftUIView = RegisterView(viewModel: viewModel)
        
        // Create hosting controller for SwiftUI view
        registerView = UIHostingController(rootView: swiftUIView)
        registerView.view.backgroundColor = .clear
        
        // Add as child view controller
        addChild(registerView)
        view.addSubview(registerView.view)
        registerView.didMove(toParent: self)
        
        // Setup constraints
        registerView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            registerView.view.topAnchor.constraint(equalTo: view.topAnchor),
            registerView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            registerView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            registerView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        DebugLogger.shared.log("RegisterViewController UI setup complete", category: .lifecycle)
    }
    
    private func setupBindings() {
        DebugLogger.shared.log("Setting up RegisterViewController bindings", category: .lifecycle)
        
        viewModel.$navigateToHome
            .dropFirst()
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    DebugLogger.shared.log("Navigation to home triggered from registration", category: .navigation)
                    self?.navigateToHome()
                }
            }
            .store(in: &cancellables)
            
        viewModel.$navigateBack
            .dropFirst()
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    DebugLogger.shared.log("Navigation back to login triggered", category: .navigation)
                    NotificationCenter.default.post(name: NSNotification.Name("ShowLoginScreen"), object: nil)
                }
            }
            .store(in: &cancellables)
        
        DebugLogger.shared.log("RegisterViewController bindings setup complete", category: .lifecycle)
    }
    
    // MARK: - Actions
    @objc private func dismissModal() {
        DebugLogger.shared.log("Posting notification to show login screen", category: .navigation)
        NotificationCenter.default.post(name: NSNotification.Name("ShowLoginScreen"), object: nil)
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        DebugLogger.shared.log("Navigating to home screen after registration", category: .navigation)
        
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
        
        // Use a transition animation and set the root view controller directly
        UIView.transition(with: window!, 
                         duration: 0.5, 
                         options: .transitionCrossDissolve, 
                         animations: {
            // Set the root view controller directly on the window
            window?.rootViewController = hostingController
            DebugLogger.shared.log("Root view controller changed to ContentView", category: .navigation)
        })
    }
}

// MARK: - SwiftUI View
struct RegisterView: View {
    @ObservedObject var viewModel: RegisterViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad {
                // iPad layout - side by side
                HStack(spacing: 0) {
                    // Left side - image and tagline
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 24) {
                            // App logo
                            Image(systemName: "fork.knife.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white)
                            
                            // Tagline
                            Text("Join \(AppConstants.appName)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Create your restaurant account and start managing orders")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        // Features list
                        VStack(alignment: .leading, spacing: 16) {
                            featureRow(icon: "checkmark.circle.fill", text: "Easy onboarding process")
                            featureRow(icon: "checkmark.circle.fill", text: "Customizable restaurant profile")
                            featureRow(icon: "checkmark.circle.fill", text: "Secure authentication")
                        }
                        .padding(.bottom, 60)
                    }
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
                    
                    // Right side - registration form
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Create Restaurant Account")
                                    .font(AppFonts.title)
                                    .foregroundColor(AppColors.darkGray)
                                
                                Text("Fill in your details to get started")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.mediumGray)
                            }
                            .padding(.top, 60)
                            
                            // Form
                            registrationForm
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(width: geometry.size.width * 0.6)
                    .background(AppColors.backgroundWhite)
                }
            } else {
                // iPhone layout - stacked
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("Create Restaurant Account")
                            .font(AppFonts.title)
                            .foregroundColor(AppColors.darkGray)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                            .onAppear {
                                DebugLogger.shared.log("Registration form view appeared", category: .lifecycle)
                            }
                        
                        // Form
                        registrationForm
                            .padding(.horizontal, 24)
                        
                        // Already have account button
                        Button(action: {
                            viewModel.navigateBack = true
                        }) {
                            Text("Already have an account? Sign In")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryGreen)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.bottom, 40)
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
                    
                    Spacer()
                }
                .zIndex(1)
            }
        }
    }
    
    // MARK: - Components
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 32)
    }
    
    private var registrationForm: some View {
        VStack(spacing: 24) {
            // Account Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Information")
                    .font(AppFonts.sectionTitle)
                    .foregroundColor(AppColors.darkGray)
                    .padding(.top, 8)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.darkGray)
                    
                    TextField("Enter your email address", text: $viewModel.email)
                        .font(AppFonts.body)
                        .padding()
                        .background(AppColors.lightGray)
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    if let error = viewModel.emailError {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.errorRed)
                    }
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.darkGray)
                    
                    SecureField("Create a password", text: $viewModel.password)
                        .font(AppFonts.body)
                        .padding()
                        .background(AppColors.lightGray)
                        .cornerRadius(8)
                        .textContentType(.none)
                    
                    if let error = viewModel.passwordError {
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.errorRed)
                    }
                }
            }
            
            // Register button
            Button(action: {
                viewModel.register()
            }) {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .font(AppFonts.buttonText)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primaryGreen)
                .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
            .padding(.top, 16)
            
            // Sign in link (iPad only)
            if horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad {
                Button(action: {
                    viewModel.navigateBack = true
                }) {
                    Text("Already have an account? Sign In")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.primaryGreen)
                }
                .padding(.top, 8)
            }
            
            // Terms
            Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
    }
}

// MARK: - ViewModel
class RegisterViewModel: ObservableObject {
    // Account info
    @Published var email = ""
    @Published var password = ""
    
    // Form validation errors
    @Published var emailError: String?
    @Published var passwordError: String?
    
    // UI state
    @Published var isLoading = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    // Navigation
    @Published var navigateToHome = false
    @Published var navigateBack = false
    
    init() {
        DebugLogger.shared.log("RegisterViewModel initialized", category: .lifecycle)
    }
    
    // Validation
    private func validateInputs() -> Bool {
        DebugLogger.shared.log("Validating registration form inputs", category: .custom)
        
        var isValid = true
        
        // Validate email
        if email.isEmpty {
            emailError = "Email is required"
            DebugLogger.shared.log("Validation error: Email is required", category: .custom, tag: "VALIDATION")
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
            DebugLogger.shared.log("Validation error: Invalid email format", category: .custom, tag: "VALIDATION")
            isValid = false
        } else {
            emailError = nil
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password is required"
            DebugLogger.shared.log("Validation error: Password is required", category: .custom, tag: "VALIDATION")
            isValid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            DebugLogger.shared.log("Validation error: Password too short", category: .custom, tag: "VALIDATION")
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
    func register() {
        DebugLogger.shared.log("Register button tapped", category: .userAction)
        
        guard validateInputs() else {
            DebugLogger.shared.log("Registration validation failed", category: .custom, tag: "VALIDATION")
            return
        }
        
        isLoading = true
        DebugLogger.shared.log("Starting registration API call", category: .network)
        
        Task {
            do {
                try await AuthService.shared.register(email: email, password: password, name: "Restaurant Owner")
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.navigateToHome = true
                    DebugLogger.shared.log("Registration successful", category: .network, tag: "SUCCESS")
                }
            } catch {
                DebugLogger.shared.log("Registration error: \(error.localizedDescription)", category: .network, tag: "ERROR")
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                }
            }
        }
    }
}
