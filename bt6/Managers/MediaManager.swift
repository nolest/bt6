import Foundation
import SwiftUI
import AVFoundation
import Photos

class MediaManager: ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResults: [UUID: [AnalysisResult]] = [:]
    
    private let fileManager = FileManager.default
    private var mediaDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("Media")
    }
    
    init() {
        createMediaDirectories()
        loadMediaItems()
    }
    
    // MARK: - 创建媒体目录
    private func createMediaDirectories() {
        let photosDir = mediaDirectory.appendingPathComponent("Photos")
        let videosDir = mediaDirectory.appendingPathComponent("Videos")
        let thumbnailsDir = mediaDirectory.appendingPathComponent("Thumbnails")
        
        for directory in [mediaDirectory, photosDir, videosDir, thumbnailsDir] {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - 加载媒体项目
    func loadMediaItems(for babyId: UUID? = nil) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .background).async {
            do {
                let photosDir = self.mediaDirectory.appendingPathComponent("Photos")
                let videosDir = self.mediaDirectory.appendingPathComponent("Videos")
                
                var items: [MediaItem] = []
                
                // 加载照片
                if self.fileManager.fileExists(atPath: photosDir.path) {
                    let photoFiles = try self.fileManager.contentsOfDirectory(at: photosDir, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
                    
                    for file in photoFiles {
                        if let mediaItem = self.createMediaItem(from: file, type: .photo) {
                            if babyId == nil || mediaItem.babyId == babyId {
                                items.append(mediaItem)
                            }
                        }
                    }
                }
                
                // 加载视频
                if self.fileManager.fileExists(atPath: videosDir.path) {
                    let videoFiles = try self.fileManager.contentsOfDirectory(at: videosDir, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
                    
                    for file in videoFiles {
                        if let mediaItem = self.createMediaItem(from: file, type: .video) {
                            if babyId == nil || mediaItem.babyId == babyId {
                                items.append(mediaItem)
                            }
                        }
                    }
                }
                
                // 按创建时间排序
                items.sort { $0.createdAt > $1.createdAt }
                
                DispatchQueue.main.async {
                    self.mediaItems = items
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "加載媒體文件失敗: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - 创建媒体项目
    private func createMediaItem(from url: URL, type: MediaType) -> MediaItem? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            
            // 从文件名解析宝宝ID（假设文件名格式为：babyId_timestamp.ext）
            let fileName = url.lastPathComponent
            let components = fileName.components(separatedBy: "_")
            guard components.count >= 2,
                  let babyId = UUID(uuidString: components[0]) else {
                return nil
            }
            
            var duration: TimeInterval?
            if type == .video {
                let asset = AVURLAsset(url: url)
                duration = CMTimeGetSeconds(asset.duration)
            }
            
            return MediaItem(
                babyId: babyId,
                type: type,
                fileName: fileName,
                filePath: url.path,
                thumbnailPath: generateThumbnailPath(for: fileName),
                fileSize: fileSize,
                duration: duration,
                createdAt: creationDate
            )
            
        } catch {
            print("Error creating media item: \(error)")
            return nil
        }
    }
    
    // MARK: - 保存照片
    func savePhoto(_ image: UIImage, for babyId: UUID, description: String? = nil) -> MediaItem? {
        let fileName = "\(babyId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let photosDir = mediaDirectory.appendingPathComponent("Photos")
        let filePath = photosDir.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "圖片壓縮失敗"
            return nil
        }
        
        do {
            try imageData.write(to: filePath)
            
            // 生成缩略图
            generateThumbnail(for: image, fileName: fileName)
            
            let mediaItem = MediaItem(
                babyId: babyId,
                type: .photo,
                fileName: fileName,
                filePath: filePath.path,
                thumbnailPath: generateThumbnailPath(for: fileName),
                fileSize: Int64(imageData.count),
                createdAt: Date(),
                description: description
            )
            
            mediaItems.insert(mediaItem, at: 0)
            return mediaItem
            
        } catch {
            errorMessage = "保存照片失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - 保存视频
    func saveVideo(from url: URL, for babyId: UUID, description: String? = nil) -> MediaItem? {
        let fileName = "\(babyId.uuidString)_\(Int(Date().timeIntervalSince1970)).mov"
        let videosDir = mediaDirectory.appendingPathComponent("Videos")
        let filePath = videosDir.appendingPathComponent(fileName)
        
        do {
            try fileManager.copyItem(at: url, to: filePath)
            
            let asset = AVURLAsset(url: filePath)
            let duration = CMTimeGetSeconds(asset.duration)
            
            // 生成视频缩略图
            generateVideoThumbnail(for: asset, fileName: fileName)
            
            let attributes = try fileManager.attributesOfItem(atPath: filePath.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            let mediaItem = MediaItem(
                babyId: babyId,
                type: .video,
                fileName: fileName,
                filePath: filePath.path,
                thumbnailPath: generateThumbnailPath(for: fileName),
                fileSize: fileSize,
                duration: duration,
                createdAt: Date(),
                description: description
            )
            
            mediaItems.insert(mediaItem, at: 0)
            return mediaItem
            
        } catch {
            errorMessage = "保存視頻失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - 生成缩略图路径
    private func generateThumbnailPath(for fileName: String) -> String {
        let thumbnailsDir = mediaDirectory.appendingPathComponent("Thumbnails")
        let nameWithoutExtension = (fileName as NSString).deletingPathExtension
        let thumbnailFileName = "\(nameWithoutExtension)_thumb.jpg"
        return thumbnailsDir.appendingPathComponent(thumbnailFileName).path
    }
    
    // MARK: - 生成图片缩略图
    private func generateThumbnail(for image: UIImage, fileName: String) {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.resized(to: thumbnailSize)
        
        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
            let thumbnailPath = generateThumbnailPath(for: fileName)
            try? thumbnailData.write(to: URL(fileURLWithPath: thumbnailPath))
        }
    }
    
    // MARK: - 生成视频缩略图
    private func generateVideoThumbnail(for asset: AVAsset, fileName: String) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            generateThumbnail(for: image, fileName: fileName)
        } catch {
            print("Error generating video thumbnail: \(error)")
        }
    }
    
    // MARK: - 删除媒体项目
    func deleteMediaItem(_ item: MediaItem) {
        do {
            // 删除原文件
            try fileManager.removeItem(atPath: item.filePath)
            
            // 删除缩略图
            if let thumbnailPath = item.thumbnailPath {
                try? fileManager.removeItem(atPath: thumbnailPath)
            }
            
            // 从数组中移除
            mediaItems.removeAll { $0.id == item.id }
            
        } catch {
            errorMessage = "刪除媒體文件失敗: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 更新媒体项目
    func updateMediaItem(_ item: MediaItem) {
        if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
            mediaItems[index] = item
        }
    }
    
    // MARK: - 获取媒体文件
    func getMediaImage(_ item: MediaItem) -> UIImage? {
        if let thumbnailPath = item.thumbnailPath,
           fileManager.fileExists(atPath: thumbnailPath) {
            return UIImage(contentsOfFile: thumbnailPath)
        } else {
            return UIImage(contentsOfFile: item.filePath)
        }
    }
    
    // MARK: - 获取媒体统计
    func getMediaStatistics(for babyId: UUID) -> (photoCount: Int, videoCount: Int, totalSize: Int64) {
        let babyMedia = mediaItems.filter { $0.babyId == babyId }
        
        let photoCount = babyMedia.filter { $0.type == .photo }.count
        let videoCount = babyMedia.filter { $0.type == .video }.count
        let totalSize = babyMedia.reduce(0) { $0 + $1.fileSize }
        
        return (photoCount: photoCount, videoCount: videoCount, totalSize: totalSize)
    }
    
    // MARK: - 搜索媒体
    func searchMedia(query: String, type: MediaType? = nil, babyId: UUID? = nil) -> [MediaItem] {
        var filteredItems = mediaItems
        
        if let babyId = babyId {
            filteredItems = filteredItems.filter { $0.babyId == babyId }
        }
        
        if let type = type {
            filteredItems = filteredItems.filter { $0.type == type }
        }
        
        if !query.isEmpty {
            filteredItems = filteredItems.filter { item in
                item.description?.localizedCaseInsensitiveContains(query) == true ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        return filteredItems
    }
    
    // MARK: - 添加标签
    func addTag(_ tag: String, to item: MediaItem) {
        var updatedItem = item
        if !updatedItem.tags.contains(tag) {
            updatedItem.tags.append(tag)
            updateMediaItem(updatedItem)
        }
    }
    
    // MARK: - 移除标签
    func removeTag(_ tag: String, from item: MediaItem) {
        var updatedItem = item
        updatedItem.tags.removeAll { $0 == tag }
        updateMediaItem(updatedItem)
    }
    
    // MARK: - 切换收藏状态
    func toggleFavorite(for item: MediaItem) {
        var updatedItem = item
        updatedItem.isFavorite.toggle()
        updateMediaItem(updatedItem)
    }
    
    // MARK: - 获取收藏的媒体
    func getFavoriteMedia(for babyId: UUID? = nil) -> [MediaItem] {
        var favorites = mediaItems.filter { $0.isFavorite }
        
        if let babyId = babyId {
            favorites = favorites.filter { $0.babyId == babyId }
        }
        
        return favorites
    }
    
    // MARK: - 清除错误消息
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 