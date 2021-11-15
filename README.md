[https://www.youtube.com/watch?v=a-tEj0QYExc&t=662s](https://www.youtube.com/watch?v=a-tEj0QYExc&t=662s)

[https://www.youtube.com/watch?v=a-tEj0QYExc&t=662s](https://www.youtube.com/watch?v=a-tEj0QYExc&t=662s)

# What is StoreKit?

Apple's Framework to support **in-app purchases** and interaction with the App Store. 

# What can we do with it?

- In-App Purchase
- Apple Music
- Recommendations and reviews

# How does In-App Purchasing work in iOS?

1. Sign In into App Store Connect
2. Register Your App
3. Define In-App purchase
4. Create Sandbox Accounts 

# What changed since WWDC 2020?

1. Open Xcode
2. Create Storekit Configuration File
3. Start Coding and Testing Purchases 

# How does it work?

[In App Purchase Tutorial, SwiftUI, All Products Covered](https://www.notion.so/In-App-Purchase-Tutorial-SwiftUI-All-Products-Covered-184b05e9776140d4872cf3ab8c62abe1)

# Create StoreKit Configuration items

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/18baf2b8-89e2-4060-a31c-f3ade322b6ea/Untitled.png)

# StoreKit Configuration → Only For TESETING!!!

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/e96ba736-6543-4f25-8ebf-6f6d2acfd559/Untitled.png)

# Code

```swift
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
```

```swift
//
//  Reecipe.swift
//  SwiftUIInApp
//
//  Created by paige on 2021/11/15.
//

import Foundation
import StoreKit

struct Recipe: Hashable {
    let id: String
    let title: String
    let description: String
    var isLocked: Bool
    var price: String?
    let locale: Locale
    let imageName: String
    
    lazy var formatter: NumberFormatter = {
       let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = locale
       return nf
    }()
    
    init(product: SKProduct, isLock: Bool = true) {
        self.id = product.productIdentifier
        self.title = product.localizedTitle
        self.description = product.localizedDescription
        self.isLocked = isLock
        self.locale = product.priceLocale
        self.imageName = product.productIdentifier
        if isLocked {
            self.price = formatter.string(from: product.price)
        }
    }
}
```

```swift
//
//  ContentView.swift
//  SwiftUIInApp
//
//  Created by paige on 2021/11/15.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var store: Store 
    

    var body: some View {
        NavigationView {
            List(store.allRecipes, id: \.self) { recipe in
                Group {
                    if !recipe.isLocked {
                        NavigationLink(destination: Text("Secret Recipe")) {
                            Row(recipe: recipe) {
                                    
                            }
                        }
                    } else {
                        Row(recipe: recipe) {
                            if let product = store.product(for: recipe.id) {
                                store.purchaseProduct(product)
                            }
                        }
                    }
                }
                .navigationBarItems(trailing: Button("Restore") {
                    store.restorePurchases()
                })
            }
            .navigationTitle("Recipe Store")
            
        }
    }
}

struct Row: View {
    let recipe: Recipe
    let action: () -> Void
    var body: some View {
        HStack {
            ZStack {
                Image(recipe.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(9)
                    .opacity(recipe.isLocked ? 0.8 : 1)
                    .blur(radius: recipe.isLocked ? 3.0 : 0)
                    .padding()
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .opacity(recipe.isLocked ? 1: 0)
            }
            VStack(alignment: .leading) {
                Text(recipe.title)
                    .font(.title)
                Text(recipe.description)
                    .font(.caption)
            }
            Spacer()
            if let price = recipe.price, recipe.isLocked {
                Button(action: action) {
                    Text(price)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical)
                        .background(Color.black)
                        .cornerRadius(25)
                }
            }
        }
    }
    
}
```
