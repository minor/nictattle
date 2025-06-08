//
//  ContentView.swift
//  nictattler
//
//  Created by saurish on 6/8/25.
//

import SwiftUI
import Contacts

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Nictattler")
                .font(.largeTitle)
                .padding()

            Button("Request Contacts Access") {
                requestContactsAccess()
            }
            .padding()

            Button("Send Test iMessage") {
                sendIMessage()
            }
            .padding()
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
            } else {
                print("access denied")
            }
        }
    }

    func sendIMessage() {
        let phoneNumber = "4082507363"
        let message = "Hello from nictattler! This is a test message."

        let scriptSource = """
        tell application "Messages"
            activate
            set targetService to 1st service whose service type = iMessage
            set targetBuddy to buddy "\(phoneNumber)" of targetService
            send "\(message)" to targetBuddy
        end tell
        """

        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            if let output = script.executeAndReturnError(&error).stringValue {
                print(output)
            } else if let error = error {
                print("error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
