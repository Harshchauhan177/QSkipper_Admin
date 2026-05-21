import SwiftUI
import Supabase

/// In-app forgot password flow: Email → OTP → New Password
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= viewModel.currentStep.rawValue ? AppColors.primaryGreen : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Step icon & title
                        stepHeader
                        
                        // Step content
                        switch viewModel.currentStep {
                        case .email:
                            emailStepView
                        case .otp:
                            otpStepView
                        case .newPassword:
                            newPasswordStepView
                        }
                        
                        // Error message
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(AppFonts.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        
                        // Success message
                        if viewModel.isSuccess {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.primaryGreen)
                                
                                Text("Password Updated Successfully!")
                                    .font(AppFonts.subtitle)
                                    .fontWeight(.semibold)
                                
                                Text("You can now sign in with your new password.")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: { dismiss() }) {
                                    Text("Back to Sign In")
                                        .font(AppFonts.buttonText)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(AppColors.primaryGreen)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if viewModel.currentStep == .email || viewModel.isSuccess {
                            dismiss()
                        } else {
                            viewModel.goBack()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(viewModel.currentStep == .email || viewModel.isSuccess ? "Cancel" : "Back")
                                .font(AppFonts.body)
                        }
                        .foregroundColor(AppColors.primaryGreen)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isSuccess)
        }
    }
    
    // MARK: - Step Header
    
    private var stepHeader: some View {
        VStack(spacing: 12) {
            if !viewModel.isSuccess {
                Image(systemName: viewModel.currentStep.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primaryGreen)
                
                Text(viewModel.currentStep.title)
                    .font(AppFonts.subtitle)
                    .fontWeight(.bold)
                
                Text(viewModel.currentStep.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Step 1: Email
    
    private var emailStepView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Button(action: {
                Task { await viewModel.sendOTP() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Send OTP")
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(AppColors.primaryGreen)
            .cornerRadius(10)
            .disabled(viewModel.isLoading || viewModel.email.isEmpty)
            .opacity(viewModel.email.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 2: OTP
    
    private var otpStepView: some View {
        VStack(spacing: 16) {
            // Show which email the OTP was sent to
            Text("Sent to: **\(viewModel.email)**")
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("OTP Code")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter 6-digit OTP", text: $viewModel.otpCode)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Button(action: {
                Task { await viewModel.verifyOTP() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Verify OTP")
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(AppColors.primaryGreen)
            .cornerRadius(10)
            .disabled(viewModel.isLoading || viewModel.otpCode.count < 6)
            .opacity(viewModel.otpCode.count < 6 ? 0.6 : 1.0)
            
            // Resend OTP
            Button(action: {
                Task { await viewModel.resendOTP() }
            }) {
                Text("Didn't receive the code? Resend OTP")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primaryGreen)
            }
            .disabled(viewModel.isLoading)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 3: New Password
    
    private var newPasswordStepView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("New Password")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Enter new password", text: $viewModel.newPassword)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Confirm new password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Password requirements hint
            VStack(alignment: .leading, spacing: 4) {
                passwordRequirement("At least 6 characters", met: viewModel.newPassword.count >= 6)
                passwordRequirement("Passwords match", met: !viewModel.newPassword.isEmpty && viewModel.newPassword == viewModel.confirmPassword)
            }
            .padding(.vertical, 4)
            
            Button(action: {
                Task { await viewModel.updatePassword() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Update Password")
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(AppColors.primaryGreen)
            .cornerRadius(10)
            .disabled(viewModel.isLoading || !viewModel.isPasswordValid)
            .opacity(!viewModel.isPasswordValid ? 0.6 : 1.0)
        }
        .padding(.horizontal, 24)
    }
    
    private func passwordRequirement(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(met ? AppColors.primaryGreen : .gray)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? .primary : .secondary)
        }
    }
}

// MARK: - ViewModel

class ForgotPasswordViewModel: ObservableObject {
    
    enum Step: Int, CaseIterable {
        case email = 0
        case otp = 1
        case newPassword = 2
        
        var title: String {
            switch self {
            case .email: return "Forgot Password"
            case .otp: return "Enter OTP"
            case .newPassword: return "Create New Password"
            }
        }
        
        var subtitle: String {
            switch self {
            case .email: return "Enter your email address and we'll send you a verification code"
            case .otp: return "Enter the 6-digit code sent to your email"
            case .newPassword: return "Create a strong new password for your account"
            }
        }
        
        var iconName: String {
            switch self {
            case .email: return "envelope.circle.fill"
            case .otp: return "lock.shield.fill"
            case .newPassword: return "key.fill"
            }
        }
    }
    
    @Published var currentStep: Step = .email
    @Published var email = ""
    @Published var otpCode = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    
    private let client = SupabaseConfig.client
    
    var isPasswordValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }
    
    // MARK: - Step 1: Send OTP
    
    @MainActor
    func sendOTP() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            
            isLoading = false
            currentStep = .otp
            DebugLogger.shared.log("OTP sent to \(email)", category: .auth)
        } catch {
            isLoading = false
            errorMessage = "Failed to send OTP: \(error.localizedDescription)"
            DebugLogger.shared.logError(error, tag: "SEND_OTP")
        }
    }
    
    // MARK: - Step 2: Verify OTP
    
    @MainActor
    func verifyOTP() async {
        guard otpCode.count >= 6 else {
            errorMessage = "Please enter the 6-digit OTP code"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Verify the OTP — this also creates a session
            _ = try await client.auth.verifyOTP(
                email: email,
                token: otpCode,
                type: .recovery
            )
            
            isLoading = false
            currentStep = .newPassword
            DebugLogger.shared.log("OTP verified for \(email)", category: .auth)
        } catch {
            isLoading = false
            errorMessage = "Invalid OTP code. Please check and try again."
            DebugLogger.shared.logError(error, tag: "VERIFY_OTP")
        }
    }
    
    // MARK: - Step 3: Update Password
    
    @MainActor
    func updatePassword() async {
        guard isPasswordValid else {
            if newPassword.count < 6 {
                errorMessage = "Password must be at least 6 characters"
            } else {
                errorMessage = "Passwords do not match"
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            _ = try await client.auth.update(
                user: UserAttributes(password: newPassword)
            )
            
            // Sign out after password change so user logs in fresh
            try await client.auth.signOut()
            
            isLoading = false
            isSuccess = true
            DebugLogger.shared.log("Password updated successfully for \(email)", category: .auth)
        } catch {
            isLoading = false
            errorMessage = "Failed to update password: \(error.localizedDescription)"
            DebugLogger.shared.logError(error, tag: "UPDATE_PASSWORD")
        }
    }
    
    // MARK: - Resend OTP
    
    @MainActor
    func resendOTP() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            isLoading = false
            errorMessage = "" // Clear any previous error
            DebugLogger.shared.log("OTP resent to \(email)", category: .auth)
        } catch {
            isLoading = false
            errorMessage = "Failed to resend OTP: \(error.localizedDescription)"
            DebugLogger.shared.logError(error, tag: "RESEND_OTP")
        }
    }
    
    // MARK: - Navigation
    
    func goBack() {
        errorMessage = ""
        switch currentStep {
        case .otp:
            currentStep = .email
            otpCode = ""
        case .newPassword:
            currentStep = .otp
            newPassword = ""
            confirmPassword = ""
        case .email:
            break
        }
    }
}
