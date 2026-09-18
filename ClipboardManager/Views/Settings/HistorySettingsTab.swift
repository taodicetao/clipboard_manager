import SwiftUI

struct HistorySettingsTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(PasteboardService.self) private var service

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Storage") {
                Picker("Keep up to", selection: $settings.maxItems) {
                    ForEach(AppSettings.maxItemsOptions, id: \.self) { count in
                        Text("\(count) items")
                    }
                }
                Toggle("Keep history across restarts", isOn: $settings.persistHistory)
                Toggle("Capture images", isOn: $settings.captureImages)
            }
            Section("Notifications") {
                Toggle("Notify when a new item is captured", isOn: $settings.showNotifications)
            }
            Section {
                LabeledContent(itemCountLabel) {
                    Button("Clear History…", role: .destructive) {
                        ClearHistoryPrompt.present(service: service)
                    }
                    .disabled(service.clipboardItems.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var itemCountLabel: String {
        let count = service.clipboardItems.count
        return count == 1 ? "1 item in history" : "\(count) items in history"
    }
}
