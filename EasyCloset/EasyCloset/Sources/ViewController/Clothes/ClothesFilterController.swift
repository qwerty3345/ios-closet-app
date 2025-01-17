//
//  ClothesFilterController.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/24.
//

import UIKit

import Combine

typealias FilterItems = [ClothesFilterController.Item]

final class ClothesFilterController: UIViewController {
  
  // MARK: - Types
  
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
  
  enum Section: Int, CaseIterable {
    case sort
    case weather
    case clothes
    
    var description: String {
      switch self {
      case .sort:
        return "정렬"
      case .weather:
        return "계절"
      case .clothes:
        return "옷 종류"
      }
    }
  }
  
  enum Item: Hashable {
    case sort(SortBy)
    case weather(WeatherType)
    case clothes(ClothesCategory)
    
    var description: String {
      switch self {
      case .sort(let sort):
        return sort.korean
      case .weather(let weather):
        return weather.korean
      case .clothes(let clothes):
        return clothes.korean
      }
    }
  }
  
  // MARK: - Properties
  
  private lazy var dataSource: DataSource = makeDataSource()
  private var selectedItems: [Section: Item] = [:]
  
  private let viewModel: ClothesViewModel
  
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - UI Components
  
  private lazy var collectionView = UICollectionView(frame: .zero,
                                                     collectionViewLayout: makeCollectionViewLayout())
  
  private lazy var doneButton = UIButton().then {
    $0.setTitle("검색", for: .normal)
    $0.setTitleColor(UIColor.white, for: .normal)
    $0.backgroundColor = .accentColor
    $0.addTarget(self, action: #selector(tappedDoneButton), for: .touchUpInside)
  }
  
  // MARK: - Initialization
  
  init(viewModel: ClothesViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    bind()
  }
  
  // MARK: - Private Methods
  
  private func bind() {
    viewModel.searchFilters
      .sink { [weak self] filters in
        self?.setSelectedFilters(with: filters)
      }
      .store(in: &cancellables)
  }
  
  private func setSelectedFilters(with filters: FilterItems) {
    filters.forEach { filter in
      switch filter {
      case .sort:
        self.selectedItems[.sort] = filter
      case .weather:
        self.selectedItems[.weather] = filter
      case .clothes:
        self.selectedItems[.clothes] = filter
      }
    }
  }
  
  @objc private func tappedDoneButton() {
    let filters = selectedItems.values.map { $0 }
    viewModel.searchFilters.send(filters)
    dismiss(animated: true)
  }
}

// MARK: - Layout

extension ClothesFilterController {
  private func setup() {
    setupLayout()
    setupUI()
    setupCollectionView()
    applySnapshot()
  }
  
  private func setupLayout() {
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(30)
      $0.horizontalEdges.equalToSuperview()
    }
    
    view.addSubview(doneButton)
    doneButton.snp.makeConstraints {
      $0.horizontalEdges.bottom.equalToSuperview().inset(40)
      $0.top.equalTo(collectionView.snp.bottom)
      $0.height.equalTo(50)
    }
  }
  
  private func setupUI() {
    view.backgroundColor = .white
    doneButton.layer.cornerRadius = 8
  }
  
  private func setupCollectionView() {
    collectionView.registerCell(cellClass: FilterCell.self)
    collectionView.registerHeaderView(viewClass: FilterTitleHeaderView.self)
    collectionView.dataSource = dataSource
    collectionView.delegate = self
    
    configureHeaderProvider()
  }
  
  private func makeCollectionViewLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                          heightDimension: .absolute(30))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .estimated(20))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = .init(top: 8, leading: 10, bottom: 16, trailing: 10)
    
    section.boundarySupplementaryItems = [headerItem()]
    
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  private func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .absolute(40))
    return NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top)
  }
}

// MARK: - DataSource

extension ClothesFilterController {
  
  private func makeDataSource() -> DataSource {
    DataSource(collectionView: collectionView) { collectionView, indexPath, item in
      let cell = collectionView.dequeueReusableCell(cellClass: FilterCell.self, for: indexPath)
      cell.filterLabel.text = item.description
      
      if let section = Section(rawValue: indexPath.section),
         let selectedItem = self.selectedItems[section],
         selectedItem == item {
        cell.backgroundColor = .seperator
      }
      
      return cell
    }
  }
  
  private func configureHeaderProvider() {
    dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
      let headerView = collectionView.dequeueReusableHeaderView(
        ofType: FilterTitleHeaderView.self,
        for: indexPath)
      if let section = Section(rawValue: indexPath.section) {
        headerView.configure(with: section)
      }
      return headerView
    }
  }
  
  private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections(Section.allCases)
    
    let sortItems = SortBy.allCases.map { Item.sort($0) }
    let weatherItems = WeatherType.allCases.map { Item.weather($0) }
    let clothesItems = ClothesCategory.allCases.map { Item.clothes($0) }
    
    snapshot.appendItems(sortItems, toSection: .sort)
    snapshot.appendItems(weatherItems, toSection: .weather)
    snapshot.appendItems(clothesItems, toSection: .clothes)
    
    dataSource.apply(snapshot, animatingDifferences: true)
  }
}

// MARK: - UICollectionViewDelegate

extension ClothesFilterController: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    guard let section = Section(rawValue: indexPath.section),
          let item = dataSource.itemIdentifier(for: indexPath) else { return }
    
    // 이전에 선택된 해당 섹션의 셀이 존재하면 선택 해제
    if let beforeItem = selectedItems[section],
       let beforeIndexPath = dataSource.indexPath(for: beforeItem) {
      let beforeCell = collectionView.cellForItem(at: beforeIndexPath)
      beforeCell?.backgroundColor = .white
      
      // 동일한 셀을 두번 클릭하면 선택 해제만 하고 return
      if beforeItem == item {
        selectedItems.removeValue(forKey: section)
        return
      }
    }
    
    // 새롭게 선택된 해당 섹션의 셀을 선택
    collectionView.cellForItem(at: indexPath)?.backgroundColor = .seperator
    selectedItems[section] = item
  }
}

// MARK: - Preview

#if DEBUG
import SwiftUI

struct ClothesFilterControllerPreview: PreviewProvider {
  static var previews: some View {
    return DIContainer.shared.makeClothesFilterController().toPreview()
  }
}
#endif
