//
//  ContentView.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import SwiftUI

enum UserDefaultsKeys {
    static let hasShownOnboardingSheet = "hasShownOnboardingSheet"
    static let hasPreloadedBudget = "hasPreloadedBudget"
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @StateObject var navController = NavController()
    
    @State private var showOnboardingSheet = false
    
    var body: some View {
        let selectedMonth = navController.selectedMonth ?? Month.current(in: context)
        TabView(selection: $navController.activeTab) {
            ManageBudgetView(month: selectedMonth)
                .tag(NavController.Tab.manage)
                .tabItem {
                    Label("Manage", systemImage: "hammer")
                }
            BudgetView(month: selectedMonth)
                .tag(NavController.Tab.budget)
                .tabItem {
                    Label("Budget", systemImage: "list.dash")
                }
            StatisticsView(month: selectedMonth)
                .tag(NavController.Tab.statistics)
                .tabItem {
                    Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasPreloadedBudget) == false {
                if Item.getTemplateItems(context: context).count == 0 {
                    DataController.seed(context: context)
                    UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasPreloadedBudget)
                }
            }
            
            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasShownOnboardingSheet) == false {
                showOnboardingSheet = true
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasShownOnboardingSheet)
            }
            
            navController.set(month: selectedMonth)
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView()
        }
        .environmentObject(navController)
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
