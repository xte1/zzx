import Foundation

struct YouTubeVideo: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let channel: String
    let thumbnail: URL?
    let publishedAt: String?
    var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(id)")! }
}

struct LocalTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var fileName: String
    var artist: String
    var addedAt: Date
    init(id: UUID = UUID(), title: String, fileName: String, artist: String = "ملف محلي", addedAt: Date = .now) {
        self.id = id; self.title = title; self.fileName = fileName; self.artist = artist; self.addedAt = addedAt
    }
}
