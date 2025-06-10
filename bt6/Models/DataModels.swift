import Foundation
import SwiftUI

// MARK: - 用户模型
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String?
    var profileImagePath: String?
    var createdAt: Date = Date()
    var familyMembers: [FamilyMember] = []
}

// MARK: - 家庭成员模型
struct FamilyMember: Identifiable, Codable {
    let id = UUID()
    var name: String
    var role: FamilyRole
    var profileImagePath: String?
    var permissions: [Permission] = []
    var inviteCode: String?
    var joinedAt: Date = Date()
}

enum FamilyRole: String, CaseIterable, Codable {
    case admin = "Admin"
    case member = "Member"
    case viewer = "Viewer"
    
    var displayName: String {
        switch self {
        case .admin: return "管理員"
        case .member: return "成員"
        case .viewer: return "觀看者"
        }
    }
}

enum Permission: String, CaseIterable, Codable {
    case addRecord = "add_record"
    case editRecord = "edit_record"
    case deleteRecord = "delete_record"
    case viewStatistics = "view_statistics"
    case manageMedia = "manage_media"
    case shareContent = "share_content"
}

// MARK: - 寶寶模型
struct Baby: Identifiable, Codable {
    let id = UUID()
    var name: String
    var birthDate: Date
    var gender: Gender
    var profileImagePath: String?
    var weight: Double?
    var height: Double?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male: return "男孩"
        case .female: return "女孩"
        case .other: return "其他"
        }
    }
    
    var emoji: String {
        switch self {
        case .male: return "👦"
        case .female: return "👧"
        case .other: return "👶"
        }
    }
}

// MARK: - 活動記錄模型
struct ActivityRecord: Identifiable, Codable {
    let id = UUID()
    let babyId: UUID
    var type: ActivityType
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var details: ActivityDetails
    var notes: String?
    let createdBy: UUID
    let createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum ActivityType: String, CaseIterable, Codable {
    case feeding = "feeding"
    case diaper = "diaper"
    case sleep = "sleep"
    case bath = "bath"
    case medicine = "medicine"
    case temperature = "temperature"
    case weight = "weight"
    case height = "height"
    case milestone = "milestone"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .feeding: return "餵食"
        case .diaper: return "換尿布"
        case .sleep: return "睡眠"
        case .bath: return "洗澡"
        case .medicine: return "用藥"
        case .temperature: return "體溫"
        case .weight: return "體重"
        case .height: return "身高"
        case .milestone: return "里程碑"
        case .custom: return "自定義"
        }
    }
    
    var icon: String {
        switch self {
        case .feeding: return "🍼"
        case .diaper: return "👶"
        case .sleep: return "😴"
        case .bath: return "🛁"
        case .medicine: return "💊"
        case .temperature: return "🌡️"
        case .weight: return "⚖️"
        case .height: return "📏"
        case .milestone: return "⭐"
        case .custom: return "📝"
        }
    }
    
    var color: Color {
        switch self {
        case .feeding: return .orange
        case .diaper: return .yellow
        case .sleep: return .purple
        case .bath: return .blue
        case .medicine: return .red
        case .temperature: return .pink
        case .weight: return .green
        case .height: return .teal
        case .milestone: return .gold
        case .custom: return .gray
        }
    }
}

// MARK: - 活動詳情模型
enum ActivityDetails: Codable {
    case feeding(FeedingDetails)
    case diaper(DiaperDetails)
    case sleep(SleepDetails)
    case bath(BathDetails)
    case medicine(MedicineDetails)
    case measurement(MeasurementDetails)
    case milestone(MilestoneDetails)
    case health(HealthDetails)
    case custom(CustomDetails)
}

struct FeedingDetails: Codable {
    var type: FeedingType
    var amount: Double?
    var unit: String = "ml"
    var side: BreastSide?
    var duration: TimeInterval?
}

enum FeedingType: String, CaseIterable, Codable {
    case breast = "breast"
    case bottle = "bottle"
    case solid = "solid"
    
    var displayName: String {
        switch self {
        case .breast: return "母乳"
        case .bottle: return "奶瓶"
        case .solid: return "固體食物"
        }
    }
}

enum BreastSide: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .left: return "左側"
        case .right: return "右側"
        case .both: return "雙側"
        }
    }
}

struct DiaperDetails: Codable {
    var type: DiaperType
    var condition: DiaperCondition?
}

enum DiaperType: String, CaseIterable, Codable {
    case wet = "wet"
    case dirty = "dirty"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .wet: return "濕"
        case .dirty: return "髒"
        case .both: return "又濕又髒"
        }
    }
}

enum DiaperCondition: String, CaseIterable, Codable {
    case normal = "normal"
    case loose = "loose"
    case hard = "hard"
    case unusual = "unusual"
    
    var displayName: String {
        switch self {
        case .normal: return "正常"
        case .loose: return "稀軟"
        case .hard: return "硬結"
        case .unusual: return "異常"
        }
    }
}

struct SleepDetails: Codable {
    var quality: SleepQuality?
    var location: String?
}

enum SleepQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "極佳"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "不佳"
        }
    }
}

struct BathDetails: Codable {
    var temperature: Double?
    var duration: TimeInterval?
    var products: [String]?
}

struct MedicineDetails: Codable {
    var name: String
    var dosage: String?
    var unit: String?
    var reason: String?
}

struct MeasurementDetails: Codable {
    var value: Double
    var unit: String
    var percentile: Double?
}

struct MilestoneDetails: Codable {
    var title: String
    var description: String?
    var category: MilestoneCategory
    var ageInMonths: Int?
}

struct HealthDetails: Codable {
    var type: String
    var value: Double
    var unit: String
    var notes: String?
}

enum MilestoneCategory: String, CaseIterable, Codable {
    case all = "all"
    case physical = "physical"
    case cognitive = "cognitive"
    case social = "social"
    case language = "language"
    case emotional = "emotional"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .physical: return "身體發展"
        case .cognitive: return "認知發展"
        case .social: return "社交發展"
        case .language: return "語言發展"
        case .emotional: return "情感發展"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "star"
        case .physical: return "figure.walk"
        case .cognitive: return "brain.head.profile"
        case .social: return "person.2"
        case .language: return "bubble.left"
        case .emotional: return "heart"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .physical: return .green
        case .cognitive: return .purple
        case .social: return .orange
        case .language: return .pink
        case .emotional: return .red
        }
    }
}

struct CustomDetails: Codable {
    var title: String
    var description: String?
    var value: String?
}

// MARK: - 媒體模型
struct MediaItem: Identifiable, Codable {
    let id = UUID()
    let babyId: UUID
    var type: MediaType
    var fileName: String
    var filePath: String
    var thumbnailPath: String?
    var fileSize: Int64
    var duration: TimeInterval?
    var createdAt: Date = Date()
    var tags: [String] = []
    var description: String?
    var analysisResults: [AnalysisResult] = []
    var isFavorite: Bool = false
    var isAnalyzed: Bool = false
}

enum MediaType: String, CaseIterable, Codable {
    case photo = "photo"
    case video = "video"
    
    var displayName: String {
        switch self {
        case .photo: return "照片"
        case .video: return "影片"
        }
    }
}

// MARK: - 分析結果模型
struct AnalysisResult: Identifiable, Codable {
    let id = UUID()
    let mediaId: UUID
    var analysisType: AnalysisType
    var result: String
    var confidence: Double
    var recommendations: [String] = []
    let analyzedAt: Date = Date()
}

enum AnalysisType: String, CaseIterable, Codable {
    case emotion = "emotion"
    case development = "development"
    case health = "health"
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .emotion: return "情緒分析"
        case .development: return "發展評估"
        case .health: return "健康檢查"
        case .milestone: return "里程碑識別"
        }
    }
}

// MARK: - 統計數據模型
struct StatisticsData: Codable {
    var period: StatisticsPeriod
    var activityCounts: [ActivityType: Int] = [:]
    var totalDuration: [ActivityType: TimeInterval] = [:]
    var averages: [String: Double] = [:]
    var trends: [String: TrendData] = [:]
    var generatedAt: Date = Date()
}

enum StatisticsPeriod: String, CaseIterable, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day: return "日"
        case .week: return "週"
        case .month: return "月"
        case .year: return "年"
        }
    }
}

struct TrendData: Codable {
    var direction: TrendDirection
    var percentage: Double
    var description: String?
}

enum TrendDirection: String, Codable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    var displayName: String {
        switch self {
        case .up: return "上升"
        case .down: return "下降"
        case .stable: return "穩定"
        }
    }
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - 設置模型
struct AppSettings: Codable {
    var notifications: NotificationSettings = NotificationSettings()
    var privacy: PrivacySettings = PrivacySettings()
    var sync: SyncSettings = SyncSettings()
    var display: DisplaySettings = DisplaySettings()
    var ai: AISettings = AISettings()
}

struct NotificationSettings: Codable {
    var enabled: Bool = true
    var feedingReminders: Bool = true
    var sleepReminders: Bool = true
    var medicineReminders: Bool = true
    var milestoneAlerts: Bool = true
    var quietHours: DateInterval?
}

struct PrivacySettings: Codable {
    var appLockEnabled: Bool = false
    var biometricEnabled: Bool = false
    var autoLockTimeout: TimeInterval = 300 // 5 minutes
    var shareAnalytics: Bool = false
    var shareWithFamily: Bool = true
}

struct SyncSettings: Codable {
    var iCloudEnabled: Bool = true
    var dropboxEnabled: Bool = false
    var autoSync: Bool = true
    var syncOnWiFiOnly: Bool = true
    var lastSyncDate: Date?
}

struct DisplaySettings: Codable {
    var theme: AppTheme = .system
    var language: String = "zh-Hant"
    var dateFormat: String = "yyyy/MM/dd"
    var timeFormat: String = "HH:mm"
    var units: UnitSettings = UnitSettings()
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "淺色"
        case .dark: return "深色"
        case .system: return "跟隨系統"
        }
    }
}

struct UnitSettings: Codable {
    var weight: WeightUnit = .kg
    var height: HeightUnit = .cm
    var temperature: TemperatureUnit = .celsius
    var volume: VolumeUnit = .ml
}

enum WeightUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case lb = "lb"
    
    var displayName: String {
        switch self {
        case .kg: return "公斤"
        case .lb: return "磅"
        }
    }
}

enum HeightUnit: String, CaseIterable, Codable {
    case cm = "cm"
    case inch = "inch"
    
    var displayName: String {
        switch self {
        case .cm: return "公分"
        case .inch: return "英寸"
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
    
    var displayName: String {
        switch self {
        case .celsius: return "攝氏"
        case .fahrenheit: return "華氏"
        }
    }
}

enum VolumeUnit: String, CaseIterable, Codable {
    case ml = "ml"
    case oz = "oz"
    
    var displayName: String {
        switch self {
        case .ml: return "毫升"
        case .oz: return "盎司"
        }
    }
}

struct AISettings: Codable {
    var analysisEnabled: Bool = true
    var autoAnalysis: Bool = false
    var analysisQuota: Int = 30
    var usedQuota: Int = 0
    var quotaResetDate: Date = Date()
}

// MARK: - 擴展方法
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

extension Date {
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: Date())
        return components.month ?? 0
    }
    
    var ageInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: Date())
        return components.day ?? 0
    }
    
    func ageString() -> String {
        let months = ageInMonths
        let days = ageInDays
        
        if months >= 12 {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years) 歲"
            } else {
                return "\(years) 歲 \(remainingMonths) 個月"
            }
        } else if months > 0 {
            return "\(months) 個月"
        } else {
            return "\(days) 天"
        }
    }
} 