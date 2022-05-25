//
//  NavController.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI
import CoreData

class NavController: ObservableObject {
    enum Tab {
        case budget
        case manage
        case statistics
        case transactions
    }
    
    @Published var activeTab = Tab.budget
    @Published var selectedMonth: Month?
    @Published var months: [Month] = []
        
    func open(_ tab: Tab, segue: Bool = false) {
        activeTab = tab
    }
    
    func getMonth(month: Int, year: Int) -> Month? {
        if let date = Calendar.current.date(from: DateComponents(year: year, month: month)) {
            if let month = months.first(where: { month in
                month.begin == date.getStart(of: .month)
            }) {
                return month
            }
            
        }
        
        return nil
    }
    
    func set(month: Month) {
        selectedMonth = month
        
        if let context = month.managedObjectContext {
            months = Month.allMonths(in: context)
        }
    }
    
    func createMonth(month: Int, year: Int) {
        if let _ = getMonth(month: month, year: year) {
            return
        }
        
        if let context = months.first?.managedObjectContext {
            if let date = Calendar.current.date(from: DateComponents(year: year, month: month)) {
                self.set(month: Month.findOrCreate(date: date, in: context))
            }
        }
    }
    
    func getEarliestMonthDate() -> Date? {
        if let firstMonth = months.first {
            return firstMonth.date
        }
        
        return nil
    }
    
    func getLatestMonthDate() -> Date? {
        if let latestMonth = months.last {
            return latestMonth.date
        }
        
        return nil
    }
    
    func loadMonths(context: NSManagedObjectContext) {
        months = Month.allMonths(in: context)
    }
}
