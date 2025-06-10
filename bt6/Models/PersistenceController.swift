import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BabyCareDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建示例数据
        // 创建示例宝宝数据
        let babyEntity = NSEntityDescription.entity(forEntityName: "BabyEntity", in: viewContext)!
        let sampleBaby = NSManagedObject(entity: babyEntity, insertInto: viewContext)
        sampleBaby.setValue(UUID(), forKey: "id")
        sampleBaby.setValue("Emma", forKey: "name")
        sampleBaby.setValue(Calendar.current.date(byAdding: .month, value: -9, to: Date())!, forKey: "birthDate")
        sampleBaby.setValue("female", forKey: "gender")
        sampleBaby.setValue(Date(), forKey: "createdAt")
        sampleBaby.setValue(Date(), forKey: "updatedAt")
        
        // 创建示例活动记录
        let activityEntity = NSEntityDescription.entity(forEntityName: "ActivityRecordEntity", in: viewContext)!
        let sampleActivity = NSManagedObject(entity: activityEntity, insertInto: viewContext)
        sampleActivity.setValue(UUID(), forKey: "id")
        sampleActivity.setValue(sampleBaby.value(forKey: "id"), forKey: "babyId")
        sampleActivity.setValue("feeding", forKey: "type")
        sampleActivity.setValue(Date(), forKey: "startTime")
        sampleActivity.setValue(Date(), forKey: "createdAt")
        sampleActivity.setValue(Date(), forKey: "updatedAt")
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview data creation failed: \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
}

// MARK: - Core Data Helper Methods
extension PersistenceController {
    func createBaby(from baby: Baby) -> NSManagedObject? {
        let context = container.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "BabyEntity", in: context) else {
            return nil
        }
        
        let babyEntity = NSManagedObject(entity: entity, insertInto: context)
        babyEntity.setValue(baby.id, forKey: "id")
        babyEntity.setValue(baby.name, forKey: "name")
        babyEntity.setValue(baby.birthDate, forKey: "birthDate")
        babyEntity.setValue(baby.gender, forKey: "gender")
        babyEntity.setValue(baby.profileImagePath, forKey: "profileImagePath")
        babyEntity.setValue(baby.weight ?? 0, forKey: "weight")
        babyEntity.setValue(baby.height ?? 0, forKey: "height")
        babyEntity.setValue(baby.createdAt, forKey: "createdAt")
        babyEntity.setValue(baby.updatedAt, forKey: "updatedAt")
        
        return babyEntity
    }
    
    func createActivityRecord(from record: ActivityRecord) -> NSManagedObject? {
        let context = container.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "ActivityRecordEntity", in: context) else {
            return nil
        }
        
        let activityEntity = NSManagedObject(entity: entity, insertInto: context)
        activityEntity.setValue(record.id, forKey: "id")
        activityEntity.setValue(record.babyId, forKey: "babyId")
        activityEntity.setValue(record.type.rawValue, forKey: "type")
        activityEntity.setValue(record.startTime, forKey: "startTime")
        activityEntity.setValue(record.endTime, forKey: "endTime")
        activityEntity.setValue(record.notes, forKey: "notes")
        activityEntity.setValue(record.createdBy, forKey: "createdBy")
        activityEntity.setValue(record.createdAt, forKey: "createdAt")
        activityEntity.setValue(record.updatedAt, forKey: "updatedAt")
        
        return activityEntity
    }
}