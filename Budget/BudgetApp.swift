//
//  BudgetApp.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI

@main
struct BudgetApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
