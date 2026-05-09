import Foundation
import UIKit
import Combine
import Supabase

/// Supabase-powered product API
/// Replaces the old ProductApi that used URLSession + custom endpoints
class SupabaseProductApi: ObservableObject {
    static let shared = SupabaseProductApi()
    
    // MARK: - Published Properties
    @Published var products: [SupabaseProduct] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    // MARK: - Private
    private let client = SupabaseConfig.client
    
    // Image cache
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {
        DebugLogger.shared.log("SupabaseProductApi initialized", category: .app)
    }
    
    // MARK: - Get All Products
    
    /// Fetch all products for the current restaurant
    @MainActor
    func getAllProducts(restaurantId: String? = nil) async throws -> [SupabaseProduct] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Get restaurant ID from parameter, auth service, or UserDefaults
        let targetId = restaurantId
            ?? SupabaseAuthService.shared.getRestaurantId()
            ?? UserDefaults.standard.string(forKey: "restaurant_id")
            ?? ""
        
        guard !targetId.isEmpty else {
            DebugLogger.shared.log("No restaurant ID available for fetching products", category: .network)
            return []
        }
        
        let result: [SupabaseProduct] = try await client
            .from(SupabaseConfig.Tables.products)
            .select()
            .eq("restaurant_id", value: targetId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        self.products = result
        
        DebugLogger.shared.log("Fetched \(result.count) products for restaurant: \(targetId)", category: .network)
        return result
    }
    
    // MARK: - Get Single Product
    
    /// Fetch a single product by ID
    func getProduct(productId: String) async throws -> SupabaseProduct? {
        guard !productId.isEmpty else { return nil }
        
        let result: [SupabaseProduct] = try await client
            .from(SupabaseConfig.Tables.products)
            .select()
            .eq("id", value: productId)
            .execute()
            .value
        
        return result.first
    }
    
    // MARK: - Create Product
    
    /// Create a new product
    @MainActor
    func createProduct(product: SupabaseProduct, image: UIImage? = nil) async throws -> SupabaseProduct {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Upload image if provided
        var imageUrl: String? = nil
        if let image = image {
            let productTempId = UUID().uuidString
            imageUrl = try await uploadProductImage(image: image, productId: productTempId)
        }
        
        let newProduct = InsertProduct(
            restaurantId: product.restaurantId,
            name: product.name,
            price: product.price,
            category: product.category,
            description: product.description,
            extraTime: product.extraTime,
            isAvailable: product.isAvailable,
            isFeatured: product.isFeatured,
            imageUrl: imageUrl
        )
        
        let result: [SupabaseProduct] = try await client
            .from(SupabaseConfig.Tables.products)
            .insert(newProduct)
            .select()
            .execute()
            .value
        
        guard let created = result.first else {
            throw NSError(domain: "SupabaseProductApi", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create product"])
        }
        
        // If we have an image and the product ID is now available, re-upload with correct path
        if let image = image, let productId = created.id, imageUrl != nil {
            let correctUrl = try await uploadProductImage(image: image, productId: productId)
            // Update the product with the correct image URL
            let _: [SupabaseProduct] = try await client
                .from(SupabaseConfig.Tables.products)
                .update(UpdateProduct(name: nil, price: nil, category: nil, description: nil, extraTime: nil, isAvailable: nil, isFeatured: nil, imageUrl: correctUrl))
                .eq("id", value: productId)
                .select()
                .execute()
                .value
        }
        
        // Post notification
        NotificationCenter.default.post(name: .productUpdated, object: nil, userInfo: ["productId": created.id ?? ""])
        
        DebugLogger.shared.log("Product created: \(created.name) with ID: \(created.id ?? "unknown")", category: .network)
        return created
    }
    
    // MARK: - Update Product
    
    /// Update an existing product
    @MainActor
    func updateProduct(productId: String, product: SupabaseProduct, image: UIImage? = nil) async throws -> SupabaseProduct {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Upload new image if provided
        var imageUrl: String? = product.imageUrl
        if let image = image {
            imageUrl = try await uploadProductImage(image: image, productId: productId)
        }
        
        let updateData = UpdateProduct(
            name: product.name,
            price: product.price,
            category: product.category,
            description: product.description,
            extraTime: product.extraTime,
            isAvailable: product.isAvailable,
            isFeatured: product.isFeatured,
            imageUrl: imageUrl
        )
        
        let result: [SupabaseProduct] = try await client
            .from(SupabaseConfig.Tables.products)
            .update(updateData)
            .eq("id", value: productId)
            .select()
            .execute()
            .value
        
        guard let updated = result.first else {
            throw NSError(domain: "SupabaseProductApi", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update product"])
        }
        
        // Clear cached image
        clearProductImageCache(productId: productId)
        
        // Post notification
        NotificationCenter.default.post(name: .productUpdated, object: nil, userInfo: ["productId": productId, "imageUpdated": image != nil])
        
        DebugLogger.shared.log("Product updated: \(updated.name)", category: .network)
        return updated
    }
    
    // MARK: - Delete Product
    
    /// Delete a product by ID
    @MainActor
    func deleteProduct(productId: String) async throws -> Bool {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        try await client
            .from(SupabaseConfig.Tables.products)
            .delete()
            .eq("id", value: productId)
            .execute()
        
        // Remove from local array
        products.removeAll { $0.id == productId }
        
        // Clear cached image
        clearProductImageCache(productId: productId)
        
        DebugLogger.shared.log("Product deleted: \(productId)", category: .network)
        return true
    }
    
    // MARK: - Image Upload
    
    /// Upload a product image to Supabase Storage
    func uploadProductImage(image: UIImage, productId: String) async throws -> String {
        guard let imageData = compressImage(image: image, targetSizeKB: 500) else {
            throw NSError(domain: "SupabaseProductApi", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let fileName = "\(productId)/photo_\(Int(Date().timeIntervalSince1970)).jpg"
        
        try await client.storage
            .from(SupabaseConfig.productImagesBucket)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        let publicUrl = try client.storage
            .from(SupabaseConfig.productImagesBucket)
            .getPublicURL(path: fileName)
        
        DebugLogger.shared.log("Product image uploaded: \(publicUrl.absoluteString)", category: .network)
        return publicUrl.absoluteString
    }
    
    // MARK: - Image Fetching & Caching
    
    /// Fetch product image from URL with caching
    func fetchImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cached = imageCache.object(forKey: urlString as NSString) {
            return cached
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: urlString as NSString)
                return image
            }
        } catch {
            DebugLogger.shared.logError(error, tag: "FETCH_PRODUCT_IMAGE")
        }
        
        return nil
    }
    
    /// Clear cached image for a specific product
    func clearProductImageCache(productId: String) {
        // We don't know the exact URL, so clear based on product ID prefix
        imageCache.removeAllObjects()
        
        NotificationCenter.default.post(
            name: .productImageCacheCleared,
            object: nil,
            userInfo: ["productId": productId]
        )
    }
    
    /// Clear all cached images
    func clearAllImageCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Image Compression
    
    /// Compress image to target size using binary search
    private func compressImage(image: UIImage, targetSizeKB: Int = 500) -> Data? {
        let maxSize: CGFloat = 600
        var processedImage = image
        
        if max(image.size.width, image.size.height) > maxSize {
            let scale = maxSize / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                processedImage = resized
            }
            UIGraphicsEndImageContext()
        }
        
        var compression: CGFloat = 0.5
        var maxC: CGFloat = 1.0
        var minC: CGFloat = 0.0
        var imageData = processedImage.jpegData(compressionQuality: compression)!
        
        for _ in 0..<6 {
            let targetSize = targetSizeKB * 1024
            
            if imageData.count <= targetSize {
                minC = compression
                compression = (maxC + compression) / 2
            } else {
                maxC = compression
                compression = (minC + compression) / 2
            }
            
            imageData = processedImage.jpegData(compressionQuality: compression)!
            
            if Double(abs(imageData.count - targetSize)) < (Double(targetSize) * 0.1) {
                break
            }
        }
        
        DebugLogger.shared.log("Product image compressed to \(imageData.count / 1024) KB", category: .network)
        return imageData
    }
}
