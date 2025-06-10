import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: AppSettings
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "AppSettings"
    
    init() {
        self.settings = Self.loadSettings()
    }
    
    // MARK: - 加载设置
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "AppSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings() // 返回默认设置
        }
        return settings
    }
    
    // MARK: - 保存设置
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            userDefaults.synchronize()
        } catch {
            errorMessage = "保存設置失敗: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 通知设置
    func updateNotificationSettings(_ notificationSettings: NotificationSettings) {
        settings.notifications = notificationSettings
        saveSettings()
    }
    
    func enableNotifications(_ enabled: Bool) {
        settings.notifications.enabled = enabled
        saveSettings()
    }
    
    func setFeedingReminders(_ enabled: Bool) {
        settings.notifications.feedingReminders = enabled
        saveSettings()
    }
    
    func setSleepReminders(_ enabled: Bool) {
        settings.notifications.sleepReminders = enabled
        saveSettings()
    }
    
    func setMedicineReminders(_ enabled: Bool) {
        settings.notifications.medicineReminders = enabled
        saveSettings()
    }
    
    func setMilestoneAlerts(_ enabled: Bool) {
        settings.notifications.milestoneAlerts = enabled
        saveSettings()
    }
    
    func setQuietHours(_ interval: DateInterval?) {
        settings.notifications.quietHours = interval
        saveSettings()
    }
    
    // MARK: - 隐私设置
    func updatePrivacySettings(_ privacySettings: PrivacySettings) {
        settings.privacy = privacySettings
        saveSettings()
    }
    
    func enableAppLock(_ enabled: Bool) {
        settings.privacy.appLockEnabled = enabled
        saveSettings()
    }
    
    func enableBiometric(_ enabled: Bool) {
        settings.privacy.biometricEnabled = enabled
        saveSettings()
    }
    
    func setAutoLockTimeout(_ timeout: TimeInterval) {
        settings.privacy.autoLockTimeout = timeout
        saveSettings()
    }
    
    func setShareAnalytics(_ enabled: Bool) {
        settings.privacy.shareAnalytics = enabled
        saveSettings()
    }
    
    func setShareWithFamily(_ enabled: Bool) {
        settings.privacy.shareWithFamily = enabled
        saveSettings()
    }
    
    // MARK: - 同步设置
    func updateSyncSettings(_ syncSettings: SyncSettings) {
        settings.sync = syncSettings
        saveSettings()
    }
    
    func enableiCloudSync(_ enabled: Bool) {
        settings.sync.iCloudEnabled = enabled
        saveSettings()
    }
    
    func enableDropboxSync(_ enabled: Bool) {
        settings.sync.dropboxEnabled = enabled
        saveSettings()
    }
    
    func enableAutoSync(_ enabled: Bool) {
        settings.sync.autoSync = enabled
        saveSettings()
    }
    
    func setSyncOnWiFiOnly(_ enabled: Bool) {
        settings.sync.syncOnWiFiOnly = enabled
        saveSettings()
    }
    
    func updateLastSyncDate(_ date: Date) {
        settings.sync.lastSyncDate = date
        saveSettings()
    }
    
    // MARK: - 显示设置
    func updateDisplaySettings(_ displaySettings: DisplaySettings) {
        settings.display = displaySettings
        saveSettings()
    }
    
    func setTheme(_ theme: AppTheme) {
        settings.display.theme = theme
        saveSettings()
    }
    
    func setLanguage(_ language: String) {
        settings.display.language = language
        saveSettings()
    }
    
    func setDateFormat(_ format: String) {
        settings.display.dateFormat = format
        saveSettings()
    }
    
    func setTimeFormat(_ format: String) {
        settings.display.timeFormat = format
        saveSettings()
    }
    
    func updateUnitSettings(_ unitSettings: UnitSettings) {
        settings.display.units = unitSettings
        saveSettings()
    }
    
    func setWeightUnit(_ unit: WeightUnit) {
        settings.display.units.weight = unit
        saveSettings()
    }
    
    func setHeightUnit(_ unit: HeightUnit) {
        settings.display.units.height = unit
        saveSettings()
    }
    
    func setTemperatureUnit(_ unit: TemperatureUnit) {
        settings.display.units.temperature = unit
        saveSettings()
    }
    
    func setVolumeUnit(_ unit: VolumeUnit) {
        settings.display.units.volume = unit
        saveSettings()
    }
    
    // MARK: - AI设置
    func updateAISettings(_ aiSettings: AISettings) {
        settings.ai = aiSettings
        saveSettings()
    }
    
    func enableAnalysis(_ enabled: Bool) {
        settings.ai.analysisEnabled = enabled
        saveSettings()
    }
    
    func enableAutoAnalysis(_ enabled: Bool) {
        settings.ai.autoAnalysis = enabled
        saveSettings()
    }
    
    func updateAnalysisQuota(_ quota: Int) {
        settings.ai.analysisQuota = quota
        saveSettings()
    }
    
    func incrementUsedQuota() {
        settings.ai.usedQuota += 1
        saveSettings()
    }
    
    func resetQuota() {
        settings.ai.usedQuota = 0
        settings.ai.quotaResetDate = Date()
        saveSettings()
    }
    
    // MARK: - 获取格式化的设置值
    func getFormattedWeight(_ weight: Double) -> String {
        switch settings.display.units.weight {
        case .kg:
            return String(format: "%.1f kg", weight)
        case .lb:
            let pounds = weight * 2.20462
            return String(format: "%.1f lb", pounds)
        }
    }
    
    func getFormattedHeight(_ height: Double) -> String {
        switch settings.display.units.height {
        case .cm:
            return String(format: "%.1f cm", height)
        case .inch:
            let inches = height / 2.54
            return String(format: "%.1f in", inches)
        }
    }
    
    func getFormattedTemperature(_ temperature: Double) -> String {
        switch settings.display.units.temperature {
        case .celsius:
            return String(format: "%.1f°C", temperature)
        case .fahrenheit:
            let fahrenheit = temperature * 9/5 + 32
            return String(format: "%.1f°F", fahrenheit)
        }
    }
    
    func getFormattedVolume(_ volume: Double) -> String {
        switch settings.display.units.volume {
        case .ml:
            return String(format: "%.0f ml", volume)
        case .oz:
            let ounces = volume / 29.5735
            return String(format: "%.1f oz", ounces)
        }
    }
    
    func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.display.dateFormat
        return formatter.string(from: date)
    }
    
    func getFormattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.display.timeFormat
        return formatter.string(from: date)
    }
    
    // MARK: - 重置设置
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }
    
    func resetNotificationSettings() {
        settings.notifications = NotificationSettings()
        saveSettings()
    }
    
    func resetPrivacySettings() {
        settings.privacy = PrivacySettings()
        saveSettings()
    }
    
    func resetSyncSettings() {
        settings.sync = SyncSettings()
        saveSettings()
    }
    
    func resetDisplaySettings() {
        settings.display = DisplaySettings()
        saveSettings()
    }
    
    func resetAISettings() {
        settings.ai = AISettings()
        saveSettings()
    }
    
    // MARK: - 导入/导出设置
    func exportSettings() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(settings)
        } catch {
            errorMessage = "導出設置失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importSettings(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedSettings = try decoder.decode(AppSettings.self, from: data)
            settings = importedSettings
            saveSettings()
            return true
        } catch {
            errorMessage = "導入設置失敗: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - 验证设置
    func validateSettings() -> [String] {
        var errors: [String] = []
        
        if settings.privacy.autoLockTimeout < 60 {
            errors.append("自動鎖定時間不能少於1分鐘")
        }
        
        if settings.ai.analysisQuota < 0 {
            errors.append("分析配額不能為負數")
        }
        
        if settings.ai.usedQuota > settings.ai.analysisQuota {
            errors.append("已使用配額不能超過總配額")
        }
        
        return errors
    }
    
    // MARK: - 获取可用的分析次数
    func getAvailableAnalysisCount() -> Int {
        return max(0, settings.ai.analysisQuota - settings.ai.usedQuota)
    }
    
    // MARK: - 检查是否需要重置配额
    func checkQuotaReset() {
        let calendar = Calendar.current
        let now = Date()
        
        if !calendar.isDate(settings.ai.quotaResetDate, inSameDayAs: now) {
            resetQuota()
        }
    }
    
    // MARK: - 清除错误消息
    func clearError() {
        errorMessage = nil
    }
} 