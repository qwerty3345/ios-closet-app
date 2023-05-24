//
//  ClothesDetailController.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/20.
//

import UIKit

import Then
import SnapKit

import Combine

final class ClothesDetailController: UIViewController {
  
  // MARK: - Properties
  
  private let viewModel = ClothesDetailViewModel()
  
  private let type: ClothesDetailControllerType
  
  private var isEditingClothes = false {
    didSet {
      turnEditMode(isOn: isEditingClothes)
    }
  }
  
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - UI Components
  
  private let scrollView = UIScrollView()
  private let contentStackView = UIStackView().then {
    $0.axis = .vertical
    $0.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 0, right: 20)
    $0.isLayoutMarginsRelativeArrangement = true
  }
  
  private lazy var photoHandlingView = PhotoHandlingView(parentController: self)
  
  private let categotyPickerView = ClothesCategoryPickerView()
  
  private lazy var weatherSegmentedControl = UISegmentedControl(
    items: WeatherType.allCases.map { $0.korean }
  )
  
  private let descriptionTextField = UITextField().then {
    $0.placeholder = "설명을 입력해주세요 (선택)"
  }
  
  private lazy var editAddBarButton = UIBarButtonItem(
    title: type.rightBarButtonTitle,
    style: .plain,
    target: self,
    action: #selector(tappedEditAddButton))
  
  // MARK: - Initialization
  
  init(type: ClothesDetailControllerType) {
    self.type = type
    super.init(nibName: nil, bundle: nil)
    
    if case let .showDetail(clothes: clothes) = type {
      self.viewModel.clothes = clothes
    }
    bind()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    descriptionTextField.resignFirstResponder()
  }
  
  // MARK: - Private Methods
  
  private func bind() {
    // viewModel의 output에 대한 bind
    viewModel.$clothes
      .sink { [weak self] clothes in
        guard let self = self,
              let clothes = clothes else { return }
        self.configure(with: clothes)
      }
      .store(in: &cancellables)
    
    viewModel.didFailToSave
      .sink { [weak self] message in
        // TODO: 저장에 실패했습니다 alert 띄우기.
        self?.showFailAlert(with: message)
      }
      .store(in: &cancellables)
    
    viewModel.didSuccessToSave
      .sink { [weak self] in
        self?.navigationController?.popViewController(animated: true)
      }
      .store(in: &cancellables)
  }
  
  private func configure(with clothes: Clothes) {
    guard case .showDetail = type else { return }
    
    photoHandlingView.setImage(clothes.image)
    categotyPickerView.selectRow(clothes.category.rawValue,
                                 inComponent: 0, animated: false)
    weatherSegmentedControl.selectedSegmentIndex = clothes.weatherType.rawValue
    if let description = clothes.description {
      descriptionTextField.text = description
    }
    turnEditMode(isOn: false)
  }
  
  private func turnEditMode(isOn: Bool) {
    categotyPickerView.isUserInteractionEnabled = isOn
    weatherSegmentedControl.isUserInteractionEnabled = isOn
    descriptionTextField.isUserInteractionEnabled = isOn
  }
  
  @objc private func tappedEditAddButton() {
    switch type {
    case .add:
      addClothes()
    case .showDetail:
      editClothes()
    }
  }
  
  private func addClothes() {
    guard let clothes = clothesFromUserInput() else { return }
    viewModel.clothes = clothes
  }
  
  private func editClothes() {
    if isEditingClothes {
      guard let clothes = clothesFromUserInput() else { return }
      viewModel.clothes = clothes
    }
    
    isEditingClothes.toggle()
    editAddBarButton.title = isEditingClothes ? "완료" : "편집"
    photoHandlingView.state = isEditingClothes ? .editing : .show
  }
  
  private func clothesFromUserInput() -> Clothes? {
    guard let image = photoHandlingView.clothesImageView.image else {
      showFailAlert(with: "사진은 필수 항목입니다.")
      return nil
    }
    guard let category = ClothesCategory(rawValue: categotyPickerView.selectedRow(inComponent: 0)) else {
      showFailAlert(with: "카테고리는 필수 항목입니다.")
      return nil
    }
    guard let weatherType = WeatherType(rawValue: weatherSegmentedControl.selectedSegmentIndex) else {
      showFailAlert(with: "계절은 필수 항목입니다.")
      return nil
    }
    let description = descriptionTextField.text
    
    return Clothes(imageURL: "",
                   image: image,
                   category: category,
                   weatherType: weatherType,
                   description: description)
  }
  
  private func showFailAlert(with title: String) {
    let alert = UIAlertController(title: title,
                                  message: nil, preferredStyle: .alert)
    let confirmAction = UIAlertAction(title: "확인", style: .default)
    alert.addAction(confirmAction)
    
    present(alert, animated: true)
  }
}

// MARK: - UI & Layout

extension ClothesDetailController {
  
  private func setup() {
    setUI()
    setupLayout()
  }
  
  private func setUI() {
    title = type.title
    navigationItem.rightBarButtonItem = editAddBarButton
    view.backgroundColor = .background
  }
  
  private func setupLayout() {
    setupScrollViewLayout()
    setupAddPhotoViewLayout()
    setupSection(with: "카테고리", view: categotyPickerView, viewHeight: 100, spacing: 16)
    setupSection(with: "계절", view: weatherSegmentedControl, viewHeight: 30, spacing: 40)
    setupSection(with: "설명", view: descriptionTextField, spacing: 16)
  }
  
  private func setupScrollViewLayout() {
    view.addSubview(scrollView)
    scrollView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    scrollView.addSubview(contentStackView)
    contentStackView.snp.makeConstraints {
      $0.edges.width.equalToSuperview()
    }
  }
  
  private func setupAddPhotoViewLayout() {
    contentStackView.addArrangedSubview(photoHandlingView)
    contentStackView.setCustomSpacing(30, after: photoHandlingView)
  }
  
  private func setupSection(with title: String, view: UIView,
                            viewHeight: CGFloat? = nil, spacing: CGFloat) {
    addHeaderLabel(with: title)
    contentStackView.addArrangedSubview(view)
    contentStackView.setCustomSpacing(spacing, after: view)
    guard let height = viewHeight else { return }
    view.snp.makeConstraints {
      $0.height.equalTo(height)
    }
  }
  
  private func addHeaderLabel(with title: String) {
    contentStackView.addArrangedSubview(.seperatorView)
    let label = UILabel().then { label in
      label.text = title
      label.font = .pretendardMediumTitle
      label.snp.makeConstraints {
        $0.height.equalTo(60)
      }
    }
    contentStackView.addArrangedSubview(label)
  }
}

// MARK: - ClothesDetailControllerType

enum ClothesDetailControllerType {
  case add
  case showDetail(clothes: Clothes)
  
  var title: String {
    switch self {
    case .add:
      return "옷 추가하기"
    case .showDetail:
      return "옷 상세보기"
    }
  }
  
  var rightBarButtonTitle: String {
    switch self {
    case .add:
      return "추가"
    case .showDetail:
      return "편집"
    }
  }
}

// MARK: - Preview

#if DEBUG
import SwiftUI

struct ClothesDetailControllerPreview: PreviewProvider {
  static var previews: some View {
    let vc = ClothesDetailController(type: .add)
    return UINavigationController(rootViewController: vc).toPreview()
  }
}
#endif
