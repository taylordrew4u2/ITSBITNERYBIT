//
//  AuthService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/20/26.
//

import Foundation
import Combine

/// Manages user preferences and basic app state (no external authentication required)
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var hasAcceptedTerms = false
    @Published var isLoading = false
    @Published var isAuthenticated = true
    @Published var authError: AuthServiceError?
    
    private let userDefaults = UserDefaults.standard
    private let termsAcceptedKey = "hasAcceptedTerms"
    
    private init() {
        hasAcceptedTerms = userDefaults.bool(forKey: termsAcceptedKey)
    }
    
    // MARK: - Terms Acceptance
    
    func acceptTerms() {
        hasAcceptedTerms = true
        userDefaults.set(true, forKey: termsAcceptedKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Auth Stubs (no external auth needed)
    
    /// Always succeeds — no external auth provider required
    func signInAnonymously() async throws {
        isAuthenticated = true
    }
    
    /// Always succeeds — no external auth provider required
    func ensureAuthenticated() async throws {
        isAuthenticated = true
    }
    
    // MARK: - User ID (for local data separation)
    
    var userId: String {
        if let storedId = userDefaults.string(forKey: "userId") {
            return storedId
        } else {
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: "userId")
            userDefaults.synchronize()
            return newId
        }
    }
}

// MARK: - Error Type

enum AuthServiceError: LocalizedError {
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
