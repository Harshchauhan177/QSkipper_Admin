import SwiftUI

struct RegisterFormView: View {
    // Environment
    @EnvironmentObject private var authService: AuthService
    @Environment(\.presentationMode) private var presentationMode
    
    // State
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(AppColors.lightGray)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Title
                    Text("Create Account")
                        .font(AppFonts.title)
                        .foregroundColor(Color(AppColors.darkGray))
                        .padding(.top)
                    
                    // Registration form
                    VStack(spacing: 20) {
                        // Name field
                        TextField("Restaurant Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
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
                        
                        // Confirm Password field
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.none)
                            .padding(.horizontal)
                        
                        // Register button
                        Button(action: {
                            registerUser()
                        }) {
                            Text("Sign Up")
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
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(AppColors.darkGray))
                    }
                }
            }
        }
    }
    
    private func registerUser() {
        // Validate fields
        guard !name.isEmpty else {
            authService.error = "Please enter your restaurant name"
            return
        }
        
        guard !email.isEmpty else {
            authService.error = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            authService.error = "Please enter a password"
            return
        }
        
        guard password == confirmPassword else {
            authService.error = "Passwords do not match"
            return
        }
        
        // Register user
        authService.register(email: email, password: password, name: name)
        
        // Close sheet if successful
        if authService.isAuthenticated {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct RegisterFormView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterFormView()
            .environmentObject(AuthService())
    }
} 