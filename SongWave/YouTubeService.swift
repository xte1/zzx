import Foundation

struct YouTubeService {
    private let apiKey = AppConfig.youtubeAPIKey
    private let base = "https://www.googleapis.com/youtube/v3/videos"
    private let searchBase = "https://www.googleapis.com/youtube/v3/search"

    func trending(region: String = "IQ") async throws -> [YouTubeVideo] {
        guard !apiKey.isEmpty else { throw APIError.missingKey }
        var c = URLComponents(string: base)!
        c.queryItems = [URLQueryItem(name: "part", value: "snippet"), URLQueryItem(name: "chart", value: "mostPopular"), URLQueryItem(name: "regionCode", value: region), URLQueryItem(name: "videoCategoryId", value: "10"), URLQueryItem(name: "maxResults", value: "25"), URLQueryItem(name: "key", value: apiKey)]
        return try await decodeVideos(from: c.url!, isSearch: false)
    }

    func search(_ query: String) async throws -> [YouTubeVideo] {
        guard !apiKey.isEmpty else { throw APIError.missingKey }
        var c = URLComponents(string: searchBase)!
        c.queryItems = [URLQueryItem(name: "part", value: "snippet"), URLQueryItem(name: "type", value: "video"), URLQueryItem(name: "videoCategoryId", value: "10"), URLQueryItem(name: "q", value: query), URLQueryItem(name: "maxResults", value: "25"), URLQueryItem(name: "key", value: apiKey)]
        return try await decodeVideos(from: c.url!, isSearch: true)
    }

    private func decodeVideos(from url: URL, isSearch: Bool) async throws -> [YouTubeVideo] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let items = root["items"] as? [[String: Any]] ?? []
        return items.compactMap { item in
            let snippet = item["snippet"] as? [String: Any] ?? [:]
            let id: String
            if isSearch { id = (item["id"] as? [String: Any])?["videoId"] as? String ?? "" }
            else { id = item["id"] as? String ?? "" }
            guard !id.isEmpty else { return nil }
            let thumbs = snippet["thumbnails"] as? [String: Any] ?? [:]
            let thumb = (thumbs["high"] as? [String: Any])?["url"] as? String ?? (thumbs["medium"] as? [String: Any])?["url"] as? String
            return YouTubeVideo(id: id, title: snippet["title"] as? String ?? "بدون عنوان", channel: snippet["channelTitle"] as? String ?? "", thumbnail: thumb.flatMap(URL.init(string:)), publishedAt: snippet["publishedAt"] as? String)
        }
    }

    enum APIError: LocalizedError {
        case missingKey, requestFailed
        var errorDescription: String? {
            switch self { case .missingKey: return "أضف مفتاح YouTube API في AppConfig.swift أو GitHub Secrets."; case .requestFailed: return "تعذر جلب النتائج. تحقق من مفتاح API والاتصال." }
        }
    }
}
