//
//  ClothesViewModel.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/19.
//

import Foundation

import Combine

final class ClothesViewModel {
  
  // MARK: - Properties
  
  @Published private var clothesList = ClothesList(clothesByCategory: [:])
  
  let searchWithFilters = CurrentValueSubject<FilterItems, Never>([])
  let clothesListDidUpdate = PassthroughSubject<Void, Never>()
  
  private var cancellables = Set<AnyCancellable>()
  
  private let clothesStorage: ClothesStorageProtocol
  private let imageFileStorage: ImageFileStorageProtocol
  
  // MARK: - Initialization
  
  // 1초 후에 로딩 되는 것을 테스트 함
  init(clothesStorage: ClothesStorageProtocol = ClothesStorage.shared,
       imageFileStorage: ImageFileStorageProtocol = ImageFileStorage.shared) {
    self.clothesStorage = clothesStorage
    self.imageFileStorage = imageFileStorage
    bind()
  }
  
  // MARK: - Public Methods
  
  func clothes(of category: ClothesCategory) -> AnyPublisher<[Clothes], Never> {
    $clothesList
      .map { $0.clothesByCategory[category] ?? [] }
      .combineLatest(searchWithFilters)
      .map(applyFilters)
      .eraseToAnyPublisher()
  }
  
  // MARK: - Private Methods
  
  private func bind() {
    if let fetchedClothesList = clothesStorage.fetchClothesList() {
      self.clothesList = fetchedClothesList
    }
    
    clothesListDidUpdate
      .compactMap { [weak self] in
        self?.clothesStorage.fetchClothesList()
      }
      .sink { [weak self] clothesList in
        self?.clothesList = clothesList
      }
      .store(in: &cancellables)
  }
    
  private func applyFilters(clothesList: [Clothes], filters: FilterItems) -> [Clothes] {
    return filters.reduce(clothesList) { currentList, filter in
      switch filter {
      case .sort(let sort):
        return applySort(filter: sort, to: currentList)
      case .weather(let weather):
        return applyWeather(filter: weather, to: currentList)
      case .clothes(let clothes):
        return applyClothes(filter: clothes, to: currentList)
      }
    }
    
//    var filteredClothes = clothesList
//    
//    for filter in filters {
//      switch filter {
//      case .sort(let sort):
//        filteredClothes = applySort(filter: sort, to: filteredClothes)
//      case .weather(let weather):
//        filteredClothes = applyWeather(filter: weather, to: filteredClothes)
//      case .clothes(let clothes):
//        filteredClothes = applyClothes(filter: clothes, to: filteredClothes)
//      }
//    }
//    return filteredClothes
  }
  
  private func applySort(filter: SortBy, to clothesList: [Clothes]) -> [Clothes] {
    switch filter {
    case .new:
      return clothesList.sorted { $0.createdAt > $1.createdAt }
    case .old:
      return clothesList.sorted { $0.createdAt < $1.createdAt }
    }
  }
  
  private func applyWeather(filter: WeatherType, to clothesList: [Clothes]) -> [Clothes] {
    return clothesList.filter { $0.weatherType == filter }
  }
  
  private func applyClothes(filter: ClothesCategory, to clothesList: [Clothes]) -> [Clothes] {
    return clothesList.filter { $0.category == filter }
  }
}
