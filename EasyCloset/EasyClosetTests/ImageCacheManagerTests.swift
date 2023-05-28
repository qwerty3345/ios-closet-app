//
//  ImageCacheManagerTests.swift
//  EasyClosetTests
//
//  Created by Mason Kim on 2023/05/28.
//

import XCTest
@testable import EasyCloset

final class ImageCacheManagerTests: XCTestCase {
  
  var sut: ImageCacheManager = .shared
  
  override func setUpWithError() throws {
    sut.countLimit = 100
    sut.megaByteLimit = 200
    print("제한 초기화는 함")
  }
  
  override func tearDownWithError() throws {
    sut.removeAll()
    print("끝나고 삭제도 함")
  }
  
  func test_이미지_캐싱_저장과_불러오기가_잘_이뤄지는지_확인() {
    // given
    let id = UUID()
    let image = UIImage.Sample.jacket1!
    
    // when
    sut.store(image, for: id)
    
    // then
    let retrivedImage = self.sut.get(for: id)
    XCTAssertEqual(retrivedImage, image)
  }
  
  func test_저장시_갯수제한이_적용되는지_확인() {
    // given
    let ids = (0...10).map { _ in UUID() }
    let countLimit = 3
    
    // when
    sut.countLimit = countLimit // 캐싱을 3개로 제한
    ids.forEach { id in
      sut.store(UIImage(), for: id)
    }
    
    // then
    let storedImages = ids
      .compactMap { sut.get(for: $0) }
    print(storedImages)
    XCTAssertGreaterThanOrEqual(countLimit, storedImages.count)
  }
  
  func test_저장시_용량제한이_적용되는지_확인() {
    // given
    let images = [
      UIImage(systemName: "pencil")!,
      UIImage(systemName: "pencil.slash")!,
      UIImage(systemName: "pencil.circle")!,
      UIImage(systemName: "pencil.circle.fill")!,
      UIImage(systemName: "pencil.line")!
    ]
    let imageDataSize = images.first!.pngData()?.count ?? 0
    let ids = (0..<5).map { _ in UUID() }
    
    // when
    sut.byteLimit = imageDataSize * 3
    zip(images, ids).forEach { image, id in
      sut.store(image, for: id)
    }
    
    // then
    let storedImages = ids
      .compactMap { sut.get(for: $0) }
    XCTAssertGreaterThanOrEqual(3, storedImages.count)
  }
}