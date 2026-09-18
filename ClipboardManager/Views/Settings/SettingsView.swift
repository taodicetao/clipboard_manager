import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            HistorySettingsTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            PrivacySettingsTab()
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .frame(width: 520, height: 420)
    }
}
