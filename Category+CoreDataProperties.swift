//
//  Category+CoreDataProperties.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//
//

import Foundation
import CoreData
import DeveloperToolsSupport

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var number: Int16
    @NSManaged public var name: String?
    @NSManaged public var items: NSSet?
        
    /// Items array belonging to category
    var itemsArray: [Item] {
        let set = items as? Set<Item> ?? []
        return set.sorted { $0.itemNumber < $1.itemNumber }
    }
    
    var templateItemsArray: [Item] {
        itemsArray.filter { $0.isTemplateItem }.sorted { $0.number < $1.number }
    }
    
    /// Budget Items in a given month
    func itemsIn(month: Month?) -> [Item] {
        itemsArray.filter { $0.month == month }
    }
    
    /// Total spent in given month
    func totalSpent(in month: Month?) -> Decimal {
        return itemsIn(month: month).map { $0.totalSpent }.reduce(0, +)
    }
    
    /// Find or create new category given name
    public class func findOrCreate(name: String, in context: NSManagedObjectContext) -> Category {
        if let category = Category.alreadyExists(name: name, in: context) {
            return category
        }
        
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.number = Int16(Category.nextAvailableNumber(context: context))
        try? context.save()
        return category
    }
    
    /// Edit name of category
    func edit(name: String, in context: NSManagedObjectContext) -> Bool {
        if let _ = Category.alreadyExists(name: name, in: context) {
            return false
        }
        
        if name == "" {
            return false
        }
        
        self.name = name
        
        if context.hasChanges {
            try? context.save()
        }
        return true
    }
    
    /// Delete category after moving all items to "None" category
    func delete(context: NSManagedObjectContext) {
        itemsArray.forEach { $0.category = Category.getNoneCategory(context: context) }
        context.delete(self)
        if context.hasChanges {
            try? context.save()
        }
    }
    
    /// Returns next available category number
    private class func nextAvailableNumber(context: NSManagedObjectContext) -> Int {
        let categories = try? context.fetch(fetchRequest())
        if let highestNumber = categories?.sorted(by: { $0.number > $1.number }).first?.number {
            return Int(highestNumber) + 1
        }
        
        return 0
    }
    
    /// Modify category numbers properly given an array of categories
    public class func rearrangeCategories(categories: [Category], context: NSManagedObjectContext) {
        var begin = 0
        categories.forEach {
            $0.number = Int16(begin)
            begin += 1
        }
        
        if context.hasChanges {
            try? context.save()
        }
        
    }
    
    /// Return "None" category
    public class func getNoneCategory(context: NSManagedObjectContext) -> Category {
        findOrCreate(name: "None", in: context)
    }
    
    /// Return category given name or nil if doesn't exist
    private class func alreadyExists(name: String, in context: NSManagedObjectContext) -> Category? {
        if let categories = try? context.fetch(fetchRequest()) as [Category] {
            if let result = categories.first(where: {$0.name == name}) {
                return result
            }
        }
        
        return nil
    }
    
    public class func isValid(name: String, context: NSManagedObjectContext) -> Bool {
        if name == "" {
            return false
        }
        
        if alreadyExists(name: name, in: context) != nil {
            return false
        }
        
        return true
    }

}

// MARK: Generated accessors for items
extension Category {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension Category : Identifiable {

}
