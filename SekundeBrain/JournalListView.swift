import SwiftUI
import CoreData
import LocalAuthentication

enum SidebarItem: String, Identifiable, CaseIterable {
    case journal = "Journal"
    case settings = "Settings"
    case about = "About"

    var id: String { rawValue }
}

struct JournalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)])
    private var entries: FetchedResults<JournalEntry>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \JournalFolder.name, ascending: true)])
    private var folders: FetchedResults<JournalFolder>

    @State private var showNewEntry = false
    @State private var entryToEdit: JournalEntry?
    @State private var isUnlocked = false
    @State private var filterText = ""
    @State private var selectedItem: SidebarItem? = .journal
    @State private var isPinnedExpanded = true
    @State private var selectedFolder: JournalFolder? = nil  // New state for folder filter

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: icon(for: item))
                    .tag(item)
            }
            .navigationTitle("Menu")
        } detail: {
            Group {
                switch selectedItem {
                case .journal:
                    journalContent
                case .settings:
                    SettingsView()
                case .about:
                    AboutView()
                default:
                    Text("Select an item")
                }
            }
        }
        .onAppear {
            authenticate()
        }
    }

    // MARK: - Journal Main Content
    private var journalContent: some View {
        NavigationStack {
            if isUnlocked {
                VStack {
                    TextField("Filter by tag or mood", text: $filterText)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .padding([.top, .horizontal])
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Folder Picker
                    Picker("Filter by Folder", selection: $selectedFolder) {
                        Text("All Folders").tag(nil as JournalFolder?)
                        ForEach(folders, id: \.self) { folder in
                            Text(folder.name ?? "Untitled").tag(folder as JournalFolder?)
                        }
                    }
                    .padding(.horizontal)

                    List {
                        if !pinnedEntries.isEmpty {
                            Section {
                                DisclosureGroup(
                                    isExpanded: $isPinnedExpanded.animation(.easeInOut),
                                    content: {
                                        ForEach(pinnedEntries) { entry in
                                            entryRow(for: entry)
                                        }
                                        .onDelete { offsets in
                                            delete(entries: offsets, from: pinnedEntries)
                                        }
                                    },
                                    label: {
                                        Label("Pinned", systemImage: "pin.fill")
                                            .font(.headline)
                                            .foregroundColor(.accentColor)
                                    }
                                )
                            }
                        }

                        Section {
                            ForEach(unpinnedEntries) { entry in
                                entryRow(for: entry)
                            }
                            .onDelete { offsets in
                                delete(entries: offsets, from: unpinnedEntries)
                            }
                        }
                        
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("My Journal")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                entryToEdit = nil
                                showNewEntry = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showNewEntry) {
                        NewEntryView(entryToEdit: entryToEdit)
                    }
                    .navigationDestination(for: JournalEntry.self) { entry in
                        JournalDetailView(entry: entry)
                    }
                }
            } else {
                VStack {
                    Text("Please authenticate to access the application...")
                        .padding()

                    Button("Unlock Journal") {
                        authenticate()
                    }
                    .padding()
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(for entry: JournalEntry) -> some View {
        NavigationLink(value: entry) {
            HStack(alignment: .top, spacing: 12) {
                if let data = entry.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title ?? "No Title")
                        .font(.headline)

                    Text(entry.date ?? Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let tags = entry.tags as? [String], !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button {
                entryToEdit = entry
                showNewEntry = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                if let index = filteredAndSortedEntries.firstIndex(of: entry) {
                    deleteEntries(offsets: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                togglePin(for: entry)
            } label: {
                Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin")
            }
            .tint(.yellow)
        }
    }

    private func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock your journal"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        print("Biometric failed: \(authError?.localizedDescription ?? "Unknown error")")
                        authenticateWithPasscode()
                    }
                }
            }
        } else {
            print("Biometrics unavailable: \(error?.localizedDescription ?? "Unknown error")")
            authenticateWithPasscode()
        }
    }

    private func authenticateWithPasscode() {
        let context = LAContext()
        let reason = "Unlock using your device passcode"

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                } else {
                    print("Passcode failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    private var filteredAndSortedEntries: [JournalEntry] {
        let filtered = filterText.isEmpty
            ? Array(entries)
            : entries.filter { entry in
                guard let tags = entry.tags as? [String] else { return false }
                return tags.contains { $0.localizedCaseInsensitiveContains(filterText) }
            }

        let folderFiltered = selectedFolder == nil
            ? filtered
            : filtered.filter { $0.folder == selectedFolder }

        return folderFiltered.sorted {
            if $0.isPinned == $1.isPinned {
                return ($0.date ?? Date()) > ($1.date ?? Date())
            }
            return $0.isPinned && !$1.isPinned
        }
    }

    private var pinnedEntries: [JournalEntry] {
        filteredAndSortedEntries.filter { $0.isPinned }
    }

    private var unpinnedEntries: [JournalEntry] {
        filteredAndSortedEntries.filter { !$0.isPinned }
    }

    private func delete(entries offsets: IndexSet, from source: [JournalEntry]) {
        for index in offsets {
            let entry = source[index]
            viewContext.delete(entry)
        }
        saveContext()
    }

    private func togglePin(for entry: JournalEntry) {
        entry.isPinned.toggle()
        saveContext()
    }

    private func deleteEntries(offsets: IndexSet) {
        for index in offsets {
            let entry = filteredAndSortedEntries[index]
            viewContext.delete(entry)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save Core Data: \(error.localizedDescription)")
        }
    }

    private func icon(for item: SidebarItem) -> String {
        switch item {
        case .journal: return "book"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}
