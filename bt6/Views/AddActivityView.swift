import SwiftUI

struct AddActivityView: View {
    let baby: Baby
    let activityType: ActivityType
    let selectedDate: Date
    let preselectedType: ActivityType?
    
    init(baby: Baby, activityType: ActivityType = .feeding, selectedDate: Date = Date(), preselectedType: ActivityType? = nil) {
        self.baby = baby
        self.activityType = preselectedType ?? activityType
        self.selectedDate = selectedDate
        self.preselectedType = preselectedType
    }
    
    @EnvironmentObject var activityManager: ActivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var hasEndTime = false
    @State private var notes = ""
    
    // 餵食相关
    @State private var feedingType = FeedingType.bottle
    @State private var feedingAmount = ""
    @State private var breastSide = BreastSide.left
    @State private var feedingDuration = ""
    
    // 尿布相关
    @State private var diaperType = DiaperType.wet
    @State private var diaperCondition = DiaperCondition.normal
    
    // 睡眠相关
    @State private var sleepQuality = SleepQuality.good
    @State private var sleepLocation = ""
    
    // 洗澡相关
    @State private var bathTemperature = ""
    @State private var bathDuration = ""
    @State private var bathProducts = ""
    
    // 用药相关
    @State private var medicineName = ""
    @State private var medicineDosage = ""
    @State private var medicineUnit = "ml"
    @State private var medicineReason = ""
    
    // 测量相关
    @State private var measurementValue = ""
    @State private var measurementUnit = ""
    
    // 自定义相关
    @State private var customTitle = ""
    @State private var customDescription = ""
    @State private var customValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section("基本信息") {
                    HStack {
                        Text(activityType.icon)
                            .font(.title2)
                        Text(activityType.displayName)
                            .font(.headline)
                        Spacer()
                    }
                    
                    DatePicker("開始時間", selection: $startTime)
                    
                    Toggle("設置結束時間", isOn: $hasEndTime)
                    
                    if hasEndTime {
                        DatePicker("結束時間", selection: $endTime)
                    }
                }
                
                // 活动特定信息
                activitySpecificSection
                
                // 备注
                Section("備註") {
                    TextField("添加備註（可選）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveActivity()
                        }
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    @ViewBuilder
    private var activitySpecificSection: some View {
        switch activityType {
        case .feeding:
            feedingSection
        case .diaper:
            diaperSection
        case .sleep:
            sleepSection
        case .bath:
            bathSection
        case .medicine:
            medicineSection
        case .weight, .height, .temperature:
            measurementSection
        case .custom:
            customSection
        default:
            EmptyView()
        }
    }
    
    private var feedingSection: some View {
        Section("餵食詳情") {
            Picker("餵食類型", selection: $feedingType) {
                ForEach(FeedingType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            if feedingType == .breast {
                Picker("餵食側", selection: $breastSide) {
                    ForEach(BreastSide.allCases, id: \.self) { side in
                        Text(side.displayName).tag(side)
                    }
                }
                
                HStack {
                    TextField("持續時間", text: $feedingDuration)
                        .keyboardType(.numberPad)
                    Text("分鐘")
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    TextField("餵食量", text: $feedingAmount)
                        .keyboardType(.decimalPad)
                    Text("ml")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var diaperSection: some View {
        Section("尿布詳情") {
            Picker("尿布類型", selection: $diaperType) {
                ForEach(DiaperType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            Picker("狀況", selection: $diaperCondition) {
                ForEach(DiaperCondition.allCases, id: \.self) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
        }
    }
    
    private var sleepSection: some View {
        Section("睡眠詳情") {
            Picker("睡眠品質", selection: $sleepQuality) {
                ForEach(SleepQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            
            TextField("睡眠地點（可選）", text: $sleepLocation)
        }
    }
    
    private var bathSection: some View {
        Section("洗澡詳情") {
            HStack {
                TextField("水溫", text: $bathTemperature)
                    .keyboardType(.decimalPad)
                Text("°C")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("持續時間", text: $bathDuration)
                    .keyboardType(.numberPad)
                Text("分鐘")
                    .foregroundColor(.secondary)
            }
            
            TextField("使用產品（可選）", text: $bathProducts)
        }
    }
    
    private var medicineSection: some View {
        Section("用藥詳情") {
            TextField("藥物名稱", text: $medicineName)
            
            HStack {
                TextField("劑量", text: $medicineDosage)
                    .keyboardType(.decimalPad)
                
                Picker("單位", selection: $medicineUnit) {
                    Text("ml").tag("ml")
                    Text("mg").tag("mg")
                    Text("顆").tag("顆")
                    Text("滴").tag("滴")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            TextField("用藥原因（可選）", text: $medicineReason)
        }
    }
    
    private var measurementSection: some View {
        Section("\(activityType.displayName)詳情") {
            HStack {
                TextField("數值", text: $measurementValue)
                    .keyboardType(.decimalPad)
                
                Text(getDefaultUnit())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var customSection: some View {
        Section("自定義記錄") {
            TextField("標題", text: $customTitle)
            
            TextField("描述（可選）", text: $customDescription, axis: .vertical)
                .lineLimit(2...4)
            
            TextField("數值（可選）", text: $customValue)
        }
    }
    
    private func setupInitialValues() {
        // 设置开始时间为选定日期的当前时间
        let calendar = Calendar.current
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: Date())
        
        var combinedComponents = selectedDateComponents
        combinedComponents.hour = currentTimeComponents.hour
        combinedComponents.minute = currentTimeComponents.minute
        
        if let combinedDate = calendar.date(from: combinedComponents) {
            startTime = combinedDate
            endTime = combinedDate.addingTimeInterval(1800) // 默认30分钟后
        }
        
        // 设置默认单位
        measurementUnit = getDefaultUnit()
    }
    
    private func getDefaultUnit() -> String {
        switch activityType {
        case .weight:
            return "kg"
        case .height:
            return "cm"
        case .temperature:
            return "°C"
        default:
            return ""
        }
    }
    
    private func saveActivity() async {
        let details = createActivityDetails()
        
        var duration: TimeInterval?
        if hasEndTime {
            duration = endTime.timeIntervalSince(startTime)
        }
        
        let activity = ActivityRecord(
            babyId: baby.id,
            type: activityType,
            startTime: startTime,
            endTime: hasEndTime ? endTime : nil,
            duration: duration,
            details: details,
            notes: notes.isEmpty ? nil : notes,
            createdBy: UUID() // 这里应该是当前用户ID
        )
        
        // 保存活动记录
        do {
            try await activityManager.addActivity(activity)
        } catch {
            print("保存活动失败: \\(error)")
        }
        
        dismiss()
    }
    
    private func createActivityDetails() -> ActivityDetails {
        switch activityType {
        case .feeding:
            return .feeding(FeedingDetails(
                type: feedingType,
                amount: Double(feedingAmount),
                side: feedingType == .breast ? breastSide : nil,
                duration: feedingType == .breast ? TimeInterval(Double(feedingDuration) ?? 0) * 60 : nil
            ))
            
        case .diaper:
            return .diaper(DiaperDetails(
                type: diaperType,
                condition: diaperCondition
            ))
            
        case .sleep:
            return .sleep(SleepDetails(
                quality: sleepQuality,
                location: sleepLocation.isEmpty ? nil : sleepLocation
            ))
            
        case .bath:
            return .bath(BathDetails(
                temperature: Double(bathTemperature),
                duration: TimeInterval(Double(bathDuration) ?? 0) * 60,
                products: bathProducts.isEmpty ? nil : [bathProducts]
            ))
            
        case .medicine:
            return .medicine(MedicineDetails(
                name: medicineName,
                dosage: medicineDosage.isEmpty ? nil : medicineDosage,
                unit: medicineUnit,
                reason: medicineReason.isEmpty ? nil : medicineReason
            ))
            
        case .weight, .height, .temperature:
            return .measurement(MeasurementDetails(
                value: Double(measurementValue) ?? 0,
                unit: measurementUnit
            ))
            
        case .custom:
            return .custom(CustomDetails(
                title: customTitle.isEmpty ? activityType.displayName : customTitle,
                description: customDescription.isEmpty ? nil : customDescription,
                value: customValue.isEmpty ? nil : customValue
            ))
            
        default:
            return .custom(CustomDetails(title: activityType.displayName))
        }
    }
}

#Preview {
    AddActivityView(
        baby: Baby(name: "Emma", birthDate: Date(), gender: .female)
    )
    .environmentObject(ActivityManager())
} 