import Foundation
import CoreData
import SwiftUI

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    @Published var activities: [ActivityRecord] = []
    @Published var todayActivities: [ActivityRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var statistics: StatisticsData?
    
    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    init() {
        // 移除自动加载，改为在需要时手动加载
    }
    
    // MARK: - 获取活动记录
    func loadActivities(for babyId: UUID) async throws {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ActivityRecordEntity")
        request.predicate = NSPredicate(format: "babyId == %@", babyId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            let activities = entities.compactMap { convertEntityToActivityRecord($0) }
            
            await MainActor.run {
                self.activities = activities
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - 获取今日活动
    func loadTodayActivities(for babyId: UUID) async throws -> [ActivityRecord] {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ActivityRecordEntity")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "babyId == %@ AND startTime >= %@ AND startTime < %@",
                                       babyId as CVarArg, today as NSDate, tomorrow as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { convertEntityToActivityRecord($0) }
        } catch {
            throw error
        }
    }
    
    // MARK: - 添加活动记录
    func addActivity(_ activity: ActivityRecord) async throws {
        let context = persistenceController.container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "ActivityRecordEntity", in: context) else {
            throw NSError(domain: "ActivityManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建ActivityRecordEntity"])
        }
        
        let activityEntity = NSManagedObject(entity: entity, insertInto: context)
        updateEntity(activityEntity, with: activity)
        
        try context.save()
        
        await MainActor.run {
            self.activities.insert(activity, at: 0)
        }
    }
    
    // MARK: - 辅助方法
    private func convertEntityToActivityRecord(_ entity: NSManagedObject) -> ActivityRecord? {
        guard let _ = entity.value(forKey: "id") as? UUID,
              let babyId = entity.value(forKey: "babyId") as? UUID,
              let typeString = entity.value(forKey: "type") as? String,
              let startTime = entity.value(forKey: "startTime") as? Date,
              let createdBy = entity.value(forKey: "createdBy") as? UUID,
              let _ = entity.value(forKey: "createdAt") as? Date,
              let _ = entity.value(forKey: "updatedAt") as? Date else {
            return nil
        }
        
        let type = ActivityType(rawValue: typeString) ?? .custom
        let endTime = entity.value(forKey: "endTime") as? Date
        let duration = entity.value(forKey: "duration") as? Double
        let notes = entity.value(forKey: "notes") as? String
        
        // 根据类型创建详细信息
        let details = createActivityDetails(from: entity, type: type)
        
        return ActivityRecord(
            babyId: babyId,
            type: type,
            startTime: startTime,
            endTime: endTime,
            duration: duration != 0 ? duration : nil,
            details: details,
            notes: notes,
            createdBy: createdBy
        )
    }
    
    private func createActivityDetails(from entity: NSManagedObject, type: ActivityType) -> ActivityDetails {
        switch type {
        case .feeding:
            let feedingType = FeedingType(rawValue: entity.value(forKey: "feedingType") as? String ?? "bottle") ?? .bottle
            let amount = entity.value(forKey: "amount") as? Double
            let breastSide = entity.value(forKey: "breastSide") as? String
            let duration = entity.value(forKey: "duration") as? Double
            
            return .feeding(FeedingDetails(
                type: feedingType,
                amount: amount != 0 ? amount : nil,
                side: breastSide != nil ? BreastSide(rawValue: breastSide!) : nil,
                duration: duration != 0 ? duration : nil
            ))
            
        case .diaper:
            let diaperType = DiaperType(rawValue: entity.value(forKey: "diaperType") as? String ?? "wet") ?? .wet
            let condition = entity.value(forKey: "diaperCondition") as? String
            
            return .diaper(DiaperDetails(
                type: diaperType,
                condition: condition != nil ? DiaperCondition(rawValue: condition!) : nil
            ))
            
        case .sleep:
            let quality = entity.value(forKey: "sleepQuality") as? String
            let location = entity.value(forKey: "location") as? String
            
            return .sleep(SleepDetails(
                quality: quality != nil ? SleepQuality(rawValue: quality!) : nil,
                location: location
            ))
            
        case .milestone:
            let title = entity.value(forKey: "customTitle") as? String ?? ""
            let description = entity.value(forKey: "customDescription") as? String
            
            return .milestone(MilestoneDetails(
                title: title,
                description: description,
                category: .physical,
                ageInMonths: nil
            ))
            
        case .custom:
            let title = entity.value(forKey: "customTitle") as? String ?? ""
            let description = entity.value(forKey: "customDescription") as? String
            let value = entity.value(forKey: "customValue") as? String
            
            return .custom(CustomDetails(
                title: title,
                description: description,
                value: value
            ))
            
        default:
            return .custom(CustomDetails(
                title: type.displayName,
                description: entity.value(forKey: "notes") as? String,
                value: nil
            ))
        }
    }
    
    private func updateEntity(_ entity: NSManagedObject, with activity: ActivityRecord) {
        entity.setValue(activity.id, forKey: "id")
        entity.setValue(activity.babyId, forKey: "babyId")
        entity.setValue(activity.type.rawValue, forKey: "type")
        entity.setValue(activity.startTime, forKey: "startTime")
        entity.setValue(activity.endTime, forKey: "endTime")
        entity.setValue(activity.duration ?? 0, forKey: "duration")
        entity.setValue(activity.notes, forKey: "notes")
        entity.setValue(activity.createdBy, forKey: "createdBy")
        entity.setValue(activity.createdAt, forKey: "createdAt")
        entity.setValue(activity.updatedAt, forKey: "updatedAt")
        
        // 清除所有详细信息字段
        entity.setValue(nil, forKey: "feedingType")
        entity.setValue(0, forKey: "amount")
        entity.setValue(nil, forKey: "breastSide")
        entity.setValue(nil, forKey: "diaperType")
        entity.setValue(nil, forKey: "diaperCondition")
        entity.setValue(nil, forKey: "sleepQuality")
        entity.setValue(nil, forKey: "location")
        entity.setValue(nil, forKey: "customTitle")
        entity.setValue(nil, forKey: "customDescription")
        entity.setValue(nil, forKey: "customValue")
        
        // 根据类型设置相应字段
        switch activity.details {
        case .feeding(let feedingDetails):
            entity.setValue(feedingDetails.type.rawValue, forKey: "feedingType")
            entity.setValue(feedingDetails.amount ?? 0, forKey: "amount")
            entity.setValue(feedingDetails.side?.rawValue, forKey: "breastSide")
            entity.setValue(feedingDetails.duration ?? 0, forKey: "duration")
            
        case .diaper(let diaperDetails):
            entity.setValue(diaperDetails.type.rawValue, forKey: "diaperType")
            entity.setValue(diaperDetails.condition?.rawValue, forKey: "diaperCondition")
            
        case .sleep(let sleepDetails):
            entity.setValue(sleepDetails.quality?.rawValue, forKey: "sleepQuality")
            entity.setValue(sleepDetails.location, forKey: "location")
            
        case .milestone(let milestoneDetails):
            entity.setValue(milestoneDetails.title, forKey: "customTitle")
            entity.setValue(milestoneDetails.description, forKey: "customDescription")
            
        case .custom(let customDetails):
            entity.setValue(customDetails.title, forKey: "customTitle")
            entity.setValue(customDetails.description, forKey: "customDescription")
            entity.setValue(customDetails.value, forKey: "customValue")
            
        default:
            break
        }
    }
    
    // MARK: - 更新活动记录
    func updateActivity(_ activity: ActivityRecord) throws {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ActivityRecordEntity")
        request.predicate = NSPredicate(format: "id == %@", activity.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                updateEntity(entity, with: activity)
                try context.save()
                
                // 更新本地数组
                if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                    activities[index] = activity
                }
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - 删除活动记录
    func deleteActivity(_ activity: ActivityRecord) throws {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ActivityRecordEntity")
        request.predicate = NSPredicate(format: "id == %@", activity.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                try context.save()
                
                // 从本地数组中移除
                activities.removeAll { $0.id == activity.id }
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - 获取最近的活动
    func getLastActivity(of type: ActivityType, for babyId: UUID) -> ActivityRecord? {
        return activities.first { $0.type == type && $0.babyId == babyId }
    }
    
    // MARK: - 获取活动间隔时间
    func getTimeSinceLastActivity(of type: ActivityType, for babyId: UUID) -> TimeInterval? {
        guard let lastActivity = getLastActivity(of: type, for: babyId) else {
            return nil
        }
        
        return Date().timeIntervalSince(lastActivity.startTime)
    }
    
    // MARK: - 生成统计数据
    private func generateStatistics(for activities: [ActivityRecord], period: StatisticsPeriod) {
        var activityCounts: [ActivityType: Int] = [:]
        var totalDuration: [ActivityType: TimeInterval] = [:]
        var averages: [String: Double] = [:]
        var trends: [String: TrendData] = [:]
        
        // 计算活动次数
        for activity in activities {
            activityCounts[activity.type, default: 0] += 1
            
            if let duration = activity.duration {
                totalDuration[activity.type, default: 0] += duration
            }
        }
        
        // 计算平均值
        for (type, count) in activityCounts {
            if let total = totalDuration[type], count > 0 {
                averages["\(type.rawValue)_average_duration"] = total / Double(count)
            }
            averages["\(type.rawValue)_daily_count"] = Double(count) / Double(period == .day ? 1 : 7)
        }
        
        // 计算趋势（简化版本）
        let feedingCount = activityCounts[.feeding] ?? 0
        let sleepDuration = totalDuration[.sleep] ?? 0
        
        trends["feeding_trend"] = TrendData(
            direction: feedingCount > 6 ? .up : .stable,
            percentage: Double(feedingCount) / 8.0 * 100,
            description: "餵食頻率"
        )
        
        trends["sleep_trend"] = TrendData(
            direction: sleepDuration > 28800 ? .up : .down, // 8 hours
            percentage: sleepDuration / 28800 * 100,
            description: "睡眠時間"
        )
        
        statistics = StatisticsData(
            period: period,
            activityCounts: activityCounts,
            totalDuration: totalDuration,
            averages: averages,
            trends: trends
        )
    }
    
    // MARK: - 获取活动建议
    func getActivitySuggestions(for babyId: UUID) -> [String] {
        var suggestions: [String] = []
        
        // 检查餵食间隔
        if let timeSinceFeeding = getTimeSinceLastActivity(of: .feeding, for: babyId) {
            if timeSinceFeeding > 10800 { // 3 hours
                suggestions.append("距離上次餵食已超過3小時，可能需要餵食")
            }
        }
        
        // 检查换尿布间隔
        if let timeSinceDiaper = getTimeSinceLastActivity(of: .diaper, for: babyId) {
            if timeSinceDiaper > 7200 { // 2 hours
                suggestions.append("距離上次換尿布已超過2小時，建議檢查尿布")
            }
        }
        
        // 检查睡眠时间
        if let timeSinceSleep = getTimeSinceLastActivity(of: .sleep, for: babyId) {
            if timeSinceSleep > 14400 { // 4 hours
                suggestions.append("寶寶已經醒來超過4小時，可能需要休息")
            }
        }
        
        return suggestions
    }
    
    // MARK: - 导出活动数据
    func exportActivities(for babyId: UUID, period: StatisticsPeriod) -> Data? {
        let activitiesToExport = activities.filter { $0.babyId == babyId }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(activitiesToExport)
        } catch {
            errorMessage = "導出活動數據失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - 搜索活动
    func searchActivities(query: String, type: ActivityType? = nil) -> [ActivityRecord] {
        var filteredActivities = activities
        
        if let type = type {
            filteredActivities = filteredActivities.filter { $0.type == type }
        }
        
        if !query.isEmpty {
            filteredActivities = filteredActivities.filter { activity in
                activity.notes?.localizedCaseInsensitiveContains(query) == true ||
                activity.type.displayName.localizedCaseInsensitiveContains(query)
            }
        }
        
        return filteredActivities
    }
    
    // MARK: - 清除错误消息
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - 获取活动摘要
    func getActivitySummary(for date: Date, babyId: UUID) -> [ActivityType: Int] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dayActivities = activities.filter { activity in
            activity.babyId == babyId &&
            activity.startTime >= startOfDay &&
            activity.startTime < endOfDay
        }
        
        var summary: [ActivityType: Int] = [:]
        for activity in dayActivities {
            summary[activity.type, default: 0] += 1
        }
        
        return summary
    }
} 