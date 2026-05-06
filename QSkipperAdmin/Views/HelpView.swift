//
//  HelpView.swift
//  QSkipper
//
//  Created by Keshav Lohiya on 02/04/25.
//

import SwiftUI

struct HelpView: View {
    // State for accordion sections
    @State private var expandedSection: String? = nil
    
    // FAQ data
    let faqSections = [
        FAQSection(
            title: "Getting Started",
            items: [
                FAQItem(
                    question: "How do I set up my restaurant profile?",
                    answer: "To set up your restaurant profile, go to the Restaurant tab in the sidebar and complete all fields including your restaurant name, address, phone number, and operation hours. Don't forget to upload a logo image for better brand recognition."
                ),
                FAQItem(
                    question: "How do I add my first product?",
                    answer: "Navigate to the Products tab and click the 'Add Product' button in the top right corner. Fill in all the required fields including product name, price, category, and description. Upload a high-quality image of your product to improve customer experience."
                ),
                FAQItem(
                    question: "How do I manage my opening hours?",
                    answer: "In the Restaurant tab, you can set specific opening hours for each day of the week. These hours will be displayed to customers in the QSkipper app."
                )
            ]
        ),
        FAQSection(
            title: "Product Management",
            items: [
                FAQItem(
                    question: "How do I organize products into categories?",
                    answer: "When adding or editing a product, you can assign it to a specific category. Consistent category names will group products together in the customer-facing menu."
                ),
                FAQItem(
                    question: "Can I make a product temporarily unavailable?",
                    answer: "Yes, you can mark a product as unavailable without deleting it. This is useful when you're temporarily out of stock but plan to offer the item again soon."
                ),
                FAQItem(
                    question: "What is 'Extra Time' for products?",
                    answer: "Extra Time indicates additional preparation time needed for a specific product. This helps set accurate expectations for customers about when their order will be ready."
                )
            ]
        ),
        FAQSection(
            title: "Order Management",
            items: [
                FAQItem(
                    question: "How do I see new orders?",
                    answer: "New orders will appear in the Orders tab. You can filter by status to see only new orders. The list refreshes automatically but you can also manually refresh by pulling down or clicking the refresh button."
                ),
                FAQItem(
                    question: "How do I update an order status?",
                    answer: "Click on an order to view its details. From there, you can update its status to 'In Progress', 'Ready for Pickup', or 'Completed'."
                ),
                FAQItem(
                    question: "Can I cancel an order?",
                    answer: "Yes, you can change an order's status to 'Cancelled' if needed. It's good practice to contact the customer when cancelling an order to explain the reason."
                )
            ]
        ),
        FAQSection(
            title: "Account & Security",
            items: [
                FAQItem(
                    question: "How do I reset my password?",
                    answer: "On the login screen, click 'Forgot Password' and follow the instructions. You'll receive an email with a link to reset your password."
                ),
                FAQItem(
                    question: "Is my restaurant data secure?",
                    answer: "Yes, QSkipper uses industry-standard encryption to protect all restaurant and order data. We never share your information with third parties without your consent."
                ),
                FAQItem(
                    question: "How do I logout from the admin panel?",
                    answer: "Click the Logout button at the bottom of the sidebar. Always remember to logout when leaving your device unattended."
                )
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Help & Support")
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
                VStack(spacing: 24) {
                    // Support contact card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Need Assistance?")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Our support team is available to help you with any questions or issues you may encounter while using QSkipper Admin.")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        ContactButton(icon: "envelope.fill", text: "Email Support", action: {
                            openEmail()
                        })
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // FAQ sections
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequently Asked Questions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(faqSections, id: \.title) { section in
                            FAQSectionView(
                                section: section,
                                isExpanded: expandedSection == section.title,
                                toggleAction: {
                                    withAnimation {
                                        if expandedSection == section.title {
                                            expandedSection = nil
                                        } else {
                                            expandedSection = section.title
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // Action to open email
    private func openEmail() {
        if let url = URL(string: "mailto:team.qskipper@gmail.com") {
            UIApplication.shared.open(url)
        }
    }
}

// Section of FAQ items
struct FAQSection: Identifiable {
    var id: String { title }
    let title: String
    let items: [FAQItem]
}

// Individual FAQ question and answer
struct FAQItem: Identifiable {
    var id: String { question }
    let question: String
    let answer: String
}

// View for a section of FAQs with expand/collapse
struct FAQSectionView: View {
    let section: FAQSection
    let isExpanded: Bool
    let toggleAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with expand/collapse
            Button(action: toggleAction) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(isExpanded ? 8 : 8)
            }
            
            // Questions and answers
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(section.items) { item in
                        FAQItemView(item: item)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1)
        .padding(.bottom, 8)
    }
}

// View for individual FAQ item
struct FAQItemView: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question button
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "minus" : "plus")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Answer (shown when expanded)
            if isExpanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
            
            Divider()
        }
    }
}

// Support contact button
struct ContactButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                
                Text(text)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green)
            .cornerRadius(8)
        }
    }
}

#Preview {
    HelpView()
} 