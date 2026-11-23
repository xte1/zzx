import SwiftUI

@main
struct SongWaveApp: App {
    @StateObject private var library = MusicLibrary()
    var body: some Scene {
        WindowGroup {
            MainTabView().environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
