//
//  ContentView.swift
//  nictattler
//
//  Created by saurish on 6/8/25.
//

import SwiftUI
import Contacts

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @State private var contacts: [CNContact] = []
    @State private var messageStatus: String = ""
    @State private var puffGoal: Int = 10
    @State private var puffsToday: Int = 2
    @State private var streak: Int = 0
    @State private var monthlyProgress: Double = 0.6
    @State private var showingGoalUpdate: Bool = false
    @State private var tempGoal: Int = 10
    @State private var contactsAccessible: Bool = false
    @State private var messagesAccessible: Bool = false

    let accentColor = Color(hex: "BBACC1")
    let backgroundColor = Color(hex: "F1DEDE")

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                // Header and Status Buttons
                VStack(spacing: 25) {
                    VStack(spacing: 8) {
                        Text("nictattler")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .padding(.bottom, 10)
                        Text("get rid of your addiction via social embarrassment :)")
                            .font(.system(size: 20, weight: .regular, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Status Buttons
                    HStack(spacing: 20) {
                    // Contacts Access Status
                    Button(action: {
                        checkContactsAccess()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: contactsAccessible ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(contactsAccessible ? .green : .red)
                                .font(.system(size: 16))
                            Text("Contacts")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Messages Access Status
                    Button(action: {
                        checkMessagesAccess()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: messagesAccessible ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(messagesAccessible ? .green : .red)
                                .font(.system(size: 16))
                            Text("Messages")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 50)

                // Update Goal Button
                Button(action: {
                    tempGoal = puffGoal
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showingGoalUpdate = true
                    }
                }) {
                    Text("Update Goal")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(accentColor)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())

                // Stats
                VStack(spacing: 15) {
                    Text("your current statistics:")
                        .font(.title2.bold())
                        .foregroundColor(Color.black.opacity(0.8))
                    
                    Text("puffs today: \(puffsToday) / \(puffGoal)")
                        .font(.title3)
                        .foregroundColor(Color.black.opacity(0.7))
                    
                    // Progress bar
                    VStack(spacing: 10) {
                        // Custom progress bar that maintains color regardless of focus
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 16)
                                    .cornerRadius(8)
                                
                                Rectangle()
                                    .fill(accentColor)
                                    .frame(width: max(0, CGFloat(Double(puffsToday) / Double(puffGoal)) * geometry.size.width), height: 16)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(height: 16)
                        .padding(.vertical, 5)
                        
                        HStack {
                            Text("0%")
                            Spacer()
                            Text("(text being sent)")
                        }
                        .font(.footnote)
                        .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 80)
                    
                    Text("current streak: \(streak) days")
                        .font(.title3)
                        .foregroundColor(Color.black.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .blur(radius: showingGoalUpdate ? 10 : 0)
            .animation(.easeInOut(duration: 1.0), value: showingGoalUpdate)

            // Goal Update Modal
            if showingGoalUpdate {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingGoalUpdate = false
                            }
                        }
                    
                    VStack(spacing: 30) {
                        Text("Update Your Goal")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Current goal: \(puffGoal) hits / day")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                        
                        VStack(spacing: 20) {
                            Text("\(tempGoal)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 40)
                                .background(Color.white.opacity(0.6))
                                .cornerRadius(20)
                            
                            HStack(spacing: 30) {
                                Button(action: {
                                    if tempGoal > 1 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            tempGoal -= 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    if tempGoal < 50 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            tempGoal += 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showingGoalUpdate = false
                                }
                            }
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 25)
                            .background(Color.white.opacity(0.4))
                            .cornerRadius(15)
                            .buttonStyle(PlainButtonStyle())
                            
                            Button("Save") {
                                puffGoal = tempGoal
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showingGoalUpdate = false
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 25)
                            .background(accentColor)
                            .cornerRadius(15)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(40)
                    .background(backgroundColor)
                    .cornerRadius(25)
                    .scaleEffect(showingGoalUpdate ? 1.0 : 0.8)
                    .opacity(showingGoalUpdate ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0), value: showingGoalUpdate)
                }
            }
        }
        .onAppear {
            requestContactsAccess()
            fetchContacts()
            tempGoal = puffGoal
            checkContactsAccess()
            checkMessagesAccess()
        }
    }

    func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            if granted {
                print("access granted")
                fetchContacts()
            } else {
                print("access denied")
            }
        }
    }
    
    func checkContactsAccess() {
        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async {
            self.contactsAccessible = (status == .authorized)
        }
    }
    
    func checkMessagesAccess() {
        // Check if Messages app can be opened (basic capability check)
        let urlString = "sms:"
        if let url = URL(string: urlString) {
            DispatchQueue.main.async {
                self.messagesAccessible = NSWorkspace.shared.urlForApplication(toOpen: url) != nil
            }
        } else {
            DispatchQueue.main.async {
                self.messagesAccessible = false
            }
        }
    }
    
    func fetchContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var fetchedContacts: [CNContact] = []
                try store.enumerateContacts(with: request) { (contact, stop) in
                    fetchedContacts.append(contact)
                }
                DispatchQueue.main.async {
                    self.contacts = fetchedContacts
                }
            } catch {
                print("failed to fetch contacts", error)
            }
        }
    }

    func sendIMessage() {
        let phoneNumber = "4082507363"
        let message = "Hello from nictattler! This is a test message."
        
        guard let messageBody = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.messageStatus = "Error: Could not encode the message."
            return
        }

        let urlString = "sms:\(phoneNumber)&body=\(messageBody)"

        guard let url = URL(string: urlString) else {
            self.messageStatus = "Error: Could not create the URL."
            return
        }

        let success = NSWorkspace.shared.open(url)

        if success {
            self.messageStatus = "Opened Messages successfully. Press send!"
        } else {
            self.messageStatus = "Error: Could not open Messages."
        }
    }
}

#Preview {
    ContentView()
} 