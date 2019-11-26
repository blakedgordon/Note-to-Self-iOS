//
//  NoteToSelfPro.swift
//  Email Note
//
//  Created by Blake Gordon on 12/13/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import Foundation
import StoreKit

class NoteToSelfPro {
    static var proProductKey = "com.BlakeGordon.EmailNote.Pro"
    
    static let store = IAPHelper(productIds: [proProductKey])
    static let purchaseNotification = "NoteToSelfPurchaseNotification"
    
    static var expireDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "proExpiration") as? Date ?? Date.distantPast
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "proExpiration")
        }
    }
    
    static var expireDateCode: Date {
        get {
            return UserDefaults.standard.object(forKey: "codeExpiration") as? Date ?? Date.distantPast
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "codeExpiration")
        }
    }
    
    static var proPriceLabel: String {
        get {
            return UserDefaults.standard.string(forKey: "proPriceLabel") ?? "$0.99/mo"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "proPriceLabel")
        }
    }
    
    static var proTrialExists: Bool?
    
    static var proTrialString: String?
    
    static func proAvailable(products: [SKProduct]?) -> Bool {
        return products?.contains(where: { (product) -> Bool in
            return product.productIdentifier == proProductKey
        }) ?? false
    }
    
    static func getProduct(_ key: String, products: [SKProduct]?) -> SKProduct? {
        if let validProducts = products {
            for product in validProducts {
                if product.productIdentifier == key {
                    return product
                }
            }
        }
        return nil
    }
    
    static func handlePurchase(productID: String) {
        UserDefaults.standard.set(true, forKey: productID)
        store.purchasedProducts.insert(productID)
        NoteToSelfPro.expireDate = Date(timeIntervalSinceNow: 120)
        validateReceipt()
            
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: purchaseNotification), object: "success")
    }
    
    // Modified from answer: ios - Implementing Receipt Validation in Swift 3
    // https://stackoverflow.com/questions/39711350/implementing-receipt-validation-in-swift-3/51652228
    // Retrieve the iTunes receipt and check the date
    static func validateReceipt() {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                let dict = ["receipt-data" : receiptString, "password" : "0cd98cddb4264e17a031a91ae82cd8cb"] as [String : Any]
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                    
                    if let storeURL = Foundation.URL(string:"https://buy.itunes.apple.com/verifyReceipt"),
                        let sandboxURL = Foundation.URL(string: "https://sandbox.itunes.apple.com/verifyReceipt") {
                        var request = URLRequest(url: storeURL)
                        request.httpMethod = "POST"
                        request.httpBody = jsonData
                        let session = URLSession(configuration: URLSessionConfiguration.default)
                        let task = session.dataTask(with: request) { data, response, error in
                            // BEGIN of closure #1 - verification with Production
                            if let receivedData = data, let httpResponse = response as? HTTPURLResponse,
                                error == nil, httpResponse.statusCode == 200 {
                                do {
                                    if let jsonResponse = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, AnyObject>,
                                        let status = jsonResponse["status"] as? Int64 {
                                        switch status {
                                        case 0: // receipt verified in Production
                                            self.updateExpirationDate(jsonResponse: jsonResponse) // Leaves isPremiumInAmbiquousState=true if fails
                                        case 21007: // Means that our receipt is from sandbox environment, need to validate it there instead
                                            var request = URLRequest(url: sandboxURL)
                                            request.httpMethod = "POST"
                                            request.httpBody = jsonData
                                            let session = URLSession(configuration: URLSessionConfiguration.default)
                                            let task = session.dataTask(with: request) { data, response, error in
                                                // BEGIN of closure #2 - verification with Sandbox
                                                if let receivedData = data, let httpResponse = response as? HTTPURLResponse,
                                                    error == nil, httpResponse.statusCode == 200 {
                                                    do {
                                                        if let jsonResponse = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, AnyObject>,
                                                            let status = jsonResponse["status"] as? Int64 {
                                                            switch status {
                                                            case 0: // receipt verified in Sandbox
                                                                self.updateExpirationDate(jsonResponse: jsonResponse) // Leaves isPremiumInAmbiquousState=true if fails
                                                            default: break
                                                            }
                                                        } else { print("Failed to cast serialized JSON to Dictionary<String, AnyObject>") }
                                                    }
                                                    catch { print("Couldn't serialize JSON with error: " + error.localizedDescription) }
                                                } else { print("Network Error: \(String(describing: error))") }
                                            }
                                            // END of closure #2 = verification with Sandbox
                                            task.resume()
                                        default: break
                                        }
                                    } else { print("Failed to cast serialized JSON to Dictionary<String, AnyObject>") }
                                } catch { print("Couldn't serialize JSON with error: " + error.localizedDescription) }
                            } else { print("Network Error: \(String(describing: error))") }
                        }
                        // END of closure #1 - verification with Production
                        task.resume()
                    } else { print("Couldn't convert string into URL. Check for special characters.") }
                } catch { print("Couldn't create JSON with error: " + error.localizedDescription) }
            } catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        } else {
            self.refreshReceipt()
        }
    }
    
    private static func updateExpirationDate(jsonResponse: Dictionary<String, Any>) {
        let receipts = jsonResponse["latest_receipt_info"] as? [[String: Any]] ?? [[String: Any]]()
        var expirationDate: Date?
        if var expirationString = receipts.last?["expires_date"] as? String {
            let stringArray = expirationString.split(separator: " ")
            if let date = stringArray.first, stringArray.count > 1 {
                let time = stringArray[1]
                expirationString = "\(date) \(time)"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                expirationDate = dateFormatter.date(from: expirationString)
            }
        }
        
        NoteToSelfPro.expireDate = expirationDate ?? Date.distantPast
        
        if NoteToSelfPro.expireDate > Date() {
            User.purchasedPro = true
        } else if NoteToSelfPro.expireDateCode < Date() {
            // If the receipt is expired and the given code is expired
            User.purchasedPro = false
        }
    }
    
    private static func refreshReceipt() {
        if NoteToSelfPro.expireDateCode < Date() {
            User.purchasedPro = false
        }
    }
}
