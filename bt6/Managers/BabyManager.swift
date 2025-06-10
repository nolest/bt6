import Foundation
import CoreData
import SwiftUI

class BabyManager: ObservableObject {
    static let shared = BabyManager()
    
    @Published var babies: [Baby] = []
    @Published var selectedBaby: Baby?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 为了兼容其他文件中使用的currentBaby
    var currentBaby: Baby? {
        get { selectedBaby }
        set { selectedBaby = newValue }
    }
    
    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    init() {
        loadBabies()
    }
    
    // MARK: - 加载宝宝列表
    func loadBabies() {
        isLoading = true
        errorMessage = nil
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "BabyEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let babyEntities = try context.fetch(request)
            self.babies = babyEntities.compactMap { entity in
                convertEntityToBaby(entity)
            }
            
            // 如果没有选中的宝宝，选择第一个
            if selectedBaby == nil && !babies.isEmpty {
                selectedBaby = babies.first
            }
        } catch {
            print("加载宝宝数据失败: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 添加宝宝
    func addBaby(_ baby: Baby) throws {
        let context = persistenceController.container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "BabyEntity", in: context) else {
            throw NSError(domain: "BabyManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建BabyEntity"])
        }
        
        let babyEntity = NSManagedObject(entity: entity, insertInto: context)
        updateEntity(babyEntity, with: baby)
        
        try context.save()
        loadBabies()
    }
    
    // MARK: - 辅助方法
    private func convertEntityToBaby(_ entity: NSManagedObject) -> Baby? {
        guard let _ = entity.value(forKey: "id") as? UUID,
              let name = entity.value(forKey: "name") as? String,
              let birthDate = entity.value(forKey: "birthDate") as? Date,
              let genderString = entity.value(forKey: "gender") as? String,
              let _ = entity.value(forKey: "createdAt") as? Date,
              let _ = entity.value(forKey: "updatedAt") as? Date else {
            return nil
        }
        
        let gender = Gender(rawValue: genderString) ?? Gender.other
        let profileImagePath = entity.value(forKey: "profileImagePath") as? String
        let weight = entity.value(forKey: "weight") as? Double
        let height = entity.value(forKey: "height") as? Double
        
        return Baby(
            name: name,
            birthDate: birthDate,
            gender: gender,
            profileImagePath: profileImagePath,
            weight: weight != 0 ? weight : nil,
            height: height != 0 ? height : nil
        )
    }
    
    private func updateEntity(_ entity: NSManagedObject, with baby: Baby) {
        entity.setValue(baby.id, forKey: "id")
        entity.setValue(baby.name, forKey: "name")
        entity.setValue(baby.birthDate, forKey: "birthDate")
        entity.setValue(baby.gender.rawValue, forKey: "gender")
        entity.setValue(baby.profileImagePath, forKey: "profileImagePath")
        entity.setValue(baby.weight ?? 0, forKey: "weight")
        entity.setValue(baby.height ?? 0, forKey: "height")
        entity.setValue(baby.createdAt, forKey: "createdAt")
        entity.setValue(baby.updatedAt, forKey: "updatedAt")
    }
    
    // MARK: - 更新宝宝信息
    func updateBaby(_ baby: Baby) throws {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "BabyEntity")
        request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                updateEntity(entity, with: baby)
                try context.save()
                loadBabies()
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - 删除宝宝
    func deleteBaby(_ baby: Baby) throws {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "BabyEntity")
        request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                try context.save()
                loadBabies()
                
                // 如果删除的是当前选中的宝宝，清空选择
                if selectedBaby?.id == baby.id {
                    selectedBaby = nil
                }
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - 选择宝宝
    func selectBaby(_ baby: Baby) {
        selectedBaby = baby
        UserDefaults.standard.set(baby.id.uuidString, forKey: "selectedBabyId")
    }
    
    // MARK: - 获取宝宝年龄信息
    func getAgeInfo(for baby: Baby) -> (months: Int, days: Int, ageString: String) {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.month, .day], from: baby.birthDate, to: now)
        let months = components.month ?? 0
        let days = components.day ?? 0
        
        let ageString = baby.birthDate.ageString()
        
        return (months: months, days: days, ageString: ageString)
    }
    
    // MARK: - 获取成长统计
    func getGrowthStats(for baby: Baby) -> (weightGain: Double?, heightGain: Double?) {
        // 这里可以实现更复杂的成长统计逻辑
        // 目前返回简单的数据
        return (weightGain: baby.weight, heightGain: baby.height)
    }
    
    // MARK: - 验证宝宝信息
    func validateBaby(_ baby: Baby) -> [String] {
        var errors: [String] = []
        
        if baby.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("寶寶姓名不能為空")
        }
        
        if baby.birthDate > Date() {
            errors.append("出生日期不能是未來日期")
        }
        
        let calendar = Calendar.current
        if let yearsAgo = calendar.date(byAdding: .year, value: -10, to: Date()),
           baby.birthDate < yearsAgo {
            errors.append("出生日期不能超過10年前")
        }
        
        return errors
    }
    
    // MARK: - 导入/导出功能
    func exportBabyData(_ baby: Baby) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(baby)
        } catch {
            errorMessage = "導出寶寶數據失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importBabyData(from data: Data) -> Baby? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Baby.self, from: data)
        } catch {
            errorMessage = "導入寶寶數據失敗: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - 搜索功能
    func searchBabies(query: String) -> [Baby] {
        if query.isEmpty {
            return babies
        }
        
        return babies.filter { baby in
            baby.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - 清除错误消息
    func clearError() {
        errorMessage = nil
    }
} 