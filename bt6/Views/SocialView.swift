import SwiftUI

struct SocialView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if !socialManager.isConnected {
                    // 未连接状态
                    SocialConnectionView()
                } else {
                    // 已连接状态
                    VStack {
                        // 顶部标签选择器
                        Picker("功能", selection: $selectedTab) {
                            Text("發布").tag(0)
                            Text("我的貼文").tag(1)
                            Text("專家諮詢").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // 内容区域
                        TabView(selection: $selectedTab) {
                            PostPublishView()
                                .tag(0)
                            
                            MyPostsView()
                                .tag(1)
                            
                            ExpertConsultationView()
                                .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("社群互動")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: socialManager.isConnected ? 
                Button("斷開連接") {
                    socialManager.disconnect()
                } : nil
            )
        }
    }
}

// MARK: - 社群连接视图
struct SocialConnectionView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 图标和标题
            VStack(spacing: 16) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("連接社群帳戶")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("連接您的Facebook帳戶，與朋友分享寶寶的成長時刻")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 连接状态
            connectionStatusView
            
            // 连接按钮
            VStack(spacing: 16) {
                Button(action: {
                    connectFacebook()
                }) {
                    HStack {
                        Image(systemName: "f.circle.fill")
                            .font(.title3)
                        
                        Text("連接 Facebook")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(socialManager.connectionStatus == .connecting)
                
                Text("我們會保護您的隱私，只會發布您明確選擇分享的內容")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .alert("連接錯誤", isPresented: $showingError) {
            Button("確定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var connectionStatusView: some View {
        Group {
            switch socialManager.connectionStatus {
            case .disconnected:
                EmptyView()
                
            case .connecting:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在連接...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
            case .connected:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已連接")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text("連接失敗")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .onAppear {
                    errorMessage = message
                    showingError = true
                }
            }
        }
    }
    
    private func connectFacebook() {
        Task {
            do {
                try await socialManager.connectFacebook()
            } catch {
                // 错误处理已在SocialManager中完成
            }
        }
    }
}

// MARK: - 发布内容视图
struct PostPublishView: View {
    @EnvironmentObject var socialManager: SocialManager
    @EnvironmentObject var mediaManager: MediaManager
    @State private var postContent = ""
    @State private var selectedPrivacy: PostPrivacy = .friends
    @State private var selectedMediaItem: MediaItem?
    @State private var showingMediaPicker = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户信息
                if let user = socialManager.currentUser {
                    userInfoCard(user)
                }
                
                // 内容输入
                contentInputSection
                
                // 媒体选择
                mediaSelectionSection
                
                // 隐私设置
                privacySettingsSection
                
                // 发布按钮
                publishButton
            }
            .padding()
        }
        .sheet(isPresented: $showingMediaPicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
                        ForEach(mediaManager.mediaItems) { item in
                            Button(action: {
                                selectedMediaItem = item
                                showingMediaPicker = false
                            }) {
                                AsyncImage(url: URL(fileURLWithPath: item.thumbnailPath ?? item.filePath)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                }
                                .frame(width: 120, height: 120)
                                .clipped()
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("選擇媒體")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("取消") {
                            showingMediaPicker = false
                        }
                    }
                }
            }
        }
        .alert("發布成功", isPresented: $showingSuccess) {
            Button("確定") {
                clearForm()
            }
        } message: {
            Text("您的貼文已成功發布到Facebook")
        }
        .alert("發布失敗", isPresented: $showingError) {
            Button("確定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func userInfoCard(_ user: SocialUser) -> some View {
        HStack {
            AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                
                Text("已連接 Facebook")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分享內容")
                .font(.headline)
            
            TextField("分享寶寶的美好時刻...", text: $postContent, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(5...10)
        }
    }
    
    private var mediaSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("添加照片/影片")
                    .font(.headline)
                
                Spacer()
                
                Button("選擇媒體") {
                    showingMediaPicker = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if selectedMediaItem == nil {
                Button(action: {
                    showingMediaPicker = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text("點擊添加照片或影片")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } else {
                AsyncImage(url: URL(fileURLWithPath: selectedMediaItem?.thumbnailPath ?? selectedMediaItem?.filePath ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(height: 200)
                .cornerRadius(12)
            }
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("隱私設置")
                .font(.headline)
            
            Picker("隱私", selection: $selectedPrivacy) {
                ForEach(PostPrivacy.allCases, id: \.self) { privacy in
                    HStack {
                        Image(systemName: iconForPrivacy(privacy))
                        Text(privacy.displayName)
                    }
                    .tag(privacy)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var publishButton: some View {
        Button(action: {
            publishPost()
        }) {
            HStack {
                if socialManager.isPublishing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                
                Text(socialManager.isPublishing ? "發布中..." : "發布到 Facebook")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canPublish ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canPublish || socialManager.isPublishing)
    }
    
    private var canPublish: Bool {
        !postContent.isEmpty || selectedMediaItem != nil
    }
    
    private func iconForPrivacy(_ privacy: PostPrivacy) -> String {
        switch privacy {
        case .everyone:
            return "globe"
        case .friends:
            return "person.2.fill"
        case .onlyMe:
            return "lock.fill"
        }
    }
    
    private func publishPost() {
        Task {
            do {
                if selectedMediaItem == nil {
                    _ = try await socialManager.publishPost(
                        content: postContent,
                        privacy: selectedPrivacy
                    )
                } else {
                    _ = try await socialManager.publishPostWithMedia(
                        content: postContent,
                        mediaItems: [selectedMediaItem!],
                        privacy: selectedPrivacy
                    )
                }
                
                DispatchQueue.main.async {
                    self.showingSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func clearForm() {
        postContent = ""
        selectedMediaItem = nil
        selectedPrivacy = .friends
    }
}

// MARK: - 我的帖子视图
struct MyPostsView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var selectedPost: SocialPost?
    @State private var showingPostDetail = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(socialManager.posts) { post in
                    PostCard(post: post) {
                        selectedPost = post
                        showingPostDetail = true
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await socialManager.loadUserPosts()
        }
        .sheet(isPresented: $showingPostDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
        .onAppear {
            Task {
                await socialManager.loadUserPosts()
            }
        }
    }
}

// MARK: - 专家咨询视图
struct ExpertConsultationView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var questionText = ""
    @State private var currentAdvice: ExpertAdvice?
    @State private var isLoading = false
    @State private var showingBooking = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 问题咨询
                questionSection
                
                // 专家建议
                if let advice = currentAdvice {
                    expertAdviceSection(advice)
                }
                
                // 预约咨询
                bookingSection
            }
            .padding()
        }
        .sheet(isPresented: $showingBooking) {
            ExpertBookingView()
        }
    }
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("專家問答")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("請輸入您的育兒問題...", text: $questionText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Button(action: {
                    getExpertAdvice()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Text(isLoading ? "諮詢中..." : "諮詢專家")
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
    
    private func expertAdviceSection(_ advice: ExpertAdvice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("專家建議")
                    .font(.headline)
                
                Spacer()
                
                if advice.isVerified {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                        Text("已驗證")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 专家信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(advice.expert.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(advice.expert.specialty)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(advice.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 建议内容
            Text(advice.advice)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private var bookingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預約專家諮詢")
                .font(.headline)
            
            Button(action: {
                showingBooking = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.green)
                    
                    Text("預約一對一諮詢")
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
    
    private func getExpertAdvice() {
        guard !questionText.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let advice = try await socialManager.getExpertAdvice(question: questionText)
                
                DispatchQueue.main.async {
                    self.currentAdvice = advice
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - 辅助视图组件

struct PostCard: View {
    let post: SocialPost
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 帖子头部
            HStack {
                Text(post.publishedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                statusBadge(post.status)
            }
            
            // 帖子内容
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.body)
            }
            
            // 媒体预览
            if !post.mediaUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(post.mediaUrls.enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 隐私设置
            HStack {
                Image(systemName: iconForPrivacy(post.privacy))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(post.privacy.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("查看詳情") {
                    onTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func statusBadge(_ status: PostStatus) -> some View {
        Text(statusText(status))
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }
    
    private func statusText(_ status: PostStatus) -> String {
        switch status {
        case .draft:
            return "草稿"
        case .publishing:
            return "發布中"
        case .published:
            return "已發布"
        case .failed:
            return "失敗"
        }
    }
    
    private func statusColor(_ status: PostStatus) -> Color {
        switch status {
        case .draft:
            return .orange
        case .publishing:
            return .blue
        case .published:
            return .green
        case .failed:
            return .red
        }
    }
    
    private func iconForPrivacy(_ privacy: PostPrivacy) -> String {
        switch privacy {
        case .everyone:
            return "globe"
        case .friends:
            return "person.2.fill"
        case .onlyMe:
            return "lock.fill"
        }
    }
}

struct PostDetailView: View {
    @EnvironmentObject var socialManager: SocialManager
    let post: SocialPost
    @Environment(\.dismiss) private var dismiss
    @State private var replyText = ""
    
    var postInteractions: [SocialInteraction] {
        socialManager.interactions.filter { $0.postId == post.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 帖子内容
                    PostCard(post: post) { }
                    
                    // 互动统计
                    interactionStats
                    
                    // 评论和点赞列表
                    interactionsList
                    
                    // 回复输入
                    replySection
                }
                .padding()
            }
            .navigationTitle("貼文詳情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    dismiss()
                }
            )
        }
        .onAppear {
            Task {
                await socialManager.loadPostInteractions(postId: post.id)
            }
        }
    }
    
    private var interactionStats: some View {
        HStack {
            let likes = postInteractions.filter { $0.type == .like }
            let comments = postInteractions.filter { $0.type == .comment }
            
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(likes.count) 個讚")
                    .font(.caption)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.blue)
                Text("\(comments.count) 則留言")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var interactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("互動")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(postInteractions.sorted { $0.createdAt > $1.createdAt }) { interaction in
                    InteractionRow(interaction: interaction)
                }
            }
        }
    }
    
    private var replySection: some View {
        VStack(spacing: 12) {
            TextField("寫下您的留言...", text: $replyText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                replyToPost()
            }) {
                Text("發送留言")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(replyText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(replyText.isEmpty)
        }
    }
    
    private func replyToPost() {
        guard !replyText.isEmpty else { return }
        
        Task {
            do {
                try await socialManager.replyToComment(
                    postId: post.id,
                    commentId: nil,
                    message: replyText
                )
                
                DispatchQueue.main.async {
                    self.replyText = ""
                }
            } catch {
                // 处理错误
            }
        }
    }
}

struct InteractionRow: View {
    let interaction: SocialInteraction
    
    var body: some View {
        HStack {
            Image(systemName: iconForInteractionType(interaction.type))
                .foregroundColor(colorForInteractionType(interaction.type))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(interaction.authorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let content = interaction.content {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(interaction.createdAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForInteractionType(_ type: InteractionType) -> String {
        switch type {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.left.fill"
        case .share:
            return "square.and.arrow.up.fill"
        }
    }
    
    private func colorForInteractionType(_ type: InteractionType) -> Color {
        switch type {
        case .like:
            return .red
        case .comment:
            return .blue
        case .share:
            return .green
        }
    }
}

struct ExpertBookingView: View {
    @EnvironmentObject var socialManager: SocialManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExpert: Expert?
    @State private var preferredDate = Date()
    @State private var questionText = ""
    @State private var isBooking = false
    
    private let experts = [
        Expert(id: "1", name: "李醫師", specialty: "兒科", verified: true),
        Expert(id: "2", name: "王護理師", specialty: "新生兒護理", verified: true),
        Expert(id: "3", name: "陳營養師", specialty: "嬰幼兒營養", verified: true)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 专家选择
                    expertSelectionSection
                    
                    // 时间选择
                    dateSelectionSection
                    
                    // 问题描述
                    questionSection
                    
                    // 预约按钮
                    bookingButton
                }
                .padding()
            }
            .navigationTitle("預約專家諮詢")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                }
            )
        }
    }
    
    private var expertSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇專家")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(experts, id: \.id) { expert in
                    Button(action: {
                        selectedExpert = expert
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(expert.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    if expert.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                
                                Text(expert.specialty)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedExpert?.id == expert.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedExpert?.id == expert.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預約時間")
                .font(.headline)
            
            DatePicker("選擇日期和時間", selection: $preferredDate, in: Date()...)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("問題描述")
                .font(.headline)
            
            TextField("請詳細描述您的問題...", text: $questionText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(5...10)
        }
    }
    
    private var bookingButton: some View {
        Button(action: {
            bookConsultation()
        }) {
            HStack {
                if isBooking {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "calendar.badge.plus")
                }
                
                Text(isBooking ? "預約中..." : "確認預約")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canBook ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canBook || isBooking)
    }
    
    private var canBook: Bool {
        selectedExpert != nil && !questionText.isEmpty
    }
    
    private func bookConsultation() {
        guard let expert = selectedExpert else { return }
        
        isBooking = true
        
        Task {
            do {
                _ = try await socialManager.scheduleExpertConsultation(
                    expertId: expert.id,
                    preferredTime: preferredDate,
                    question: questionText
                )
                
                DispatchQueue.main.async {
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isBooking = false
                }
            }
        }
    }
}

#Preview {
    SocialView()
        .environmentObject(SocialManager())
        .environmentObject(MediaManager())
} 