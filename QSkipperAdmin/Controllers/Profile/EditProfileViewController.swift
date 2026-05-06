import UIKit
import SwiftUI
import Combine
// Import ViewModels if in a separate module
// import ViewModels

class EditProfileViewController: UIViewController {
    
    // MARK: - Properties
    private var editProfileView: UIHostingController<EditProfileUIView>!
    private var viewModel = EditProfileViewModel()
    private var cancellables = Set<AnyCancellable>()
    var currentUser: User?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Use User model if passed from ProfileViewController
        if let user = currentUser {
            viewModel.initializeWithUser(user)
        } else if let profile = AuthService.shared.currentUser {
            // Otherwise use the profile from AuthService
            viewModel.initializeWithUserProfile(profile)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set background color
        view.backgroundColor = UIColor(AppColors.backgroundWhite)
        
        // Configure view controller
        title = "Edit Profile"
        
        // Create SwiftUI view
        let swiftUIView = EditProfileUIView(viewModel: viewModel)
        
        // Create hosting controller for SwiftUI view
        editProfileView = UIHostingController(rootView: swiftUIView)
        
        // Add as child view controller
        addChild(editProfileView)
        view.addSubview(editProfileView.view)
        editProfileView.didMove(toParent: self)
        
        // Set constraints
        editProfileView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editProfileView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editProfileView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editProfileView.view.topAnchor.constraint(equalTo: view.topAnchor),
            editProfileView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        // Handle success
        viewModel.$isSuccess
            .receive(on: RunLoop.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
} 