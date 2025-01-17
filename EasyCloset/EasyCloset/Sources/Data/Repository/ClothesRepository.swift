//
//  ClothesRepository.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/25.
//

import UIKit
import Then

import Combine

import RealmSwift

// MARK: - Protocol

protocol ClothesRepositoryProtocol {
  func fetchClothesList() -> AnyPublisher<ClothesList, RepositoryError>
  func save(clothes: Clothes) -> AnyPublisher<Void, RepositoryError>
  func remove(clothes: Clothes)
  func removeAll()
}

// MARK: - ClothesRepository

final class ClothesRepository: ClothesRepositoryProtocol, ImageFetchableRepository {
  
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
  
  func remove(clothes: Clothes) {
    realmStorage.remove(id: clothes.id.uuidString, entityType: ClothesEntity.self)
    imageFileStorage.remove(withID: clothes.id)
      // 딱히 삭제에 대한 에러 처리를 할 필요가 없기에 단순히 무응답 클로저로 남김
      .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
      .store(in: &cancellables)
  }
  
  func removeAll() {
    realmStorage.removeAll(entityType: ClothesEntity.self)
    imageCacheManager.removeAll()
    imageFileStorage.removeAll()
      .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
      .store(in: &cancellables)
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
