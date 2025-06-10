import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isNotificationsEnabled = false
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
        setupNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)
        
        await MainActor.run {
            self.authorizationStatus = granted ? .authorized : .denied
            self.isNotificationsEnabled = granted
        }
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Feeding Reminders
    
    func scheduleFeedingReminder(for babyId: String, interval: TimeInterval) async throws {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "餵食提醒"
        content.body = "該給寶寶餵食了"
        content.sound = .default
        content.categoryIdentifier = "FEEDING_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(
            identifier: "feeding_reminder_\(babyId)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    func cancelFeedingReminder(for babyId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["feeding_reminder_\(babyId)"])
    }
    
    // MARK: - Sleep Reminders
    
    func scheduleSleepReminder(for babyId: String, at time: DateComponents) async throws {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "睡眠提醒"
        content.body = "該讓寶寶準備睡覺了"
        content.sound = .default
        content.categoryIdentifier = "SLEEP_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "sleep_reminder_\(babyId)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    func cancelSleepReminder(for babyId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["sleep_reminder_\(babyId)"])
    }
    
    // MARK: - Diaper Change Reminders
    
    func scheduleDiaperReminder(for babyId: String, interval: TimeInterval) async throws {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "換尿布提醒"
        content.body = "該檢查寶寶的尿布了"
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(
            identifier: "diaper_reminder_\(babyId)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    func cancelDiaperReminder(for babyId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["diaper_reminder_\(babyId)"])
    }
    
    // MARK: - Medicine Reminders
    
    func scheduleMedicineReminder(
        for babyId: String,
        medicineName: String,
        at time: DateComponents,
        repeatDays: [Int] = []
    ) async throws {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "用藥提醒"
        content.body = "該給寶寶服用 \(medicineName) 了"
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"
        content.userInfo = ["medicine_name": medicineName, "baby_id": babyId]
        
        if repeatDays.isEmpty {
            // 单次提醒
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
            let request = UNNotificationRequest(
                identifier: "medicine_\(babyId)_\(medicineName)_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        } else {
            // 重复提醒
            for day in repeatDays {
                var timeWithDay = time
                timeWithDay.weekday = day
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: timeWithDay, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "medicine_\(babyId)_\(medicineName)_day\(day)",
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
        }
    }
    
    func cancelMedicineReminder(for babyId: String, medicineName: String) {
        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains("medicine_\(babyId)_\(medicineName)") }
                .map { $0.identifier }
            
            self.center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // MARK: - Growth Milestone Notifications
    
    func scheduleGrowthMilestoneCheck(for babyId: String, ageInMonths: Int) async throws {
        guard isNotificationsEnabled else { return }
        
        let milestones = getExpectedMilestones(for: ageInMonths)
        
        for milestone in milestones {
            let content = UNMutableNotificationContent()
            content.title = "成長里程碑提醒"
            content.body = "寶寶現在 \(ageInMonths) 個月大了，可以檢查是否達到：\(milestone)"
            content.sound = .default
            content.categoryIdentifier = "MILESTONE_CHECK"
            
            // 在宝宝达到特定月龄时提醒
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "milestone_\(babyId)_\(ageInMonths)months",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        }
    }
    
    private func getExpectedMilestones(for ageInMonths: Int) -> [String] {
        switch ageInMonths {
        case 1:
            return ["抬頭", "對聲音有反應", "眼睛能追蹤物體"]
        case 2:
            return ["社交性微笑", "發出咕咕聲", "短暫抬頭"]
        case 3:
            return ["俯臥時能抬頭45度", "握拳開始鬆開", "對熟悉的聲音有反應"]
        case 4:
            return ["翻身", "抓握玩具", "笑出聲"]
        case 6:
            return ["獨立坐立", "開始吃固體食物", "認識熟悉的面孔"]
        case 9:
            return ["爬行", "用手指抓取小物品", "說簡單的詞語"]
        case 12:
            return ["獨立行走", "說第一個詞", "用杯子喝水"]
        default:
            return []
        }
    }
    
    // MARK: - Smart Suggestions
    
    func scheduleSmartSuggestion(title: String, body: String, delay: TimeInterval = 3600) async throws {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SMART_SUGGESTION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "smart_suggestion_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    // MARK: - Notification Management
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }
    
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
    
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let feedingAction = UNNotificationAction(
            identifier: "FEEDING_DONE",
            title: "已餵食",
            options: []
        )
        
        let feedingCategory = UNNotificationCategory(
            identifier: "FEEDING_REMINDER",
            actions: [feedingAction],
            intentIdentifiers: [],
            options: []
        )
        
        let sleepAction = UNNotificationAction(
            identifier: "SLEEP_DONE",
            title: "已入睡",
            options: []
        )
        
        let sleepCategory = UNNotificationCategory(
            identifier: "SLEEP_REMINDER",
            actions: [sleepAction],
            intentIdentifiers: [],
            options: []
        )
        
        let diaperAction = UNNotificationAction(
            identifier: "DIAPER_CHANGED",
            title: "已更換",
            options: []
        )
        
        let diaperCategory = UNNotificationCategory(
            identifier: "DIAPER_REMINDER",
            actions: [diaperAction],
            intentIdentifiers: [],
            options: []
        )
        
        let medicineAction = UNNotificationAction(
            identifier: "MEDICINE_TAKEN",
            title: "已服用",
            options: []
        )
        
        let medicineCategory = UNNotificationCategory(
            identifier: "MEDICINE_REMINDER",
            actions: [medicineAction],
            intentIdentifiers: [],
            options: []
        )
        
        let milestoneAction = UNNotificationAction(
            identifier: "MILESTONE_CHECKED",
            title: "已檢查",
            options: []
        )
        
        let milestoneCategory = UNNotificationCategory(
            identifier: "MILESTONE_CHECK",
            actions: [milestoneAction],
            intentIdentifiers: [],
            options: []
        )
        
        let smartSuggestionAction = UNNotificationAction(
            identifier: "SUGGESTION_VIEWED",
            title: "查看",
            options: [.foreground]
        )
        
        let smartSuggestionCategory = UNNotificationCategory(
            identifier: "SMART_SUGGESTION",
            actions: [smartSuggestionAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([
            feedingCategory,
            sleepCategory,
            diaperCategory,
            medicineCategory,
            milestoneCategory,
            smartSuggestionCategory
        ])
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - Notification Response Handling

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        let notification = response.notification
        
        Task { @MainActor in
            switch identifier {
            case "FEEDING_DONE":
                handleFeedingDone(notification: notification)
            case "SLEEP_DONE":
                handleSleepDone(notification: notification)
            case "DIAPER_CHANGED":
                handleDiaperChanged(notification: notification)
            case "MEDICINE_TAKEN":
                handleMedicineTaken(notification: notification)
            case "MILESTONE_CHECKED":
                handleMilestoneChecked(notification: notification)
            case "SUGGESTION_VIEWED":
                handleSuggestionViewed(notification: notification)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在应用前台时也显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    private func handleFeedingDone(notification: UNNotification) {
        // 自动记录喂食活动
        Task {
            // 这里可以调用ActivityManager来自动记录喂食
        }
    }
    
    private func handleSleepDone(notification: UNNotification) {
        // 自动记录睡眠活动
        Task {
            // 这里可以调用ActivityManager来自动记录睡眠
        }
    }
    
    private func handleDiaperChanged(notification: UNNotification) {
        // 自动记录换尿布活动
        Task {
            // 这里可以调用ActivityManager来自动记录换尿布
        }
    }
    
    private func handleMedicineTaken(notification: UNNotification) {
        // 自动记录用药活动
        Task {
            // 这里可以调用ActivityManager来自动记录用药
        }
    }
    
    private func handleMilestoneChecked(notification: UNNotification) {
        // 打开里程碑检查界面
        Task {
            // 这里可以导航到里程碑界面
        }
    }
    
    private func handleSuggestionViewed(notification: UNNotification) {
        // 打开智能建议界面
        Task {
            // 这里可以导航到智能助理界面
        }
    }
} 