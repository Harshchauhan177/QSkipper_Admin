import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var height: CGFloat = 50
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(title)
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background(AppColors.primaryGreen)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var height: CGFloat = 50
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                        .scaleEffect(1.2)
                } else {
                    Text(title)
                        .font(AppFonts.buttonText)
                        .foregroundColor(AppColors.primaryGreen)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.primaryGreen, lineWidth: 2)
            )
        }
        .disabled(isLoading)
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var height: CGFloat = 50
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(title)
                        .font(AppFonts.buttonText)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background(AppColors.errorRed)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}

#Preview("Buttons") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Login", action: {})
        SecondaryButton(title: "Cancel", action: {})
        DestructiveButton(title: "Delete", action: {})
        
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        SecondaryButton(title: "Loading", action: {}, isLoading: true)
    }
    .padding()
    .frame(maxWidth: 300)
} 