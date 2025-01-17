//
//  RealmStorage.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/25.
//

import UIKit
import Then

import Combine

import RealmSwift

// MARK: - Protocol, RealmStorageError

protocol RealmStorageProtocol {
  func load<T: Object>(entityType: T.Type) -> [T]
  @discardableResult func save<T: Object>(_ data: T) -> Bool
  @discardableResult func remove<T: Object>(id: String, entityType: T.Type) -> Bool
  func removeAll<T: Object>(entityType: T.Type)
}

enum RealmStorageError: Error {
  case realmNotInitialized
}

// MARK: - RealmStorage

final class RealmStorage: RealmStorageProtocol {
  
  // MARK: - Properties
  
  private let realm = try? Realm()
  
  // MARK: - Public Methods
  
  func load<T: Object>(entityType: T.Type) -> [T] {
    guard let realm = realm else { return [] }
    let datas = Array(realm.objects(T.self))
    return datas
  }
  
  @discardableResult func save<T: Object>(_ data: T) -> Bool {
    guard let realm = realm else { return false }
    
    do {
      try realm.write {
        realm.add(data, update: .modified) // PrimaryKey가 같은 항목은 업데이트
      }
      return true
    } catch {
      return false
    }
  }
  
  func remove<T: Object>(id: String, entityType: T.Type) -> Bool {
    guard let realm = realm else { return false }
    
    guard let object = realm.object(ofType: entityType.self, forPrimaryKey: id) else {
      return false
    }
    
    do {
      try realm.write {
        realm.delete(object)
      }
      return true
    } catch {
      return false
    }
  }
  
  func removeAll<T: Object>(entityType: T.Type) {
    guard let realm = realm else { return }
    let datas = realm.objects(T.self)
    
    try? realm.write {
      realm.delete(datas)
    }
  }
}
