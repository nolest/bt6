import Foundation
import SwiftUI
import Combine

// MARK: - 社群互动管理器
@MainActor
class SocialManager: ObservableObject {
    @Published var isConnected = false
    @Published var currentUser: SocialUser?
    @Published var posts: [SocialPost] = []
    @Published var interactions: [SocialInteraction] = []
    @Published var isPublishing = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private let facebookService = FacebookService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkConnectionStatus()
        loadCachedData()
    }
    
    // MARK: - 连接管理
    
    /// 连接Facebook账户
    func connectFacebook() async throws {
        DispatchQueue.main.async {
            self.connectionStatus = .connecting
        }
        
        do {
            let user = try await facebookService.login()
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isConnected = true
                self.connectionStatus = .connected
            }
            
            // 保存连接状态
            saveConnectionStatus()
            
            // 获取初始数据
            await loadUserPosts()
            
        } catch {
            DispatchQueue.main.async {
                self.connectionStatus = .error(error.localizedDescription)
            }
            throw error
        }
    }
    
    /// 断开连接
    func disconnect() {
        facebookService.logout()
        
        currentUser = nil
        isConnected = false
        connectionStatus = .disconnected
        posts.removeAll()
        interactions.removeAll()
        
        // 清除保存的状态
        UserDefaults.standard.removeObject(forKey: "socialConnectionStatus")
        UserDefaults.standard.removeObject(forKey: "socialUserData")
    }
    
    // MARK: - 内容发布
    
    /// 发布文本内容
    func publishPost(content: String, privacy: PostPrivacy = .friends) async throws -> String {
        guard isConnected else {
            throw SocialError.notConnected
        }
        
        DispatchQueue.main.async {
            self.isPublishing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isPublishing = false
            }
        }
        
        do {
            let postId = try await facebookService.publishPost(
                content: content,
                media: nil,
                privacy: privacy
            )
            
            // 创建本地记录
            let post = SocialPost(
                id: postId,
                content: content,
                mediaUrls: [],
                privacy: privacy,
                publishedAt: Date(),
                platform: .facebook,
                status: .published
            )
            
            DispatchQueue.main.async {
                self.posts.insert(post, at: 0)
            }
            
            // 保存到本地
            savePosts()
            
            return postId
            
        } catch {
            throw SocialError.publishFailed(error.localizedDescription)
        }
    }
    
    /// 发布带媒体的内容
    func publishPostWithMedia(content: String, mediaItems: [MediaItem], privacy: PostPrivacy = .friends) async throws -> String {
        guard isConnected else {
            throw SocialError.notConnected
        }
        
        DispatchQueue.main.async {
            self.isPublishing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isPublishing = false
            }
        }
        
        do {
            // 准备媒体数据
            let mediaData = try await prepareMediaForSharing(mediaItems)
            
            let postId = try await facebookService.publishPost(
                content: content,
                media: mediaData,
                privacy: privacy
            )
            
            // 创建本地记录
            let post = SocialPost(
                id: postId,
                content: content,
                mediaUrls: mediaItems.map { URL(fileURLWithPath: $0.filePath) },
                privacy: privacy,
                publishedAt: Date(),
                platform: .facebook,
                status: .published
            )
            
            DispatchQueue.main.async {
                self.posts.insert(post, at: 0)
            }
            
            savePosts()
            
            return postId
            
        } catch {
            throw SocialError.publishFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 互动管理
    
    /// 获取用户发布的帖子
    func loadUserPosts() async {
        guard isConnected else { return }
        
        do {
            let fetchedPosts = try await facebookService.getUserPosts(limit: 20)
            
            DispatchQueue.main.async {
                self.posts = fetchedPosts
            }
            
            savePosts()
            
        } catch {
            print("Failed to load user posts: \(error)")
        }
    }
    
    /// 获取帖子的互动信息
    func loadPostInteractions(postId: String) async {
        guard isConnected else { return }
        
        do {
            let comments = try await facebookService.getPostComments(postId: postId, limit: 50)
            let likes = try await facebookService.getPostLikes(postId: postId, limit: 50)
            
            let interactions = comments.map { comment in
                SocialInteraction(
                    id: comment.id,
                    postId: postId,
                    type: .comment,
                    content: comment.message,
                    authorName: comment.authorName,
                    createdAt: comment.createdAt
                )
            } + likes.map { like in
                SocialInteraction(
                    id: like.id,
                    postId: postId,
                    type: .like,
                    content: nil,
                    authorName: like.authorName,
                    createdAt: like.createdAt
                )
            }
            
            DispatchQueue.main.async {
                // 更新或添加互动记录
                self.interactions.removeAll { $0.postId == postId }
                self.interactions.append(contentsOf: interactions)
            }
            
            saveInteractions()
            
        } catch {
            print("Failed to load post interactions: \(error)")
        }
    }
    
    /// 回复评论
    func replyToComment(postId: String, commentId: String?, message: String) async throws {
        guard isConnected else {
            throw SocialError.notConnected
        }
        
        let replyId = try await facebookService.replyToComment(
            postId: postId,
            commentId: commentId,
            message: message
        )
        
        // 添加到本地记录
        let interaction = SocialInteraction(
            id: replyId,
            postId: postId,
            type: .comment,
            content: message,
            authorName: currentUser?.name ?? "我",
            createdAt: Date()
        )
        
        DispatchQueue.main.async {
            self.interactions.append(interaction)
        }
        
        saveInteractions()
    }
    
    // MARK: - 专家咨询
    
    /// 获取专家建议
    func getExpertAdvice(question: String) async throws -> ExpertAdvice {
        // 这里可以整合专业育儿专家的API或者社群
        // 目前返回模拟数据
        
        let experts = [
            Expert(id: "1", name: "李醫師", specialty: "兒科", verified: true),
            Expert(id: "2", name: "王護理師", specialty: "新生兒護理", verified: true),
            Expert(id: "3", name: "陳營養師", specialty: "嬰幼兒營養", verified: true)
        ]
        
        let randomExpert = experts.randomElement()!
        
        // 模拟专家回复
        let advice = generateExpertAdvice(for: question, expert: randomExpert)
        
        return advice
    }
    
    /// 预约专家咨询
    func scheduleExpertConsultation(expertId: String, preferredTime: Date, question: String) async throws -> ConsultationBooking {
        // 模拟预约流程
        let booking = ConsultationBooking(
            id: UUID().uuidString,
            expertId: expertId,
            scheduledTime: preferredTime,
            question: question,
            status: .pending,
            createdAt: Date()
        )
        
        return booking
    }
    
    // MARK: - 私有方法
    
    private func checkConnectionStatus() {
        if let userData = UserDefaults.standard.data(forKey: "socialUserData"),
           let user = try? JSONDecoder().decode(SocialUser.self, from: userData) {
            currentUser = user
            isConnected = true
            connectionStatus = .connected
        }
    }
    
    private func saveConnectionStatus() {
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "socialUserData")
            UserDefaults.standard.set(true, forKey: "socialConnectionStatus")
        }
    }
    
    private func loadCachedData() {
        // 加载缓存的帖子
        if let postsData = UserDefaults.standard.data(forKey: "socialPosts"),
           let cachedPosts = try? JSONDecoder().decode([SocialPost].self, from: postsData) {
            posts = cachedPosts
        }
        
        // 加载缓存的互动
        if let interactionsData = UserDefaults.standard.data(forKey: "socialInteractions"),
           let cachedInteractions = try? JSONDecoder().decode([SocialInteraction].self, from: interactionsData) {
            interactions = cachedInteractions
        }
    }
    
    private func savePosts() {
        if let postsData = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(postsData, forKey: "socialPosts")
        }
    }
    
    private func saveInteractions() {
        if let interactionsData = try? JSONEncoder().encode(interactions) {
            UserDefaults.standard.set(interactionsData, forKey: "socialInteractions")
        }
    }
    
    private func prepareMediaForSharing(_ mediaItems: [MediaItem]) async throws -> [ShareableMedia] {
        var shareableMedia: [ShareableMedia] = []
        
        for item in mediaItems {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: item.filePath)) else {
                continue
            }
            
            let shareableItem = ShareableMedia(
                type: item.type == .photo ? .image : .video,
                data: data,
                filename: item.fileName
            )
            
            shareableMedia.append(shareableItem)
        }
        
        return shareableMedia
    }
    
    private func generateExpertAdvice(for question: String, expert: Expert) -> ExpertAdvice {
        // 基于问题关键词生成相应建议
        let lowercaseQuestion = question.lowercased()
        
        var advice = ""
        var category = AdviceCategory.general
        
        if lowercaseQuestion.contains("餵") || lowercaseQuestion.contains("奶") {
            category = .feeding
            advice = "關於餵食問題，建議觀察寶寶的飢餓信號，按需餵養。新生兒通常每2-3小時需要餵奶一次。如果是母乳餵養，確保正確的含乳姿勢很重要。"
        } else if lowercaseQuestion.contains("睡") {
            category = .sleep
            advice = "寶寶的睡眠很重要。建立固定的睡前儀式，保持房間安靜舒適，溫度適宜。新生兒每天需要14-17小時的睡眠。"
        } else if lowercaseQuestion.contains("哭") {
            category = .behavior
            advice = "寶寶哭泣是正常的溝通方式。常見原因包括飢餓、需要換尿布、疲倦、不舒服等。嘗試安撫技巧如輕拍、搖擺或播放白噪音。"
        } else {
            advice = "感謝您的問題。建議您提供更多具體情況，這樣我能給出更準確的建議。如有緊急情況，請立即就醫。"
        }
        
        return ExpertAdvice(
            id: UUID().uuidString,
            question: question,
            advice: advice,
            expert: expert,
            category: category,
            createdAt: Date(),
            isVerified: expert.verified
        )
    }
}

// MARK: - Facebook服务
class FacebookService {
    func login() async throws -> SocialUser {
        // 模拟Facebook登录流程
        // 实际实现需要使用Facebook SDK
        
        // 模拟延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return SocialUser(
            id: "facebook_user_123",
            name: "測試用戶",
            email: "test@example.com",
            profileImageUrl: nil,
            platform: .facebook
        )
    }
    
    func logout() {
        // 实现Facebook登出逻辑
    }
    
    func publishPost(content: String, media: [ShareableMedia]?, privacy: PostPrivacy) async throws -> String {
        // 模拟发布帖子
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 模拟可能的错误
        if content.isEmpty {
            throw SocialError.invalidContent
        }
        
        return "facebook_post_\(UUID().uuidString)"
    }
    
    func getUserPosts(limit: Int) async throws -> [SocialPost] {
        // 模拟获取用户帖子
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            SocialPost(
                id: "post_1",
                content: "寶寶今天第一次翻身了！好開心 😊",
                mediaUrls: [],
                privacy: .friends,
                publishedAt: Date().addingTimeInterval(-86400),
                platform: .facebook,
                status: .published
            ),
            SocialPost(
                id: "post_2",
                content: "分享一下寶寶的可愛睡姿",
                mediaUrls: [],
                privacy: .friends,
                publishedAt: Date().addingTimeInterval(-172800),
                platform: .facebook,
                status: .published
            )
        ]
    }
    
    func getPostComments(postId: String, limit: Int) async throws -> [FacebookComment] {
        // 模拟获取评论
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            FacebookComment(
                id: "comment_1",
                message: "好可愛！恭喜！",
                authorName: "朋友A",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            FacebookComment(
                id: "comment_2",
                message: "寶寶真棒！",
                authorName: "朋友B",
                createdAt: Date().addingTimeInterval(-1800)
            )
        ]
    }
    
    func getPostLikes(postId: String, limit: Int) async throws -> [FacebookLike] {
        // 模拟获取点赞
        try await Task.sleep(nanoseconds: 300_000_000)
        
        return [
            FacebookLike(
                id: "like_1",
                authorName: "朋友C",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            FacebookLike(
                id: "like_2",
                authorName: "朋友D",
                createdAt: Date().addingTimeInterval(-5400)
            )
        ]
    }
    
    func replyToComment(postId: String, commentId: String?, message: String) async throws -> String {
        // 模拟回复评论
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return "reply_\(UUID().uuidString)"
    }
}

// MARK: - 数据模型

struct SocialUser: Codable {
    let id: String
    let name: String
    let email: String?
    let profileImageUrl: String?
    let platform: SocialPlatform
}

struct SocialPost: Identifiable, Codable {
    let id: String
    let content: String
    let mediaUrls: [URL]
    let privacy: PostPrivacy
    let publishedAt: Date
    let platform: SocialPlatform
    let status: PostStatus
}

struct SocialInteraction: Identifiable, Codable {
    let id: String
    let postId: String
    let type: InteractionType
    let content: String?
    let authorName: String
    let createdAt: Date
}

struct ShareableMedia {
    let type: ShareableMediaType
    let data: Data
    let filename: String
}

enum ShareableMediaType {
    case image
    case video
}



struct FacebookComment {
    let id: String
    let message: String
    let authorName: String
    let createdAt: Date
}

struct FacebookLike {
    let id: String
    let authorName: String
    let createdAt: Date
}

struct Expert: Codable {
    let id: String
    let name: String
    let specialty: String
    let verified: Bool
}

struct ExpertAdvice: Identifiable {
    let id: String
    let question: String
    let advice: String
    let expert: Expert
    let category: AdviceCategory
    let createdAt: Date
    let isVerified: Bool
}

struct ConsultationBooking: Identifiable {
    let id: String
    let expertId: String
    let scheduledTime: Date
    let question: String
    let status: BookingStatus
    let createdAt: Date
}

// MARK: - 枚举

enum SocialPlatform: String, Codable {
    case facebook = "facebook"
    case instagram = "instagram"
    case twitter = "twitter"
}

enum PostPrivacy: String, Codable, CaseIterable {
    case everyone = "everyone"
    case friends = "friends"
    case onlyMe = "only_me"
    
    var displayName: String {
        switch self {
        case .everyone:
            return "公開"
        case .friends:
            return "朋友"
        case .onlyMe:
            return "僅自己"
        }
    }
}

enum PostStatus: String, Codable {
    case draft = "draft"
    case publishing = "publishing"
    case published = "published"
    case failed = "failed"
}

enum InteractionType: String, Codable {
    case like = "like"
    case comment = "comment"
    case share = "share"
}

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}



enum AdviceCategory {
    case feeding
    case sleep
    case behavior
    case development
    case health
    case general
}

enum BookingStatus {
    case pending
    case confirmed
    case completed
    case cancelled
}

enum SocialError: Error, LocalizedError {
    case notConnected
    case publishFailed(String)
    case invalidContent
    case networkError
    case authenticationFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "尚未連接社群帳戶"
        case .publishFailed(let message):
            return "發布失敗：\(message)"
        case .invalidContent:
            return "內容無效"
        case .networkError:
            return "網絡連接錯誤"
        case .authenticationFailed:
            return "身份驗證失敗"
        case .permissionDenied:
            return "權限不足"
        }
    }
} 