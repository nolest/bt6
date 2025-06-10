import SwiftUI

struct GAIAnalysisView: View {
    @EnvironmentObject var gaiManager: GAIAnalysisManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var selectedMediaItem: MediaItem?
    @State private var analysisInProgress = false
    @State private var showingAnalysisResults = false
    @State private var showingImagePicker = false
    @State private var showingCameraView = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                if let selectedMediaItem = selectedMediaItem {
                    MediaAnalysisView(mediaItem: selectedMediaItem)
                } else {
                    MediaSelectionView()
                }
            }
            .navigationTitle("智能分析")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("從相機拍照") {
                            showingCameraView = true
                        }
                        Button("從相冊選擇") {
                            showingImagePicker = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .sheet(isPresented: $showingCameraView) {
            CameraView(image: $capturedImage)
        }
        .sheet(isPresented: $showingAnalysisResults) {
            if let selectedMediaItem = selectedMediaItem {
                AnalysisResultsView(mediaItemId: selectedMediaItem.id.uuidString)
            }
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if let image = newValue {
                // 保存照片并准备分析
                handleCapturedImage(image)
            }
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // 保存图片到媒体库，然后设置为选中项目
        // 这里需要实现保存逻辑
        capturedImage = nil
    }
}

struct MediaSelectionView: View {
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 20) {
            if !settingsManager.settings.ai.analysisEnabled {
                ContentUnavailableView {
                    Label("智能分析已禁用", systemImage: "brain.head.profile")
                } description: {
                    Text("請在設置中啟用雲端智能分析功能")
                } actions: {
                    Button("前往設置") {
                        // 导航到设置页面
                    }
                }
            } else if mediaManager.mediaItems.isEmpty {
                ContentUnavailableView {
                    Label("沒有媒體文件", systemImage: "photo.on.rectangle")
                } description: {
                    Text("請先拍攝或添加照片和影片")
                } actions: {
                    Button("添加媒體") {
                        // 打开相机或图片选择器
                    }
                }
            } else {
                MediaGridView()
            }
        }
        .padding()
    }
}

struct MediaGridView: View {
    @EnvironmentObject var mediaManager: MediaManager
    @State private var selectedMediaItem: MediaItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mediaManager.mediaItems) { mediaItem in
                    MediaThumbnailView(mediaItem: mediaItem) {
                        selectedMediaItem = mediaItem
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: .constant(selectedMediaItem != nil)) {
            if let mediaItem = selectedMediaItem {
                MediaAnalysisView(mediaItem: mediaItem)
            }
        }
    }
}

struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(fileURLWithPath: mediaItem.thumbnailPath ?? mediaItem.filePath)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: mediaItem.type == MediaType.photo ? "photo" : "video")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MediaAnalysisView: View {
    let mediaItem: MediaItem
    @EnvironmentObject var gaiManager: GAIAnalysisManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var analysisInProgress = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 媒体预览
                    AsyncImage(url: URL(fileURLWithPath: mediaItem.thumbnailPath ?? mediaItem.filePath)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 200)
                    }
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    
                    // 分析按钮
                    VStack(spacing: 12) {
                        if analysisInProgress {
                            ProgressView("分析中...")
                                .frame(maxWidth: .infinity)
                        } else {
                            Button("開始智能分析") {
                                startAnalysis()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canAnalyze)
                        }
                        
                        Button("查看歷史分析結果") {
                            showingResults = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .navigationTitle("媒體分析")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingResults) {
            AnalysisResultsView(mediaItemId: mediaItem.id.uuidString)
        }
    }
    
    private var canAnalyze: Bool {
        settingsManager.settings.ai.analysisEnabled &&
        !analysisInProgress
    }
    
    private func startAnalysis() {
        analysisInProgress = true
        
        Task {
            do {
                _ = try await gaiManager.requestAnalysis(
                    mediaItemId: mediaItem.id.uuidString,
                    analysisType: GAIAnalysisType.development
                )
                
                await MainActor.run {
                    analysisInProgress = false
                    showingResults = true
                }
            } catch {
                await MainActor.run {
                    analysisInProgress = false
                }
            }
        }
    }
}

struct AnalysisResultsView: View {
    let mediaItemId: String
    @EnvironmentObject var gaiManager: GAIAnalysisManager
    @Environment(\.dismiss) private var dismiss
    @State private var results: [AnalysisResult] = []
    
    var body: some View {
        NavigationView {
            Group {
                if results.isEmpty {
                    ContentUnavailableView {
                        Label("沒有分析結果", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text("此媒體文件還沒有分析結果")
                    }
                } else {
                    List(results) { result in
                        AnalysisResultRow(result: result)
                    }
                }
            }
            .navigationTitle("分析結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadResults()
        }
    }
    
    private func loadResults() {
        if let uuid = UUID(uuidString: mediaItemId) {
            results = gaiManager.getAnalysisResults(for: uuid)
        }
    }
}

struct AnalysisResultRow: View {
    let result: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.analysisType.displayName)
                    .font(.headline)
                Spacer()
                Text(result.analyzedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.result)
                .font(.body)
            
            HStack {
                Label("信心度", systemImage: "gauge")
                    .font(.caption)
                ProgressView(value: result.confidence)
                    .frame(width: 100)
                Text("\(Int(result.confidence * 100))%")
                    .font(.caption)
            }
            
            if !result.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("建議:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(result.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

#Preview {
    GAIAnalysisView()
        .environmentObject(GAIAnalysisManager())
        .environmentObject(MediaManager())
        .environmentObject(SettingsManager())
} 