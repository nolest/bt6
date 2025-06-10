import Foundation
import SwiftUI
import Combine

// MARK: - GAI分析管理器
@MainActor
class GAIAnalysisManager: ObservableObject {
    @Published var analysisResults: [AnalysisResult] = []
    @Published var isAnalyzing = false
    @Published var analysisQuota = GAIQuotaStatus(hourlyRemaining: 10, dailyRemaining: 30)
    
    private let apiKeyManager = GAIAPIKeyManager()
    private let rateLimiter = GAIRateLimiter()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAnalysisResults()
    }
    
    // MARK: - 公共方法
    
    /// 请求分析媒体
    func requestAnalysis(mediaItemId: String, analysisType: GAIAnalysisType) async throws -> AnalysisResult {
        // 检查是否启用云端分析
        guard isCloudAnalysisEnabled() else {
            throw GAIError.analysisOptedOut
        }
        
        // 检查速率限制
        guard rateLimiter.allowRequest(type: analysisType) else {
            throw GAIError.rateLimitExceeded
        }
        
        // 检查配额
        guard hasAvailableQuota(for: analysisType) else {
            throw GAIError.quotaExceeded
        }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isAnalyzing = false
            }
        }
        
        do {
            // 获取API密钥
            let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            let apiKey = apiKeyManager.getAPIKey(for: deviceId)
            
            // 获取匿名化媒体数据
            let mediaData = try await getAnonymizedMediaData(mediaItemId: mediaItemId)
            
            // 调用Deepseek API
            let resultData = try await callDeepseekAPI(
                apiKey: apiKey,
                mediaData: mediaData,
                analysisType: analysisType
            )
            
            // 创建分析结果
            let result = AnalysisResult(
                mediaId: UUID(uuidString: mediaItemId) ?? UUID(),
                analysisType: AnalysisType.development,
                result: "分析完成",
                confidence: 0.9,
                recommendations: extractRecommendations(from: resultData) ?? []
            )
            
            // 保存结果
            await saveAnalysisResult(result)
            
            // 记录请求
            rateLimiter.recordRequest(type: analysisType)
            updateQuotaStatus()
            
            return result
            
        } catch {
            if let gaiError = error as? GAIError, case .invalidAPIKey = gaiError {
                await apiKeyManager.reportFailedKey(apiKeyManager.getAPIKey(for: await UIDevice.current.identifierForVendor?.uuidString ?? ""))
            }
            throw error
        }
    }
    
    /// 获取分析结果
    func getAnalysisResult(for id: UUID) -> AnalysisResult? {
        return analysisResults.first { $0.id == id }
    }
    
    /// 获取媒体的分析结果
    func getAnalysisResults(for mediaItemId: UUID) -> [AnalysisResult] {
        return analysisResults.filter { $0.mediaId == mediaItemId }
    }
    
    /// 获取配额状态
    func getQuotaStatus() -> GAIQuotaStatus {
        return analysisQuota
    }
    
    // MARK: - 私有方法
    
    private func isCloudAnalysisEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "cloudAnalysisEnabled")
    }
    
    private func hasAvailableQuota(for type: GAIAnalysisType) -> Bool {
        switch type {
        case .emotion, .development:
            return analysisQuota.hourlyRemaining > 0 && analysisQuota.dailyRemaining > 0
        case .milestoneCheck:
            return analysisQuota.dailyRemaining > 0
        }
    }
    
    private func getAnonymizedMediaData(mediaItemId: String) async throws -> Data {
        // 这里应该从MediaManager获取媒体数据并进行匿名化处理
        // 移除EXIF数据，可能模糊背景等
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw GAIError.dataProcessingFailed
        }
        
        // 模拟获取媒体数据
        let mediaPath = documentsPath.appendingPathComponent("Media/\(mediaItemId)")
        
        guard let data = try? Data(contentsOf: mediaPath) else {
            throw GAIError.mediaNotFound
        }
        
        // 这里应该实现匿名化处理
        return data
    }
    
    private func callDeepseekAPI(apiKey: String, mediaData: Data, analysisType: GAIAnalysisType) async throws -> [String: Any] {
        // 构建API请求
        let url = URL(string: "https://api.deepseek.com/v1/analyze")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "request_id": UUID().uuidString,
            "analysis_type": analysisType.rawValue,
            "anonymized_media": [
                "format": "jpg", // 根据实际格式设置
                "data": mediaData.base64EncodedString()
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GAIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw GAIError.quotaExceeded
            } else if httpResponse.statusCode == 401 {
                throw GAIError.invalidAPIKey
            } else {
                throw GAIError.apiError(code: "\(httpResponse.statusCode)", message: "API request failed")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GAIError.invalidResponse
        }
        
        if let error = json["error"] as? [String: Any],
           let code = error["code"] as? String,
           let message = error["message"] as? String {
            throw GAIError.apiError(code: code, message: message)
        }
        
        return json["results"] as? [String: Any] ?? [:]
    }
    
    private func extractRecommendations(from data: [String: Any]) -> [String]? {
        return data["recommendations"] as? [String]
    }
    
    private func extractDevelopmentScores(from data: [String: Any]) -> [String: Double]? {
        return data["development_scores"] as? [String: Double]
    }
    
    private func extractEmotionTags(from data: [String: Any]) -> [String]? {
        return data["emotion_tags"] as? [String]
    }
    
    private func saveAnalysisResult(_ result: AnalysisResult) async {
        DispatchQueue.main.async {
            self.analysisResults.append(result)
        }
        
        // 保存到UserDefaults
        if let encoded = try? JSONEncoder().encode(analysisResults) {
            UserDefaults.standard.set(encoded, forKey: "analysisResults")
        }
    }
    
    private func loadAnalysisResults() {
        if let data = UserDefaults.standard.data(forKey: "analysisResults"),
           let results = try? JSONDecoder().decode([AnalysisResult].self, from: data) {
            self.analysisResults = results
        }
    }
    
    private func updateQuotaStatus() {
        // 更新配额状态
        let hourlyUsed = rateLimiter.getHourlyUsage()
        let dailyUsed = rateLimiter.getDailyUsage()
        
        analysisQuota = GAIQuotaStatus(
            hourlyRemaining: max(0, 10 - hourlyUsed),
            dailyRemaining: max(0, 30 - dailyUsed)
        )
    }
}

// MARK: - API密钥管理器
class GAIAPIKeyManager {
    private let keyPool = [
        "sk-deepseek-key-1-obfuscated",
        "sk-deepseek-key-2-obfuscated",
        "sk-deepseek-key-3-obfuscated"
    ]
    
    private var failedKeys = Set<String>()
    
    func getAPIKey(for deviceId: String) -> String {
        let hash = deviceId.hash
        let index = abs(hash) % keyPool.count
        let obfuscatedKey = keyPool[index]
        
        // 这里应该实现密钥解混淆逻辑
        return deobfuscateKey(obfuscatedKey)
    }
    
    func reportFailedKey(_ key: String) {
        failedKeys.insert(key)
    }
    
    private func deobfuscateKey(_ obfuscatedKey: String) -> String {
        // 这里应该实现实际的解混淆逻辑
        // 为了演示，直接返回模拟的密钥
        return "sk-deepseek-demo-key"
    }
}

// MARK: - 速率限制器
class GAIRateLimiter {
    private var requestTimestamps: [GAIAnalysisType: [Date]] = [:]
    private let hourlyLimit = 10
    private let dailyLimit = 30
    
    func allowRequest(type: GAIAnalysisType) -> Bool {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        // 清理过期的时间戳
        if var timestamps = requestTimestamps[type] {
            timestamps = timestamps.filter { $0 > oneDayAgo }
            requestTimestamps[type] = timestamps
            
            let hourlyCount = timestamps.filter { $0 > oneHourAgo }.count
            let dailyCount = timestamps.count
            
            return hourlyCount < hourlyLimit && dailyCount < dailyLimit
        }
        
        return true
    }
    
    func recordRequest(type: GAIAnalysisType) {
        let now = Date()
        if requestTimestamps[type] == nil {
            requestTimestamps[type] = []
        }
        requestTimestamps[type]?.append(now)
    }
    
    func getHourlyUsage() -> Int {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        return requestTimestamps.values.flatMap { $0 }.filter { $0 > oneHourAgo }.count
    }
    
    func getDailyUsage() -> Int {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        return requestTimestamps.values.flatMap { $0 }.filter { $0 > oneDayAgo }.count
    }
}

// MARK: - 数据模型

enum GAIAnalysisType: String, Codable, CaseIterable {
    case emotion = "emotion"
    case development = "development"
    case milestoneCheck = "milestone"
    
    var displayName: String {
        switch self {
        case .emotion:
            return "情緒分析"
        case .development:
            return "發展評估"
        case .milestoneCheck:
            return "里程碑檢查"
        }
    }
}

struct GAIQuotaStatus {
    let hourlyRemaining: Int
    let dailyRemaining: Int
}

enum GAIError: Error, LocalizedError {
    case analysisOptedOut
    case rateLimitExceeded
    case quotaExceeded
    case invalidAPIKey
    case apiError(code: String, message: String)
    case networkError
    case invalidResponse
    case dataProcessingFailed
    case mediaNotFound
    
    var errorDescription: String? {
        switch self {
        case .analysisOptedOut:
            return "用戶未啟用雲端分析功能"
        case .rateLimitExceeded:
            return "請求頻率超出限制，請稍後再試"
        case .quotaExceeded:
            return "分析配額已用完，請明天再試"
        case .invalidAPIKey:
            return "API密鑰無效"
        case .apiError(let code, let message):
            return "API錯誤 (\(code)): \(message)"
        case .networkError:
            return "網絡連接錯誤"
        case .invalidResponse:
            return "無效的API響應"
        case .dataProcessingFailed:
            return "數據處理失敗"
        case .mediaNotFound:
            return "找不到媒體文件"
        }
    }
} 