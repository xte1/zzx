import SwiftUI
import UniformTypeIdentifiers

struct MainTabView: View {
    @EnvironmentObject private var library: MusicLibrary
    var body: some View {
        TabView {
            TrendingView().tabItem { Label("الرائج", systemImage: "chart.line.uptrend.xyaxis") }
            SearchMusicView().tabItem { Label("بحث", systemImage: "magnifyingglass") }
            LocalLibraryView().tabItem { Label("مكتبتي", systemImage: "music.note.list") }
            DeveloperView().tabItem { Label("حول", systemImage: "info.circle") }
        }
        .tint(.purple)
        .safeAreaInset(edge: .bottom, spacing: 0) { if library.currentTrack != nil { MiniPlayerView() } }
        .alert("تنبيه", isPresented: Binding(get: { library.errorMessage != nil }, set: { if !$0 { library.errorMessage = nil } })) { Button("حسناً") { library.errorMessage = nil } } message: { Text(library.errorMessage ?? "") }
    }
}

struct TrendingView: View {
    @State private var videos: [YouTubeVideo] = []
    @State private var loading = false
    @State private var error: String?
    private let service = YouTubeService()
    var body: some View {
        NavigationStack {
            Group {
                if loading { ProgressView("جاري تحميل الأغاني...") }
                else if let error { VStack(spacing: 10) { Image(systemName: "wifi.exclamationmark").font(.largeTitle); Text("تعذر تحميل الرائج"); Text(error).font(.caption).foregroundStyle(.secondary); Button("إعادة المحاولة") { Task { await load() } } } }
                else { List(videos) { video in VideoRow(video: video) } .listStyle(.plain) }
            }
            .navigationTitle("الأغاني الرائجة")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } } }
            .task { if videos.isEmpty { await load() } }
        }
    }
    @MainActor private func load() async {
        loading = true; error = nil
        do { videos = try await service.trending() } catch { self.error = error.localizedDescription }
        loading = false
    }
}

struct SearchMusicView: View {
    @State private var query = ""
    @State private var results: [YouTubeVideo] = []
    @State private var loading = false
    @State private var error: String?
    private let service = YouTubeService()
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("ابحث عن أغنية أو فنان", text: $query).textFieldStyle(.roundedBorder).submitLabel(.search).onSubmit { Task { await search() } }
                    Button { Task { await search() } } label: { Image(systemName: "magnifyingglass").padding(10) }.disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                }.padding()
                if loading { ProgressView() }
                if let error { Text(error).foregroundStyle(.secondary).padding() }
                List(results) { video in VideoRow(video: video) }.listStyle(.plain)
            }.navigationTitle("البحث")
        }
    }
    @MainActor private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines); guard !term.isEmpty else { return }
        loading = true; error = nil
        do { results = try await service.search(term) } catch { self.error = error.localizedDescription }
        loading = false
    }
}

struct VideoRow: View {
    let video: YouTubeVideo
    @EnvironmentObject private var library: MusicLibrary
    @State private var showPlayer = false
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: video.thumbnail) { phase in
                if let image = phase.image { image.resizable().scaledToFill() } else { RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.2)).overlay(Image(systemName: "music.note")) }
            }.frame(width: 112, height: 66).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 5) {
                Text(video.title).font(.subheadline).lineLimit(2)
                Text(video.channel).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Button { showPlayer = true } label: { Label("شغّل الفيديو", systemImage: "play.rectangle.fill").font(.caption) }.tint(.purple)
            }
        }.padding(.vertical, 4)
        .sheet(isPresented: $showPlayer) { NavigationStack { YouTubePlayerView(videoID: video.id).frame(height: 240).navigationTitle(video.title).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .topBarTrailing) { Button("إغلاق") { showPlayer = false } } } } }
    }
}

struct LocalLibraryView: View {
    @EnvironmentObject private var library: MusicLibrary
    @State private var importing = false
    var body: some View {
        NavigationStack {
            Group {
                if library.tracks.isEmpty { VStack(spacing: 12) { Image(systemName: "music.note.list").font(.largeTitle); Text("مكتبتك فارغة"); Text("استورد ملفات صوتية من جهازك للاستماع دون إنترنت.").font(.caption).foregroundStyle(.secondary); Button("استيراد ملفات") { importing = true } } }
                else { List { ForEach(library.tracks) { track in
                    HStack {
                        Button { library.play(track) } label: { Image(systemName: library.currentTrack?.id == track.id && library.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.title2).foregroundStyle(.purple) }
                        VStack(alignment: .leading) { Text(track.title).lineLimit(1); Text(track.artist).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Button { library.toggleFavorite(track) } label: { Image(systemName: library.isFavorite(track) ? "heart.fill" : "heart").foregroundStyle(.pink) }
                    }.swipeActions { Button(role: .destructive) { library.delete(track) } label: { Label("حذف", systemImage: "trash") } }
                } } .listStyle(.plain) }
            }
            .navigationTitle("مكتبتي")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { importing = true } label: { Image(systemName: "plus") } } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.audio, .mp3, .mpeg4Audio], allowsMultipleSelection: true) { result in
                switch result { case .success(let urls): library.importFiles(urls); case .failure(let error): library.errorMessage = error.localizedDescription }
            }
        }
    }
}

struct MiniPlayerView: View {
    @EnvironmentObject private var library: MusicLibrary
    var body: some View {
        HStack {
            Image(systemName: "waveform").foregroundStyle(.purple)
            VStack(alignment: .leading) { Text(library.currentTrack?.title ?? "").font(.caption).lineLimit(1); Text("تشغيل محلي").font(.caption2).foregroundStyle(.secondary) }
            Spacer()
            Button { library.togglePlayback() } label: { Image(systemName: library.isPlaying ? "pause.fill" : "play.fill").font(.title3) }
        }.padding(.horizontal).padding(.vertical, 8).background(.ultraThinMaterial)
    }
}

struct DeveloperView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("حول التطبيق") {
                    LabeledContent("اسم التطبيق", value: "SongWave")
                    LabeledContent("الإصدار", value: AppConfig.appVersion)
                    Text("مشغل موسيقى للبحث عن الأغاني ومشاهدة محتوى YouTube، مع مكتبة محلية وتشغيل الملفات الصوتية بالخلفية.").font(.subheadline)
                }
                Section("معلومات المطور") {
                    LabeledContent("المطور", value: AppConfig.developerName)
                    LabeledContent("البريد الإلكتروني", value: AppConfig.developerEmail)
                    if let mail = URL(string: "mailto:\(AppConfig.developerEmail)") { Link("تواصل مع المطور", destination: mail) }
                }
                Section("الخصوصية") { Text("لا يتم رفع ملفات الموسيقى المحلية إلى أي خادم. بحث YouTube يستخدم YouTube Data API. لا يدعم التطبيق تنزيل صوت YouTube أو تشغيله مخفياً؛ يتم فتح الفيديو عبر YouTube.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("حول التطبيق")
        }
    }
}
