import SwiftUI
import AVKit

struct MediaView: View {
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var mediaManager: MediaManager
    @State private var selectedFilter: MediaFilter = .all
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var selectedMedia: MediaItem?
    @State private var showingMediaDetail = false
    @State private var capturedImage: UIImage?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 过滤器
                FilterBar(selectedFilter: $selectedFilter)
                
                // 媒体网格
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(filteredMedia) { media in
                            MediaThumbnail(media: media) {
                                selectedMedia = media
                                showingMediaDetail = true
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Photos & Videos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Menu("選項", systemImage: "camera.circle.fill") {
                    Button(action: {
                        showingCamera = true
                    }) {
                        Label("拍照", systemImage: "camera")
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Label("從相簿選擇", systemImage: "photo.on.rectangle")
                    }
                }
                .font(.title2)
                .foregroundColor(.blue)
            )
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $capturedImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .sheet(isPresented: $showingMediaDetail) {
            if let media = selectedMedia {
                MediaDetailView(media: media)
            }
        }
        .onAppear {
            if let baby = babyManager.selectedBaby {
                mediaManager.loadMediaItems(for: baby.id)
            }
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if let image = newValue, let baby = babyManager.selectedBaby {
                _ = mediaManager.savePhoto(image, for: baby.id)
                // 清空图片以准备下次拍摄
                capturedImage = nil
            }
        }
    }
    
    private var filteredMedia: [MediaItem] {
        guard let baby = babyManager.selectedBaby else { return [] }
        
        let babyMedia = mediaManager.mediaItems.filter { $0.babyId == baby.id }
        
        switch selectedFilter {
        case .all:
            return babyMedia
        case .photos:
            return babyMedia.filter { $0.type == .photo }
        case .videos:
            return babyMedia.filter { $0.type == .video }
        case .analyzed:
            return babyMedia.filter { $0.isAnalyzed }
        case .milestones:
            return babyMedia.filter { $0.tags.contains("milestone") }
        case .favorites:
            return babyMedia.filter { $0.isFavorite }
        }
    }
}

// MARK: - 媒体过滤器
enum MediaFilter: String, CaseIterable {
    case all = "All"
    case photos = "Photos"
    case videos = "Videos"
    case analyzed = "Analyzed"
    case milestones = "Milestones"
    case favorites = "Favorites"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .photos: return "照片"
        case .videos: return "影片"
        case .analyzed: return "已分析"
        case .milestones: return "里程碑"
        case .favorites: return "收藏"
        }
    }
}

// MARK: - 过滤器栏
struct FilterBar: View {
    @Binding var selectedFilter: MediaFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MediaFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedFilter == filter ?
                                Color.blue.opacity(0.2) :
                                Color(.systemGray6)
                            )
                            .foregroundColor(
                                selectedFilter == filter ?
                                .blue : .primary
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - 媒体缩略图
struct MediaThumbnail: View {
    let media: MediaItem
    let action: () -> Void
    @EnvironmentObject var mediaManager: MediaManager
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 缩略图
                if let image = mediaManager.getMediaImage(media) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width / 3 - 4, height: UIScreen.main.bounds.width / 3 - 4)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: UIScreen.main.bounds.width / 3 - 4, height: UIScreen.main.bounds.width / 3 - 4)
                        .overlay(
                            Image(systemName: media.type == .photo ? "photo" : "video")
                                .foregroundColor(.gray)
                        )
                }
                
                // 视频标识
                if media.type == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                if let duration = media.duration {
                                    Text(formatDuration(duration))
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(4)
                        }
                    }
                }
                
                // 收藏标识
                if media.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
                
                // 分析状态
                if media.isAnalyzed {
                    VStack {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 媒体详情视图
struct MediaDetailView: View {
    let media: MediaItem
    @EnvironmentObject var mediaManager: MediaManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingAnalysis = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 媒体显示
                    if media.type == .photo {
                        if let image = mediaManager.getMediaImage(media) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        }
                    } else {
                        VideoPlayer(player: AVPlayer(url: URL(fileURLWithPath: media.filePath)))
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                    
                    // 媒体信息
                    MediaInfoCard(media: media)
                    
                    // 分析结果
                    if media.isAnalyzed && !media.analysisResults.isEmpty {
                        AnalysisResultsCard(results: media.analysisResults)
                    }
                    
                    // 操作按钮
                    ActionButtonsCard(media: media) {
                        showingAnalysis = true
                    }
                }
                .padding(16)
            }
            .navigationTitle("媒體詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            mediaManager.toggleFavorite(for: media)
                        }) {
                            Label(
                                media.isFavorite ? "取消收藏" : "加入收藏",
                                systemImage: media.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                        
                        Button(action: {
                            // 分享功能
                        }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("刪除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("刪除媒體", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                mediaManager.deleteMediaItem(media)
                dismiss()
            }
        } message: {
            Text("確定要刪除這個媒體文件嗎？此操作無法撤銷。")
        }
        .sheet(isPresented: $showingAnalysis) {
            AIAnalysisView(media: media)
        }
    }
}

// MARK: - 媒体信息卡片
struct MediaInfoCard: View {
    let media: MediaItem
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("媒體信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(title: "類型", value: media.type.displayName)
                InfoRow(title: "創建時間", value: settingsManager.getFormattedDate(media.createdAt))
                InfoRow(title: "文件大小", value: formatFileSize(media.fileSize))
                
                if let duration = media.duration {
                    InfoRow(title: "時長", value: formatDuration(duration))
                }
                
                if let description = media.description {
                    InfoRow(title: "描述", value: description)
                }
                
                if !media.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("標籤")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(media.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - 分析结果卡片
struct AnalysisResultsCard: View {
    let results: [AnalysisResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 分析結果")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(results) { result in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(result.analysisType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", result.confidence * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(result.result)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !result.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("建議:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            ForEach(result.recommendations, id: \.self) { recommendation in
                                Text("• \(recommendation)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 操作按钮卡片
struct ActionButtonsCard: View {
    let media: MediaItem
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if !media.isAnalyzed {
                Button(action: onAnalyze) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("AI 分析")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    // 编辑功能
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("編輯")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // 导出功能
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("導出")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - AI分析视图
struct AIAnalysisView: View {
    let media: MediaItem
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("AI 正在分析中...")
                            .font(.headline)
                        
                        Text("這可能需要幾秒鐘時間")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !analysisResult.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("分析結果")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(analysisResult)
                                .font(.subheadline)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("AI 媒體分析")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("使用人工智能分析這個媒體文件，獲得關於寶寶發展的洞察")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("開始分析") {
                            startAnalysis()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("AI 分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startAnalysis() {
        isAnalyzing = true
        
        // 模拟AI分析过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isAnalyzing = false
            analysisResult = "分析完成！這張照片顯示寶寶正在進行精細動作發展，表情愉快，發展狀況良好。建議繼續提供豐富的感官刺激和互動機會。"
        }
    }
}





#Preview {
    MediaView()
        .environmentObject(BabyManager())
        .environmentObject(MediaManager())
} 