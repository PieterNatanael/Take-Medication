//
//  PurchaseManager.swift
//  Take Medication
//
//  Created by Pieter Yoshua Natanael on 15/10/24.
//

//
//import Foundation
//import StoreKit
//import Combine
//
//class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
//    
//    @Published var unlimitedNotificationsUnlocked = false
//    @Published var products: [SKProduct] = []
//    
//    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
//    private var cancellables = Set<AnyCancellable>()
//    
//    override init() {
//        super.init()
//        SKPaymentQueue.default().add(self)
//        fetchProducts()
//    }
//    
//    deinit {
//        SKPaymentQueue.default().remove(self)
//    }
//    
//    func fetchProducts() {
//        let request = SKProductsRequest(productIdentifiers: [productID])
//        request.delegate = self
//        request.start()
//    }
//    
//    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//        // Make sure to update on the main thread
//        DispatchQueue.main.async {
//            self.products = response.products
//        }
//    }
//    
//    func buyProduct(_ product: SKProduct) {
//        let payment = SKPayment(product: product)
//        SKPaymentQueue.default().add(payment)
//    }
//    
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//        for transaction in transactions {
//            switch transaction.transactionState {
//            case .purchased:
//                // Ensure all updates are made on the main thread
//                DispatchQueue.main.async {
//                    self.unlimitedNotificationsUnlocked = true
//                }
//                SKPaymentQueue.default().finishTransaction(transaction)
//                
//            case .failed:
//                if let error = transaction.error {
//                    print("Payment failed: \(error.localizedDescription)")
//                }
//                SKPaymentQueue.default().finishTransaction(transaction)
//                
//            case .restored:
//                // Ensure all updates are made on the main thread
//                DispatchQueue.main.async {
//                    self.unlimitedNotificationsUnlocked = true
//                }
//                SKPaymentQueue.default().finishTransaction(transaction)
//                
//            default:
//                break
//            }
//        }
//    }
//}



/*

import Foundation
import StoreKit

class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
    
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
        DispatchQueue.main.async { // Ensure this is updated on the main thread
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
                DispatchQueue.main.async { // Ensure UI state changes happen on the main thread
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                DispatchQueue.main.async { // Ensure UI state changes happen on the main thread
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

import Foundation
import StoreKit

class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.takemedication.FullVersion" // Replace with your Product ID from App Store Connect
    
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
        products = response.products
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                unlimitedNotificationsUnlocked = true
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                unlimitedNotificationsUnlocked = true
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
*/
