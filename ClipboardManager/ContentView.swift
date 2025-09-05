// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var pasteboardService = PasteboardService.shared // ใช้ shared
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return pasteboardService.clipboardItems
        }
        return pasteboardService.clipboardItems.filter {
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("ค้นหา...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Clipboard Items List
            if filteredItems.isEmpty {
                VStack {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("ยังไม่มี clipboard history")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("copy อะไรสักอย่างเพื่อเริ่มต้น")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(filteredItems) { item in
                        ClipboardItemRow(item: item, pasteboardService: pasteboardService)
                            .id(item.id)
                    }
                    .listStyle(PlainListStyle())
                    .onChange(of: pasteboardService.clipboardItems) { oldItems, newItems in
                        // Auto-scroll to top เมื่อมี item ใหม่
                        if !newItems.isEmpty {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newItems.first!.id, anchor: .top)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to top เมื่อเปิดแอปครั้งแรก
                        if let firstItem = pasteboardService.clipboardItems.first {
                            proxy.scrollTo(firstItem.id, anchor: .top)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                Text("\(filteredItems.count) รายการ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    pasteboardService.clearAll()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}
