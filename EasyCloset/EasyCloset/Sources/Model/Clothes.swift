//
//  Clothes.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/17.
//

import UIKit

struct Clothes {
  let id: UUID
  let name: String
  let createdAt: Date
  let imageURL: String
  let category: ClothesCategory
  
  init(id: UUID = UUID(),
       name: String,
       createdAt: Date = Date(),
       imageURL: String,
       category: ClothesCategory) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.imageURL = imageURL
    self.category = category
  }
}
