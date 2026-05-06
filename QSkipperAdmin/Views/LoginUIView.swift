import SwiftUI

struct LoginUIView: View {
    @ObservedObject var viewModel: LoginViewModel
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
                                    AppColors.primaryGreen.opacity(0.8),
                                    AppColors.primaryGreen
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Right side - login form
                    formView
                        .frame(width: geometry.size.width * 0.6)
                        .background(AppColors.backgroundWhite)
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                // iPhone layout - stacked
                ScrollView {
                    VStack(spacing: 0) {
                        // Top - branding
                        brandingView
                            .frame(height: geometry.size.height * 0.3)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.primaryGreen.opacity(0.8),
                                        AppColors.primaryGreen
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Bottom - login form
                        formView
                            .frame(minHeight: geometry.size.height * 0.7)
                            .background(AppColors.backgroundWhite)
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Components
    
    private var brandingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Text("QSkipper")
                .font(AppFonts.title)
                .foregroundColor(.white)
            
            Text("Restaurant Partner Portal")
                .font(AppFonts.body)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
    
    private var formView: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign In")
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.darkGray)
                
                Text("Sign in to your restaurant account")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            
            // Form fields
            VStack(spacing: 20) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.mediumGray)
                    
                    TextField("Enter your email", text: $viewModel.email)
                        .font(AppFonts.body)
                        .padding()
                        .background(AppColors.lightGray)
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.mediumGray)
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .font(AppFonts.body)
                        .padding()
                        .background(AppColors.lightGray)
                        .cornerRadius(10)
                        .textContentType(.none)
                }
                
                // Forgot password link
                Button(action: {
                    // Handle forgot password
                }) {
                    Text("Forgot Password?")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primaryGreen)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Submit button
            Button(action: {
                viewModel.login()
            }) {
                Text("Sign In")
                    .font(AppFonts.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primaryGreen)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoggingIn)
            .opacity(viewModel.isLoggingIn ? 0.7 : 1.0)
            .overlay(
                Group {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.3)
                    }
                }
            )
            
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
                        .foregroundColor(AppColors.primaryGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(horizontalSizeClass == .regular ? 50 : 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 