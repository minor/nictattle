//
//  ContentView.swift
//  nictattler
//
//  Created by saurish on 6/8/25.
//

import SwiftUI
import Contacts
import AVFoundation

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
    @AppStorage("puffGoal") var puffGoal: Int = 10
    @AppStorage("puffsToday") var puffsToday: Int = 0
    @AppStorage("lastResetDate") var lastResetDate: String = ""
    @AppStorage("penaltySentToday") var penaltySentToday: Bool = false
    @State private var streak: Int = 0
    @State private var monthlyProgress: Double = 0.6
    @State private var showingGoalUpdate: Bool = false
    @State private var tempGoal: Int = 10
    @State private var contactsAccessible: Bool = false
    @State private var messagesAccessible: Bool = false
    @StateObject private var cameraManager = CameraManager()
    @State private var boundingBoxes: [CGRect] = []
    @State private var lastDetectionDate: Date?
    
    private let objectDetector = ObjectDetector()

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
                    
                    // Camera Access Status
                    Button(action: {
                        cameraManager.checkAuthorization()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: cameraManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(cameraManager.isAuthorized ? .green : .red)
                                .font(.system(size: 16))
                            Text("Camera")
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

                // Camera View
                if cameraManager.isAuthorized {
                    CameraPreview(session: cameraManager.session)
                        .frame(height: 200)
                        .cornerRadius(15)
                        .overlay(
                            // Add the bounding box overlay
                            BoundingBoxOverlay(boxes: boundingBoxes)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(accentColor.opacity(0.5), lineWidth: 2)
                        )
                } else {
                    VStack(spacing: 10) {
                        Text("Enable camera access to begin vape tracking.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Button("Grant Camera Access") {
                            cameraManager.checkAuthorization()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(accentColor)
                        .cornerRadius(12)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .frame(height: 200)
                    .background(Color.white.opacity(0.4))
                    .cornerRadius(15)
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
            cameraManager.checkAuthorization()
            resetPuffsIfNeeded()

            // Connect the camera manager to the object detector
            cameraManager.objectDetector = objectDetector
            objectDetector.onResults = { boxes in
                self.boundingBoxes = boxes

                // Increment puff count on detection, with a cooldown
                guard !boxes.isEmpty else { return }

                let now = Date()
                let cooldown: TimeInterval = 5 // 5 seconds

                if let lastDate = self.lastDetectionDate {
                    if now.timeIntervalSince(lastDate) > cooldown {
                        self.puffsToday += 1
                        self.lastDetectionDate = now
                    }
                } else {
                    // First detection
                    self.puffsToday += 1
                    self.lastDetectionDate = now
                }
            }
        }
        .onChange(of: puffsToday) { newValue in
            if newValue > puffGoal && !penaltySentToday {
                executePenalty()
            }
        }
    }

    func resetPuffsIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        if todayString != lastResetDate {
            puffsToday = 0
            penaltySentToday = false
            lastResetDate = todayString
            print("Puff counter has been reset for the new day.")
        }
    }

    func executePenalty() {
        print("Puff goal exceeded! Executing penalty.")

        // 1. Select a random contact with a phone number
        guard let contact = contacts.filter({ !$0.phoneNumbers.isEmpty }).randomElement() else {
            self.messageStatus = "No contacts with phone numbers found to send penalty to."
            return
        }

        // 2. Send the message
        sendPenaltyMessage(to: contact)
        
        // 3. Mark penalty as sent for the day
        penaltySentToday = true
    }

    func sendPenaltyMessage(to contact: CNContact) {
        // 1. Get phone number
        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue.filter("0123456789".contains) else { return }
        
        // 2. Prepare and send the message
        let embarrassingMessage = "Hey, my friend is holding me accountable for my vaping addiction. I just went over my limit for the day. I have been a very bad boy and hopefully my addiction gets better."
        
        guard let messageBody = embarrassingMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.messageStatus = "Error: Could not encode the message."
            return
        }

        let urlString = "sms:\(phoneNumber)&body=\(messageBody)"
        guard let url = URL(string: urlString) else { return }

        let success = NSWorkspace.shared.open(url)
        if success {
            self.messageStatus = "Penalty message opened. Press send!"
        } else {
            self.messageStatus = "Error: Could not open Messages."
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

// MARK: - Camera Components

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var session = AVCaptureSession()
    @Published var isAuthorized = false

    private let sessionQueue = DispatchQueue(label: "com.nictattler.sessionQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Add a reference to the object detector
    var objectDetector: ObjectDetector?

    override init() {
        super.init()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            setupSession()
        case .notDetermined:
            requestAccess()
        default:
            DispatchQueue.main.async { self.isAuthorized = false }
        }
    }

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupSession()
                }
            }
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(for: .video) else {
                print("Error: No video device found.")
                self.session.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    print("Error: Can't add camera input to session.")
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                print("Error setting up camera input: \(error.localizedDescription)")
                self.session.commitConfiguration()
                return
            }
            
            // Add the video data output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            } else {
                print("Error: Can't add video output to session.")
                self.session.commitConfiguration()
                return
            }

            self.session.commitConfiguration()
            
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // This delegate method is called for every frame captured by the camera
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Pass the frame to the object detector
        objectDetector?.processFrame(sampleBuffer)
    }
}

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        
        // Flip the camera view horizontally for a mirror effect
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }

        view.layer = previewLayer
        
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                layer.frame = nsView.bounds
            }
        }
    }
}

// A new view to draw the bounding boxes on the screen
struct BoundingBoxOverlay: View {
    let boxes: [CGRect]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<boxes.count, id: \.self) { index in
                let box = boxes[index]
                
                // Vision's coordinate system is normalized and has an origin at the bottom-left.
                // We need to convert it to SwiftUI's top-left origin system AND account for the horizontal mirroring of the preview.
                let rect = CGRect(
                    x: (1 - box.origin.x - box.width) * geometry.size.width, // Flip horizontally
                    y: (1 - box.origin.y - box.height) * geometry.size.height, // Flip vertically
                    width: box.width * geometry.size.width,
                    height: box.height * geometry.size.height
                )
                
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}

#Preview {
    ContentView()
} 
