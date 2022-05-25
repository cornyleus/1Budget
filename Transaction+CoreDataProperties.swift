//
//  Transaction+CoreDataProperties.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var expense: Bool
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var memo: String?
    @NSManaged public var date: Date?
    @NSManaged public var payee: Payee?
    @NSManaged public var item: Item?
    
    /// Name of the transaction's payee
    var name: String {
        payee?.name ?? "Payee"
    }
    
    /// Create transaction
    public class func createTransaction(context: NSManagedObjectContext, expense: Bool = true, item: Item, name: String, amount: Decimal, memo: String = "", date: Date) -> Transaction {
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.expense = expense
        
        let month = Month.findOrCreate(date: date, in: context)
        transaction.item = month.getItem(templateItem: item.templateItem ?? item)
        
        transaction.date = date
        transaction.payee = Payee.findOrCreate(name: name, in: context)
        transaction.amount = amount as NSDecimalNumber
        transaction.memo = memo
        try? context.save()
        return transaction
    }
    
    /// Edit transaction
    func edit(context: NSManagedObjectContext, expense: Bool = true, item: Item, name: String, amount: Decimal, memo: String = "", date: Date) -> Transaction {
        self.expense = expense
        self.payee = Payee.findOrCreate(name: name, in: context)
        self.amount = amount as NSDecimalNumber
        self.memo = memo
        self.date = date
        
        let month = Month.findOrCreate(date: date, in: context)
        self.item = month.getItem(templateItem: item.templateItem ?? item)
        
        if context.hasChanges {
            try? context.save()
        }

    
        return self
    }

    /// Return true if transaction is within given Month object
    func isWithin(month: Month) -> Bool {
        let dateRange = month.begin ... month.end
        if dateRange.contains(date!) {
            return true
        }
        return false
    }
    
    /// Delete transaction, return true if successful
    public class func delete(transaction: Transaction) -> Bool {
        guard let context = transaction.managedObjectContext else { return false }
        
        context.delete(transaction)
        
        if context.hasChanges {
            try? context.save()
        }

        return true
    }
    
    /// Validate name and/or amount
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
}

extension Transaction : Identifiable {

}
