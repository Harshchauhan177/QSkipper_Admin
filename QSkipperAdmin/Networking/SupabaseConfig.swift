import Foundation
import Supabase

/// Central configuration for the Supabase client.
/// This replaces the old NetworkManager.baseURL approach.
struct SupabaseConfig {
    
    // MARK: - Supabase Credentials
    
    /// Your Supabase project URL
    static let projectURL = URL(string: "https://bhxhjsandxjairzccbqk.supabase.co")!
    
    /// Your Supabase anon (public) key — safe to include in the app
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJoeGhqc2FuZHhqYWlyemNjYnFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyOTQ2NzIsImV4cCI6MjA5Mzg3MDY3Mn0.fvyI2DPxsvNDTvTUq-MIluMYjwPeQO_7CrDMatjLLrI"
    
    // MARK: - Shared Client
    
    /// The shared Supabase client instance used throughout the app
    static let client = SupabaseClient(
        supabaseURL: projectURL,
        supabaseKey: anonKey
    )
    
    // MARK: - Storage Bucket Names
    
    /// Storage bucket for restaurant banner images
    static let restaurantImagesBucket = "restaurant-images"
    
    /// Storage bucket for product images
    static let productImagesBucket = "product-images"
    
    // MARK: - Table Names
    
    struct Tables {
        static let restaurants = "restaurants"
        static let products = "products"
        static let orders = "orders"
        static let orderItems = "order_items"
    }
}
