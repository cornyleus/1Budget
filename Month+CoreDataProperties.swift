//
//  Period+CoreDataProperties.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//
//

import Foundation
import CoreData


extension Month {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Month> {
        return NSFetchRequest<Month>(entityName: "Month")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var year: Int16
    @NSManaged public var month: Int16
    @NSManaged public var items: NSSet?
    
    /// Returns Month as March '22, etc.
    public override var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM ''yy"
        return formatter.string(from: date)
    }
    
    /// The DateComponents() object returned using Month's year and month attributes
    var dateComponents: DateComponents {
        DateComponents(year: Int(year), month: Int(month))
    }
    
    /// Date() object for the Month
    var date: Date {
        Calendar.current.date(from: dateComponents)?.getStart(of: .month) ?? Date()
    }
    
    /// Date() of beginning of the Month
    var begin: Date {
        date
    }
    
    /// Date() of end of month
    var end: Date {
        date.getEnd(of: .month) ?? Date()
    }
    
    /// Budget items belonging to month
    var monthlyItems: [Item] {
        let set = items as? Set<Item> ?? []
        
        return set.sorted { $0.categoryName > $1.categoryName }
    }
    
    /// Find or create Month object given a passed Date()
    public class func findOrCreate(date: Date, in context: NSManagedObjectContext) -> Month {
        if let month = alreadyExists(date: date, in: context) {
            return month
        }
        
        let yearInt = Calendar.current.component(.year, from: date)
        let monthInt = Calendar.current.component(.month, from: date)
        
        let month = Month(context: context)
        month.id = UUID()
        month.year = Int16(yearInt)
        month.month = Int16(monthInt)
        
        let templateItems = Item.getTemplateItems(context: context)
        templateItems.forEach { item in
            Item.createItem(in: month, templateItem: item, context: context)
        }
        
        try? context.save()
        
        return month
    }
    
    /// Returns (creating if needed) the current Month based on current Date()
    static func current(in context: NSManagedObjectContext) -> Month {
        if let month = alreadyExists(date: Date(), in: context) {
            return month
        }
        
        let month = findOrCreate(date: Date(), in: context)
        return month
    }
    
    /// All transactions from all items in Month
    var allTransactions: [Transaction] {
        var transactions: [Transaction] = []
        
        monthlyItems.forEach { transactions.append(contentsOf: $0.getTransactions()) }
        return transactions
    }
        
    /// Total budgeted across all items in Month
    var totalBudgeted: Decimal {
        monthlyItems.map { $0.amount! as Decimal }.reduce(0, +)
    }
    
    /// Total spent across all items in Month
    var totalSpent: Decimal {
        monthlyItems.map { $0.totalSpent }.reduce(0, +)
    }
    
    /// Total balance remaining in month
    var totalBalance: Decimal {
        monthlyItems.map { $0.totalRemaining }.reduce(0, +)
    }
    
    /// Return all Month objects that exist in context
    public class func allMonths(in context: NSManagedObjectContext) -> [Month] {
        guard let months = try? context.fetch(Month.fetchRequest()) else { return [] }
        
        return months.sorted { $0.date < $1.date }
    }
    
    /// Return Month if already exists
    private class func alreadyExists(date: Date, in context: NSManagedObjectContext) -> Month? {
        if let months = try? context.fetch(fetchRequest()) as [Month] {
            if let result = months.first(where: {$0.begin == date.getStart(of: .month) }) {
                return result
            }
        }
    
        return nil
    }
    
    /// Return monthly item from passed  TemplateItem
    func getItem(templateItem: Item) -> Item? {
        if let item = monthlyItems.first(where: { item in
            templateItem.name! == item.name
        }) {
            return item
        }
        
        return nil
    }

}

// MARK: Generated accessors for items
extension Month {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension Month : Identifiable {

}
