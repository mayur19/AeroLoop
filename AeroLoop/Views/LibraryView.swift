import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: WallpaperLibraryService
    @EnvironmentObject var playlistsService: PlaylistService
    
    @State private var isFilePickerPresented = false
    @State private var searchText = ""
    @State private var selection: SidebarItem? = .library
    
    enum SidebarItem: Hashable {
        case library
        case favorites
        case playlist(UUID)
    }
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case duration = "Duration"
    }
    
    @State private var sortOption: SortOption = .dateAdded
    
    var filteredItems: [WallpaperItem] {
        var itemsToFilter: [WallpaperItem]
        
        switch selection {
        case .playlist(let id):
            if let playlist = playlistsService.playlists.first(where: { $0.playlist.id == id }) {
                itemsToFilter = playlist.items
            } else {
                itemsToFilter = []
            }
        case .favorites:
            itemsToFilter = library.items.filter { $0.isFavorite }
        case .library, .none:
            itemsToFilter = library.items
        }
        
        if !searchText.isEmpty {
            itemsToFilter = itemsToFilter.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOption {
        case .dateAdded:
            return itemsToFilter.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return itemsToFilter.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .duration:
            return itemsToFilter.sorted { $0.duration > $1.duration }
        }
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 16)
    ]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Library") {
                    Label("All Wallpapers", systemImage: "photo.on.rectangle")
                        .tag(SidebarItem.library)
                    Label("Favorites", systemImage: "star.fill")
                        .tag(SidebarItem.favorites)
                        .foregroundStyle(selection == .favorites ? .white : .yellow)
                }
                
                Section("Playlists") {
                    ForEach(playlistsService.playlists, id: \.playlist.id) { pw in
                        Label(pw.playlist.title, systemImage: "list.and.film")
                            .tag(SidebarItem.playlist(pw.playlist.id))
                            .contextMenu {
                                Button("Play", systemImage: "play.fill") {
                                    appState.wallpaperEngine.applyPlaylist(pw)
                                }
                                Divider()
                                Button("Delete Playlist", systemImage: "trash", role: .destructive) {
                                    Task { await playlistsService.deletePlaylist(pw.playlist) }
                                }
                            }
                    }
                    
                    Button {
                        Task { await playlistsService.createPlaylist(title: "New Playlist") }
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("AeroLoop")
        } detail: {
            ZStack {
                // Glass backdrop
                VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Glass Toolbar
                    HStack {
                        if case .playlist(let id) = selection, let pw = playlistsService.playlists.first(where: { $0.playlist.id == id }) {
                            TextField("Playlist Name", text: Binding(
                                get: { pw.playlist.title },
                                set: { newValue in
                                    var updated = pw.playlist
                                    updated.title = newValue
                                    Task { await playlistsService.updatePlaylist(updated) }
                                }
                            ))
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .textFieldStyle(.plain)
                            .frame(maxWidth: 250)
                            
                            Button {
                                appState.wallpaperEngine.applyPlaylist(pw)
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            .padding(.leading, 8)
                            
                            Menu {
                                Toggle("Shuffle", isOn: Binding(
                                    get: { pw.playlist.shuffle },
                                    set: { newValue in
                                        var updated = pw.playlist
                                        updated.shuffle = newValue
                                        Task { await playlistsService.updatePlaylist(updated) }
                                    }
                                ))
                                
                                Menu("Rotation Interval") {
                                    ForEach([60.0, 300.0, 900.0, 1800.0, 3600.0, 43200.0, 86400.0], id: \.self) { interval in
                                        Button(formatInterval(interval)) {
                                            var updated = pw.playlist
                                            updated.rotationInterval = interval
                                            Task { await playlistsService.updatePlaylist(updated) }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "gear")
                            }
                            .menuIndicator(.hidden)
                            .fixedSize()
                            
                        } else if selection == .favorites {
                            Text("Favorites")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.semibold)
                        } else {
                            Text("All Wallpapers")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Picker("Sort By", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Search...", text: $searchText)
                                    .textFieldStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .frame(width: 160)
                            
                            Button {
                                isFilePickerPresented = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.accentColor))
                                    .shadow(color: Color.accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    
                    // MARK: - Grid
                    ScrollView {
                        if filteredItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text(library.items.isEmpty ? "Your library is empty." : "No results found.")
                                    .foregroundStyle(.secondary)
                                if library.items.isEmpty {
                                    Button("Import Video") {
                                        isFilePickerPresented = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(filteredItems) { item in
                                    LibraryItemView(item: item, selection: selection)
                                        .environmentObject(appState)
                                        .environmentObject(library)
                                        .environmentObject(playlistsService)
                                }
                            }
                            .padding(24)
                        }
                    }
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        let group = DispatchGroup()
                        var urls: [URL] = []
                        for provider in providers {
                            group.enter()
                            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                                if let url = url, ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased()) {
                                    urls.append(url)
                                }
                                group.leave()
                            }
                        }
                        group.notify(queue: .main) {
                            if !urls.isEmpty {
                                handleFileImport(.success(urls))
                            }
                        }
                        return true
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .alert(item: $appState.appError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            
            // Create a security-scoped bookmark before losing access
            let bookmark = BookmarkManager.createBookmark(for: url)
            
            Task {
                do {
                    let durableURL = try await VideoMetadataService.importVideoToLibrary(url: url)
                    var item = await VideoMetadataService.extractMetadata(from: durableURL)
                    item.bookmarkData = bookmark
                    await library.add(item)
                    // Pre-generate and cache thumbnail
                    _ = await VideoMetadataService.generateThumbnail(from: durableURL)
                } catch {
                    appState.appError = AppState.AppError(message: "Failed to import video: \(error.localizedDescription)")
                }
                if didStart { url.stopAccessingSecurityScopedResource() }
            }
        }
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .full
        return formatter.string(from: interval) ?? "\(interval)s"
    }
}

// MARK: - Library Item View

struct LibraryItemView: View {
    let item: WallpaperItem
    let selection: LibraryView.SidebarItem?
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: WallpaperLibraryService
    @EnvironmentObject var playlistsService: PlaylistService
    
    @State private var thumbnail: NSImage?
    @State private var isHovered = false
    
    var isActive: Bool {
        appState.currentWallpaper?.id == item.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail Area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ProgressView()
                }
                
                // Glossy glass sheer gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.4), location: 0),
                                .init(color: .white.opacity(0.0), location: 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Play overlay if active
                if isActive {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).clipShape(RoundedRectangle(cornerRadius: 12)))
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.accentColor : Color.white.opacity(0.2), lineWidth: isActive ? 3 : 1)
            )
            .shadow(color: isActive ? Color.accentColor.opacity(0.5) : (isHovered ? .black.opacity(0.4) : .black.opacity(0.2)), radius: isHovered ? 12 : 6, x: 0, y: isHovered ? 8 : 4)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(), value: isActive)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                appState.applyWallpaper(item)
            }
            
            // Info Area
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(item.metadataLabel)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    var updated = item
                    updated.isFavorite.toggle()
                    Task { await library.update(updated) }
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? .yellow : .secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .contextMenu {
            if SettingsManager.sharedDefaults.bool(forKey: "aeroloop.syncAllDisplays") {
                Button("Apply Wallpaper") {
                    appState.wallpaperEngine.applyWallpaper(item)
                    SettingsManager().saveLastWallpaper(item)
                }
            } else {
                Menu("Apply to Display") {
                    Button("All Displays") {
                        appState.wallpaperEngine.applyWallpaper(item)
                        SettingsManager().saveLastWallpaper(item)
                    }
                    Divider()
                    ForEach(NSScreen.screens, id: \.displayID) { screen in
                        if let displayID = screen.displayID {
                            Button(screen.localizedName) {
                                appState.wallpaperEngine.applyWallpaper(item, to: displayID)
                                SettingsManager().saveLastWallpaper(item, for: displayID)
                            }
                        }
                    }
                }
            }
            Divider()
            
            Menu("Add to Playlist") {
                ForEach(playlistsService.playlists, id: \.playlist.id) { pw in
                    Button(pw.playlist.title) {
                        Task { await playlistsService.addWallpaper(item, to: pw.playlist) }
                    }
                }
            }
            
            if case .playlist(let id) = selection, let playlist = playlistsService.playlists.first(where: { $0.playlist.id == id }) {
                Button("Remove from Playlist", role: .destructive) {
                    Task { await playlistsService.removeWallpaper(item, from: playlist.playlist) }
                }
            }
            
            Divider()
            Button("Toggle Favorite") {
                var updated = item
                updated.isFavorite.toggle()
                Task { await library.update(updated) }
            }
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            Divider()
            Button("Delete from Library", role: .destructive) {
                Task { await library.delete(item) }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            if let image = await VideoMetadataService.generateThumbnail(from: item.url) {
                thumbnail = image
            }
        }
    }
}
