import Foundation
import Combine
import UIKit
import Supabase

/// Supabase-powered restaurant service
/// Replaces the old RestaurantService that used URLSession + custom endpoints
class SupabaseRestaurantService: ObservableObject {
    static let shared = SupabaseRestaurantService()
    
    // MARK: - Published Properties
    @Published var restaurant: SupabaseRestaurant?
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    // MARK: - Private
    private let client = SupabaseConfig.client
    
    init() {
        DebugLogger.shared.log("SupabaseRestaurantService initialized", category: .app)
    }
    
    // MARK: - Register Restaurant
    
    /// Register a new restaurant for the current user
    @MainActor
    func registerRestaurant(
        name: String,
        cuisine: String,
        estimatedTime: Int,
        bannerImage: UIImage?
    ) async throws -> SupabaseRestaurant {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        guard let userId = SupabaseAuthService.shared.getUserId() else {
            throw NSError(domain: "SupabaseRestaurantService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        // Upload banner image if provided
        var bannerUrl: String? = nil
        if let image = bannerImage {
            bannerUrl = try await uploadRestaurantImage(image: image, restaurantId: UUID().uuidString)
        }
        
        // Create restaurant record
        let newRestaurant = InsertRestaurant(
            ownerId: userId,
            name: name,
            cuisine: cuisine,
            estimatedTime: estimatedTime,
            bannerImageUrl: bannerUrl
        )
        
        let result: [SupabaseRestaurant] = try await client
            .from(SupabaseConfig.Tables.restaurants)
            .insert(newRestaurant)
            .select()
            .execute()
            .value
        
        guard let created = result.first else {
            throw NSError(domain: "SupabaseRestaurantService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create restaurant"])
        }
        
        self.restaurant = created
        
        // Update UserDefaults for compatibility
        if let id = created.id {
            UserDefaults.standard.set(id, forKey: "restaurant_id")
            UserDefaults.standard.set(true, forKey: "is_restaurant_registered")
        }
        
        // Update AuthService
        await SupabaseAuthService.shared.loadMyRestaurant()
        
        DebugLogger.shared.log("Restaurant registered: \(created.name) with ID: \(created.id ?? "unknown")", category: .network)
        return created
    }
    
    // MARK: - Update Restaurant
    
    /// Update an existing restaurant
    @MainActor
    func updateRestaurant(
        restaurantId: String,
        name: String,
        cuisine: String,
        estimatedTime: Int,
        bannerImage: UIImage?
    ) async throws -> SupabaseRestaurant {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Upload new banner image if provided
        var bannerUrl: String? = nil
        if let image = bannerImage {
            bannerUrl = try await uploadRestaurantImage(image: image, restaurantId: restaurantId)
        }
        
        let updateData = UpdateRestaurant(
            name: name,
            cuisine: cuisine,
            estimatedTime: estimatedTime,
            bannerImageUrl: bannerUrl
        )
        
        let result: [SupabaseRestaurant] = try await client
            .from(SupabaseConfig.Tables.restaurants)
            .update(updateData)
            .eq("id", value: restaurantId)
            .select()
            .execute()
            .value
        
        guard let updated = result.first else {
            throw NSError(domain: "SupabaseRestaurantService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update restaurant"])
        }
        
        self.restaurant = updated
        
        // Update AuthService
        await SupabaseAuthService.shared.loadMyRestaurant()
        
        DebugLogger.shared.log("Restaurant updated: \(updated.name)", category: .network)
        return updated
    }
    
    // MARK: - Delete Restaurant
    
    /// Delete a restaurant by ID
    @MainActor
    func deleteRestaurant(restaurantId: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        try await client
            .from(SupabaseConfig.Tables.restaurants)
            .delete()
            .eq("id", value: restaurantId)
            .execute()
        
        self.restaurant = nil
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "restaurant_id")
        UserDefaults.standard.set(false, forKey: "is_restaurant_registered")
        UserDefaults.standard.removeObject(forKey: "restaurant_data")
        
        // Update AuthService
        SupabaseAuthService.shared.currentRestaurant = nil
        
        DebugLogger.shared.log("Restaurant deleted: \(restaurantId)", category: .network)
    }
    
    // MARK: - Fetch Restaurant
    
    /// Fetch restaurant for the current user
    @MainActor
    func fetchMyRestaurant() async throws -> SupabaseRestaurant? {
        guard let userId = SupabaseAuthService.shared.getUserId() else {
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let restaurants: [SupabaseRestaurant] = try await client
            .from(SupabaseConfig.Tables.restaurants)
            .select()
            .eq("owner_id", value: userId)
            .execute()
            .value
        
        self.restaurant = restaurants.first
        return restaurants.first
    }
    
    // MARK: - Image Upload
    
    /// Upload a restaurant banner image to Supabase Storage
    func uploadRestaurantImage(image: UIImage, restaurantId: String) async throws -> String {
        // Compress the image
        guard let imageData = compressImage(image: image, targetSizeKB: 500) else {
            throw NSError(domain: "SupabaseRestaurantService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let fileName = "\(restaurantId)/banner_\(Int(Date().timeIntervalSince1970)).jpg"
        
        try await client.storage
            .from(SupabaseConfig.restaurantImagesBucket)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Get the public URL
        let publicUrl = try client.storage
            .from(SupabaseConfig.restaurantImagesBucket)
            .getPublicURL(path: fileName)
        
        DebugLogger.shared.log("Restaurant image uploaded: \(publicUrl.absoluteString)", category: .network)
        return publicUrl.absoluteString
    }
    
    /// Fetch restaurant banner image from URL
    func fetchRestaurantImage(url: String) async -> UIImage? {
        guard let imageUrl = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageUrl)
            return UIImage(data: data)
        } catch {
            DebugLogger.shared.logError(error, tag: "FETCH_RESTAURANT_IMAGE")
            return nil
        }
    }
    
    // MARK: - Image Compression
    
    /// Compress image to target size using binary search
    private func compressImage(image: UIImage, targetSizeKB: Int = 500) -> Data? {
        let maxSize: CGFloat = 800
        var processedImage = image
        
        // Resize if too large
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
        
        // Binary search for optimal compression
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
        
        DebugLogger.shared.log("Image compressed to \(imageData.count / 1024) KB", category: .network)
        return imageData
    }
}
