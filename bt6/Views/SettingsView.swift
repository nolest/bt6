import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var gaiAnalysisManager: GAIAnalysisManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingExportData = false
    @State private var showingImportData = false
    @State private var showingBabyProfile = false
    
    var body: some View {
        NavigationView {
            List {
                babyProfileSection
                notificationSection
                privacySection
                syncSection
                
                // 显示设置
                Section("顯示設置") {
                    Picker("主題", selection: $settingsManager.settings.display.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    
                    Picker("單位制", selection: Binding<UnitSystem>(
                        get: { 
                            return UnitSystem.metric
                        },
                        set: { (unitSystem: UnitSystem) in
                            switch unitSystem {
                            case .metric:
                                settingsManager.settings.display.units.weight = .kg
                                settingsManager.settings.display.units.height = .cm
                            case .imperial:
                                settingsManager.settings.display.units.weight = .lb
                                settingsManager.settings.display.units.height = .inch
                            }
                        }
                    )) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    
                    Picker("語言", selection: Binding<AppLanguage>(
                        get: { 
                            AppLanguage(rawValue: settingsManager.settings.display.language) ?? .chinese
                        },
                        set: { (language: AppLanguage) in
                            settingsManager.settings.display.language = language.rawValue
                        }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
                
                dataManagementSection
                aboutSection
            }
            .navigationTitle("設置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("這將刪除所有寶寶數據，此操作無法復原。")
            }
            .sheet(isPresented: $showingBabyProfile) {
                if let baby = babyManager.selectedBaby {
                    EditBabyView(baby: baby)
                }
            }
            .sheet(isPresented: $showingExportData) {
                DataExportView()
            }
            .sheet(isPresented: $showingImportData) {
                DataImportView()
            }
        }
    }
    
    private var babyProfileSection: some View {
        Group {
            Section(header: Text("寶寶資料")) {
                NavigationLink(destination: BabyProfileView()) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.blue)
                        Text("管理寶寶資料")
                    }
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Group {
            Section(header: Text("通知設置")) {
                Toggle(isOn: $settingsManager.settings.notifications.enabled) {
                    HStack {
                        Image(systemName: "bell")
                        Text("推送通知")
                    }
                }
                
                if settingsManager.settings.notifications.enabled {
                    Toggle(isOn: $settingsManager.settings.notifications.feedingReminders) {
                        HStack {
                            Image(systemName: "drop")
                            Text("餵食提醒")
                        }
                    }
                    
                    Toggle(isOn: $settingsManager.settings.notifications.sleepReminders) {
                        HStack {
                            Image(systemName: "moon")
                            Text("睡眠提醒")
                        }
                    }
                    
                    Toggle(isOn: $settingsManager.settings.notifications.milestoneAlerts) {
                        HStack {
                            Image(systemName: "star")
                            Text("里程碑通知")
                        }
                    }
                    
                    Toggle(isOn: $settingsManager.settings.notifications.medicineReminders) {
                        HStack {
                            Image(systemName: "pill")
                            Text("藥物提醒")
                        }
                    }
                }
            }
        }
    }
    
    private var privacySection: some View {
        Group {
            Section(header: Text("隱私與安全")) {
                Toggle(isOn: $settingsManager.settings.ai.analysisEnabled) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading) {
                            Text("雲端智能分析")
                            Text("使用AI分析寶寶照片和影片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if settingsManager.settings.ai.analysisEnabled {
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("分析配額")
                            Text("本月已使用 \(settingsManager.settings.ai.usedQuota)/\(settingsManager.settings.ai.analysisQuota)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(settingsManager.settings.ai.analysisQuota - settingsManager.settings.ai.usedQuota)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $settingsManager.settings.privacy.biometricEnabled) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(.red)
                        Text("生物識別鎖定")
                    }
                }
                
                Toggle(isOn: $settingsManager.settings.privacy.shareAnalytics) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("分享使用統計")
                            Text("幫助改善應用體驗")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var syncSection: some View {
        Group {
            Section(header: Text("數據同步")) {
                Toggle(isOn: $settingsManager.settings.sync.iCloudEnabled) {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                        Text("iCloud 同步")
                    }
                }
                
                Toggle(isOn: $settingsManager.settings.sync.dropboxEnabled) {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.blue)
                        Text("Dropbox 備份")
                    }
                }
                
                if settingsManager.settings.sync.iCloudEnabled || settingsManager.settings.sync.dropboxEnabled {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        Text("上次同步")
                        Spacer()
                        Text(settingsManager.settings.sync.lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "從未")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        Group {
            Section(header: Text("數據管理")) {
                Button(action: {
                    showingExportData = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("導出數據")
                    }
                }
                
                Button(action: {
                    showingImportData = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                        Text("導入數據")
                    }
                }
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("清除所有數據")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Group {
            Section(header: Text("關於")) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.purple)
                        Text("隱私政策")
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        Text("服務條款")
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "mailto:support@babycare.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.orange)
                        Text("聯繫我們")
                    }
                }
            }
        }
    }
    
    private func deleteAllData() {
        Task {
            // 清除所有数据的逻辑
            // 删除所有宝宝
            for baby in babyManager.babies {
                try? babyManager.deleteBaby(baby)
            }
            
            // 清除其他数据...
        }
    }
}

// MARK: - Supporting Views

struct BabyProfileView: View {
    @EnvironmentObject var babyManager: BabyManager
    
    var body: some View {
        List {
            ForEach(babyManager.babies) { baby in
                NavigationLink(destination: EditBabyView(baby: baby)) {
                    HStack {
                        AsyncImage(url: URL(string: baby.profileImagePath ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(baby.name)
                                .font(.headline)
                            Text("出生日期: \(baby.birthDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("寶寶資料")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditBabyView: View {
    let baby: Baby
    @EnvironmentObject var babyManager: BabyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: String
    
    init(baby: Baby) {
        self.baby = baby
        self._name = State(initialValue: baby.name)
        self._birthDate = State(initialValue: baby.birthDate)
        self._gender = State(initialValue: baby.gender.rawValue)
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("姓名", text: $name)
                DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                Picker("性別", selection: $gender) {
                    Text("男").tag("male")
                    Text("女").tag("female")
                }
            }
        }
        .navigationTitle("編輯資料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveBaby()
                }
            }
        }
    }
    
    private func saveBaby() {
        Task {
            var updatedBaby = baby
            updatedBaby.name = name
            updatedBaby.birthDate = birthDate
            updatedBaby.gender = Gender(rawValue: gender) ?? .other
            
            try? babyManager.updateBaby(updatedBaby)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct FamilyMembersView: View {
    var body: some View {
        List {
            Text("家庭成員功能開發中...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("家庭成員")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("數據導出功能開發中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("導出數據")
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
}

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("數據導入功能開發中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("導入數據")
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
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隱私政策")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("我們重視您的隱私，致力於保護您和寶寶的個人信息...")
                    .font(.body)
                
                // 更多隐私政策内容
            }
            .padding()
        }
        .navigationTitle("隱私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("服務條款")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("歡迎使用智能寶寶生活記錄應用...")
                    .font(.body)
                
                // 更多服务条款内容
            }
            .padding()
        }
        .navigationTitle("服務條款")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Types

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "公制"
        case .imperial: return "英制"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case chinese = "zh-Hant"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "English"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(BabyManager())
        .environmentObject(GAIAnalysisManager())
} 