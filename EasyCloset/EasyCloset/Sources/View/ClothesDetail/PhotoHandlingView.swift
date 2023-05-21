//
//  PhotoHandlingView.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/21.
//

import UIKit

import SnapKit
import Then

import Combine

final class PhotoHandlingView: UIStackView {
  
  enum PhotoState {
    case empty
    case show
    case added
    case editing
  }
  
  // MARK: - Properties
  
  var state: PhotoState = .empty {
    didSet {
      configure(with: state)
    }
  }
  
  private let photoPicker: PhotoPicker
  
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  
  init(with photoPicker: PhotoPicker) {
    self.photoPicker = photoPicker
    super.init(frame: .zero)
    setupLayout()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - UI Components
  
  private let clothesImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .white
  }
  
  private let addPhotoLabel = UILabel().then {
    $0.text = "사진 등록하기"
    $0.font = .pretendardLargeTitle
  }
  
  private lazy var cameraButton = AddPhotoButton(
    title: "카메라",
    image: UIImage(systemName: "camera.fill")).then {
      $0.addTarget(self, action: #selector(tappedCameraButton), for: .touchUpInside)
    }
  private lazy var galleryButton = AddPhotoButton(
    title: "사진첩",
    image: UIImage(systemName: "photo.fill")).then {
      $0.addTarget(self, action: #selector(tappedGalleryButton), for: .touchUpInside)
    }
  
  private lazy var addPhotoStackView = UIStackView(arrangedSubviews: [
    cameraButton, galleryButton
  ]).then {
    $0.axis = .horizontal
    $0.spacing = 20
  }
  
  private lazy var photoRemoveButton = UIButton().then {
    $0.setImage(UIImage(systemName: "trash"), for: .normal)
    $0.tintColor = .systemRed
    $0.isHidden = true
    $0.addTarget(self, action: #selector(didRemovePhoto), for: .valueChanged)
  }
  
  // MARK: - Public Methods
  
  func setImage(_ image: UIImage?) {
    clothesImageView.image = image
    state = .show
  }
  
  // MARK: - Private Methods
  
  private func configure(with state: PhotoState) {
    // 사진이 있으면, 사진추가 관련 뷰들을 숨김
    let addPhotoIsHidden = state != .empty
    setAddPhotoView(isHidden: addPhotoIsHidden)
    
    // 아무 사진도 없거나 / 편집없이 보기만 하는 상태면, 사진 삭제 버튼을 숨김
    let removePhotoIsHidden = (state == .empty || state == .show)
    photoRemoveButton.isHidden = removePhotoIsHidden
  }
  
  private func setAddPhotoView(isHidden: Bool) {
    addPhotoStackView.isHidden = isHidden
    addPhotoLabel.isHidden = isHidden
  }
  
  @objc private func tappedCameraButton() {
    let cameraPublisher = photoPicker.requestCamera()
    handlePhoto(with: cameraPublisher)
    
//    photoPicker.requestCamera()
//      .sink { [weak self] completion in
//        guard let self = self else { return }
//
//        if case .failure(let error) = completion {
//          delegate?.photoHandlingView(self, didFailToAddPhotoWith: error)
//        }
//      } receiveValue: { [weak self] image in
//        self?.clothesImageView.image = image
//        self?.state = .added
//      }
//      .store(in: &cancellables)
  }
  
  @objc private func tappedGalleryButton() {
    let albumPublisher = photoPicker.requestAlbum()
    handlePhoto(with: albumPublisher)
//    photoPicker.requestAlbum()
//      .sink { [weak self] completion in
//        guard let self = self else { return }
//
//        if case .failure(let error) = completion {
//          delegate?.photoHandlingView(self, didFailToAddPhotoWith: error)
//        }
//      } receiveValue: { [weak self] image in
//        self?.clothesImageView.image = image
//        self?.state = .added
//      }
//      .store(in: &cancellables)
  }
  
  private func handlePhoto(with publisher: AnyPublisher<UIImage, PhotoPickerError>) {
    publisher.sink { [weak self] completion in
      guard let self = self else { return }
      if case .failure(let error) = completion {
        delegate?.photoHandlingView(self, didFailToAddPhotoWith: error)
      }
    } receiveValue: { [weak self] image in
      guard let self = self else { return }
      self.clothesImageView.image = image
      self.state = .added
    }
    .store(in: &cancellables)
  }
  
  @objc private func didRemovePhoto() {
    state = .empty
  }
}

// MARK: - UI & Layout

extension PhotoHandlingView {
  
  private func setupLayout() {
    setupclothesImageViewLayout()
    setupAddPhotoButtonsLayout()
    setupPhotoRemoveButtonLayout()
  }
  
  private func setupclothesImageViewLayout() {
    addArrangedSubview(clothesImageView)
    clothesImageView.snp.makeConstraints {
      $0.width.equalTo(clothesImageView.snp.height)
    }
  }
  
  private func setupAddPhotoButtonsLayout() {
    [cameraButton, galleryButton].forEach { button in
      button.snp.makeConstraints {
        $0.width.equalTo(80)
        $0.height.equalTo(90)
      }
    }
    addSubview(addPhotoStackView)
    addPhotoStackView.snp.makeConstraints {
      $0.center.equalTo(clothesImageView)
    }
    
    addSubview(addPhotoLabel)
    addPhotoLabel.snp.makeConstraints {
      $0.bottom.equalTo(addPhotoStackView.snp.top).inset(-20)
      $0.centerX.equalTo(addPhotoStackView)
    }
  }
  
  private func setupPhotoRemoveButtonLayout() {
    addSubview(photoRemoveButton)
    photoRemoveButton.snp.makeConstraints {
      $0.bottom.equalTo(clothesImageView.snp.bottom)
      $0.centerX.equalTo(addPhotoStackView)
      $0.height.width.equalTo(80)
    }
  }
}

// MARK: - Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AddPhotoViewPreview: PreviewProvider {
  static var previews: some View {
    UIViewPreview {
      PhotoHandlingView(with: .init(parent: UIViewController()))
    }
    .frame(height: 180)
    .previewLayout(.sizeThatFits)
  }
}
#endif