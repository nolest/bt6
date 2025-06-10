import Foundation
import SwiftUI
import Combine

// MARK: - 智慧助理管理器
@MainActor
class SmartAssistantManager: ObservableObject {
    @Published var scheduleSuggestions: [ScheduleSuggestion] = []
    @Published var dailyTips: [ParentingTip] = []
    @Published var supportMessages: [SupportMessage] = []
    @Published var isLearningPatterns = false
    
    private let patternLearner = BabyPatternLearner()
    private let knowledgeBase = ParentingKnowledgeBase()
    private let emotionSupporter = EmotionSupporter()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDailyTips()
        startPatternLearning()
    }
    
    // MARK: - 智能排程
    
    /// 学习宝宝作息模式
    func learnBabyPatterns(babyId: String) async {
        DispatchQueue.main.async {
            self.isLearningPatterns = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isLearningPatterns = false
            }
        }
        
        await patternLearner.learnPatterns(for: babyId)
        await generateScheduleSuggestions(for: babyId)
    }
    
    /// 生成每日排程建议
    func generateScheduleSuggestions(for babyId: String) async {
        let suggestions = await patternLearner.generateDailySchedule(for: babyId, date: Date())
        
        DispatchQueue.main.async {
            self.scheduleSuggestions = suggestions
        }
    }
    
    /// 获取下一个预测事件
    func getNextPredictedEvent(for babyId: String) -> PredictedEvent? {
        return patternLearner.getNextPredictedEvent(for: babyId)
    }
    
    // MARK: - 育儿咨询
    
    /// 获取育儿建议
    func getParentingAdvice(query: String, babyId: String) async -> AdviceResponse {
        return await knowledgeBase.getAdvice(for: query, babyId: babyId)
    }
    
    /// 获取上下文提示
    func getContextualTips(babyId: String, context: AppContext) -> [ParentingTip] {
        return knowledgeBase.getContextualTips(for: context, babyId: babyId)
    }
    
    // MARK: - 情绪支持
    
    /// 检测用户压力水平
    func detectUserStressLevel() -> StressLevel {
        return emotionSupporter.detectStressLevel()
    }
    
    /// 提供支持消息
    func provideSupportMessage(level: StressLevel) -> SupportMessage {
        let message = emotionSupporter.generateSupportMessage(for: level)
        
        DispatchQueue.main.async {
            self.supportMessages.append(message)
        }
        
        return message
    }
    
    /// 建议放松技巧
    func suggestRelaxationTechnique() -> RelaxationTechnique {
        return emotionSupporter.suggestRelaxationTechnique()
    }
    
    // MARK: - 私有方法
    
    private func loadDailyTips() {
        dailyTips = knowledgeBase.getDailyTips()
    }
    
    private func startPatternLearning() {
        // 定期学习模式
        Timer.publish(every: 3600, on: .main, in: .common) // 每小时
            .autoconnect()
            .sink { _ in
                Task {
                    // 为所有宝宝学习模式
                    // 这里应该从BabyManager获取宝宝列表
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 宝宝模式学习器
class BabyPatternLearner {
    private var learnedPatterns: [String: BabyPattern] = [:]
    
    func learnPatterns(for babyId: String) async {
        // 获取历史活动数据
        let activities = getHistoricalActivities(for: babyId)
        
        // 分析睡眠模式
        let sleepPattern = analyzeSleepPattern(activities: activities)
        
        // 分析喂食模式
        let feedingPattern = analyzeFeedingPattern(activities: activities)
        
        // 分析换尿布模式
        let diaperPattern = analyzeDiaperPattern(activities: activities)
        
        // 保存学习到的模式
        learnedPatterns[babyId] = BabyPattern(
            sleepPattern: sleepPattern,
            feedingPattern: feedingPattern,
            diaperPattern: diaperPattern
        )
    }
    
    func generateDailySchedule(for babyId: String, date: Date) async -> [ScheduleSuggestion] {
        guard let pattern = learnedPatterns[babyId] else {
            return getDefaultSchedule()
        }
        
        var suggestions: [ScheduleSuggestion] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // 基于学习到的模式生成建议
        if let sleepPattern = pattern.sleepPattern {
            for sleepTime in sleepPattern.typicalSleepTimes {
                let suggestedTime = calendar.date(byAdding: .minute, value: sleepTime, to: startOfDay)!
                suggestions.append(ScheduleSuggestion(
                    type: .sleep,
                    suggestedTime: suggestedTime,
                    confidence: sleepPattern.confidence,
                    reason: "基於過往睡眠規律"
                ))
            }
        }
        
        if let feedingPattern = pattern.feedingPattern {
            for feedingTime in feedingPattern.typicalFeedingTimes {
                let suggestedTime = calendar.date(byAdding: .minute, value: feedingTime, to: startOfDay)!
                suggestions.append(ScheduleSuggestion(
                    type: .feeding,
                    suggestedTime: suggestedTime,
                    confidence: feedingPattern.confidence,
                    reason: "基於過往餵食規律"
                ))
            }
        }
        
        return suggestions.sorted { $0.suggestedTime < $1.suggestedTime }
    }
    
    func getNextPredictedEvent(for babyId: String) -> PredictedEvent? {
        guard let pattern = learnedPatterns[babyId] else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        // 找到下一个最可能的事件
        var nextEvents: [(ActivityType, Int, Double)] = []
        
        if let sleepPattern = pattern.sleepPattern {
            for sleepTime in sleepPattern.typicalSleepTimes {
                if sleepTime > currentMinutes {
                    nextEvents.append((.sleep, sleepTime, sleepPattern.confidence))
                }
            }
        }
        
        if let feedingPattern = pattern.feedingPattern {
            for feedingTime in feedingPattern.typicalFeedingTimes {
                if feedingTime > currentMinutes {
                    nextEvents.append((.feeding, feedingTime, feedingPattern.confidence))
                }
            }
        }
        
        // 选择最近且置信度最高的事件
        if let nextEvent = nextEvents.min(by: { $0.1 < $1.1 }) {
            let predictedTime = calendar.date(byAdding: .minute, value: nextEvent.1 - currentMinutes, to: now)!
            return PredictedEvent(
                type: nextEvent.0,
                predictedTime: predictedTime,
                confidence: nextEvent.2
            )
        }
        
        return nil
    }
    
    private func getHistoricalActivities(for babyId: String) -> [ActivityRecord] {
        // 这里应该从ActivityManager获取历史数据
        // 为了演示，返回空数组
        return []
    }
    
    private func analyzeSleepPattern(activities: [ActivityRecord]) -> SleepPattern? {
        let sleepActivities = activities.filter { $0.type == .sleep }
        guard !sleepActivities.isEmpty else { return nil }
        
        // 分析睡眠时间模式
        let sleepTimes = sleepActivities.compactMap { activity -> Int? in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: activity.startTime)
            let minute = calendar.component(.minute, from: activity.startTime)
            return hour * 60 + minute
        }
        
        // 聚类分析找出典型睡眠时间
        let typicalTimes = clusterTimes(sleepTimes)
        
        return SleepPattern(
            typicalSleepTimes: typicalTimes,
            averageDuration: calculateAverageDuration(sleepActivities),
            confidence: calculateConfidence(sleepTimes)
        )
    }
    
    private func analyzeFeedingPattern(activities: [ActivityRecord]) -> FeedingPattern? {
        let feedingActivities = activities.filter { $0.type == .feeding }
        guard !feedingActivities.isEmpty else { return nil }
        
        let feedingTimes = feedingActivities.compactMap { activity -> Int? in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: activity.startTime)
            let minute = calendar.component(.minute, from: activity.startTime)
            return hour * 60 + minute
        }
        
        let typicalTimes = clusterTimes(feedingTimes)
        
        return FeedingPattern(
            typicalFeedingTimes: typicalTimes,
            averageInterval: calculateAverageInterval(feedingActivities),
            confidence: calculateConfidence(feedingTimes)
        )
    }
    
    private func analyzeDiaperPattern(activities: [ActivityRecord]) -> DiaperPattern? {
        let diaperActivities = activities.filter { $0.type == .diaper }
        guard !diaperActivities.isEmpty else { return nil }
        
        return DiaperPattern(
            averageInterval: calculateAverageInterval(diaperActivities),
            confidence: 0.7 // 尿布更换相对不规律
        )
    }
    
    private func clusterTimes(_ times: [Int]) -> [Int] {
        // 简单的聚类算法，将相近的时间归为一类
        guard !times.isEmpty else { return [] }
        
        let sortedTimes = times.sorted()
        var clusters: [[Int]] = []
        var currentCluster = [sortedTimes[0]]
        
        for i in 1..<sortedTimes.count {
            if sortedTimes[i] - sortedTimes[i-1] <= 60 { // 1小时内认为是同一类
                currentCluster.append(sortedTimes[i])
            } else {
                clusters.append(currentCluster)
                currentCluster = [sortedTimes[i]]
            }
        }
        clusters.append(currentCluster)
        
        // 返回每个聚类的平均时间
        return clusters.map { cluster in
            cluster.reduce(0, +) / cluster.count
        }
    }
    
    private func calculateAverageDuration(_ activities: [ActivityRecord]) -> TimeInterval {
        let durations = activities.compactMap { $0.duration }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func calculateAverageInterval(_ activities: [ActivityRecord]) -> TimeInterval {
        guard activities.count > 1 else { return 0 }
        
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        var intervals: [TimeInterval] = []
        
        for i in 1..<sortedActivities.count {
            let interval = sortedActivities[i].startTime.timeIntervalSince(sortedActivities[i-1].startTime)
            intervals.append(interval)
        }
        
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    private func calculateConfidence(_ times: [Int]) -> Double {
        guard times.count > 2 else { return 0.5 }
        
        // 基于时间的一致性计算置信度
        let variance = calculateVariance(times)
        let maxVariance = 3600.0 // 1小时的方差作为最大值
        
        return max(0.1, 1.0 - (variance / maxVariance))
    }
    
    private func calculateVariance(_ values: [Int]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func getDefaultSchedule() -> [ScheduleSuggestion] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        return [
            ScheduleSuggestion(
                type: .feeding,
                suggestedTime: calendar.date(byAdding: .hour, value: 7, to: startOfDay)!,
                confidence: 0.8,
                reason: "建議的早餐時間"
            ),
            ScheduleSuggestion(
                type: .sleep,
                suggestedTime: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
                confidence: 0.7,
                reason: "建議的上午小睡時間"
            ),
            ScheduleSuggestion(
                type: .feeding,
                suggestedTime: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
                confidence: 0.8,
                reason: "建議的午餐時間"
            )
        ]
    }
}

// MARK: - 育儿知识库
class ParentingKnowledgeBase {
    private let knowledgeItems: [KnowledgeItem] = [
        KnowledgeItem(
            category: .feeding,
            question: "寶寶多久餵一次奶？",
            answer: "新生兒通常每2-3小時需要餵奶一次，隨著寶寶成長，間隔會逐漸延長。",
            tags: ["餵奶", "新生兒", "頻率"]
        ),
        KnowledgeItem(
            category: .sleep,
            question: "寶寶睡眠時間不規律怎麼辦？",
            answer: "建立固定的睡前儀式，保持環境安靜舒適，逐漸培養規律的作息時間。",
            tags: ["睡眠", "作息", "規律"]
        ),
        KnowledgeItem(
            category: .development,
            question: "如何促進寶寶的大腦發育？",
            answer: "多與寶寶說話、唱歌，提供豐富的感官刺激，進行適當的互動遊戲。",
            tags: ["發育", "大腦", "互動"]
        )
    ]
    
    private let dailyTips: [ParentingTip] = [
        ParentingTip(
            title: "今日育兒小貼士",
            content: "與寶寶進行眼神交流有助於建立親子關係和促進社交發展。",
            category: .development
        ),
        ParentingTip(
            title: "餵食提醒",
            content: "觀察寶寶的飢餓信號，如吸吮動作、轉頭尋找等，及時回應寶寶的需求。",
            category: .feeding
        ),
        ParentingTip(
            title: "睡眠建議",
            content: "保持寶寶房間溫度在18-20°C，有助於提高睡眠質量。",
            category: .sleep
        )
    ]
    
    func getAdvice(for query: String, babyId: String) async -> AdviceResponse {
        // 简单的关键词匹配
        let lowercaseQuery = query.lowercased()
        
        for item in knowledgeItems {
            if item.tags.contains(where: { lowercaseQuery.contains($0) }) ||
               item.question.lowercased().contains(lowercaseQuery) {
                return AdviceResponse(
                    question: query,
                    answer: item.answer,
                    category: item.category,
                    confidence: 0.8,
                    sources: ["育兒知識庫"]
                )
            }
        }
        
        // 如果没有匹配的，返回通用建议
        return AdviceResponse(
            question: query,
            answer: "建議諮詢專業的兒科醫生或育兒專家，獲取針對您寶寶具體情況的專業建議。",
            category: .general,
            confidence: 0.5,
            sources: ["通用建議"]
        )
    }
    
    func getContextualTips(for context: AppContext, babyId: String) -> [ParentingTip] {
        switch context {
        case .homeScreen:
            return Array(dailyTips.prefix(2))
        case .feedingLog:
            return dailyTips.filter { $0.category == .feeding }
        case .sleepLog:
            return dailyTips.filter { $0.category == .sleep }
        }
    }
    
    func getDailyTips() -> [ParentingTip] {
        return dailyTips
    }
}

// MARK: - 情绪支持器
class EmotionSupporter {
    private var userInteractionHistory: [UserInteraction] = []
    
    func detectStressLevel() -> StressLevel {
        // 基于用户交互模式检测压力水平
        let recentInteractions = userInteractionHistory.suffix(10)
        
        if recentInteractions.isEmpty {
            return .low
        }
        
        let stressIndicators = recentInteractions.filter { interaction in
            interaction.type == .frequentLogging ||
            interaction.type == .lateNightActivity ||
            interaction.type == .multipleRetries
        }
        
        let stressRatio = Double(stressIndicators.count) / Double(recentInteractions.count)
        
        if stressRatio > 0.6 {
            return .high
        } else if stressRatio > 0.3 {
            return .medium
        } else {
            return .low
        }
    }
    
    func generateSupportMessage(for level: StressLevel) -> SupportMessage {
        let messages: [StressLevel: [String]] = [
            .low: [
                "您做得很好！繼續保持這樣的育兒節奏。",
                "寶寶在您的悉心照料下健康成長。",
                "記得也要照顧好自己哦！"
            ],
            .medium: [
                "育兒確實不容易，您已經很努力了。",
                "記得適時休息，照顧寶寶的同時也要照顧自己。",
                "如果感到疲憊，不妨尋求家人朋友的幫助。"
            ],
            .high: [
                "育兒路上的挑戰很多，但您並不孤單。",
                "感到壓力是正常的，請記得尋求支持和幫助。",
                "建議您與專業人士或其他父母交流經驗。"
            ]
        ]
        
        let messageTexts = messages[level] ?? messages[.medium]!
        let randomMessage = messageTexts.randomElement()!
        
        return SupportMessage(
            text: randomMessage,
            level: level,
            timestamp: Date(),
            type: .encouragement
        )
    }
    
    func suggestRelaxationTechnique() -> RelaxationTechnique {
        let techniques = [
            RelaxationTechnique(
                name: "深呼吸練習",
                description: "緩慢深呼吸4秒，屏住呼吸4秒，然後緩慢呼氣4秒。重複5-10次。",
                duration: 300, // 5分钟
                category: .breathing
            ),
            RelaxationTechnique(
                name: "漸進式肌肉放鬆",
                description: "從腳趾開始，逐漸緊張然後放鬆身體各部位的肌肉。",
                duration: 600, // 10分钟
                category: .muscleRelaxation
            ),
            RelaxationTechnique(
                name: "正念冥想",
                description: "專注於當下的感受，觀察呼吸和身體感覺，不做判斷。",
                duration: 900, // 15分钟
                category: .mindfulness
            )
        ]
        
        return techniques.randomElement()!
    }
    
    func recordUserInteraction(_ interaction: UserInteraction) {
        userInteractionHistory.append(interaction)
        
        // 保持最近100个交互记录
        if userInteractionHistory.count > 100 {
            userInteractionHistory.removeFirst()
        }
    }
}

// MARK: - 数据模型

struct ScheduleSuggestion: Identifiable {
    let id = UUID()
    let type: ActivityType
    let suggestedTime: Date
    let confidence: Double
    let reason: String
}

struct PredictedEvent {
    let type: ActivityType
    let predictedTime: Date
    let confidence: Double
}

struct ParentingTip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let category: TipCategory
}

struct AdviceResponse {
    let question: String
    let answer: String
    let category: TipCategory
    let confidence: Double
    let sources: [String]
}

struct SupportMessage: Identifiable {
    let id = UUID()
    let text: String
    let level: StressLevel
    let timestamp: Date
    let type: SupportMessageType
}

struct RelaxationTechnique {
    let name: String
    let description: String
    let duration: TimeInterval // 秒
    let category: RelaxationCategory
}

// MARK: - 枚举

enum StressLevel {
    case low, medium, high
}

enum AppContext {
    case homeScreen, feedingLog, sleepLog
}

enum TipCategory {
    case feeding, sleep, development, health, general
}

enum SupportMessageType {
    case encouragement, advice, reminder
}

enum RelaxationCategory {
    case breathing, muscleRelaxation, mindfulness
}

enum UserInteractionType {
    case normalLogging
    case frequentLogging
    case lateNightActivity
    case multipleRetries
}

// MARK: - 内部数据结构

struct BabyPattern {
    let sleepPattern: SleepPattern?
    let feedingPattern: FeedingPattern?
    let diaperPattern: DiaperPattern?
}

struct SleepPattern {
    let typicalSleepTimes: [Int] // 一天中的分钟数
    let averageDuration: TimeInterval
    let confidence: Double
}

struct FeedingPattern {
    let typicalFeedingTimes: [Int] // 一天中的分钟数
    let averageInterval: TimeInterval
    let confidence: Double
}

struct DiaperPattern {
    let averageInterval: TimeInterval
    let confidence: Double
}

struct KnowledgeItem {
    let category: TipCategory
    let question: String
    let answer: String
    let tags: [String]
}

struct UserInteraction {
    let timestamp: Date
    let type: UserInteractionType
    let context: String?
}

 