import SwiftUI

struct LoginView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    
    // State
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(AppColors.lightGray)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 16) {
                        Image(systemName: "square.fill.text.grid.1x2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(AppColors.primaryGreen))
                        
                        Text(AppConstants.appName)
                            .font(AppFonts.title)
                            .foregroundColor(Color(AppColors.darkGray))
                    }
                    .padding(.bottom, 40)
                    
                    // Login form
                    VStack(spacing: 20) {
                        // Email field
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                        
                        // Password field
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.none)
                            .padding(.horizontal)
                        
                        // Login button
                        Button(action: {
                            loginUser()
                        }) {
                            Text("Sign In")
                                .font(AppFonts.buttonText)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(AppColors.primaryGreen))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(authService.isLoading)
                        
                        // Error message
                        if let error = authService.error {
                            Text(error)
                                .font(AppFonts.caption)
                                .foregroundColor(Color(AppColors.errorRed))
                                .padding(.horizontal)
                        }
                        
                        // Loading indicator
                        if authService.isLoading {
                            ProgressView()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Register navigation
                    NavigationLink(destination: RegisterFormView()) {
                        Text("Don't have an account? Sign Up")
                            .font(AppFonts.body)
                            .foregroundColor(Color(AppColors.primaryGreen))
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegistration) {
                RegisterFormView()
                    .environmentObject(authService)
            }
        }
    }
    
    private func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            authService.error = "Please enter email and password"
            return
        }
        
        authService.login(email: email, password: password)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthService())
    }
} 