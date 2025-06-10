import SwiftUI

struct MilestoneView: View {
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var activityManager: ActivityManager
    @State private var showingAddMilestone = false
    @State private var selectedCategory: MilestoneCategory = .physical
    @State private var milestones: [Milestone] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if milestones.isEmpty {
                    EmptyMilestoneView()
                } else {
                    MilestoneListView(milestones: milestones)
                }
            }
            .navigationTitle("成長里程碑")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMilestone = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                AddMilestoneView()
            }
            .onAppear {
                loadMilestones()
            }
        }
    }
    
    private func loadMilestones() {
        guard let currentBaby = babyManager.currentBaby else { return }
        
        // 从ActivityManager获取里程碑记录
        let milestoneActivities = activityManager.activities.filter { activity in
            activity.babyId == currentBaby.id && activity.type == .milestone
        }
        
        // 转换为Milestone对象
        milestones = milestoneActivities.compactMap { activity in
            Milestone(
                id: activity.id.uuidString,
                babyId: activity.babyId.uuidString,
                title: activity.notes ?? "未命名里程碑",
                description: activity.notes ?? "",
                category: .physical,
                achievedDate: activity.startTime,
                photos: []
            )
        }
    }
}

struct EmptyMilestoneView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("還沒有記錄任何里程碑")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("記錄寶寶的第一個微笑、第一次翻身、第一聲叫聲等珍貴時刻")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct MilestoneListView: View {
    let milestones: [Milestone]
    @State private var selectedCategory: MilestoneCategory = .all
    
    var filteredMilestones: [Milestone] {
        if selectedCategory == .all {
            return milestones.sorted { $0.achievedDate > $1.achievedDate }
        } else {
            return milestones.filter { $0.category == selectedCategory }
                .sorted { $0.achievedDate > $1.achievedDate }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MilestoneCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            List(filteredMilestones) { milestone in
                MilestoneRowView(milestone: milestone)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct CategoryFilterChip: View {
    let category: MilestoneCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct MilestoneRowView: View {
    let milestone: Milestone
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: milestone.category.iconName)
                .font(.title2)
                .foregroundColor(milestone.category.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(milestone.category.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !milestone.description.isEmpty {
                    Text(milestone.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(milestone.achievedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !milestone.photos.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.caption)
                    Text("\(milestone.photos.count)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddMilestoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var activityManager: ActivityManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: MilestoneCategory = .physical
    @State private var achievedDate = Date()
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("里程碑標題", text: $title)
                    
                    TextField("詳細描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("分類")) {
                    Picker("分類", selection: $selectedCategory) {
                        ForEach(MilestoneCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(category.color)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("達成時間")) {
                    DatePicker("達成日期", selection: $achievedDate, displayedComponents: [.date])
                }
            }
            .navigationTitle("新增里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMilestone()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveMilestone() {
        guard let currentBaby = babyManager.currentBaby else { return }
        
        isSaving = true
        
        Task {
            do {
                let activity = ActivityRecord(
                    babyId: currentBaby.id,
                    type: .milestone,
                    startTime: achievedDate,
                    endTime: nil,
                    details: ActivityDetails.milestone(MilestoneDetails(
                        title: title, 
                        description: description,
                        category: selectedCategory,
                        ageInMonths: nil
                    )),
                    notes: title,
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

struct Milestone: Identifiable, Codable {
    let id: String
    let babyId: String
    var title: String
    var description: String
    var category: MilestoneCategory
    var achievedDate: Date
    var photos: [String]
}

#Preview {
    MilestoneView()
        .environmentObject(BabyManager())
        .environmentObject(ActivityManager())
} 