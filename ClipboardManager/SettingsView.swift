// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = ClipboardSettings()
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AdvancedSettingsView(settings: settings)
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 350)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: ClipboardSettings
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("จำนวนรายการสูงสุด:")
                            .frame(width: 150, alignment: .leading)
                        
                        Picker("", selection: $settings.maxItems) {
                            Text("25 รายการ").tag(25)
                            Text("50 รายการ").tag(50)
                            Text("100 รายการ").tag(100)
                            Text("200 รายการ").tag(200)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        .onChange(of: settings.maxItems) { _, _ in
                            NotificationCenter.default.post(name: .settingsChanged, object: nil)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("ความถี่ในการเช็ค:")
                            .frame(width: 150, alignment: .leading)
                        
                        Picker("", selection: $settings.pollingInterval) {
                            Text("0.1 วินาที").tag(0.1)
                            Text("0.5 วินาที").tag(0.5)
                            Text("1 วินาที").tag(1.0)
                            Text("2 วินาที").tag(2.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        .onChange(of: settings.pollingInterval) { _, _ in
                            NotificationCenter.default.post(name: .settingsChanged, object: nil)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("แสดงรูปภาพใน clipboard", isOn: $settings.showImages)
                        Toggle("แสดงการแจ้งเตือน", isOn: $settings.showNotifications)
                    }
                }
                .padding()
            }
        }
        .formStyle(.grouped)
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var settings: ClipboardSettings
    @State private var showingClearAlert = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Toggle("เปิดโปรแกรมอัตโนมัติเมื่อเปิดเครื่อง", isOn: $settings.autoStart)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("จัดการข้อมูล")
                            .font(.headline)
                        
                        Button("ล้างประวัติ clipboard ทั้งหมด") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                        
                        Button("รีเซ็ตการตั้งค่าเป็นค่าเริ่มต้น") {
                            settings.resetToDefaults()
                        }
                        .foregroundColor(.orange)
                    }
                }
                .padding()
            }
        }
        .formStyle(.grouped)
        .alert("ยืนยันการลบ", isPresented: $showingClearAlert) {
            Button("ยกเลิก", role: .cancel) { }
            Button("ลบทั้งหมด", role: .destructive) {
                NotificationCenter.default.post(name: .clearAllClipboard, object: nil)
            }
        } message: {
            Text("คุณแน่ใจหรือไม่ที่จะลบประวัติ clipboard ทั้งหมด?")
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("Clipboard Manager")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("จัดการ clipboard history บน macOS อย่างง่ายดาย")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("© 2024 Made with ❤️ in Thailand")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
