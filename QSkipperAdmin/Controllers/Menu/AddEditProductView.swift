import SwiftUI
import PhotosUI

// MARK: - Edit Mode
enum ProductEditMode {
    case add
    case edit(Product)
}

// MARK: - View
struct AddEditProductView: View {
    @ObservedObject var viewModel: AddEditProductViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section(header: Text("Basic Information")) {
                    InputField(
                        title: "Name",
                        text: $viewModel.name,
                        placeholder: "Enter dish name",
                        error: viewModel.nameError
                    )
                    .padding(.vertical, 8)
                    
                    MultilineInputField(
                        title: "Description",
                        text: $viewModel.description,
                        placeholder: "Enter dish description",
                        error: viewModel.descriptionError
                    )
                    .padding(.vertical, 8)
                    
                    PriceInputField(
                        title: "Price",
                        value: $viewModel.price,
                        error: viewModel.priceError
                    )
                    .padding(.vertical, 8)
                    
                    InputField(
                        title: "Category",
                        text: $viewModel.category,
                        placeholder: "Appetizer, Main, Dessert, etc.",
                        error: viewModel.categoryError
                    )
                    .padding(.vertical, 8)
                }
                
                // Image Section
                Section(header: Text("Dish Image")) {
                    imageSection
                }
                
                // Status Section (edit mode only)
                if case .edit = viewModel.mode {
                    Section(header: Text("Status")) {
                        Toggle("Active", isOn: $viewModel.isActive)
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryGreen))
                    }
                }
                
                // Action Buttons
                Section {
                    VStack(spacing: 16) {
                        PrimaryButton(
                            title: viewModel.isEditMode ? "Update Dish" : "Add Dish",
                            action: {
                                viewModel.saveProduct()
                            },
                            isLoading: viewModel.isLoading
                        )
                        
                        if viewModel.isEditMode {
                            SecondaryButton(
                                title: "Cancel",
                                action: {
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Dish" : "Add Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                
                HStack {
                    Spacer()
                    
                    Button("Remove Image") {
                        viewModel.selectedImage = nil
                    }
                    .foregroundColor(AppColors.errorRed)
                    
                    Spacer()
                }
            } else if let imageUrlString = viewModel.imageUrl,
                      let imageUrl = URL(string: imageUrlString) {
                // Show existing image from URL
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                    case .failure:
                        imagePickerButton
                    @unknown default:
                        imagePickerButton
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                imagePickerButton
            }
        }
    }
    
    private var imagePickerButton: some View {
        PhotosPicker(
            selection: $viewModel.photoItem,
            matching: .images
        ) {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(AppColors.mediumGray)
                
                Text("Tap to select an image")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.darkGray)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(AppColors.lightGray)
            .cornerRadius(10)
        }
    }
}

// MARK: - ViewModel
class AddEditProductViewModel: ObservableObject {
    // Form fields
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var price: Double = 0.0
    @Published var category: String = ""
    @Published var isActive: Bool = true
    @Published var imageUrl: String? = nil
    
    // Image selection
    @Published var photoItem: PhotosPickerItem? = nil {
        didSet {
            if let photoItem = photoItem {
                loadImage(from: photoItem)
            }
        }
    }
    @Published var selectedImage: UIImage? = nil
    
    // Form validation
    @Published var nameError: String? = nil
    @Published var descriptionError: String? = nil
    @Published var priceError: String? = nil
    @Published var categoryError: String? = nil
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // Mode and callbacks
    let mode: ProductEditMode
    let onComplete: () -> Void
    
    var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    init(mode: ProductEditMode, onComplete: @escaping () -> Void) {
        self.mode = mode
        self.onComplete = onComplete
        
        // If editing, populate form with product data
        if case .edit(let product) = mode {
            self.name = product.name
            self.price = Double(product.price)
            self.description = product.description
            self.category = product.category
            self.isActive = product.isActive
            self.imageUrl = product.imageUrl
        }
    }
    
    // MARK: - Image handling
    private func loadImage(from photoItem: PhotosPickerItem) {
        photoItem.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self.selectedImage = image
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Validation
    private func validateInputs() -> Bool {
        var isValid = true
        
        // Validate name
        if name.isEmpty {
            nameError = "Name is required"
            isValid = false
        } else {
            nameError = nil
        }
        
        // Validate description
        if description.isEmpty {
            descriptionError = "Description is required"
            isValid = false
        } else {
            descriptionError = nil
        }
        
        // Validate price
        if price <= 0 {
            priceError = "Price must be greater than 0"
            isValid = false
        } else {
            priceError = nil
        }
        
        // Validate category
        if category.isEmpty {
            categoryError = "Category is required"
            isValid = false
        } else {
            categoryError = nil
        }
        
        return isValid
    }
    
    // MARK: - API calls
    func saveProduct() {
        guard validateInputs() else { return }
        
        isLoading = true
        
        Task {
            do {
                // Try using multipart method first (better for handling images)
                if isEditMode {
                    if case .edit(let product) = mode {
                        var updatedProduct = product
                        updatedProduct.name = name
                        updatedProduct.description = description
                        updatedProduct.price = Int(price)
                        updatedProduct.category = category
                        updatedProduct.isActive = isActive
                        
                        // Update using multipart
                        updatedProduct.productPhoto = selectedImage
                        let _ = try await ProductApi.shared.createProductWithMultipart(product: updatedProduct, image: selectedImage)
                    }
                } else {
                    // Create a new product
                    let newProduct = Product(
                        name: name,
                        price: Int(price),
                        restaurantId: DataController.shared.restaurant.id,
                        category: category,
                        description: description,
                        isActive: isActive,
                        productPhoto: selectedImage
                    )
                    
                    let _ = try await ProductApi.shared.createProductWithMultipart(product: newProduct, image: selectedImage)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.onComplete()
                }
            } catch {
                // If multipart fails, try standard method as fallback
                do {
                    if isEditMode {
                        if case .edit(let product) = mode {
                            var updatedProduct = product
                            updatedProduct.name = name
                            updatedProduct.description = description
                            updatedProduct.price = Int(price)
                            updatedProduct.category = category
                            updatedProduct.isActive = isActive
                            
                            // Update using standard method
                            updatedProduct.productPhoto = selectedImage
                            let _ = try await ProductApi.shared.createProduct(product: updatedProduct, image: selectedImage)
                        }
                    } else {
                        // Create a new product
                        let newProduct = Product(
                            name: name,
                            price: Int(price),
                            restaurantId: DataController.shared.restaurant.id,
                            category: category,
                            description: description,
                            isActive: isActive,
                            productPhoto: selectedImage
                        )
                        
                        let _ = try await ProductApi.shared.createProduct(product: newProduct, image: selectedImage)
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                        self?.onComplete()
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                        self?.showErrorAlert = true
                    }
                }
            }
        }
    }
}

#Preview("Add/Edit Product") {
    Group {
        AddEditProductView(viewModel: AddEditProductViewModel(mode: .add, onComplete: {}))
            .previewDisplayName("Add Mode")
        
        AddEditProductView(viewModel: AddEditProductViewModel(
            mode: .edit(Product(
                id: "123",
                name: "Margherita Pizza",
                price: 1299,
                restaurantId: "456",
                category: "Main",
                description: "Classic Italian pizza with tomato sauce, mozzarella, and basil",
                extraTime: 0,
                rating: 4.5,
                isAvailable: true,
                isActive: true,
                isFeatured: false
            )),
            onComplete: {}
        ))
        .previewDisplayName("Edit Mode")
    }
} 