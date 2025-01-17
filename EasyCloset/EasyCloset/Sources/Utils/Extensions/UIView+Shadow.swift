//
//  UIView+Shadow.swift
//  EasyCloset
//
//  Created by Mason Kim on 2023/05/19.
//

import UIKit

extension UIView {
  enum ShadowLocation {
    case top
    case bottom
    case left
    case right
  }
  
  func addShadow(to location: ShadowLocation,
                 length: CGFloat = 5,
                 color: UIColor = .black,
                 opacity: Float = 0.2,
                 radius: CGFloat = 5.0) {
    switch location {
    case .bottom:
      addShadow(offset: CGSize(width: 0, height: length), color: color, opacity: opacity, radius: radius)
    case .top:
      addShadow(offset: CGSize(width: 0, height: -length), color: color, opacity: opacity, radius: radius)
    case .left:
      addShadow(offset: CGSize(width: -length, height: 0), color: color, opacity: opacity, radius: radius)
    case .right:
      addShadow(offset: CGSize(width: length, height: 0), color: color, opacity: opacity, radius: radius)
    }
  }
  
  private func addShadow(offset: CGSize,
                         color: UIColor,
                         opacity: Float,
                         radius: CGFloat) {
    layer.masksToBounds = false
    layer.shadowColor = color.cgColor
    layer.shadowOffset = offset
    layer.shadowOpacity = opacity
    layer.shadowRadius = radius
  }
}
