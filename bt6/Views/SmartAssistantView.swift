import SwiftUI

struct SmartAssistantView: View {
    @EnvironmentObject var assistantManager: SmartAssistantManager
    @EnvironmentObject var babyManager: BabyManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // 顶部标签选择器
                Picker("功能", selection: $selectedTab) {
                    Text("智能排程").tag(0)
                    Text("育兒咨詢").tag(1)
                    Text("情緒支持").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    SmartScheduleView()
                        .tag(0)
                    
                    ParentingConsultationView()
                        .tag(1)
                    
                    EmotionalSupportView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("智慧助理")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 智能排程视图
struct SmartScheduleView: View {
    @EnvironmentObject var assistantManager: SmartAssistantManager
    @EnvironmentObject var babyManager: BabyManager
    @State private var isLearning = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 学习状态卡片
                learningStatusCard
                
                // 下一个预测事件
                nextPredictedEventCard
                
                // 今日排程建议
                todayScheduleSection
                
                // 每日小贴士
                dailyTipsSection
            }
            .padding()
        }
        .refreshable {
            await refreshSchedule()
        }
    }
    
    private var learningStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("模式學習")
                    .font(.headline)
                
                Spacer()
                
                if assistantManager.isLearningPatterns {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text(assistantManager.isLearningPatterns ? "正在學習寶寶的作息模式..." : "已學習寶寶的日常規律")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button(action: {
                Task {
                    await learnPatterns()
                }
            }) {
                Text("重新學習模式")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            .disabled(assistantManager.isLearningPatterns)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var nextPredictedEventCard: some View {
        Group {
            if let selectedBaby = babyManager.selectedBaby,
               let nextEvent = assistantManager.getNextPredictedEvent(for: selectedBaby.id.uuidString) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: iconForActivityType(nextEvent.type))
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        Text("下一個預測事件")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nextEvent.type.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("預計時間：\(nextEvent.predictedTime, style: .time)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("置信度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(nextEvent.confidence * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("需要更多數據來預測")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日排程建議")
                .font(.headline)
            
            if assistantManager.scheduleSuggestions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("暫無排程建議")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(assistantManager.scheduleSuggestions) { suggestion in
                        ScheduleSuggestionRow(suggestion: suggestion)
                    }
                }
            }
        }
    }
    
    private var dailyTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日小貼士")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(assistantManager.dailyTips) { tip in
                    DailyTipCard(tip: tip)
                }
            }
        }
    }
    
    private func iconForActivityType(_ type: ActivityType) -> String {
        switch type {
        case .feeding:
            return "bottle.fill"
        case .sleep:
            return "bed.double.fill"
        case .diaper:
            return "tshirt.fill"
        case .bath:
            return "drop.fill"
        case .custom:
            return "gamecontroller.fill"
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
        }
    }
    
    private func learnPatterns() async {
        guard let selectedBaby = babyManager.selectedBaby else { return }
        await assistantManager.learnBabyPatterns(babyId: selectedBaby.id.uuidString)
    }
    
    private func refreshSchedule() async {
        guard let selectedBaby = babyManager.selectedBaby else { return }
        await assistantManager.generateScheduleSuggestions(for: selectedBaby.id.uuidString)
    }
}

// MARK: - 育儿咨询视图
struct ParentingConsultationView: View {
    @EnvironmentObject var assistantManager: SmartAssistantManager
    @EnvironmentObject var babyManager: BabyManager
    @State private var questionText = ""
    @State private var currentAdvice: AdviceResponse?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 问题输入区域
                questionInputSection
                
                // 建议回复区域
                if let advice = currentAdvice {
                    adviceResponseSection(advice)
                }
                
                // 上下文提示
                contextualTipsSection
            }
            .padding()
        }
    }
    
    private var questionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("育兒問題咨詢")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("請輸入您的育兒問題...", text: $questionText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Button(action: {
                    getAdvice()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "questionmark.circle.fill")
                        }
                        
                        Text(isLoading ? "諮詢中..." : "獲取建議")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(questionText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(questionText.isEmpty || isLoading)
            }
        }
    }
    
    private func adviceResponseSection(_ advice: AdviceResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("專業建議")
                    .font(.headline)
                
                Spacer()
                
                Text("置信度: \(Int(advice.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            Text(advice.answer)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            if !advice.sources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("資料來源:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(advice.sources, id: \.self) { source in
                        Text("• \(source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var contextualTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相關小貼士")
                .font(.headline)
            
            let contextualTips = assistantManager.getContextualTips(
                babyId: babyManager.selectedBaby?.id.uuidString ?? "",
                context: .homeScreen
            )
            
            LazyVStack(spacing: 8) {
                ForEach(contextualTips) { tip in
                    DailyTipCard(tip: tip)
                }
            }
        }
    }
    
    private func getAdvice() {
        guard !questionText.isEmpty,
              let selectedBaby = babyManager.selectedBaby else { return }
        
        isLoading = true
        
        Task {
            let advice = await assistantManager.getParentingAdvice(
                query: questionText,
                babyId: selectedBaby.id.uuidString
            )
            
            DispatchQueue.main.async {
                self.currentAdvice = advice
                self.isLoading = false
            }
        }
    }
}

// MARK: - 情绪支持视图
struct EmotionalSupportView: View {
    @EnvironmentObject var assistantManager: SmartAssistantManager
    @State private var currentStressLevel: StressLevel = .low
    @State private var showingRelaxationTechnique = false
    @State private var selectedTechnique: RelaxationTechnique?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 压力水平检测
                stressLevelSection
                
                // 支持消息
                supportMessagesSection
                
                // 放松技巧
                relaxationTechniquesSection
            }
            .padding()
        }
        .onAppear {
            checkStressLevel()
        }
        .sheet(isPresented: $showingRelaxationTechnique) {
            if let technique = selectedTechnique {
                RelaxationTechniqueView(technique: technique)
            }
        }
    }
    
    private var stressLevelSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(colorForStressLevel(currentStressLevel))
                    .font(.title2)
                
                Text("壓力水平檢測")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text("當前狀態:")
                    .font(.subheadline)
                
                Text(textForStressLevel(currentStressLevel))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForStressLevel(currentStressLevel))
                
                Spacer()
                
                Button("重新檢測") {
                    checkStressLevel()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var supportMessagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支持訊息")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(assistantManager.supportMessages.suffix(3).reversed(), id: \.id) { message in
                    SupportMessageCard(message: message)
                }
            }
            
            Button(action: {
                provideSupportMessage()
            }) {
                Text("獲取鼓勵")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var relaxationTechniquesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("放鬆技巧")
                .font(.headline)
            
            Button(action: {
                suggestRelaxationTechnique()
            }) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    
                    Text("推薦放鬆技巧")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func colorForStressLevel(_ level: StressLevel) -> Color {
        switch level {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    private func textForStressLevel(_ level: StressLevel) -> String {
        switch level {
        case .low:
            return "輕鬆"
        case .medium:
            return "中等壓力"
        case .high:
            return "高壓力"
        }
    }
    
    private func checkStressLevel() {
        currentStressLevel = assistantManager.detectUserStressLevel()
    }
    
    private func provideSupportMessage() {
        let _ = assistantManager.provideSupportMessage(level: currentStressLevel)
    }
    
    private func suggestRelaxationTechnique() {
        selectedTechnique = assistantManager.suggestRelaxationTechnique()
        showingRelaxationTechnique = true
    }
}

// MARK: - 辅助视图组件

struct ScheduleSuggestionRow: View {
    let suggestion: ScheduleSuggestion
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(suggestion.suggestedTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("置信度 \(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DailyTipCard: View {
    let tip: ParentingTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tip.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(tip.content)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SupportMessageCard: View {
    let message: SupportMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForMessageType(message.type))
                    .foregroundColor(colorForStressLevel(message.level))
                
                Text(message.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(message.text)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func iconForMessageType(_ type: SupportMessageType) -> String {
        switch type {
        case .encouragement:
            return "heart.fill"
        case .advice:
            return "lightbulb.fill"
        case .reminder:
            return "bell.fill"
        }
    }
    
    private func colorForStressLevel(_ level: StressLevel) -> Color {
        switch level {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

struct RelaxationTechniqueView: View {
    let technique: RelaxationTechnique
    @Environment(\.dismiss) private var dismiss
    @State private var isActive = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 技巧信息
                VStack(spacing: 12) {
                    Text(technique.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(technique.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                // 计时器
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(1 - (timeRemaining / technique.duration)))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeRemaining)
                        
                        VStack {
                            Text(formatTime(timeRemaining))
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(isActive ? "進行中" : "準備開始")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        if isActive {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        Text(isActive ? "停止" : "開始")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 120, height: 44)
                            .background(isActive ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(22)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("放鬆練習")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    stopTimer()
                    dismiss()
                }
            )
        }
        .onAppear {
            timeRemaining = technique.duration
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    SmartAssistantView()
        .environmentObject(SmartAssistantManager())
        .environmentObject(BabyManager())
} 