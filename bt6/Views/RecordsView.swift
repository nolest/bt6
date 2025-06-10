import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var babyManager: BabyManager
    @State private var selectedDate = Date()
    @State private var showingAddActivity = false
    @State private var selectedActivityType: ActivityType?
    
    private let activityTypes: [ActivityType] = [
        .feeding, .diaper, .sleep, .bath,
        .weight, .height, .medicine, .temperature
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日期选择器
                DatePicker("選擇日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                
                Divider()
                
                // 活动类型网格
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(activityTypes, id: \.self) { activityType in
                            ActivityTypeCard(
                                activityType: activityType,
                                date: selectedDate
                            ) {
                                selectedActivityType = activityType
                                showingAddActivity = true
                            }
                        }
                        
                        // 自定义记录卡片
                        CustomRecordCard {
                            selectedActivityType = .custom
                            showingAddActivity = true
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("記錄")
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingAddActivity) {
            if let activityType = selectedActivityType,
               let baby = babyManager.selectedBaby {
                AddActivityView(
                    baby: baby,
                    activityType: activityType,
                    selectedDate: selectedDate
                )
            }
        }
    }
}

// MARK: - 活动类型卡片
struct ActivityTypeCard: View {
    let activityType: ActivityType
    let date: Date
    let action: () -> Void
    @EnvironmentObject var activityManager: ActivityManager
    @EnvironmentObject var babyManager: BabyManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 图标和标题
                VStack(spacing: 8) {
                    Text(activityType.icon)
                        .font(.system(size: 40))
                    
                    Text(activityType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // 今日统计
                if let baby = babyManager.selectedBaby {
                    let todayCount = getTodayCount(for: activityType, baby: baby)
                    
                    VStack(spacing: 4) {
                        Text("今日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(todayCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(activityType.color)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getTodayCount(for type: ActivityType, baby: Baby) -> Int {
        let summary = activityManager.getActivitySummary(for: date, babyId: baby.id)
        return summary[type] ?? 0
    }
}

// MARK: - 自定义记录卡片
struct CustomRecordCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Custom Record")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("添加自定義記錄")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RecordsView()
        .environmentObject(BabyManager())
        .environmentObject(ActivityManager())
} 