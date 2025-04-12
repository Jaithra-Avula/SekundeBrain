import SwiftUI

enum ColorblindType: String, CaseIterable, Identifiable {
    case none = "None"
    case protanopia = "Protanopia"
    case deuteranopia = "Deuteranopia"
    case tritanopia = "Tritanopia"
    case achromatopsia = "Achromatopsia"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .none:
            return Color(red: 113/255, green: 147/255, blue: 255/255)
        case .protanopia:
            return Color(red: 0.0, green: 0.6, blue: 0.6)
        case .deuteranopia:
            return Color(red: 0.8, green: 0.5, blue: 0.0)
        case .tritanopia:
            return Color(red: 0.7, green: 0.5, blue: 0.0)
        case .achromatopsia:
            return Color(white: 0.5)
        }
    }

    var description: String {
        switch self {
        case .none:
            return "No colorblind filter is applied."
        case .protanopia:
            return "Red-blind: Reduced sensitivity to red light."
        case .deuteranopia:
            return "Green-blind: Difficulty distinguishing greens."
        case .tritanopia:
            return "Blue-blind: Difficulty distinguishing blues and yellows."
        case .achromatopsia:
            return "Total color blindness: Sees mostly in shades of gray."
        }
    }

    var paletteBefore: [Color] {
        [Color.red, Color.green, Color.blue, Color.yellow, Color.purple]
    }

    var paletteAfter: [Color] {
        switch self {
        case .none:
            return paletteBefore
        case .protanopia:
            return [.cyan, .green, .blue, .yellow, .gray]
        case .deuteranopia:
            return [.orange, .yellow, .blue, .green, .gray]
        case .tritanopia:
            return [.green, .orange, .blue, .yellow, .gray]
        case .achromatopsia:
            return Array(repeating: .gray, count: 5)
        }
    }
}

struct SettingsView: View {
    @AppStorage("accentColorRed") private var accentColorRed: Double = 113 / 255
    @AppStorage("accentColorGreen") private var accentColorGreen: Double = 147 / 255
    @AppStorage("accentColorBlue") private var accentColorBlue: Double = 255 / 255
    @AppStorage("appTheme") private var appTheme: String = AppTheme.dark.rawValue
    @AppStorage("colorblindType") private var colorblindTypeRaw: String = ColorblindType.none.rawValue
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    
    @State private var profilePicture: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var newFolderName: String = ""
    @State private var isEditingFolder: Bool = false
    @State private var editingFolderId: UUID?
    
    private var colorblindType: ColorblindType {
        ColorblindType(rawValue: colorblindTypeRaw) ?? .none
    }
    
    private var selectedColor: Color {
        if colorblindType != .none {
            return colorblindType.color
        }
        return Color(red: accentColorRed, green: accentColorGreen, blue: accentColorBlue)
    }

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme.rawValue)
                    }
                }
                .disabled(colorblindType != .none)
                
                Slider(value: $fontSize, in: 10...30, step: 1) {
                    Text("Font Size")
                }
                .onChange(of: fontSize) { newValue in
                    // Update font size dynamically
                }
                .padding()
                
                Text("Font Size: \(Int(fontSize))")
                    .font(.subheadline)
            }
            
            Section(header: Text("Accessibility")) {
                Picker("Colorblind Mode", selection: $colorblindTypeRaw) {
                    ForEach(ColorblindType.allCases) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }
                .onChange(of: colorblindTypeRaw) { newValue in
                    if let type = ColorblindType(rawValue: newValue), type != .none {
                        let uiColor = UIColor(type.color)
                        if let components = uiColor.cgColor.components, components.count >= 3 {
                            accentColorRed = components[0]
                            accentColorGreen = components[1]
                            accentColorBlue = components[2]
                        }
                    }
                }
                
                if colorblindType != .none {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(spacing: 4) {
                            Text("Original Palette")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            HStack(spacing: 8) {
                                ForEach(colorblindType.paletteBefore.indices, id: \.self) { index in
                                    Rectangle()
                                        .fill(colorblindType.paletteBefore[index])
                                        .frame(width: 24, height: 24)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("Adjusted Palette")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            HStack(spacing: 8) {
                                ForEach(colorblindType.paletteAfter.indices, id: \.self) { index in
                                    Rectangle()
                                        .fill(colorblindType.paletteAfter[index])
                                        .frame(width: 24, height: 24)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        Text(colorblindType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.top, 8)
                }
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
            }
            
            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("German").tag("German")
                }
            }

            Section(header: Text("Profile")) {
                Button("Change Profile Picture") {
                    showingImagePicker.toggle()
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $profilePicture)
                }

                if let profileImage = profilePicture {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.top, 10)
                }
            }

            Section(header: Text("App Settings")) {
                Text("App Version: 1.0.0")
                Button("Check for Updates") {
                    // Handle update check logic here
                }
            }

            Section(header: Text("Backup & Restore")) {
                Button("Backup Data to iCloud") {
                    // Backup logic to iCloud or local storage
                }
                Button("Restore Data from Backup") {
                    // Restore logic from iCloud or local storage
                }
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Allow Location Access", isOn: .constant(true)) // Placeholder for location permission
                Toggle("Allow Camera Access", isOn: .constant(true)) // Placeholder for camera permission
            }
        }
        .navigationTitle("Settings")
        .tint(selectedColor)
    }
}

struct ImagePicker: View {
    @Binding var image: UIImage?
    
    var body: some View {
        // Replace with your ImagePicker implementation
        Text("Image Picker")
    }
}
