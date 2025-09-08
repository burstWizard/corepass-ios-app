// Session.swift
import Foundation
import FirebaseAuth

/// What the app needs from "who's signed in".
protocol SessionProviding {
    var uid: String? { get }
}

/// Real session: read from Firebase Auth at runtime.
struct FirebaseSession: SessionProviding {
    var uid: String? { Auth.auth().currentUser?.uid }
}

/// Mock session: set any UID for previews/tests.
struct MockSession: SessionProviding {
    var uid: String?
    init(uid: String = "preview-uid") { self.uid = uid }
}

/// Simple service locator so views/services can read the session.
enum Services {
    static var session: SessionProviding = FirebaseSession()
}
