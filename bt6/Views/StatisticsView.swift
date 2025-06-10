import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var activityManager: ActivityManager
    @EnvironmentObject var babyManager: BabyManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedActivityType: ActivityType? = nil
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 概览卡片
                    overviewCards
                    
                    // 活动类型选择器
                    activityTypeSelector
                    
                    // 图表区域
                    chartsSection
                    
                    // 趋势分析
                    trendsSection
                    
                    // 详细统计
                    detailsSection
                }
                .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            loadStatistics()
        }
        .onChange(of: selectedTimeRange) { oldValue, newValue in
            loadStatistics()
        }
    }
    
    private var timeRangeSelector: some View {
        Picker("時間範圍", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            OverviewCard(
                title: "總記錄",
                value: "\(activityManager.todayActivities.count)",
                icon: "doc.text.fill",
                color: .blue,
                trend: .up,
                trendValue: "12%"
            )
            
            OverviewCard(
                title: "今日餵食",
                value: "\(feedingCount)",
                icon: "bottle.fill",
                color: .green,
                trend: .stable,
                trendValue: "0%"
            )
            
            OverviewCard(
                title: "睡眠時間",
                value: "\(sleepHours)h",
                icon: "bed.double.fill",
                color: .purple,
                trend: .up,
                trendValue: "8%"
            )
            
            OverviewCard(
                title: "換尿布",
                value: "\(diaperCount)",
                icon: "tshirt.fill",
                color: .orange,
                trend: .down,
                trendValue: "5%"
            )
        }
    }
    
    private var activityTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活動類型")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActivityTypeButton(
                        type: nil,
                        isSelected: selectedActivityType == nil,
                        action: { selectedActivityType = nil }
                    )
                    
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        ActivityTypeButton(
                            type: type,
                            isSelected: selectedActivityType == type,
                            action: { selectedActivityType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("趨勢圖表")
                .font(.headline)
            
            VStack(spacing: 16) {
                // 活动频率图表
                ActivityFrequencyChart(
                    activities: filteredActivities,
                    timeRange: selectedTimeRange
                )
                
                // 时间分布图表
                if selectedActivityType != nil {
                    TimeDistributionChart(
                        activities: filteredActivities,
                        activityType: selectedActivityType!
                    )
                }
            }
        }
    }
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趨勢分析")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(trendAnalysis, id: \.id) { trend in
                    TrendCard(trend: trend)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("詳細統計")
                    .font(.headline)
                
                Spacer()
                
                Button("查看更多") {
                    showingDetailView = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(detailedStats, id: \.id) { stat in
                    DetailStatRow(stat: stat)
                }
            }
        }
        .sheet(isPresented: $showingDetailView) {
            DetailedStatisticsView(
                activities: filteredActivities,
                timeRange: selectedTimeRange
            )
        }
    }
    
    // MARK: - 计算属性
    
    private var filteredActivities: [ActivityRecord] {
        let activities = activityManager.getActivitiesInRange(
            from: selectedTimeRange.startDate,
            to: selectedTimeRange.endDate
        )
        
        if let selectedType = selectedActivityType {
            return activities.filter { $0.type == selectedType }
        }
        
        return activities
    }
    
    private var feedingCount: Int {
        activityManager.todayActivities.filter { $0.type == .feeding }.count
    }
    
    private var sleepHours: Int {
        let sleepActivities = activityManager.todayActivities.filter { $0.type == .sleep }
        let totalMinutes = sleepActivities.compactMap { $0.duration }.reduce(0, +) / 60
        return Int(totalMinutes)
    }
    
    private var diaperCount: Int {
        activityManager.todayActivities.filter { $0.type == .diaper }.count
    }
    
    private var trendAnalysis: [TrendAnalysis] {
        return activityManager.generateTrendAnalysis(
            for: selectedTimeRange,
            activityType: selectedActivityType
        )
    }
    
    private var detailedStats: [DetailedStat] {
        return activityManager.generateDetailedStats(
            for: selectedTimeRange,
            activityType: selectedActivityType
        )
    }
    
    // MARK: - 方法
    
    private func loadStatistics() {
        Task {
            await activityManager.loadStatistics(for: selectedTimeRange)
        }
    }
    
    private func refreshData() async {
        await activityManager.refreshStatistics()
    }
}

// MARK: - 概览卡片
struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    let trendValue: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                        .font(.caption)
                    
                    Text(trendValue)
                        .font(.caption)
                        .foregroundColor(trendColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up:
            return .green
        case .down:
            return .red
        case .stable:
            return .gray
        }
    }
}

// MARK: - 活动类型按钮
struct ActivityTypeButton: View {
    let type: ActivityType?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.caption)
                
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
    
    private var iconName: String {
        guard let type = type else { return "chart.bar.fill" }
        
        return self.iconName(for: type)
    }
    
    private func iconName(for type: ActivityType) -> String {
        switch type {
        case .feeding:
            return "drop.fill"
        case .sleep:
            return "moon.fill"
        case .diaper:
            return "tshirt.fill"
        case .bath:
            return "drop.fill"
        case .medicine:
            return "pills.fill"
        case .temperature:
            return "thermometer"
        case .weight:
            return "scalemass"
        case .height:
            return "ruler"
        case .milestone:
            return "star.fill"
        case .custom:
            return "circle.fill"
        }
    }
    
    private var displayName: String {
        type?.displayName ?? "全部"
    }
}

// MARK: - 活动频率图表
struct ActivityFrequencyChart: View {
    let activities: [ActivityRecord]
    let timeRange: TimeRange
    
    var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        switch timeRange {
        case .day:
            dateFormatter.dateFormat = "HH:mm"
            return generateHourlyData()
        case .week:
            dateFormatter.dateFormat = "E"
            return generateDailyData()
        case .month:
            dateFormatter.dateFormat = "d"
            return generateDailyData()
        case .year:
            dateFormatter.dateFormat = "MMM"
            return generateMonthlyData()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活動頻率")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart(chartData, id: \.date) { dataPoint in
                BarMark(
                    x: .value("時間", dataPoint.date),
                    y: .value("次數", dataPoint.count)
                )
                .foregroundStyle(Color.blue.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func generateHourlyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        var data: [ChartDataPoint] = []
        
        for hour in 0..<24 {
            let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
            
            let count = activities.filter { activity in
                activity.startTime >= hourStart && activity.startTime < hourEnd
            }.count
            
            data.append(ChartDataPoint(date: hourStart, count: count))
        }
        
        return data
    }
    
    private func generateDailyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = timeRange.startDate
        
        var data: [ChartDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let count = activities.filter { activity in
                activity.startTime >= dayStart && activity.startTime < dayEnd
            }.count
            
            data.append(ChartDataPoint(date: dayStart, count: count))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return data
    }
    
    private func generateMonthlyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = timeRange.startDate
        
        var data: [ChartDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let monthStart = calendar.dateInterval(of: .month, for: currentDate)!.start
            let monthEnd = calendar.dateInterval(of: .month, for: currentDate)!.end
            
            let count = activities.filter { activity in
                activity.startTime >= monthStart && activity.startTime < monthEnd
            }.count
            
            data.append(ChartDataPoint(date: monthStart, count: count))
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        
        return data
    }
}

// MARK: - 时间分布图表
struct TimeDistributionChart: View {
    let activities: [ActivityRecord]
    let activityType: ActivityType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(activityType.displayName) 時間分布")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart(hourlyDistribution, id: \.hour) { data in
                SectorMark(
                    angle: .value("次數", data.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("時間", data.hour))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var hourlyDistribution: [HourlyData] {
        let calendar = Calendar.current
        var distribution: [Int: Int] = [:]
        
        for activity in activities {
            let hour = calendar.component(.hour, from: activity.startTime)
            distribution[hour, default: 0] += 1
        }
        
        return distribution.map { HourlyData(hour: $0.key, count: $0.value) }
            .sorted { $0.hour < $1.hour }
    }
}

// MARK: - 趋势卡片
struct TrendCard: View {
    let trend: TrendAnalysis
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(trend.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: trend.direction.icon)
                        .foregroundColor(trend.direction.color)
                        .font(.caption)
                    
                    Text(trend.changeValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trend.direction.color)
                }
                
                Text(trend.period)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - 详细统计行
struct DetailStatRow: View {
    let stat: DetailedStat
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let subtitle = stat.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(stat.value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 详细统计视图
struct DetailedStatisticsView: View {
    let activities: [ActivityRecord]
    let timeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 总体统计
                    overallStatsSection
                    
                    // 按活动类型统计
                    activityTypeStatsSection
                    
                    // 时间模式分析
                    timePatternSection
                }
                .padding()
            }
            .navigationTitle("詳細統計")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    dismiss()
                }
            )
        }
    }
    
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("總體統計")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "總記錄數", value: "\(activities.count)", icon: "doc.text.fill")
                StatCard(title: "平均每日", value: "\(averagePerDay)", icon: "calendar.circle.fill")
                StatCard(title: "最活躍日", value: mostActiveDay, icon: "star.fill")
                StatCard(title: "記錄天數", value: "\(recordedDays)", icon: "clock.fill")
            }
        }
    }
    
    private var activityTypeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活動類型統計")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(activityTypeStats, id: \.type) { stat in
                    ActivityTypeStatRow(stat: stat)
                }
            }
        }
    }
    
    private var timePatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時間模式")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                TimePatternRow(title: "最活躍時段", value: mostActiveHour)
                TimePatternRow(title: "平均間隔", value: averageInterval)
                TimePatternRow(title: "最長間隔", value: longestInterval)
                TimePatternRow(title: "最短間隔", value: shortestInterval)
            }
        }
    }
    
    // 计算属性
    private var averagePerDay: Int {
        guard recordedDays > 0 else { return 0 }
        return activities.count / recordedDays
    }
    
    private var mostActiveDay: String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        
        let dayGroups = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        
        let mostActiveDate = dayGroups.max { $0.value.count < $1.value.count }?.key
        return mostActiveDate.map { dateFormatter.string(from: $0) } ?? "無"
    }
    
    private var recordedDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(activities.map { calendar.startOfDay(for: $0.startTime) })
        return uniqueDays.count
    }
    
    private var activityTypeStats: [ActivityTypeStat] {
        let grouped = Dictionary(grouping: activities) { $0.type }
        return grouped.map { type, activities in
            ActivityTypeStat(
                type: type,
                count: activities.count,
                percentage: Double(activities.count) / Double(self.activities.count) * 100
            )
        }.sorted { $0.count > $1.count }
    }
    
    private var mostActiveHour: String {
        let calendar = Calendar.current
        let hourGroups = Dictionary(grouping: activities) { activity in
            calendar.component(.hour, from: activity.startTime)
        }
        
        let mostActiveHourValue = hourGroups.max { $0.value.count < $1.value.count }?.key
        return mostActiveHourValue.map { "\($0):00" } ?? "無"
    }
    
    private var averageInterval: String {
        guard activities.count > 1 else { return "無" }
        
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        var intervals: [TimeInterval] = []
        
        for i in 1..<sortedActivities.count {
            let interval = sortedActivities[i].startTime.timeIntervalSince(sortedActivities[i-1].startTime)
            intervals.append(interval)
        }
        
        let averageSeconds = intervals.reduce(0, +) / Double(intervals.count)
        return formatInterval(averageSeconds)
    }
    
    private var longestInterval: String {
        guard activities.count > 1 else { return "無" }
        
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        var maxInterval: TimeInterval = 0
        
        for i in 1..<sortedActivities.count {
            let interval = sortedActivities[i].startTime.timeIntervalSince(sortedActivities[i-1].startTime)
            maxInterval = max(maxInterval, interval)
        }
        
        return formatInterval(maxInterval)
    }
    
    private var shortestInterval: String {
        guard activities.count > 1 else { return "無" }
        
        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }
        var minInterval: TimeInterval = .greatestFiniteMagnitude
        
        for i in 1..<sortedActivities.count {
            let interval = sortedActivities[i].startTime.timeIntervalSince(sortedActivities[i-1].startTime)
            minInterval = min(minInterval, interval)
        }
        
        return formatInterval(minInterval)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小時\(minutes)分鐘"
        } else {
            return "\(minutes)分鐘"
        }
    }
}

// MARK: - 辅助视图组件

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ActivityTypeStatRow: View {
    let stat: ActivityTypeStat
    
    var body: some View {
        HStack {
            Text(stat.type.displayName)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stat.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", stat.percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimePatternRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 数据模型

enum TimeRange: CaseIterable {
    case day, week, month, year
    
    var displayName: String {
        switch self {
        case .day: return "今日"
        case .week: return "本週"
        case .month: return "本月"
        case .year: return "本年"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        }
    }
    
    var endDate: Date {
        return Date()
    }
}



struct ChartDataPoint {
    let date: Date
    let count: Int
}

struct HourlyData {
    let hour: Int
    let count: Int
}

struct TrendAnalysis: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let direction: TrendDirection
    let changeValue: String
    let period: String
}

struct DetailedStat: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let subtitle: String?
}

struct ActivityTypeStat {
    let type: ActivityType
    let count: Int
    let percentage: Double
}

// MARK: - ActivityManager 扩展

extension ActivityManager {
    func getActivitiesInRange(from startDate: Date, to endDate: Date) -> [ActivityRecord] {
        // 这里应该实现从数据库获取指定时间范围内的活动记录
        // 目前返回模拟数据
        return todayActivities.filter { activity in
            activity.startTime >= startDate && activity.startTime <= endDate
        }
    }
    
    func loadStatistics(for timeRange: TimeRange) async {
        // 实现统计数据加载逻辑
    }
    
    func refreshStatistics() async {
        // 实现统计数据刷新逻辑
    }
    
    func generateTrendAnalysis(for timeRange: TimeRange, activityType: ActivityType?) -> [TrendAnalysis] {
        // 生成趋势分析数据
        return [
            TrendAnalysis(
                title: "餵食頻率",
                description: "比上週增加",
                direction: .up,
                changeValue: "+12%",
                period: "本週"
            ),
            TrendAnalysis(
                title: "睡眠時間",
                description: "保持穩定",
                direction: .stable,
                changeValue: "0%",
                period: "本週"
            ),
            TrendAnalysis(
                title: "換尿布",
                description: "比上週減少",
                direction: .down,
                changeValue: "-8%",
                period: "本週"
            )
        ]
    }
    
    func generateDetailedStats(for timeRange: TimeRange, activityType: ActivityType?) -> [DetailedStat] {
        // 生成详细统计数据
        return [
            DetailedStat(name: "平均每日記錄", value: "8.5", subtitle: "次"),
            DetailedStat(name: "最長連續記錄", value: "15", subtitle: "天"),
            DetailedStat(name: "記錄完整度", value: "92%", subtitle: nil),
            DetailedStat(name: "最常記錄時間", value: "09:00", subtitle: "上午")
        ]
    }
}

#Preview {
    StatisticsView()
        .environmentObject(ActivityManager())
        .environmentObject(BabyManager())
} 