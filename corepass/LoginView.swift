import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - Service protocol
protocol GoogleSignInProviding {
    func signIn(presenting: UIViewController) async throws
}

// MARK: - Real implementation
final class FirebaseGoogleSignInService: GoogleSignInProviding {
    enum SignInError: LocalizedError {
        case misconfiguredClientID, missingTokens
        var errorDescription: String? {
            switch self {
            case .misconfiguredClientID: "Missing or invalid Google Client ID."
            case .missingTokens:         "Could not retrieve Google tokens."
            }
        }
    }

    func signIn(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw SignInError.misconfiguredClientID
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

       
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)

        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw SignInError.missingTokens
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: signInResult.user.accessToken.tokenString
        )

        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: result!) }
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isSigningIn = false
    @Published var errorText: String?

    private let service: GoogleSignInProviding

    init(service: GoogleSignInProviding = FirebaseGoogleSignInService()) {
        self.service = service
    }

    func signIn(presenter: UIViewController?) async {
        guard !isSigningIn else { return }
        guard let presenter else {
            errorText = "No active window to present sign-in."
            return
        }

        isSigningIn = true
        defer { isSigningIn = false }

        do {
            try await service.signIn(presenting: presenter)
        } catch {
            if let le = error as? LocalizedError, let msg = le.errorDescription {
                errorText = msg
            } else {
                errorText = error.localizedDescription
            }
        }
    }
}

// MARK: - View
@MainActor
struct LoginView: View {
    @StateObject private var vm: LoginViewModel

    init(viewModel: LoginViewModel? = nil) {
        let resolved = viewModel ?? LoginViewModel()
        _vm = StateObject(wrappedValue: resolved)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.circle.fill").font(.title)
                        Text("corepass").font(.title).bold()
                    }
                    .padding(.top, 40)

                    Text("Digital hall passes for students")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Content
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Sign in with your school Google account")
                            .font(.title2).fontWeight(.medium)
                            .multilineTextAlignment(.center)

                        Text("Access is managed by your school district. Contact IT for help.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    GoogleSignInButton(isLoading: vm.isSigningIn) {
                        Task { await vm.signIn(presenter: UIApplication.cp_topViewController) }
                    }
                }

                Spacer()

                // Footer
                Text("By continuing, you agree to your school's Acceptable Use Policy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
            .background(Color(.systemBackground))
            .alert("Couldn't sign in", isPresented: Binding(
                get: { vm.errorText != nil },
                set: { if !$0 { vm.errorText = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.errorText ?? "")
            }
        }
    }
}

// MARK: - Button (unchanged)
struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView().scaleEffect(0.9)
                } else if UIImage(named: "google_logo") != nil {
                    Image("google_logo").resizable().frame(width: 20, height: 20)
                } else {
                    Image(systemName: "g.circle").font(.system(size: 20, weight: .medium))
                }
                Text(isLoading ? "Signing in..." : "Sign in with Google")
                    .font(.system(size: 16, weight: .medium))
                    .bold()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .accessibilityLabel("Sign in with Google")
        .accessibilityHint("Opens Google sign-in")
    }
}

// MARK: - Presenter helper
private extension UIApplication {
    static var cp_topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

#Preview("Login") {
    LoginView() // layout preview; no auth until you tap
}
