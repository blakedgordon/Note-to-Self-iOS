/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// This file has been copied and modified for this project

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper: NSObject  {
    
    // MARK: - Properties
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    public var purchasedProducts = Set<ProductIdentifier>()
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    // MARK: - Initializers
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        purchasedProducts = Set(productIds.filter { UserDefaults.standard.bool(forKey: $0) })
        
        super.init()
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - StoreKit API
extension IAPHelper {
    
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print(product.localizedDescription)
        let payment = SKPayment(product: product)
        print("Payment - \(payment.productIdentifier)")
        SKPaymentQueue.default().add(payment)
    }
    
    public func isPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProducts.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        // Restore Consumables and Non-Consumables from Apple
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        print("Loaded list of products...")
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for prod in products {
            print("Found product: \(prod.productIdentifier) \(prod.localizedTitle) \(prod.price.floatValue)")
            if prod.productIdentifier == NoteToSelfPro.proProductKey {
                var priceString = "\(prod.priceLocale.currencySymbol ?? "$")\(prod.price.floatValue)"
                if #available(iOS 11.2, *) {
                    let subscriptionPeriod = prod.subscriptionPeriod?.unit.rawValue ?? 9999
                    priceString.append(subscriptionUnitToString(period: subscriptionPeriod, shortened: true, plural: false))
                    
                    if let introPrice = prod.introductoryPrice {
                        if introPrice.price == 0 {
                            priceString = "Free Trial"
                        } else {
                            let introSubscription = introPrice.subscriptionPeriod.unit.rawValue
                            let introLength = subscriptionUnitToString(period: introSubscription,
                                                                       shortened: false,
                                                                       plural: introPrice.subscriptionPeriod.numberOfUnits > 1)
                            priceString = "\(introPrice.priceLocale.currencySymbol ?? "$")\(introPrice.price.floatValue) for \(introPrice.subscriptionPeriod.numberOfUnits) \(introLength)"
                        }
                    }
                }
                NoteToSelfPro.proPriceLabel = priceString
            }
        }
    }
    
    private func subscriptionUnitToString(period: UInt, shortened: Bool, plural: Bool) -> String {
        switch period {
        case 0:
            return (shortened) ? "/day" : (plural) ? "days" : "day"
        case 1:
            return (shortened) ? "/wk" : (plural) ? "weeks" : "week"
        case 2:
            return (shortened) ? "/mo" : (plural) ? "months" : "month"
        case 3:
            return (shortened) ? "/yr" : (plural) ? "years" : "year"
        default:
            return""
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                print("purchased")
                complete(transaction: transaction)
                break
            case .failed:
                print("failed")
                fail(transaction: transaction)
                break
            case .restored:
                print("restored")
                restore(transaction: transaction)
                break
            case .deferred:
                print("deferred")
                fail(transaction: transaction)
                break
            case .purchasing:
                print("purchasing")
                break
            default:
                print("other")
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else {
            fail(transaction: transaction)
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        
        if NoteToSelfPro.expireDate < Date() {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NoteToSelfPro.purchaseNotification), object: "expired")
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        
        print("restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(transaction.error?.localizedDescription ?? "")")
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NoteToSelfPro.purchaseNotification), object: "failure")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        NoteToSelfPro.handlePurchase(productID: identifier)
    }
}
