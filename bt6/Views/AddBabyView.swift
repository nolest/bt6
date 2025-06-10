import SwiftUI
import PhotosUI

struct AddBabyView: View {
    @EnvironmentObject var babyManager: BabyManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var selectedGender = Gender.other
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 头像选择
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                        Text("添加照片")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            Button("相機") {
                                showingCamera = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("相簿") {
                                showingImagePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // 基本信息
                    VStack(spacing: 20) {
                        // 姓名
                        VStack(alignment: .leading, spacing: 8) {
                            Text("寶寶姓名")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("請輸入寶寶姓名", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // 出生日期
                        VStack(alignment: .leading, spacing: 8) {
                            Text("出生日期")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // 性别
                        VStack(alignment: .leading, spacing: 8) {
                            Text("性別")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("性別", selection: $selectedGender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    HStack {
                                        Text(gender.emoji)
                                        Text(gender.displayName)
                                    }
                                    .tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // 体重（可选）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("體重（可選）")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("0.0", text: $weight)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Text("kg")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 身高（可选）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("身高（可選）")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("0.0", text: $height)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Text("cm")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle("添加寶寶")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveBaby()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $selectedImage)
        }
        .alert("錯誤", isPresented: $showingError) {
            Button("確定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveBaby() {
        // 验证输入
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "請輸入寶寶姓名"
            showingError = true
            return
        }
        
        // 创建宝宝对象
        var baby = Baby(
            name: trimmedName,
            birthDate: birthDate,
            gender: selectedGender
        )
        
        // 设置体重和身高
        if let weightValue = Double(weight), weightValue > 0 {
            baby.weight = weightValue
        }
        
        if let heightValue = Double(height), heightValue > 0 {
            baby.height = heightValue
        }
        
        // 保存头像
        if let image = selectedImage {
            saveProfileImage(image, for: baby.id)
            baby.profileImagePath = getProfileImagePath(for: baby.id)
        }
        
        // 验证宝宝信息
        let validationErrors = babyManager.validateBaby(baby)
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.joined(separator: "\n")
            showingError = true
            return
        }
        
        // 添加宝宝
        do {
            try babyManager.addBaby(baby)
            appState.markBabySetup()
        } catch {
            // 处理错误，可以添加错误提示
            print("添加宝宝失败: \\(error)")
        }
        
        // 设置为当前选中的宝宝
        babyManager.selectBaby(baby)
        
        // 更新应用状态
        appState.isFirstLaunch = false
        
        dismiss()
    }
    
    private func saveProfileImage(_ image: UIImage, for babyId: UUID) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profilesDir = documentsPath.appendingPathComponent("Profiles")
        
        // 创建目录
        if !FileManager.default.fileExists(atPath: profilesDir.path) {
            try? FileManager.default.createDirectory(at: profilesDir, withIntermediateDirectories: true)
        }
        
        let imagePath = profilesDir.appendingPathComponent("\(babyId.uuidString).jpg")
        try? imageData.write(to: imagePath)
    }
    
    private func getProfileImagePath(for babyId: UUID) -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profilesDir = documentsPath.appendingPathComponent("Profiles")
        return profilesDir.appendingPathComponent("\(babyId.uuidString).jpg").path
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 相机视图
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddBabyView()
        .environmentObject(BabyManager())
        .environmentObject(AppState())
} 