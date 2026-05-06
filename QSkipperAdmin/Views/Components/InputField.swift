import SwiftUI

struct InputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: UITextAutocapitalizationType = .none
    var error: String?
    
    @State private var isShowingPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.darkGray)
            
            if isSecure {
                HStack {
                    if isShowingPassword {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(contentType ?? .none)
                            .autocapitalization(autocapitalization)
                            .frame(height: 44)
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(.none)
                            .frame(height: 44)
                    }
                    
                    Button(action: {
                        isShowingPassword.toggle()
                    }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(AppColors.lightGray)
                .cornerRadius(10)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .autocapitalization(autocapitalization)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(AppColors.lightGray)
                    .cornerRadius(10)
            }
            
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.errorRed)
            }
        }
    }
}

struct MultilineInputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100
    var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.darkGray)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(AppColors.mediumGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .frame(minHeight: minHeight)
                    .background(AppColors.lightGray)
                    .cornerRadius(10)
            }
            .frame(minHeight: minHeight)
            .background(AppColors.lightGray)
            .cornerRadius(10)
            
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.errorRed)
            }
        }
    }
}

struct PriceInputField: View {
    let title: String
    @Binding var value: Double
    var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.darkGray)
            
            HStack {
                Text("$")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.darkGray)
                    .padding(.leading, 16)
                
                TextField("0.00", value: $value, formatter: NumberFormatter.currencyFormatter)
                    .keyboardType(.decimalPad)
            }
            .frame(height: 50)
            .background(AppColors.lightGray)
            .cornerRadius(10)
            
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.errorRed)
            }
        }
    }
}

extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

struct InputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InputField(title: "Email", text: .constant("test@example.com"), placeholder: "Enter email", keyboardType: .emailAddress)
            
            InputField(title: "Password", text: .constant("password"), placeholder: "Enter password", isSecure: true)
            
            InputField(title: "Error Field", text: .constant(""), placeholder: "Field with error", error: "This field is required")
            
            MultilineInputField(title: "Description", text: .constant(""), placeholder: "Enter description")
            
            PriceInputField(title: "Price", value: .constant(9.99))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 