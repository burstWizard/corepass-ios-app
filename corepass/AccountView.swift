import SwiftUI
import FirebaseAuth
import GoogleSignIn

// MARK: - Google sign-out helper
enum GoogleAuthHelper {
    static func signOutIfAvailable() {
        GIDSignIn.sharedInstance.signOut()
    }
}

struct AccountView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var errorText: String?

    // Styling constants
    private let cardCornerRadius: CGFloat = 14

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Greeting
                header

                // Profile card
                profileCard

                Spacer()

                // Sign-out
                Button {
                    do {
                        try signOut()
                    } catch {
                        errorText = error.localizedDescription
                    }
                } label: {
                    Label("Log Out", systemImage: "key.slash")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BrandTitle()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
            .toolbarBackground(Color(.white), for: .navigationBar, .tabBar)
            .toolbarBackground(.visible, for: .navigationBar, .tabBar)
            .alert("Sign out failed", isPresented: Binding(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        // One utterance for VoiceOver; style just the name
        (Text("Hello ") +
        Text(auth.uiDisplayName).foregroundStyle(.blue) +
        Text("!"))
            .font(.title).bold()
            .accessibilityLabel("Hello \(auth.uiDisplayName)!")
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                AvatarView(displayName: auth.uiDisplayName, photoURL: auth.uiPhotoURL, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.uiDisplayName)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    if let email = auth.uiEmail, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .accessibilityLabel("Email \(email)")
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName) profile")
    }

    // MARK: - Derived values

    private var displayName: String {
        return auth.uiDisplayName
    }

    // MARK: - Actions

    private func signOut() throws {
        try Auth.auth().signOut()
        GoogleAuthHelper.signOutIfAvailable()
    }
}

// MARK: - Avatar

private struct AvatarView: View {
    let displayName: String
    let photoURL: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        initialsCircle
                    case .empty:
                        ProgressView()
                    @unknown default:
                        initialsCircle
                    }
                }
            } else {
                initialsCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
        .accessibilityLabel("Profile image for \(displayName)")
        .accessibilityHidden(false)
    }

    private var initialsCircle: some View {
        let initials = initials(from: displayName)
        return ZStack {
            Circle().fill(Color.blue.opacity(0.15))
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

// MARK: - Brand title (keeps nav bar tidy)

private struct BrandTitle: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hammer.circle").font(.title2).bold()
            Text("corepass").font(.title2).bold()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("CorePass")
    }
}

#Preview("Account — Light") {
    let vm = AuthViewModel()
    vm.injectPreview(
        name: "Ava Nguyen",
        email: "ava@school.org",
        photoURL: URL(string: "https://picsum.photos/seed/ava/200")
    )
    return AccountView()
        .environmentObject(vm)
        .preferredColorScheme(.light)
}

#Preview("Account — Dark") {
    let vm = AuthViewModel()
    vm.injectPreview(
        name: "Ava Nguyen",
        email: "ava@school.org",
        photoURL: URL(string: "https://picsum.photos/seed/ava/200")
    )
    return AccountView()
        .environmentObject(vm)
        .preferredColorScheme(.dark)
}

#Preview("Account — No User") {
    // Shows your "Student" fallback
    AccountView()
        .environmentObject(AuthViewModel())
}



