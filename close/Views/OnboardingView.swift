//
//  OnboardingView.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    @Environment(NotificationManager.self) private var notificationManager
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)
                
                notificationPage
                    .tag(1)
                
                readyPage
                    .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .interactiveDismissDisabled()
        .background(Color("BackgroundPrimary"))
    }
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color("StatusRed"))
            
            Text("Welcome to Close")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Stay in touch with the people who matter most")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: { currentPage = 1 }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .padding()
    }
    
    private var notificationPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)
            
            Text("Stay Reminded")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get gentle reminders when it's time to reach out to your friends and family")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                Task {
                    let granted = await notificationManager.requestAuthorization()
                    if granted {
                        currentPage = 2
                    } else {
                        currentPage = 2
                    }
                }
            }) {
                Text("Enable Notifications")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: { currentPage = 2 }) {
                Text("Skip")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
    
    private var readyPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color("StatusGreen"))
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Start by adding contacts you want to keep in touch with")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
                isPresented = false
            }) {
                Text("Start Using Close")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true), hasCompletedOnboarding: .constant(false))
        .environment(NotificationManager.shared)
}

