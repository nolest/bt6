import SwiftUI
import Charts

struct HealthRecordView: View {
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var activityManager: ActivityManager
    @State private var selectedHealthType: HealthRecordType = .temperature
    @State private var showingAddRecord = false
    @State private var healthRecords: [HealthRecord] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if healthRecords.isEmpty {
                    EmptyHealthRecordView()
                } else {
                    HealthRecordContentView(
                        records: healthRecords,
                        selectedType: $selectedHealthType
                    )
                }
            }
            .navigationTitle("健康記錄")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRecord = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddHealthRecordView()
            }
            .onAppear {
                loadHealthRecords()
            }
        }
    }
    
    private func loadHealthRecords() {
        guard let currentBaby = babyManager.currentBaby else { return }
        
        // 从ActivityManager获取健康记录
        let healthActivities = activityManager.activities.filter { activity in
            activity.babyId == currentBaby.id && 
            (activity.type == .temperature || activity.type == .weight || activity.type == .height)
        }
        
        // 转换为HealthRecord对象
        healthRecords = healthActivities.compactMap { activity in
            let type: HealthRecordType
            let value: Double
            
            switch activity.type {
            case .temperature, .weight, .height:
                // 从details中提取健康信息
                if case .health(let healthDetails) = activity.details {
                    switch activity.type {
                    case .temperature:
                        type = .temperature
                        value = healthDetails.value
                    case .weight:
                        type = .weight
                        value = healthDetails.value
                    case .height:
                        type = .height
                        value = healthDetails.value
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            default:
                return nil
            }
            
            return HealthRecord(
                id: activity.id.uuidString,
                babyId: activity.babyId.uuidString,
                type: type,
                value: value,
                unit: type.defaultUnit,
                recordedAt: activity.startTime,
                notes: activity.notes
            )
        }
    }
}

struct EmptyHealthRecordView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("還沒有健康記錄")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("開始記錄寶寶的體溫、體重、身高等健康信息")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct HealthRecordContentView: View {
    let records: [HealthRecord]
    @Binding var selectedType: HealthRecordType
    
    var filteredRecords: [HealthRecord] {
        records.filter { $0.type == selectedType }
            .sorted { $0.recordedAt > $1.recordedAt }
    }
    
    var body: some View {
        VStack {
            // 类型选择器
            HealthTypeSelector(selectedType: $selectedType)
            
            if filteredRecords.isEmpty {
                EmptyTypeRecordView(type: selectedType)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 图表视图
                        HealthChartView(records: filteredRecords, type: selectedType)
                        
                        // 记录列表
                        HealthRecordListView(records: filteredRecords)
                    }
                    .padding()
                }
            }
        }
    }
}

struct HealthTypeSelector: View {
    @Binding var selectedType: HealthRecordType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HealthRecordType.allCases, id: \.self) { type in
                    HealthTypeChip(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct HealthTypeChip: View {
    let type: HealthRecordType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.caption)
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? type.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct HealthChartView: View {
    let records: [HealthRecord]
    let type: HealthRecordType
    
    var chartData: [HealthChartData] {
        records.suffix(10).map { record in
            HealthChartData(
                date: record.recordedAt,
                value: record.value
            )
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(type.displayName)趨勢")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let latestRecord = records.first {
                    VStack(alignment: .trailing) {
                        Text("\(latestRecord.value, specifier: "%.1f") \(latestRecord.unit)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(type.color)
                        
                        Text("最新記錄")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if chartData.count >= 2 {
                Chart(chartData) { data in
                    LineMark(
                        x: .value("日期", data.date),
                        y: .value(type.displayName, data.value)
                    )
                    .foregroundStyle(type.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("日期", data.date),
                        y: .value(type.displayName, data.value)
                    )
                    .foregroundStyle(type.color)
                    .symbolSize(30)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("需要至少2個記錄才能顯示趨勢圖")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HealthRecordListView: View {
    let records: [HealthRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記錄歷史")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 8) {
                ForEach(records) { record in
                    HealthRecordRowView(record: record)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct HealthRecordRowView: View {
    let record: HealthRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.iconName)
                .font(.title3)
                .foregroundColor(record.type.color)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(record.value, specifier: "%.1f") \(record.unit)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(record.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyTypeRecordView: View {
    let type: HealthRecordType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type.iconName)
                .font(.system(size: 60))
                .foregroundColor(type.color)
            
            Text("還沒有\(type.displayName)記錄")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("點擊右上角的 + 號開始記錄")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AddHealthRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var activityManager: ActivityManager
    
    @State private var selectedType: HealthRecordType = .temperature
    @State private var value: String = ""
    @State private var recordedAt = Date()
    @State private var notes = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("記錄類型")) {
                    Picker("類型", selection: $selectedType) {
                        ForEach(HealthRecordType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("數值")) {
                    HStack {
                        TextField("輸入數值", text: $value)
                            .keyboardType(.decimalPad)
                        
                        Text(selectedType.defaultUnit)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(selectedType.inputHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("記錄時間")) {
                    DatePicker("時間", selection: $recordedAt, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("備註")) {
                    TextField("可選備註", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新增健康記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveHealthRecord()
                    }
                    .disabled(value.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveHealthRecord() {
        guard let currentBaby = babyManager.currentBaby,
              let numericValue = Double(value) else { return }
        
        isSaving = true
        
        Task {
            do {
                let activityType: ActivityType
                var details: [String: Any] = [:]
                
                switch selectedType {
                case .temperature:
                    activityType = .temperature
                    details["temperature"] = numericValue
                case .weight:
                    activityType = .weight
                    details["weight"] = numericValue
                case .height:
                    activityType = .height
                    details["height"] = numericValue
                }
                
                let activity = ActivityRecord(
                    babyId: currentBaby.id,
                    type: activityType,
                    startTime: recordedAt,
                    endTime: nil,
                    details: ActivityDetails.health(HealthDetails(
                        type: selectedType.rawValue,
                        value: numericValue,
                        unit: selectedType.defaultUnit
                    )),
                    notes: notes.isEmpty ? nil : notes,
                    createdBy: UUID() // 临时使用随机UUID，实际应该是当前用户ID
                )
                
                try await activityManager.addActivity(activity)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum HealthRecordType: String, CaseIterable, Codable {
    case temperature = "temperature"
    case weight = "weight"
    case height = "height"
    
    var displayName: String {
        switch self {
        case .temperature: return "體溫"
        case .weight: return "體重"
        case .height: return "身高"
        }
    }
    
    var iconName: String {
        switch self {
        case .temperature: return "thermometer"
        case .weight: return "scalemass"
        case .height: return "ruler"
        }
    }
    
    var color: Color {
        switch self {
        case .temperature: return .red
        case .weight: return .blue
        case .height: return .green
        }
    }
    
    var defaultUnit: String {
        switch self {
        case .temperature: return "°C"
        case .weight: return "kg"
        case .height: return "cm"
        }
    }
    
    var inputHint: String {
        switch self {
        case .temperature: return "正常範圍：36.0-37.5°C"
        case .weight: return "請輸入準確的體重數值"
        case .height: return "請輸入準確的身高數值"
        }
    }
}

struct HealthRecord: Identifiable, Codable {
    let id: String
    let babyId: String
    let type: HealthRecordType
    let value: Double
    let unit: String
    let recordedAt: Date
    let notes: String?
}

struct HealthChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    HealthRecordView()
        .environmentObject(BabyManager())
        .environmentObject(ActivityManager())
} 