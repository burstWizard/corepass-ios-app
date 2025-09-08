import SwiftUI

@main
struct CorePassApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthViewModel()

    init() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let testUID = env["TEST_UID"], !testUID.isEmpty {
            Services.session = MockSession(uid: testUID)          // UI tests
        } else if env["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
            Services.session = MockSession()                      // Previews
        } else {
            Services.session = FirebaseSession()                  // Real app
        }
        #else
        Services.session = FirebaseSession()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.user == nil { LoginView() } else { RootTabView() }
            }
            .environmentObject(auth)
        }
    }
}
