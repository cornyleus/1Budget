//
//  Payee+CoreDataProperties.swift
//  Budget
//
//  Created by Cory Iley on 3/31/22.
//
//

import Foundation
import CoreData

extension Payee {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Payee> {
        return NSFetchRequest<Payee>(entityName: "Payee")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var locationCoords: String?
    @NSManaged public var transactions: NSSet?
    
    /// All transactions from Payee in array
    var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { $0.date! < $1.date! }
    }
    
    /// Total spent by Payee
    func totalSpent() -> Decimal {
        transactionsArray.map { $0.amount! as Decimal }.reduce(0, +)
    }
    
    /// All transactions from a given Item and/or Month
    func transactionsFrom(month: Month? = nil, item: Item? = nil) -> [Transaction] {
        var tempTransactions = transactionsArray
        
        if let month = month {
            tempTransactions = tempTransactions.filter { $0.isWithin(month: month) }
            if let item = item {
                tempTransactions = tempTransactions.filter { $0.item == item }
            }
        } else {
            if let item = item {
                if item.isTemplateItem {
                    tempTransactions = tempTransactions.filter { $0.item?.templateItem == item }
                } else {
                    tempTransactions = tempTransactions.filter { $0.item == item }
                }
            }
        }
        
        return tempTransactions
    }
    
    /// Total spent by payee in given Item and/or Month
    func totalSpent(in month: Month? = nil, item: Item? = nil) -> Decimal {
        transactionsFrom(month: month, item: item).map { $0.amount! as Decimal }.reduce(0, +)
    }
    
    /// Edit name of payee
    func edit(name: String, in context: NSManagedObjectContext) -> Bool {
        if name == "" {
            return false
        }
        
        if let existingPayee = Payee.alreadyExists(name: name, in: context) {
            mergeFrom(existingPayee: existingPayee, context: context)
            return true
        }

        print("new name")
        self.name = name
        if context.hasChanges {
            try? context.save()
        }

        return true
    }
    
    private func mergeFrom(existingPayee: Payee, context: NSManagedObjectContext) {
        let existingTransactions = existingPayee.transactionsArray
        
        existingTransactions.forEach { $0.payee = self }
        if existingPayee.transactionsArray.count == 0 {
            self.name = existingPayee.name
            context.delete(existingPayee)
        }
        
        if context.hasChanges {
            try? context.save()
        }

    }
    
    /// Find or create new Payee with given name
    public class func findOrCreate(name: String, in context: NSManagedObjectContext) -> Payee? {
        if let payee = Payee.alreadyExists(name: name, in: context) {
            return payee
        }
        
        if name == "" {
            return nil
        }
        
        let payee = Payee(context: context)
        payee.id = UUID()
        payee.name = name
        try? context.save()
        return payee
    }
    
    /// Return payee if already exists
    class func alreadyExists(name: String, in context: NSManagedObjectContext) -> Payee? {
        if let payees = try? context.fetch(fetchRequest()) as [Payee] {
            if let result = payees.first(where: {$0.name!.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
                return result
            }
        }
        
        return nil
    }
    
    class func delete(payee: Payee) -> Bool {
        guard let context = payee.managedObjectContext else { return false }
        
        context.delete(payee)
        
        if context.hasChanges {
            try? context.save()
        }
        
        return true
    }

}

// MARK: Generated accessors for transactions
extension Payee {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension Payee : Identifiable {

}
