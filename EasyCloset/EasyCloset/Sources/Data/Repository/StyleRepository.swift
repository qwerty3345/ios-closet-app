//
//  StyleRepository.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/26.
//

import UIKit
import RealmSwift

import Combine

import Then

// MARK: - Protocol

protocol StyleRepositoryProtocol {
  func fetchStyles() -> AnyPublisher<[Style], RepositoryError>
  func save(style: Style) -> AnyPublisher<Void, RepositoryError>
  func removeAll()
}

// MARK: - ClothesRepository

final class StyleRepository: StyleRepositoryProtocol, ImageFetchable {
  
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
  
  func fetchStyles() -> AnyPublisher<[Style], RepositoryError> {
    let styleEntities = realmStorage.load(entityType: StyleEntity.self)
    let styleModels = styleEntities.map { $0.toModelWithoutImage() }
    
    // 내부의 clothes들에 이미지가 반영된 style 객체들
    let styleWithImagePublishers = styleModels.map { style in
      let clothes = style.clothes.values.map { $0 }
      
      return self.addingImages(to: clothes)
        .map { clothesWithImages -> Style in
          var newStyle = style
          newStyle.clothes = clothesWithImages.toClothesDictionary()
          return newStyle
        }
        .eraseToAnyPublisher()
    }
    
    // 각각의 style들을 배열 값으로 한 번에 내보내도록 처리
    return Publishers.MergeMany(styleWithImagePublishers)
      .collect()
      .mapError { _ in RepositoryError.invalidData }
      .eraseToAnyPublisher()
  }
  
  func save(style: Style) -> AnyPublisher<Void, RepositoryError> {
    return Future { [weak self] promise in
      guard let self = self else { return }
      
      let styleEntity = style.toEntity()
      
      let isSuccessToSave = self.realmStorage.save(styleEntity)
      if isSuccessToSave {
        promise(.success(()))
        return
      }
      
      promise(.failure(.failToSave))
    }
    .eraseToAnyPublisher()
  }
  
  func removeAll() {
    realmStorage.removeAll(entityType: StyleEntity.self)
  }
  
  // MARK: - Private Methods
  
  // 초기 데이터가 없을 때 테스트 용도로 Mock 데이터를 저장 해 주는 메서드
#if DEBUG
  private func setupMockData() {
    guard realmStorage.load(entityType: StyleEntity.self).isEmpty else { return }
    Style.Mock.mocks.forEach {
      save(style: $0)
        .sink(receiveCompletion: { _ in }, receiveValue: { })
        .store(in: &cancellables)
    }
  }
#endif
}
