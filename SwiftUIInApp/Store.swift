//
//  Store.swift
//  SwiftUIInApp
//
//  Created by paige on 2021/11/15.
//

import StoreKit

typealias FetchCompletionHandler = (([SKProduct]) -> Void)
typealias PurchaseCompletionHandler = ((SKPaymentTransaction?) -> Void)

class Store: NSObject, ObservableObject {
    
    @Published var allRecipes = [Recipe]()
    
    private let allProductIdentifiers = Set(["com.product.berryblue", "com.product.lemonberry"])
    
    private var completedPurchases = [String]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for index in self.allRecipes.indices {
                    self.allRecipes[index].isLocked = !self.completedPurchases.contains(self.allRecipes[index].id)
                }
            }
        }
    }
    private var productsRequest: SKProductsRequest?
    private var fetchedProducts = [SKProduct]()
    private var fetchCompletionHandler: FetchCompletionHandler? // fetch product
    private var purchaseCompletionHandler: PurchaseCompletionHandler?
    
    override init() {
        super.init()
        startObservingPaymentQueue()
        fetchProducts { products in
            self.allRecipes = products.map { Recipe(product: $0) }
        }
    }
    
//    func loadStoredPurchases() {
//        if let storedPurchases = UserDefaults.standard.object(forKey: "completedPurchase") as? [String] {
//            self.completedPurchases = storedPurchases
//        }
//    }
    
    private func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    private func fetchProducts(_ completion: @escaping FetchCompletionHandler) {
        guard self.productsRequest == nil else { return }
        fetchCompletionHandler = completion
        productsRequest = SKProductsRequest(productIdentifiers: allProductIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    private func buy(_ product: SKProduct, completion: @escaping PurchaseCompletionHandler) {
        purchaseCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
}

extension Store {
    
    func product(for identifier: String) -> SKProduct? {
        return fetchedProducts.first(where: { $0.productIdentifier == identifier })
    }
    
    func purchaseProduct(_ product: SKProduct) {
        startObservingPaymentQueue()
        buy(product) { _ in
            
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension Store: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            var shouldFinishTransaction = false
            switch transaction.transactionState {
            case .purchased, .restored:
                completedPurchases.append(transaction.payment.productIdentifier)
                shouldFinishTransaction = true
            case .failed:
                shouldFinishTransaction = true
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
            
            if shouldFinishTransaction {
                SKPaymentQueue.default().finishTransaction(transaction)
                DispatchQueue.main.async { [weak self] in
                    self?.purchaseCompletionHandler?(transaction)
                    self?.purchaseCompletionHandler = nil
                }
            }
            
        }
        
//        if !completedPurchases.isEmpty {
//            UserDefaults.standard.setValue(completedPurchases, forKey: "completedPurchase")
//        }
        
    }
    
}

extension Store: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let loadedProducts = response.products
        let invalidProducts = response.invalidProductIdentifiers
        guard !loadedProducts.isEmpty else {
            print("Could not load the products!")
            if !invalidProducts.isEmpty {
                print("Invalid Products found: \(invalidProducts)")
            }
            productsRequest = nil
            return
        }
        
        // Cache the fetched products
        fetchedProducts = loadedProducts
        
        // Notify anyone waiting on the product load
        DispatchQueue.main.async { [weak self] in
            self?.fetchCompletionHandler?(loadedProducts)
            self?.fetchCompletionHandler = nil
            self?.productsRequest = nil
        }
        
    }
    
}
