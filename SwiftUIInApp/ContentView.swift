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
