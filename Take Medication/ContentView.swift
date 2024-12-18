//
//  ContentView.swift
//  Take Medication
//
//  Created by Pieter Yoshua Natanael on 15/10/24.
//

import SwiftUI
import StoreKit
import UserNotifications
import Combine


// Astruct to store notification settings
struct NotificationSettings: Codable {
    var customTitle: String = ""
    var customBody: String = ""
}

// ContentView
struct ContentView: View {
    @AppStorage("customNotificationTitle") private var customTitle: String = ""
    @AppStorage("customNotificationBody") private var customBody: String = ""
    @State private var notificationSettings = NotificationSettings()
    @State private var showSettings = false
    @State private var showAdsAndAppFunctionality = false
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        ZStack {
            
            // Background Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)),.clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAdsAndAppFunctionality = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.white))
                                .padding()
                                .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                        }
                    }
                    // Purchase button for unlocking full version
               
                
                    
                    
                    Text("Take Medication")                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding()
                    
                    // Grid of 24 buttons, representing 24 hours of the day
                    let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<24) { index in
                            Button(action: {
                                // Toggle button and handle notification scheduling/canceling
                                if buttonStates[index] {
                                    cancelNotification(for: index)
                                    buttonStates[index] = false
                                    saveButtonStates()
                                } else if buttonStates.filter({ $0 }).count < 2 || purchaseManager.unlimitedNotificationsUnlocked {
                                    buttonStates[index] = true
                                    scheduleNotification(for: index)
                                    saveButtonStates()
                                } else {
                                    print("Limit reached: Upgrade to unlock more notifications.")
                                }
                            }) {
                                Text("\(index):00")
                                    .font(.body) // Standard font
                                    .foregroundColor(.black)
                                    .frame(width: 80, height: 80)
                                    .background(buttonStates[index] ? Color.green : Color.white)
                                    .clipShape(Circle()) // Make button circular
                                    .overlay(
                                        Divider()
                                            .frame(height: 70) // Divider height
                                            .background(Color.gray)
                                            .padding(.horizontal, 20) // Adjust divider position
                                    )
                                    .shadow(color: Color.black.opacity(1), radius: 3, x: 3, y: 3)
                            }
                        }
                    }
                    
                    VStack{
                        Button(action: {
                            showSettings = true
                        }) {
                            Text("Settings")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .font(.title3.bold())
                                .cornerRadius(10)
                               
                                .shadow(color: Color(#colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)).opacity(12), radius: 3, x: 3, y: 3)
                        }
                        
                        
                        
                        Button(action: {
                            if let product = purchaseManager.products.first {
                                purchaseManager.buyProduct(product)
                            }
                        }) {
                            Text("Unlimited Reminders")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)))
                                .foregroundColor(.white)
                                .font(.title3.bold())
                                .cornerRadius(10)
                               
                                .shadow(color: Color.white.opacity(1), radius: 3, x: 3, y: 3)
                        }
                        
                        // Restore Purchases button
                        Button(action: {
                            purchaseManager.restorePurchases()
                        }) {
                            Text("Restore Purchases")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.black)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                
                                .shadow(color: Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)).opacity(12), radius: 3, x: 3, y: 3)
                        }
                        Spacer()
                    }
                    
                }
                .sheet(isPresented: $showAdsAndAppFunctionality) {
                    ShowAdsAndAppFunctionalityView(onConfirm: {
                        showAdsAndAppFunctionality = false
                    })
                }
//                .background(Color(.systemPink)) // Light pink background
                .sheet(isPresented: $showSettings) {
                                 NotificationSettingsView(notificationSettings: $notificationSettings)
                             }
                .onAppear {
                    loadButtonStates()
                    requestNotificationPermission()
                    purchaseManager.fetchProducts()
                }
                .padding()
            }
        }
    }

    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
   

     func loadNotificationSettings() {
         if let savedSettings = UserDefaults.standard.object(forKey: "NotificationSettings") as? Data {
             let decoder = JSONDecoder()
             if let loadedSettings = try? decoder.decode(NotificationSettings.self, from: savedSettings) {
                 notificationSettings = loadedSettings
             }
         }
     }

    

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = customTitle.isEmpty ? "Medication Reminder" : customTitle
        content.body = customBody.isEmpty ?  "Time to take your medication for \(hour):00!" :customBody
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }
    // Save and load notification settings
     func saveNotificationSettings() {
         let encoder = JSONEncoder()
         if let encoded = try? encoder.encode(notificationSettings) {
             UserDefaults.standard.set(encoded, forKey: "NotificationSettings")
         }
     }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

// PurchaseManager class for handling in-app purchases
class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Make sure to update on the main thread
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Restore previously made purchases
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}


// Notification Settings View
struct NotificationSettingsView: View {
    @Binding var notificationSettings: NotificationSettings
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("customNotificationTitle") private var customTitle: String = ""
    @AppStorage("customNotificationBody") private var customBody: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customize Notifications")) {
                    TextField("Notification Title (Optional)", text: $customTitle)
                    
                    TextField("Notification Body (Optional)", text: $customBody)
                }
                
                Section {
                    Text("Leave fields empty to use default notifications.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    // Save the settings
                    saveNotificationSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    // Save settings method
    private func saveNotificationSettings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(notificationSettings) {
            UserDefaults.standard.set(encoded, forKey: "NotificationSettings")
        }
    }
}

struct ShowAdsAndAppFunctionalityView: View {
    var onConfirm: () -> Void

    var body: some View {
        ScrollView {
            VStack {
                // Section header
                HStack {
                    Text("Ads & App Functionality")
                        .font(.title3.bold())
                    Spacer()
                }
                Divider().background(Color.gray)
                
                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("App For You")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
               
                    
                    // App Cards for ads
                    VStack {
                        Divider().background(Color.gray)


                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

//                        AppCardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
//                        Divider().background(Color.gray)

//                        AppCardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
//                        Divider().background(Color.gray)
//
                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "The Ultimate Sleep App.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "BST", appName: "Blink Screen Time", appDescription: "Using screens can reduce your blink rate to just 6 blinks per minute, leading to dry eyes and eye strain. Our app helps you maintain a healthy blink rate to prevent these issues and keep your eyes comfortable.", appURL: "https://apps.apple.com/id/app/blink-screen-time/id6587551095")
                        Divider().background(Color.gray)

//                        AppCardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
//                        Divider().background(Color.gray)

                       
                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)
                
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • 24-Hour Buttons: Select the hour of the day to schedule medication reminders, set up to 2 medication reminders for free users.
                • Cancel Reminders: Easily cancel a scheduled reminder by pressing the corresponding hour button.
                • Unlimited Reminders: Purchase the Unlimited Reminders feature to set an unlimited number of reminders.
                •Restore Purchases: Restore your previously purchased Unlimited Reminders on any device, or if you reinstall the app on the same device.
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

               

                // App functionality section
      

                Spacer()

                HStack {
                    Text("Take Medication is developed by Three Dollar.")
                        .font(.title3.bold())
                    Spacer()
                }

                // Close button
                Button("Close") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .font(.title3.bold())
                .cornerRadius(10)
                .padding()
                .shadow(color: Color.white.opacity(12), radius: 3, x: 3, y: 3)
            }
            .padding()
            .cornerRadius(15.0)
        }
    }
}

// MARK: - Ads App Card View

// View displaying individual ads app cards
struct AppCardView: View {
    var imageName: String
    var appName: String
    var appDescription: String
    var appURL: String

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(7)

            VStack(alignment: .leading) {
                Text(appName)
                    .font(.title3)
                Text(appDescription)
                    .font(.caption)
            }
            .frame(alignment: .leading)

            Spacer()

            // Try button
            Button(action: {
                if let url = URL(string: appURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Try")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

/*
//works but mau nambah feature stting notifikasi

import SwiftUI
import StoreKit
import UserNotifications
import Combine

// ContentView
struct ContentView: View {
    @State private var showAdsAndAppFunctionality = false
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        ZStack {
            
            // Background Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)),.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAdsAndAppFunctionality = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.white))
                                .padding()
                                .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                        }
                    }
                    // Purchase button for unlocking full version
               
                
                    
                    
                    Text("Take Medication")                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding()
                    
                    // Grid of 24 buttons, representing 24 hours of the day
                    let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<24) { index in
                            Button(action: {
                                // Toggle button and handle notification scheduling/canceling
                                if buttonStates[index] {
                                    cancelNotification(for: index)
                                    buttonStates[index] = false
                                    saveButtonStates()
                                } else if buttonStates.filter({ $0 }).count < 3 || purchaseManager.unlimitedNotificationsUnlocked {
                                    buttonStates[index] = true
                                    scheduleNotification(for: index)
                                    saveButtonStates()
                                } else {
                                    print("Limit reached: Upgrade to unlock more notifications.")
                                }
                            }) {
                                Text("\(index):00")
                                    .font(.body) // Standard font
                                    .foregroundColor(.black)
                                    .frame(width: 80, height: 80)
                                    .background(buttonStates[index] ? Color.green : Color.white)
                                    .clipShape(Circle()) // Make button circular
                                    .overlay(
                                        Divider()
                                            .frame(height: 70) // Divider height
                                            .background(Color.gray)
                                            .padding(.horizontal, 20) // Adjust divider position
                                    )
                                    .shadow(color: Color.black.opacity(1), radius: 3, x: 3, y: 3)
                            }
                        }
                    }
                    
                    VStack{
                        Button(action: {
                            if let product = purchaseManager.products.first {
                                purchaseManager.buyProduct(product)
                            }
                        }) {
                            Text("Unlimited Reminders")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)))
                                .foregroundColor(.white)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.white.opacity(1), radius: 3, x: 3, y: 3)
                        }
                        
                        // Restore Purchases button
                        Button(action: {
                            purchaseManager.restorePurchases()
                        }) {
                            Text("Restore Purchases")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)).opacity(12), radius: 3, x: 3, y: 3)
                        }
                        Spacer()
                    }
                    
                }
                .sheet(isPresented: $showAdsAndAppFunctionality) {
                    ShowAdsAndAppFunctionalityView(onConfirm: {
                        showAdsAndAppFunctionality = false
                    })
                }
//                .background(Color(.systemPink)) // Light pink background
                .onAppear {
                    loadButtonStates()
                    requestNotificationPermission()
                    purchaseManager.fetchProducts()
                }
                .padding()
            }
        }
    }

    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

// PurchaseManager class for handling in-app purchases
class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Make sure to update on the main thread
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Restore previously made purchases
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}

struct ShowAdsAndAppFunctionalityView: View {
    var onConfirm: () -> Void

    var body: some View {
        ScrollView {
            VStack {
                // Section header
                HStack {
                    Text("Ads & App Functionality")
                        .font(.title3.bold())
                    Spacer()
                }
                Divider().background(Color.gray)
                
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • 24-Hour Buttons: Select the hour of the day to schedule medication reminders, set up to 3 medication reminders for free users.
                • Cancel Reminders: Easily cancel a scheduled reminder by pressing the corresponding hour button.
                • Unlimited Reminders: Purchase the Unlimited Reminders feature to set an unlimited number of reminders.
                •Restore Purchases: Restore your previously purchased Unlimited Reminders on any device, or if you reinstall the app on the same device.
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("App For You")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
               
                    
                    // App Cards for ads
                    VStack {
                        Divider().background(Color.gray)


                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "BST", appName: "Blink Screen Time", appDescription: "Using screens can reduce your blink rate to just 6 blinks per minute, leading to dry eyes and eye strain. Our app helps you maintain a healthy blink rate to prevent these issues and keep your eyes comfortable.", appURL: "https://apps.apple.com/id/app/blink-screen-time/id6587551095")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                       
                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
      

                Spacer()

                HStack {
                    Text("Take Medication is developed by Three Dollar.")
                        .font(.title3.bold())
                    Spacer()
                }

                // Close button
                Button("Close") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .font(.title3.bold())
                .cornerRadius(10)
                .padding()
                .shadow(color: Color.white.opacity(12), radius: 3, x: 3, y: 3)
            }
            .padding()
            .cornerRadius(15.0)
        }
    }
}

// MARK: - Ads App Card View

// View displaying individual ads app cards
struct AppCardView: View {
    var imageName: String
    var appName: String
    var appDescription: String
    var appURL: String

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(7)

            VStack(alignment: .leading) {
                Text(appName)
                    .font(.title3)
                Text(appDescription)
                    .font(.caption)
            }
            .frame(alignment: .leading)

            Spacer()

            // Try button
            Button(action: {
                if let url = URL(string: appURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Try")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

*/

/*

//bagus tapi mau add restore purchase button yg di request pihak Apple
import SwiftUI
import StoreKit
import UserNotifications
import Combine

// ContentView
struct ContentView: View {
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)),.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    // Purchase button for unlocking full version
                    HStack {
                        Button(action: {
                            if let product = purchaseManager.products.first {
                                purchaseManager.buyProduct(product)
                            }
                        }) {
                            Text("Unlock Full Version")
                                .font(.body) // Standard font
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black)
                                .cornerRadius(5)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Text("Take Medication")
                        .font(.title.bold()) // Standard font for title
                        .foregroundColor(.white)
                    
                        .padding()
                    
                    // Grid of 24 buttons, representing 24 hours of the day
                    let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<24) { index in
                            Button(action: {
                                // Toggle button and handle notification scheduling/canceling
                                if buttonStates[index] {
                                    cancelNotification(for: index)
                                    buttonStates[index] = false
                                    saveButtonStates()
                                } else if buttonStates.filter({ $0 }).count < 3 || purchaseManager.unlimitedNotificationsUnlocked {
                                    buttonStates[index] = true
                                    scheduleNotification(for: index)
                                    saveButtonStates()
                                } else {
                                    print("Limit reached: Upgrade to unlock more notifications.")
                                }
                            }) {
                                Text("\(index):00")
                                    .font(.body.bold()) // Standard font
                                    .foregroundColor(.black)
                                    .frame(width: 80, height: 80)
                                    .background(buttonStates[index] ? Color.green : Color.white)
                                    .clipShape(Circle()) // Make button circular
                                    .overlay(
                                        Divider()
                                            .frame(height: 70) // Divider height
                                            .background(Color.gray)
                                            .padding(.horizontal, 20) // Adjust divider position
                                    )
                                    .shadow(color: Color.black.opacity(1), radius: 3, x: 3, y: 3)
                            }
                        }
                    }
                }
                //        .background(Color(.systemPink).ignoresSafeArea()) // Light pink background
                .onAppear {
                    loadButtonStates()
                    requestNotificationPermission()
                    purchaseManager.fetchProducts()
                }
                .padding()
            }
        }
    }

    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

// PurchaseManager class for handling in-app purchases
class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Make sure to update on the main thread
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .restored:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}

*/

/*
// udah berfungsi baik, tapi ada sedikit masalah di archive yg tidak bisa
import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        VStack {
            // Purchase button for unlocking full version
            HStack {
                Button(action: {
                    if let product = purchaseManager.products.first {
                        purchaseManager.buyProduct(product)
                    }
                }) {
                    Text("Unlock Full Version")
                        .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.025))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                Spacer()
            }
            .padding()
            
            Text("Take Medication")
                .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.033)) // Responsive title
                .padding()

            // Grid of 24 buttons, representing 24 hours of the day
            let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<24) { index in
                    Button(action: {
                        // Toggle button and handle notification scheduling/canceling
                        if buttonStates[index] {
                            // Cancel notification if it was already selected
                            cancelNotification(for: index)
                            buttonStates[index] = false
                            saveButtonStates()
                        } else if buttonStates.filter({ $0 }).count < 3 || purchaseManager.unlimitedNotificationsUnlocked {
                            // Schedule new notification if less than 3 are selected
                            buttonStates[index] = true
                            scheduleNotification(for: index)
                            saveButtonStates()
                        } else {
                            print("Limit reached: Upgrade to unlock more notifications.")
                        }
                    }) {
                        Text("\(index):00")
                            .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.023))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(buttonStates[index] ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onAppear {
            loadButtonStates()
            requestNotificationPermission()
            purchaseManager.fetchProducts()
        }
        .padding()
    }
    
    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)" // Unique identifier for each notification

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)" // Use the same identifier for cancellation

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        // Check if the notification was successfully removed
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

*/

/*

//masalah tidak bisa cancel notification
import SwiftUI
import UserNotifications

struct ContentView: View {
    // Array to track the state of each button (24 buttons for each hour of the day)
    @State private var buttonStates = Array(repeating: false, count: 24)
    @StateObject private var purchaseManager = PurchaseManager() // Initialize PurchaseManager

    var body: some View {
        VStack {
            // Purchase Button
            HStack {
                Button(action: {
                    if let product = purchaseManager.products.first {
                        purchaseManager.buyProduct(product)
                    }
                }) {
                    Text("Unlock Full Version")
                        .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.025))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                Spacer()
            }
            .padding()

            Text("Medication Reminder")
                .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.055)) // Responsive size
                .padding()

            // Grid layout of 24 buttons
            let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<24) { index in
                    Button(action: {
                        // Toggle the button's state and save it
                        if purchaseManager.unlimitedNotificationsUnlocked || buttonStates.filter({ $0 }).count < 3 {
                            buttonStates[index].toggle()
                            saveButtonStates()

                            if buttonStates[index] {
                                scheduleNotification(for: index) // Schedule alarm
                            } else {
                                cancelNotification(for: index) // Cancel alarm
                            }
                        } else {
                            // Show alert: User has reached the limit
                            print("Limit reached: Upgrade to unlock more notifications.")
                        }
                    }) {
                        Text("\(index):00")
                            .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.023))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(buttonStates[index] ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onAppear(perform: {
            loadButtonStates()
            requestNotificationPermission() // Ask for notification permission when the app launches
            purchaseManager.fetchProducts() // Fetch IAP products
        })
        .padding()
    }
    
    // MARK: - Save button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }
    
    // MARK: - Load button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }
    
    // MARK: - Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Schedule notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        // Set the trigger time for the notification (specific hour)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true) // Repeats daily
        
        let identifier = "medication_\(hour)" // Unique identifier for each notification
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cancel notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)" // Unique identifier
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Notification for \(hour):00 canceled")
    }
}

struct TakeMedicationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

*/

/*
import SwiftUI
import UserNotifications

struct ContentView: View {
    // Array to track the state of each button (24 buttons for each hour of the day)
    @State private var buttonStates = Array(repeating: false, count: 24)
    
    var body: some View {
        VStack {
            Text("Medication Reminder")
                .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.055)) // Responsive size
//                .font(.largeTitle)
//                .font(/*.custom("PressStart2P-Regular", size: 30))*/
                .padding()
            
            // Grid layout of 24 buttons
            let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<24) { index in
                    Button(action: {
                        // Toggle the button's state and save it
                        buttonStates[index].toggle()
                        saveButtonStates()
                        
                        if buttonStates[index] {
                            scheduleNotification(for: index) // Schedule alarm
                        } else {
                            cancelNotification(for: index) // Cancel alarm
                        }
                    }) {
                        Text("\(index):00")
                            .font(.custom("PressStart2P-Regular", size: UIScreen.main.bounds.width * 0.023))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(buttonStates[index] ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onAppear(perform: {
            loadButtonStates()
            requestNotificationPermission() // Ask for notification permission when the app launches
        })
        .padding()
    }
    
    // MARK: - Save button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }
    
    // MARK: - Load button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }
    
    // MARK: - Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Schedule notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        // Set the trigger time for the notification (specific hour)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true) // Repeats daily
        
        let identifier = "medication_\(hour)" // Unique identifier for each notification
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cancel notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)" // Unique identifier
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Notification for \(hour):00 canceled")
    }
}


struct TakeMedicationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
 
 */
/*

import SwiftUI

struct ContentView: View {
    // Array to track the state of each button (24 buttons for each hour of the day)
    @State private var buttonStates = Array(repeating: false, count: 24)
    
    var body: some View {
        VStack {
            Text("Medication Reminder")
                .font(.largeTitle)
                .padding()
            
            // Grid layout of 24 buttons
            let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<24) { index in
                    Button(action: {
                        // Toggle the button's state and save it
                        buttonStates[index].toggle()
                        saveButtonStates()
                    }) {
                        Text("\(index):00")
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(buttonStates[index] ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onAppear(perform: loadButtonStates) // Load saved states when app launches
        .padding()
    }
    
    // MARK: - Save button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }
    
    // MARK: - Load button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }
}


struct TakeMedicationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

*/

#Preview {
    MainAppView()
}
