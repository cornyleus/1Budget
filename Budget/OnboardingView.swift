//
//  OnboardingView.swift
//  Budget
//
//  Created by Cory Iley on 4/27/22.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    
    struct OnboardImage: View {
        let imageName: String
        
        init(_ imageName: String) {
            self.imageName = imageName
        }
        
        var body: some View {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .shadow(radius: 2)
        }
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentIndex) {
                Group {
                    VStack {
                        Text("To begin, navigate to the Manage tab and add Budget Items.")
                        OnboardImage("onboard_newbudgitem1")
                        Spacer()
                        OnboardImage("onboard_newbudgitem2")
                        Spacer()
                    }
                    .tag(0)
                    VStack {
                        Text("Track your spending by creating transactions in the Budget tab.")
                        OnboardImage("onboard_newtransac1")
                        Spacer()
                        Text("Or...")
                        Spacer()
                        OnboardImage("onboard_newtransac2")
                        Spacer()
                    }
                    
                    .tag(1)
                    VStack {
                        Text("The Statistics tab allows you to view your monthly spending habits over time.")
                        OnboardImage("onboard_stats")
                        Spacer()
                    }
                    
                    .tag(2)
                    VStack {
                        Text("We've pre-loaded some categories and budget items for you.  Feel free to delete or modify them as you see fit!")
                        Spacer()
                        Button("Start Budgeting") { dismiss() }
                        Spacer()
                    }
                    .tag(3)
                }
                .padding()
                
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .navigationTitle("Welcome!")
        }
    }
}
