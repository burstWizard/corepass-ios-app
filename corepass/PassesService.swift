import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class PassesService: ObservableObject {
  private let db = Firestore.firestore()
  private var listener: ListenerRegistration?

  @Published var passes: [Pass] = []
  @Published var errorMessage: String?

  /// Begin listening to the current student's passes
  func startListeningForCurrentUser() {
    stopListening()

    guard let uid = Auth.auth().currentUser?.uid else {
      self.passes = []
      self.errorMessage = "Not signed in."
      return
    }

    // Query: passes for this uid, newest first
    listener = db.collection("passes")
      .whereField("author", isEqualTo: uid)
      .order(by: "created_at", descending: true)
      .addSnapshotListener { [weak self] snap, err in
        guard let self else { return }
        if let err = err {
          self.errorMessage = err.localizedDescription
          return
        }
        guard let snap else { return }
        self.passes = snap.documents.compactMap { try? $0.data(as: Pass.self) }
        self.errorMessage = nil
      }
  }

  func stopListening() {
    listener?.remove()
    listener = nil
  }

  // Optional: quick seeder to test the UI
  func seedExamplePasses() async {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let now = Date()
    let docs: [[String: Any]] = [
      [
        "author": uid,
        "fromRoom": "Room 204",
        "toRoom": "Nurse",
        "created_at": Timestamp(date: now.addingTimeInterval(-60*20)),
        "approved": "pending",
        "start_time": FieldValue.delete(),
        "duration": FieldValue.delete()
      ],
      [
        "author": uid,
        "fromRoom": "Room 204",
        "toRoom": "Library",
        "created_at": Timestamp(date: now.addingTimeInterval(-60*60)),
        "approved": "approved",
        "start_time": Timestamp(date: now.addingTimeInterval(-60*30)),
        "duration": 10
      ],
      [
        "author": uid,
        "fromRoom": "Gym",
        "toRoom": "Office",
        "created_at": Timestamp(date: now.addingTimeInterval(-60*90)),
        "approved": "rejected",
        "start_time": FieldValue.delete(),
        "duration": FieldValue.delete()
      ]
    ]
    for d in docs {
      try? await db.collection("passes").addDocument(data: d)
    }
  }
}
