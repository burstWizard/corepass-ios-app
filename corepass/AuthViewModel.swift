import Foundation
import FirebaseAuth
import FirebaseCore

final class AuthViewModel: ObservableObject {
  @Published var user: User?

  private var handle: AuthStateDidChangeListenerHandle?

  init() {
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil,
       FirebaseApp.app() == nil {
      return
    }
    #endif

    handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  deinit {
    if let handle { Auth.auth().removeStateDidChangeListener(handle) }
  }

  func signOut() { try? Auth.auth().signOut() }

  // MARK: - UI-facing values (work both in-app and in previews)

  var uiDisplayName: String {
    #if DEBUG
    if let n = previewName, !n.isEmpty { return n }
    #endif
    if let dn = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !dn.isEmpty {
      return dn
    }
    if let email = user?.email, let local = email.split(separator: "@").first {
      return local
        .replacingOccurrences(of: ".", with: " ")
        .split(separator: " ")
        .map { $0.capitalized }
        .joined(separator: " ")
    }
    return "Student"
  }

  var uiEmail: String? {
    #if DEBUG
    if let e = previewEmail { return e }
    #endif
    return user?.email
  }

  var uiPhotoURL: URL? {
    #if DEBUG
    if let u = previewPhotoURL { return u }
    #endif
    return user?.photoURL
  }

  // MARK: - Preview injection
  #if DEBUG
  @Published private var previewName: String?
  @Published private var previewEmail: String?
  @Published private var previewPhotoURL: URL?

  @MainActor
  func injectPreview(name: String, email: String?, photoURL: URL?) {
    previewName = name
    previewEmail = email
    previewPhotoURL = photoURL
  }
  #endif
}
