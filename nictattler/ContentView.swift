//
//  ContentView.swift
//  nictattler
//
//  Created by saurish on 6/8/25.
//

import SwiftUI
import Contacts

struct ContentView: View {
    @State private var contacts: [CNContact] = []
    @State private var messageStatus: String = ""

    var body: some View {
        VStack {
            Text("Nictattler")
                .font(.largeTitle)
                .padding()

            Button("Request and Load Contacts") {
                requestContactsAccess()
            }
            .padding()

            Button("Send Test iMessage") {
                sendIMessage()
            }
            .padding()
            
            Text(messageStatus)
                .padding()

            List(contacts, id: \.self) { contact in
                VStack(alignment: .leading) {
                    Text("\(contact.givenName) \(contact.familyName)")
                        .font(.headline)
                    ForEach(contact.phoneNumbers, id: \.self) { phoneNumber in
                        Text(phoneNumber.value.stringValue)
                    }
                }
            }
        }
        .padding()
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
