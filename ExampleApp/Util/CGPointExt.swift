//
//  CGPointExt.swift
//
//  Created by Mohammed Janish on 06/01/20.
//  Copyright © 2020 LifeSignals. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint {
    func adding(x: CGFloat) -> CGPoint { return CGPoint(x: self.x + x, y: self.y) }
    func adding(y: CGFloat) -> CGPoint { return CGPoint(x: self.x, y: self.y + y) }
    func multiplying(x: CGFloat) -> CGPoint {return CGPoint(x: self.x * x, y: self.y)}
    func multiplying(y: CGFloat) -> CGPoint {return CGPoint(x: self.x, y: self.y * y)}
    func dividing(x: CGFloat) -> CGPoint {return CGPoint(x: self.x / x, y: self.y)}
    func dividing(y: CGFloat) -> CGPoint {return CGPoint(x: self.x, y: self.y / y)}
}

