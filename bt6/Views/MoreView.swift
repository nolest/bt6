import SwiftUI

struct MoreView: View {
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSettings = false
    @State private var showingSmartAssistant = false
    @State private var showingCommunity = false
    @State private var showingMilestones = false
    @State private var showingFamilyManagement = false
    @State private var showingDataManagement = false
    @State private var showingGAIAnalysis = false
    @State private var showingSocial = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户信息卡片
                    UserProfileCard()
                    
                    // 主要功能区域
                    MainFeaturesSection(
                        showingSmartAssistant: $showingSmartAssistant,
                        showingCommunity: $showingCommunity,
                        showingMilestones: $showingMilestones,
                        showingGAIAnalysis: $showingGAIAnalysis,
                        showingSocial: $showingSocial
                    )
                    
                    // 管理功能区域
                    ManagementSection(
                        showingFamilyManagement: $showingFamilyManagement,
                        showingDataManagement: $showingDataManagement,
                        showingSettings: $showingSettings
                    )
                    
                    // 关于与支持区域
                    AboutSection()
                }
                .padding()
            }
            .navigationTitle("更多")
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSmartAssistant) {
            SmartAssistantView()
        }
        .sheet(isPresented: $showingCommunity) {
            CommunityView()
        }
        .sheet(isPresented: $showingMilestones) {
            MilestoneView()
        }
        .sheet(isPresented: $showingFamilyManagement) {
            FamilyManagementView()
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingGAIAnalysis) {
            GAIAnalysisView()
        }
        .sheet(isPresented: $showingSocial) {
            SocialView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - 用户信息卡片
struct UserProfileCard: View {
    @EnvironmentObject var babyManager: BabyManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // 用户头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能宝宝记录")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let baby = babyManager.selectedBaby {
                        Text("当前宝宝: \(baby.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("未选择宝宝")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("记录美好时光")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 快速统计
            HStack(spacing: 20) {
                QuickStat(title: "宝宝", value: "\(babyManager.babies.count)", icon: "person.2.fill", color: .blue)
                QuickStat(title: "记录", value: "128", icon: "doc.text.fill", color: .green)
                QuickStat(title: "照片", value: "56", icon: "photo.fill", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
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

// MARK: - 主要功能区域
struct MainFeaturesSection: View {
    @Binding var showingSmartAssistant: Bool
    @Binding var showingCommunity: Bool
    @Binding var showingMilestones: Bool
    @Binding var showingGAIAnalysis: Bool
    @Binding var showingSocial: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("智能功能")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "智慧助理",
                    subtitle: "AI育儿建议与智能排程",
                    color: .purple,
                    badge: "AI"
                ) {
                    showingSmartAssistant = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "brain",
                    title: "GAI 智能分析",
                    subtitle: "照片情緒分析與發展評估",
                    color: .blue,
                    badge: "NEW"
                ) {
                    showingGAIAnalysis = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "person.3.fill",
                    title: "社群互動",
                    subtitle: "Facebook分享與專家諮詢",
                    color: .green,
                    badge: "社群"
                ) {
                    showingSocial = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "person.2.fill",
                    title: "育儿社群",
                    subtitle: "与其他家长和专家交流",
                    color: .orange,
                    badge: "社群"
                ) {
                    showingCommunity = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "star.fill",
                    title: "成长里程碑",
                    subtitle: "记录宝宝重要成长时刻",
                    color: .yellow,
                    badge: nil
                ) {
                    showingMilestones = true
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 管理功能区域
struct ManagementSection: View {
    @Binding var showingFamilyManagement: Bool
    @Binding var showingDataManagement: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("管理功能")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "person.2.badge.plus",
                    title: "家庭成员管理",
                    subtitle: "添加和管理家庭成员",
                    color: .blue,
                    badge: nil
                ) {
                    showingFamilyManagement = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "externaldrive.fill",
                    title: "数据管理",
                    subtitle: "备份、同步和导出数据",
                    color: .green,
                    badge: nil
                ) {
                    showingDataManagement = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "gearshape.fill",
                    title: "设置",
                    subtitle: "应用设置和偏好",
                    color: .gray,
                    badge: nil
                ) {
                    showingSettings = true
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 关于与支持区域
struct AboutSection: View {
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("关于与支持")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "info.circle.fill",
                    title: "关于应用",
                    subtitle: "版本信息和开发团队",
                    color: .blue,
                    badge: nil
                ) {
                    showingAbout = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "questionmark.circle.fill",
                    title: "帮助中心",
                    subtitle: "使用指南和常见问题",
                    color: .green,
                    badge: nil
                ) {
                    showingHelp = true
                }
                
                Divider()
                
                FeatureRow(
                    icon: "envelope.fill",
                    title: "意见反馈",
                    subtitle: "告诉我们您的想法",
                    color: .orange,
                    badge: nil
                ) {
                    showingFeedback = true
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
    }
}

// MARK: - 功能行组件
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                }
                
                // 文本内容
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(color.opacity(0.2))
                                .foregroundColor(color)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 占位视图
struct CommunityView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("育儿社群")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("育儿社群")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



struct FamilyManagementView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("家庭成员管理")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("家庭成员管理")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DataManagementView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("数据管理")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("数据管理")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 应用图标和名称
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("智能宝宝生活记录")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 应用描述
                    VStack(alignment: .leading, spacing: 12) {
                        Text("关于应用")
                            .font(.headline)
                        
                        Text("智能宝宝生活记录是一款专为新手父母设计的育儿助手应用。通过AI技术和智能分析，帮助您更好地记录和了解宝宝的成长过程。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 开发团队
                    VStack(alignment: .leading, spacing: 12) {
                        Text("开发团队")
                            .font(.headline)
                        
                        Text("由专业的移动应用开发团队打造，致力于为家长提供最好的育儿体验。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("关于应用")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HelpView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("帮助中心")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("帮助中心")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeedbackView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("意见反馈")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("意见反馈")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MoreView()
        .environmentObject(BabyManager())
        .environmentObject(SettingsManager())
} 