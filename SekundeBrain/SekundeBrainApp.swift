//
//  SekundeBrainApp.swift
//  SekundeBrain
//
//  Created by Jaithra on 27/02/25.
//

import SwiftUI

@main
struct JournalingApp: App {
    @AppStorage("appTheme") private var appTheme: String = AppTheme.dark.rawValue
    @StateObject private var themeManager = ThemeManager()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            JournalListView()
                .environmentObject(themeManager)
                .environment(\.managedObjectContext, persistenceController.context)
                .accentColor(Color("AccentColor"))
            
                .preferredColorScheme(
                    appTheme == "light" ? .light :
                    appTheme == "dark" ? .dark : nil
                )
        }
    }
}



