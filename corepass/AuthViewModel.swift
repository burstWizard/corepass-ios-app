//
//  AuthViewModel.swift
//  corepass
//
//  Created by Hari Shankar on 9/7/25.
//


import Foundation
import FirebaseAuth

final class AuthViewModel: ObservableObject {
  @Published var user: User?

  private var handle: AuthStateDidChangeListenerHandle?

  init() {
    handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  deinit {
    if let handle { Auth.auth().removeStateDidChangeListener(handle) }
  }

  func signOut() {
    try? Auth.auth().signOut()
  }
}
