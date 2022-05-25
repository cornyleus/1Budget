//
//  DataController.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentCloudKitContainer(name: "Budget")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core data failed to load: \(error.localizedDescription)")
            }
        }
        
        //        #if DEBUG
        //        do {
        //            // Use the container to initialize the development schema.
        //            try container.initializeCloudKitSchema(options: [])
        //        } catch {
        //            // Handle any errors.
        //        }
        //        #endif
    }
    
    public class func seed(context: NSManagedObjectContext) {
        let month = Month.current(in: context)
        
        let monthlyExpensesCat = Category.findOrCreate(name: "Monthly Expenses", in: context)
        let monthlyExpensesItems = [
            Item.createTemplateItem(context: context, category: monthlyExpensesCat, name: "Housing"),
            Item.createTemplateItem(context: context, category: monthlyExpensesCat, name: "Utilities"),
            Item.createTemplateItem(context: context, category: monthlyExpensesCat, name: "Online Services"),
            Item.createTemplateItem(context: context, category: monthlyExpensesCat, name: "Insurance")
        ]
        monthlyExpensesItems.forEach { $0.createMonthlyItem(in: month, context: context) }
        
        let dailyExpensesCat = Category.findOrCreate(name: "Daily Expenses", in: context)
        let dailyExpensesItems = [
            Item.createTemplateItem(context: context, category: dailyExpensesCat, name: "Groceries"),
            Item.createTemplateItem(context: context, category: dailyExpensesCat, name: "Personal Care"),
            Item.createTemplateItem(context: context, category: dailyExpensesCat, name: "Home Goods"),
            Item.createTemplateItem(context: context, category: dailyExpensesCat, name: "Spending Money")
        ]
        dailyExpensesItems.forEach { $0.createMonthlyItem(in: month, context: context) }
        
        let transportationCat = Category.findOrCreate(name: "Transportation", in: context)
        let transportationItems = [
            Item.createTemplateItem(context: context, category: transportationCat, name: "Car Payment"),
            Item.createTemplateItem(context: context, category: transportationCat, name: "Insurance"),
            Item.createTemplateItem(context: context, category: transportationCat, name: "Gas"),
            Item.createTemplateItem(context: context, category: transportationCat, name: "Maintenance")
        ]
        transportationItems.forEach { $0.createMonthlyItem(in: month, context: context) }
        
        let savingsCat = Category.findOrCreate(name: "Savings", in: context)
        let savingsItems = [
            Item.createTemplateItem(context: context, category: savingsCat, name: "Investing"),
            Item.createTemplateItem(context: context, category: savingsCat, name: "Debt Payoff")
        ]
        savingsItems.forEach { $0.createMonthlyItem(in: month, context: context) }
        
        /// create initial None category
        let noneCat = Category.getNoneCategory(context: context)
    }
    
}
