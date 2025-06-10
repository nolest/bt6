import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddBaby = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 左侧蓝色背景区域
                HStack(spacing: 0) {
                    // 左侧区域
                    VStack {
                        Spacer()
                        
                        // 应用图标
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        // 应用名称
                        Text("BabyCare")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // 底部装饰
                        Image(systemName: "moon.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // 右侧区域
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // 欢迎图标
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "figure.and.child.holdinghands")
                                        .font(.system(size: 50))
                                        .foregroundColor(.orange)
                                )
                            
                            Text("Welcome")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // 登录选项
                        VStack(spacing: 16) {
                            // Apple登录按钮
                            Button(action: {
                                // Apple登录逻辑
                                signInWithApple()
                            }) {
                                HStack {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Sign in with Apple")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .cornerRadius(25)
                            }
                            
                            // 邮箱登录按钮
                            Button(action: {
                                // 邮箱登录逻辑
                                signInWithEmail()
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Sign in with Email")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(25)
                            }
                            
                            // 分隔线
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 10)
                            
                            // Facebook登录按钮
                            Button(action: {
                                // Facebook登录逻辑
                                continueWithFacebook()
                            }) {
                                HStack {
                                    Image(systemName: "f.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Continue with Facebook")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        // 底部指示器
                        HStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddBaby) {
            AddBabyView()
        }
    }
    
    // MARK: - 登录方法
    private func signInWithApple() {
        // 实现Apple登录
        // 这里暂时跳过登录，直接进入添加宝宝页面
        showingAddBaby = true
    }
    
    private func signInWithEmail() {
        // 实现邮箱登录
        // 这里暂时跳过登录，直接进入添加宝宝页面
        showingAddBaby = true
    }
    
    private func continueWithFacebook() {
        // 实现Facebook登录
        // 这里暂时跳过登录，直接进入添加宝宝页面
        showingAddBaby = true
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppState())
        .environmentObject(BabyManager())
} 