import Foundation
import FirebaseFirestore

enum PassStatus: String, Codable, CaseIterable {
  case rejected, pending, approved
}

struct Pass: Codable, Identifiable {
  @DocumentID var id: String?
  let author: String
  let fromRoom: String
  let toRoom: String
  let createdAt: Date
  let approved: PassStatus
  let startTime: Date?
  let duration: Int?
    let active: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case author
    case fromRoom
    case toRoom
    case createdAt = "created_at"
    case approved
    case startTime = "start_time"
    case duration
      case active
  }
}
