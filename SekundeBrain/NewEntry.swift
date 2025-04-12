import SwiftUI
import Foundation
import PhotosUI

struct NewEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var tagsText: String = ""
    @State private var isPinned = false

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var selectedFolder: JournalFolder? = nil
    @State private var newFolderName: String = "" // Store the new folder name
    @State private var showingFolderSheet: Bool = false // Toggle to show folder creation sheet

    @FetchRequest(
        entity: JournalFolder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalFolder.createdAt, ascending: true)]
    ) var folders: FetchedResults<JournalFolder>

    var entryToEdit: JournalEntry? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Entry title", text: $title)
                }

                Section(header: Text("Content")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }

                Section(header: Text("Tags / Moods")) {
                    TextField("Enter tags (comma separated)", text: $tagsText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Folder")) {
                    Picker("Select Folder", selection: $selectedFolder) {
                        ForEach(folders, id: \.self) { folder in
                            Text(folder.name ?? "Untitled").tag(folder as JournalFolder?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button("Create New Folder") {
                        showingFolderSheet.toggle()
                    }
                    .sheet(isPresented: $showingFolderSheet) {
                        VStack {
                            TextField("New Folder Name", text: $newFolderName)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Save Folder") {
                                saveNewFolder()
                            }
                            .padding()
                            .disabled(newFolderName.isEmpty)
                        }
                        .padding()
                    }
                }

                Section(header: Text("Image")) {
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                    }

                    PhotosPicker("Select Image", selection: $selectedPhoto, matching: .images)
                        .onChange(of: selectedPhoto) { newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                }
            }
            .navigationTitle(entryToEdit == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if let entry = entryToEdit {
                    title = entry.title ?? ""
                    content = entry.content ?? ""
                    if let tags = entry.tags as? [String] {
                        tagsText = tags.joined(separator: ", ")
                    }
                    selectedFolder = entry.folder
                }
            }
        }
    }

    private func saveEntry() {
        let entry = entryToEdit ?? JournalEntry(context: viewContext)
        entry.title = title
        entry.content = content
        entry.date = Date()
        entry.imageData = selectedImageData
        entry.folder = selectedFolder

        let trimmedTags = tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        entry.setValue(trimmedTags, forKey: "tags")

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save entry: \(error.localizedDescription)")
        }
    }

    private func saveNewFolder() {
        let newFolder = JournalFolder(context: viewContext)
        newFolder.name = newFolderName
        newFolder.createdAt = Date()

        do {
            try viewContext.save()
            showingFolderSheet = false
            newFolderName = "" // Clear the folder name after saving
        } catch {
            print("Failed to save new folder: \(error.localizedDescription)")
        }
    }
}
