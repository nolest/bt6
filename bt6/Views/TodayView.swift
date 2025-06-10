import SwiftUI
import Combine

struct TodayView: View {
    @StateObject private var babyManager = BabyManager.shared
    @StateObject private var activityManager = ActivityManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedBaby: Baby?
    @State private var recentActivities: [ActivityRecord] = []
    @State private var showingAddActivity = false
    @State private var showingAddBaby = false
    @State private var quickActivityType: ActivityType?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let baby = selectedBaby {
                        // 宝宝状态摘要
                        BabyStatusCard(baby: baby)
                        
                        // 快速操作按钮
                        QuickActionsSection(baby: baby, quickActivityType: $quickActivityType)
                        
                        // 智能建议卡片
                        SmartSuggestionsSection(baby: baby)
                        
                        // 今日活动时间线
                        TodayTimelineSection(activities: recentActivities)
                        
                    } else if babyManager.babies.isEmpty {
                        // 没有宝宝时显示添加宝宝提示
                        EmptyBabyStateView(showingAddBaby: $showingAddBaby)
                    } else {
                        // 有宝宝但未选择
                        BabySelectionView(babies: babyManager.babies, selectedBaby: $selectedBaby)
                    }
                }
                .padding()
            }
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !babyManager.babies.isEmpty {
                            ForEach(babyManager.babies) { baby in
                                Button(baby.name) {
                                    selectedBaby = baby
                                    loadTodayData()
                                }
                            }
                            Divider()
                        }
                        Button("添加宝宝") {
                            showingAddBaby = true
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingAddBaby) {
                AddBabyView()
            }
            .sheet(isPresented: $showingAddActivity) {
                if let baby = selectedBaby {
                    AddActivityView(baby: baby, preselectedType: quickActivityType)
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: quickActivityType) { oldValue, newValue in
            showingAddActivity = newValue != nil
        }
    }
    
    private func setupInitialState() {
        if selectedBaby == nil && !babyManager.babies.isEmpty {
            selectedBaby = babyManager.babies.first
        }
        loadTodayData()
    }
    
    private func loadTodayData() {
        guard let baby = selectedBaby else { return }
        
        Task {
            do {
                let today = Calendar.current.startOfDay(for: Date())
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
                let _ = DateInterval(start: today, end: tomorrow)
                
                let activities = try await activityManager.loadTodayActivities(for: baby.id)
                
                await MainActor.run {
                    self.recentActivities = activities.sorted { $0.startTime > $1.startTime }
                }
            } catch {
                print("加载今日数据失败: \(error)")
            }
        }
    }
    
    @MainActor
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        babyManager.loadBabies()
        loadTodayData()
    }
}

// MARK: - 宝宝状态卡片
struct BabyStatusCard: View {
    let baby: Baby
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // 宝宝头像
                AsyncImage(url: baby.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(baby.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(baby.ageDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("生日: \(baby.birthDate, formatter: DateFormatter.shortDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 今日统计
            HStack(spacing: 20) {
                StatItem(title: "餵食", value: "6次", icon: "drop.fill", color: .blue)
                StatItem(title: "睡眠", value: "12小时", icon: "moon.fill", color: .purple)
                StatItem(title: "换尿布", value: "8次", icon: "circle.fill", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 快速操作区域
struct QuickActionsSection: View {
    let baby: Baby
    @Binding var quickActivityType: ActivityType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速记录")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                QuickActionButton(
                    title: "餵食",
                    icon: "drop.fill",
                    color: .blue
                ) {
                    quickActivityType = .feeding
                }
                
                QuickActionButton(
                    title: "睡眠",
                    icon: "moon.fill",
                    color: .purple
                ) {
                    quickActivityType = .sleep
                }
                
                QuickActionButton(
                    title: "换尿布",
                    icon: "circle.fill",
                    color: .orange
                ) {
                    quickActivityType = .diaper
                }
                
                QuickActionButton(
                    title: "洗澡",
                    icon: "drop.triangle.fill",
                    color: .cyan
                ) {
                    quickActivityType = .bath
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 智能建议区域
struct SmartSuggestionsSection: View {
    let baby: Baby
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("智能建议")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                SuggestionCard(
                    icon: "clock.fill",
                    title: "下次餵食时间",
                    description: "根据作息规律，建议在2小时后餵食",
                    color: .blue
                )
                
                SuggestionCard(
                    icon: "moon.fill",
                    title: "午睡提醒",
                    description: "宝宝可能需要午睡了，注意观察困倦信号",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct SuggestionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 今日时间线
struct TodayTimelineSection: View {
    let activities: [ActivityRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日时间线")
                .font(.headline)
                .fontWeight(.semibold)
            
            if activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("今天还没有记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("点击上方快速操作开始记录宝宝的活动")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(activities.prefix(10)) { activity in
                        TimelineItem(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct TimelineItem: View {
    let activity: ActivityRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 时间线点
            VStack {
                Circle()
                    .fill(activity.type.color)
                    .frame(width: 12, height: 12)
                
                // 显示连接线（除了最后一个）
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 20)
            }
            
            // 活动图标
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
                .font(.title3)
                .frame(width: 24)
            
            // 活动信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(activity.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空状态视图
struct EmptyBabyStateView: View {
    @Binding var showingAddBaby: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("欢迎使用智能宝宝记录")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("添加您的第一个宝宝开始记录美好时光")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("添加宝宝") {
                showingAddBaby = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
}

// MARK: - 宝宝选择视图
struct BabySelectionView: View {
    let babies: [Baby]
    @Binding var selectedBaby: Baby?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("选择宝宝")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(babies) { baby in
                    Button {
                        selectedBaby = baby
                    } label: {
                        VStack(spacing: 8) {
                            AsyncImage(url: baby.profileImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            Text(baby.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }
}

// MARK: - 扩展
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

extension Baby {
    var ageDescription: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate, to: now)
        
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        
        if years > 0 {
            return "\(years)年\(months)个月\(days)天"
        } else if months > 0 {
            return "\(months)个月\(days)天"
        } else {
            return "\(days)天"
        }
    }
    
    var profileImageURL: URL? {
        guard let profileImagePath = profileImagePath else { return nil }
        return URL(string: profileImagePath)
    }
}



#Preview {
    TodayView()
        .environmentObject(BabyManager.shared)
        .environmentObject(ActivityManager.shared)
        .environmentObject(SettingsManager.shared)
} 