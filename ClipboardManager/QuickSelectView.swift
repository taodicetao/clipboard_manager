import SwiftUI

struct QuickSelectView: View {
    @ObservedObject var state: QuickSelectState
    let onItemSelected: (ClipboardItem) -> Void
    let onCancel: () -> Void
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar with Close Button
            HStack {
                // Close button ทางซ้าย
                Button(action: {
                    print("🔴 Close button tapped")
                    onCancel()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Title และ Icon อยู่ตรงกลาง
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(.primary)
                    
                    Text("Quick Paste")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Placeholder สำหรับความสมดุล
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.controlBackgroundColor),
                        Color(.controlBackgroundColor).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.separatorColor))
                    .opacity(0.5),
                alignment: .bottom
            )
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                
                TextField("Search clipboard...", text: $state.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .focused($isSearchFocused)
                    .onSubmit {
                        print("🔍 Search submitted")
                        state.selectCurrent(onItemSelected: onItemSelected)
                    }
                
                // Clear search button
                if !state.searchText.isEmpty {
                    Button(action: {
                        state.searchText = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Items list - ใช้ state.filteredItems ที่ reactive
            if state.filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("No items found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !state.searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Copy something to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(state.filteredItems.enumerated()), id: \.element.id) { index, item in
                                QuickSelectItemRow(
                                    item: item,
                                    isSelected: index == state.selectedIndex,
                                    index: index + 1
                                )
                                .onTapGesture {
                                    print("🖱️ Item \(index) tapped: \(item.content.prefix(30))")
                                    state.selectedIndex = index
                                    onItemSelected(item)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(index == state.selectedIndex ?
                                              Color.accentColor.opacity(0.15) :
                                              Color.clear)
                                        .padding(.horizontal, 8)
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: state.selectedIndex) { oldIndex, newIndex in
                        if newIndex >= 0 && newIndex < state.filteredItems.count {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(state.filteredItems[newIndex].id, anchor: .center)
                            }
                        }
                    }
                    // **เพิ่ม: Auto-scroll เมื่อมี items ใหม่**
                    .onChange(of: state.clipboardItems.count) { oldCount, newCount in
                        if newCount > oldCount && !state.filteredItems.isEmpty {
                            // มี item ใหม่ -> scroll ไปที่ item แรก
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(state.filteredItems.first!.id, anchor: .top)
                                }
                            }
                            
                            // Reset selection ไปที่ item ใหม่
                            state.selectedIndex = 0
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                HStack(spacing: 8) {
                    Label("↑↓", systemImage: "arrow.up.arrow.down")
                        .font(.caption2)
                        .labelStyle(.iconOnly)
                    Text("navigate")
                        .font(.caption2)
                    
                    Label("↵", systemImage: "return")
                        .font(.caption2)
                        .labelStyle(.iconOnly)
                    Text("paste")
                        .font(.caption2)
                    
                    Label("esc", systemImage: "escape")
                        .font(.caption2)
                        .labelStyle(.iconOnly)
                    Text("cancel")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(state.filteredItems.count) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 400)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            print("📱 QuickSelectView appeared with \(state.clipboardItems.count) items")
            state.selectedIndex = 0
            isSearchFocused = false
        }
        .onChange(of: state.searchText) { _, _ in
            // Reset selection when search changes
            state.selectedIndex = 0
        }
        .onChange(of: state.filteredItems.count) { _, newCount in
            // Ensure selectedIndex is within bounds
            if state.selectedIndex >= newCount && newCount > 0 {
                state.selectedIndex = newCount - 1
            } else if newCount == 0 {
                state.selectedIndex = 0
            }
        }
    }
}

// QuickSelectItemRow เหมือนเดิม...
struct QuickSelectItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption.monospacedDigit())
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 24, alignment: .trailing)
                .fontWeight(isSelected ? .medium : .regular)
            
            Group {
                if item.type == .image, let nsImage = item.image {
                    // แสดง preview รูปจริง
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    // แสดง icon ปกติสำหรับ text และ file
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(item.type.color)
                        .frame(width: 32, height: 32)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if item.type == .image {
                    // แสดงข้อมูลรูป
                    if let nsImage = item.image {
                        let size = nsImage.size
                        Text("Image (\(Int(size.width))×\(Int(size.height)))")
                            .lineLimit(1)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .fontWeight(isSelected ? .medium : .regular)
                    } else {
                        Text(item.content)
                            .lineLimit(2)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .fontWeight(isSelected ? .medium : .regular)
                    }
                } else {
                    // แสดงเนื้อหาปกติสำหรับ text และ file
                    Text(item.content)
                        .lineLimit(2)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .fontWeight(isSelected ? .medium : .regular)
                }
                
                HStack {
                    Text(item.type.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.type.color.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// Extensions เหมือนเดิม...
extension ClipboardItemType {
    var iconName: String {
        switch self {
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        case .file: return "folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .image: return .green
        case .file: return .orange
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .file: return "File"
        }
    }
}
