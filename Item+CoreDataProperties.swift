//
//  Item+CoreDataProperties.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//
//

import Foundation
import CoreData


extension Item {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }
    
    @NSManaged public var name: String?
    @NSManaged public var id: UUID?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var number: Int16
    @NSManaged public var month: Month?
    @NSManaged public var category: Category?
    @NSManaged public var templateItem: Item?
    @NSManaged public var monthlyItems: NSSet?
    @NSManaged public var transactions: NSSet?
    
    
    /// All Items
    public class func getAllItems(context: NSManagedObjectContext) -> [Item] {
        if let items = try? context.fetch(fetchRequest()) {
            return items
        }
        
        return []
    }
    
    /// All Template items
    public class func getTemplateItems(context: NSManagedObjectContext) -> [Item] {
        if let items = try? context.fetch(fetchRequest()) {
            return items.filter { $0.isTemplateItem }
        }
        
        return []
    }
    
    /// Item's category name
    @objc public var categoryName: String {
        category?.name ?? "None"
    }
    
    /// Item number for sorting within category
    @objc var itemNumber: Int {
        if isTemplateItem {
            return Int(number)
        } else {
            if let templateItem = templateItem {
                return Int(templateItem.number)
            }
        }
        
        return 1
    }
    
    /// Private helper to retrieve transactions
    private var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { $0.date! < $1.date! }
    }
    
    /// Monthly items casted as array
    var monthlyItemsArray: [Item] {
        let set = monthlyItems as? Set<Item> ?? []
        return set.sorted { $0.name! > $1.name! }
    }
    
    /// Public method to get all transactions of Monthly item or Template item
    func getTransactions() -> [Transaction] {
        let children = monthlyItems as? Set<Item> ?? []
        if children.isEmpty {
            return transactionsArray
        }
        
        var array = transactionsArray
        
        children.forEach { item in
            array += item.transactionsArray
        }
        
        return array
    }
    
    /// Total spent of Monthly or Template item
    public var totalSpent: Decimal {
        getTransactions().map { $0.amount! as Decimal }.reduce(0, +)
    }
    
    /// Balance remaining in budget
    public var totalRemaining: Decimal {
        (amount! as Decimal) - totalSpent
    }
    
    /// True if Item is a template item
    var isTemplateItem: Bool {
        templateItem == nil
    }
    
    /// Most recent payee from item
    func mostRecentPayee() -> Payee? {
        if let latestTransaction = getTransactions().last {
            if let latestPayee = latestTransaction.payee {
                return latestPayee
            }
        }
        
        return nil
    }
    
        
    /// Public edit for updating Amount only of monthly item
    func edit(amount: Decimal, context: NSManagedObjectContext) {
        if !isTemplateItem {
            edit(context: context, amount: amount)
        }
        
        if context.hasChanges {
            try? context.save()
        }
    }
    
    /// Public edit, handles items as well as template item
    func edit(name: String, amount: Decimal, category: Category, month: Month, in context: NSManagedObjectContext) {
            edit(context: context, name: name, amount: amount, month: month, category: category)
            templateItem?.edit(context: context, name: name, category: category)
            templateItem?.monthlyItemsArray.forEach { $0.edit(context: context, name: name, category: category) }
        
        if context.hasChanges {
            try? context.save()
        }

    }
    
    /// Private helper edit, change whatever is passed, ignore what isn't
    private func edit(context: NSManagedObjectContext, name: String? = nil, amount: Decimal, month: Month? = nil, category: Category? = nil, templateItem: Item? = nil) {
        if let name = name {
            self.name = name
        }
        self.amount = amount as NSDecimalNumber
        if let month = month {
            self.month = month
        }
        if let category = category {
            self.category = category
        }
        if let templateItem = templateItem {
            self.templateItem = templateItem
        }
        
        if context.hasChanges {
            try? context.save()
        }

    }
    
    /// Private helper edit, only change name and category
    private func edit(context: NSManagedObjectContext, name: String, category: Category) -> Item {
        self.name = name
        self.category = category
        
        if context.hasChanges {
            try? context.save()
        }

        return self
    }
    
    /// Create base budget item from which periods will generate their budget items
    public class func createTemplateItem(context: NSManagedObjectContext, category: Category, name: String) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.number = Int16(Item.nextAvailableNumberWithin(category: category, context: context))
        item.category = category
        item.name = name
        item.amount = 0
        item.templateItem = nil
        
        print(item.name)
        print(item.number)
        
        try? context.save()
        return item
    }
    
    func createMonthlyItem(in month: Month, context: NSManagedObjectContext) {
        Item.createItem(in: month, templateItem: self, context: context)
        try? context.save()
    }
    
    /// Create items in specific period based on passed templateItem
    public class func createItem(in month: Month, templateItem: Item, amount: Decimal = 0, seedMonths: Bool = false, context: NSManagedObjectContext) -> Item {
        
        let item = Item(context: context)
        item.id = UUID()
        item.month = month
        item.category = templateItem.category
        item.name = templateItem.name
        item.amount = amount as NSDecimalNumber
        item.templateItem = templateItem
        
        if seedMonths {
            self.seedMonths(item: templateItem, currentMonth: month, context: context)
        }
        
        try? context.save()
        
        return item
    }
    
    /// create Month items within other existing months with newly created item
    public class func seedMonths(item: Item, currentMonth: Month, context: NSManagedObjectContext) {
        if let allMonths = try? context.fetch(Month.fetchRequest()) as [Month] {
            allMonths.filter { $0 != currentMonth }.forEach { month in
                // create item in all periods other than currentPeriod
                self.createItem(in: month, templateItem: item, context: context)
            }
        }
        
        if context.hasChanges {
            try? context.save()
        }
    }
    
    /// Delete Item: deletes template item as well as all monthly budget items
    public class func delete(item: Item) -> Bool {
        guard let context = item.managedObjectContext else { return false }
        
        if item.isTemplateItem {
            item.monthlyItemsArray.forEach {
                context.delete($0)
            }
        } else {
            if let templateItem = item.templateItem {
                delete(item: templateItem)
            }
        }
        
        context.delete(item)
        
        if context.hasChanges {
            try? context.save()
        }
        
        return true
    }
    
    /// Find item given name and month
    public class func getItem(named name: String, in month: Month?, context: NSManagedObjectContext) -> Item? {
        let items = getAllItems(context: context)
        if let item = items.filter({ $0.name == name && $0.month == month }).first {
            return item
        }
        
        return nil
    }
    
    /// Find next available item number within category
    private class func nextAvailableNumberWithin(category: Category, context: NSManagedObjectContext) -> Int {
        let categoryTemplateItems = category.templateItemsArray
        if let highestNumber = categoryTemplateItems.last?.itemNumber {
            return Int(highestNumber) + 1
        }
        
        return 0
    }
    
    /// Validate item
    public class func validate(name: String? = nil, amount: String? = nil) -> Bool {
        var valid = true
        
        if let amount = amount {
            var decimalAmount: NSDecimalNumber {
                NSDecimalNumber(string: amount.removeFormatAmount())
            }
            
            if decimalAmount == NSDecimalNumber.notANumber {
                valid = false
            }
        }
        
        if let name = name {
            if name == "" {
                valid = false
            }
        }
        
        return valid
    }
    
    /// Modify item numbers properly given an array of items
    public class func rearrangeItems(items: [Item], context: NSManagedObjectContext) {
        var begin = 0
        items.forEach {
            $0.number = Int16(begin)
            begin += 1
        }
        
        if context.hasChanges {
            try? context.save()
        }
    }

}

// MARK: Generated accessors for transactions
extension Item {
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
    
}

extension Item : Identifiable {
}
