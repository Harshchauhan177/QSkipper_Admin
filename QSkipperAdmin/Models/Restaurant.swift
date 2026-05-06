import Foundation
import UIKit

// MARK: - Restaurant Model
struct Restaurant: Codable, Identifiable {
    var id: String
    var restaurantId: String
    var restaurantName: String
    var cuisine: String
    var estimatedTime: Int
    private var bannerPhoto64Image: String?
    var dishes: [Dish]
    var rating: Double
    
    var bannerPhoto: UIImage? {
        get {
            guard let imageData = bannerPhoto64Image,
                  let data = Data(base64Encoded: imageData) else { return nil }
            return UIImage(data: data)
        }
        set {
            if let newImage = newValue, let data = newImage.jpegData(compressionQuality: 0.7) {
                bannerPhoto64Image = data.base64EncodedString()
            } else {
                bannerPhoto64Image = nil
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case restaurantId = "restaurantid"
        case restaurantName = "restaurant_Name"
        case bannerPhoto64Image
        case cuisine
        case estimatedTime
        case dishes = "dish"
        case rating
    }
    
    init(id: String = "", 
         restaurantId: String = "", 
         restaurantName: String = "", 
         cuisine: String = "", 
         estimatedTime: Int = 10, 
         bannerPhoto: UIImage? = nil, 
         dishes: [Dish] = [], 
         rating: Double = 0.0) {
        self.id = id
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.cuisine = cuisine
        self.estimatedTime = estimatedTime
        self.dishes = dishes
        self.rating = rating
        self.bannerPhoto = bannerPhoto
    }
}

// MARK: - Dish Model
struct Dish: Codable, Identifiable {
    var id: String = UUID().uuidString // For local identification
    var image: String
    var name: String
    var description: String
    var price: Int
    var rating: Double
    var foodType: String
    
    enum CodingKeys: String, CodingKey {
        case image
        case name
        case description
        case price
        case rating
        case foodType
    }
}

// Common cuisine types
struct CuisineTypes {
    static let list = ["North Indian", "South Indian", "Chinese", "Fast Food", "Drinks & Snacks"]
} 