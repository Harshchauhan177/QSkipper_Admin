//
//  AboutView.swift
//  QSkipper
//
//  Created by Keshav Lohiya on 02/04/25.
//

import SwiftUI

struct AboutView: View {
    
    let teamMembers = [
        ("Baniya Bros", "Full Stack Devs Org", "person.3.sequence.fill", Color.blue),
        ("Keshav Lohiya", "Full Stack Developer", "brain.fill", Color.green),
        ("Vinayak Bansal", "Full Stack Developer", "hammer.fill", Color.orange),
        ("Priyanshu Gupta", "Full Stack Developer", "server.rack", Color.purple)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("About QSkipper")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App info section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("QSkipper Admin")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("QSkipper is a comprehensive restaurant management platform designed to streamline operations for restaurant owners and staff. The admin panel provides easy management of menu items, orders, and restaurant information.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Features section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        FeatureItem(icon: "building.2.fill", title: "Restaurant Management", description: "Update profile, hours, and contact information")
                        FeatureItem(icon: "cube.fill", title: "Product Management", description: "Add, edit, and remove menu items with prices and categories")
                        FeatureItem(icon: "bag.fill", title: "Order Management", description: "Process customer orders in real-time with status updates")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Team Members section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Our Team")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.bottom, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(teamMembers, id: \.0) { member in
                                TeamMemberView(
                                    name: member.0,
                                    role: member.1,
                                    color: member.3,
                                    icon: member.2
                                )
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Contact section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Support")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)
                            Text("team.qskipper@gmail.com")
                                .font(.body)
                        }
                        
                        Link(destination: URL(string: "https://qskipper.com")!) {
                            HStack {
                                Text("Visit our website")
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.green)
                            .font(.body)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Legal section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("© 2025 QSkipper. All rights reserved.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Link("Privacy Policy", destination: URL(string: "https://qskipper.com/privacy")!)
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Link("Terms of Service", destination: URL(string: "https://qskipper.com/terms")!)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryGreen)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }
}

struct TeamMemberView: View {
    let name: String
    let role: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(role)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.05)))
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
} 