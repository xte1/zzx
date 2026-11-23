import Foundation
import Combine
import AVFoundation
import MediaPlayer

@MainActor
final class MusicLibrary: ObservableObject {
    @Published var tracks: [LocalTrack] = []
    @Published var currentTrack: LocalTrack?
    @Published var isPlaying = false
    @Published var favorites: Set<UUID> = []
    @Published var errorMessage: String?
    private var player: AVAudioPlayer?
    private let tracksKey = "songwave.tracks"
    private let favoritesKey = "songwave.favorites"

    init() {
        configureAudioSession()
        load()
        setupRemoteControls()
    }
    var documents: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    func fileURL(for track: LocalTrack) -> URL { documents.appendingPathComponent(track.fileName) }

    func importFiles(_ urls: [URL]) {
        for source in urls {
            guard source.startAccessingSecurityScopedResource() else { continue }
            defer { source.stopAccessingSecurityScopedResource() }
            let ext = source.pathExtension.isEmpty ? "mp3" : source.pathExtension
            let name = "\(UUID().uuidString).\(ext)"
            let destination = documents.appendingPathComponent(name)
            do {
                try FileManager.default.copyItem(at: source, to: destination)
                let track = LocalTrack(title: source.deletingPathExtension().lastPathComponent, fileName: name)
                tracks.insert(track, at: 0)
            } catch { errorMessage = "تعذر استيراد الملف: \(error.localizedDescription)" }
        }
        save()
    }

    func play(_ track: LocalTrack) {
        do {
            try configureAudioSession()
            if currentTrack?.id == track.id, let player {
                player.play(); isPlaying = true
            } else {
                player = try AVAudioPlayer(contentsOf: fileURL(for: track))
                player?.prepareToPlay(); player?.play()
                currentTrack = track; isPlaying = true
            }
            updateNowPlaying()
        } catch { errorMessage = "تعذر تشغيل الملف: \(error.localizedDescription)" }
    }
    func togglePlayback() {
        guard let player else { return }
        if player.isPlaying { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
        updateNowPlaying()
    }
    func delete(_ track: LocalTrack) {
        if currentTrack?.id == track.id { player?.stop(); player = nil; currentTrack = nil; isPlaying = false }
        try? FileManager.default.removeItem(at: fileURL(for: track))
        tracks.removeAll { $0.id == track.id }; favorites.remove(track.id); save()
    }
    func toggleFavorite(_ track: LocalTrack) { if favorites.contains(track.id) { favorites.remove(track.id) } else { favorites.insert(track.id) }; save() }
    func isFavorite(_ track: LocalTrack) -> Bool { favorites.contains(track.id) }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch { errorMessage = error.localizedDescription }
    }
    private func setupRemoteControls() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.player?.play(); self?.isPlaying = true; self?.updateNowPlaying() }; return .success }
        center.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.player?.pause(); self?.isPlaying = false; self?.updateNowPlaying() }; return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.togglePlayback() }; return .success }
    }
    private func updateNowPlaying() {
        guard let track = currentTrack else { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: track.title, MPMediaItemPropertyArtist: track.artist, MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0, MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime ?? 0, MPMediaItemPropertyPlaybackDuration: player?.duration ?? 0]
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: tracksKey), let value = try? JSONDecoder().decode([LocalTrack].self, from: data) { tracks = value }
        if let data = UserDefaults.standard.data(forKey: favoritesKey), let value = try? JSONDecoder().decode(Set<UUID>.self, from: data) { favorites = value }
    }
    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(tracks), forKey: tracksKey)
        UserDefaults.standard.set(try? JSONEncoder().encode(favorites), forKey: favoritesKey)
    }
}
