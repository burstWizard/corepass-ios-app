import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // In previews/tests, you may not want to touch Firebase at all.
        if shouldSkipFirebaseSetup {
            return true
        }

        configureFirebaseIfNeeded()

        #if DEBUG
        // Optional: connect to local emulators when asked (handy for manual QA).
        if ProcessInfo.processInfo.arguments.contains("USE_FIREBASE_EMULATORS") {
            connectEmulators()
        }
        #endif

        return true
    }

    /// Handles OAuth redirect back into the app (Google Sign-In, etc.)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // If you also use Firebase email-link auth, let Firebase try to handle first:
        if Auth.auth().canHandle(url) {
            return true
        }
        // Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return false
    }
}

// MARK: - Private helpers

private extension AppDelegate {
    var shouldSkipFirebaseSetup: Bool {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["XCODE_RUNNING_FOR_PREVIEWS"] != nil { return true }
        if env["SKIP_FIREBASE"] != nil { return true }
        #endif
        return false
    }

    func configureFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    #if DEBUG
    func connectEmulators() {
        let host = "127.0.0.1"
        Auth.auth().useEmulator(withHost: host, port: 9099)
    }
    #endif
}
