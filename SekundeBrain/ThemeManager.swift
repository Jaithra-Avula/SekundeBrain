import SwiftUI

class ThemeManager: ObservableObject {
    @Published var accentColor: Color = Color(red: 113/255, green: 147/255, blue: 255/255)

    init() {
        loadAccentColor()
    }

    func loadAccentColor() {
        let red = UserDefaults.standard.double(forKey: "accentColorRed")
        let green = UserDefaults.standard.double(forKey: "accentColorGreen")
        let blue = UserDefaults.standard.double(forKey: "accentColorBlue")
        accentColor = Color(red: red, green: green, blue: blue)
    }

    func updateAccentColor(red: Double, green: Double, blue: Double) {
        UserDefaults.standard.set(red, forKey: "accentColorRed")
        UserDefaults.standard.set(green, forKey: "accentColorGreen")
        UserDefaults.standard.set(blue, forKey: "accentColorBlue")
        accentColor = Color(red: red, green: green, blue: blue)
    }
}
