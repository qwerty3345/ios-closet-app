//
//  ClothesRepository.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/25.
//

import UIKit
import RealmSwift

import Combine

import Then

// MARK: - Protocol

protocol ClothesRepositoryProtocol {
  func fetchClothesList() -> AnyPublisher<ClothesList, RepositoryError>
  func save(clothes: Clothes) -> AnyPublisher<Void, RepositoryError>
  func removeAll()
}

// MARK: - ClothesRepository

final class ClothesRepository: ClothesRepositoryProtocol, ImageFetchable {
  
  // MARK: - Properties
  
  private let realmStorage: RealmStorageProtocol
  let imageFileStorage: ImageFileStorageProtocol
  
  private var cancellables = Set<AnyCancellable>()
  
  init(realmStorage: RealmStorageProtocol,
       imageFileStorage: ImageFileStorageProtocol) {
    self.realmStorage = realmStorage
    self.imageFileStorage = imageFileStorage
    setupMockData()
  }
  
  // MARK: - Public Methods
  
  func fetchClothesList() -> AnyPublisher<ClothesList, RepositoryError> {
    let clothesEntities = realmStorage.load(entityType: ClothesEntity.self)
    let clothesModelsWithoutImage = clothesEntities.map { $0.toModelWithoutImage() }
    return addingImages(to: clothesModelsWithoutImage)
      .map { $0.toClothesList() }
      .mapError { _ in RepositoryError.invalidData }
      .eraseToAnyPublisher()
  }
  
  func save(clothes: Clothes) -> AnyPublisher<Void, RepositoryError> {
    let clothesEntity = clothes.toEntity()
    if self.realmStorage.save(clothesEntity) == false {
      return Fail(error: RepositoryError.failToSave).eraseToAnyPublisher()
    }
    
    guard let image = clothes.image else {
      return Fail(error: RepositoryError.invalidImage).eraseToAnyPublisher()
    }
    
    // 캐시 저장
    imageCacheManager.store(image, for: clothes.id)
    
    // 이미지 파일 저장
    return imageFileStorage.save(image: image, id: clothes.id)
      .mapError { _ in RepositoryError.failToSave }
      .eraseToAnyPublisher()
  }
  
  func removeAll() {
    realmStorage.removeAll(entityType: ClothesEntity.self)
    imageCacheManager.removeAll()
  }
  
  // MARK: - Private Methods
  
  // 초기 데이터가 없을 때 테스트 용도로 Mock 데이터를 저장 해 주는 메서드
#if DEBUG
  private func setupMockData() {
    guard realmStorage.load(entityType: ClothesEntity.self).isEmpty else { return }
    
    ClothesList.mocks.clothesByCategory.forEach { (_, value: [Clothes]) in
      value.forEach { clothes in
        save(clothes: clothes)
          .sink(receiveCompletion: { _ in }, receiveValue: { })
          .store(in: &cancellables)
      }
    }
  }
#endif
}
