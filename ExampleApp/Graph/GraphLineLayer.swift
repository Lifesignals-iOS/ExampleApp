//
//  GraphLineLayer.swift
//
//  Created by Mohammed Janish on 26/02/20.
//  Copyright © 2020 LifeSignals. All rights reserved.
//

import Foundation
import UIKit

class GraphLineLayer: CAShapeLayer {
    var data: [Int] = [Int]()
    private var currentLine: [Int] = [Int]()
    private var prevLine: [Int] = [Int]()
    private var mWidth: Int32 = 0
    private var mHeight: Int32 = 0
    private var centreOffSet: Int32 = 0
    private var vScale: CGFloat = 1.0
    private var hScale: CGFloat = 1.0
    private var mSpacing: Int32 = 0
    private var mBalance: Double = 0;
    
   private var crossLineLayer = CAShapeLayer()
    
    init(yCenter: Int32, width: Int32,height: Int32, pixelPerSec: CGFloat, spacing: Int32, valuePerPixel: CGFloat, graphColor: CGColor) {
        super.init()
        data = [Int]()
        mWidth = width
        mHeight = height
        hScale = CGFloat(pixelPerSec / CGFloat(100000/spacing))
        vScale = valuePerPixel
        centreOffSet = yCenter
        mSpacing = spacing
        strokeColor = graphColor
        fillColor = UIColor.clear.cgColor
        
        crossLineLayer.fillColor = UIColor.white.cgColor
        crossLineLayer.strokeColor = UIColor.white.cgColor
        self.addSublayer(crossLineLayer)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func setLinePath(for points: [Int], transform: CGAffineTransform) {
        
        //let nPoints = Int(ceil(Float(200 * 1000/self.mSpacing)))
        var scaledPoints = [Int]()
        for _ in 0 ..< points.count {
            var d: Int = -524288
            if self.data.count > 0 {
                d = self.data[0]
                self.data.remove(at: 0)
            }
//            if d == -524288 {
//                d = 0
//            }

            scaledPoints.append(d)
        }
        self.addPoints(points: scaledPoints)
        
        
    }
    
    
    private func addPoints(points: [Int]) {
        let maxPoints = Int(CGFloat(mWidth) / (hScale))
        if points.count > 0 {
            for i in 0 ..< points.count {
                if currentLine.count >= maxPoints {
                    prevLine.removeAll()
                    prevLine.append(contentsOf: currentLine)
                    currentLine.removeAll()
                }
                currentLine.append(points[i])
            }
        }
        self.drawPath()
    }
    
    private func drawPath() {
        
        var points = [CGPoint]()
        let linePath = CGMutablePath()
        var nx:CGFloat = 0
        var ny:CGFloat = 0
        var emptyLayerWidth: CGFloat = 10
        

        var crossX: CGFloat?
        for n in 0..<currentLine.count {
            nx = CGFloat(n) * hScale
            if nx > CGFloat(mWidth) {
                break
            }
            
            ny = CGFloat(centreOffSet) - CGFloat(currentLine[n]) * vScale
            if(!(currentLine[n] == -524288 || currentLine[n] == -8388608)) {
                points.append(CGPoint(x: nx, y: ny))
            }
            crossX = CGFloat(nx)
            
        }
        
        let maxPoints = Int(CGFloat(mWidth) / (hScale))
        let restPoints = maxPoints - currentLine.count + 10
        if restPoints >= 10 {
            prevLine = prevLine.suffix(restPoints - 10)
        }
        
         for n in 0..<prevLine.count {
            nx = CGFloat(n + currentLine.count) * hScale
            if nx > CGFloat(mWidth) {
                break
            }
            
            ny = CGFloat(centreOffSet) - CGFloat(prevLine[n]) * vScale
            if(!(prevLine[n] == -524288 || prevLine[n] == -8388608)) {
                points.append(CGPoint(x: nx, y: ny))
            }
        }
        
        let yMin = CGFloat(centreOffSet - mHeight/2)
        let yMax = CGFloat(centreOffSet + mHeight/2)
        
        
        let crossPath = CGMutablePath()

        DispatchQueue.main.async {
            
            for (index, _) in points.enumerated() {
                if index < points.count - 1 {
                    if index > 1 {
//                        if ((CGFloat(self.centreOffSet) - points[index - 1].y) / self.vScale == CGFloat(invalidValue) || (CGFloat(self.centreOffSet) - points[index - 2].y) / self.vScale == CGFloat(invalidValue)) ||
//                            (CGFloat(self.centreOffSet) - points[index].y) / self.vScale == CGFloat(invalidValue) {
//                            continue
//                        }
                        if (points[index - 1].x - points[index - 2].x < 2) {
                            linePath.move(to: points[index - 2])
                            linePath.addLine(to: points[index - 1])
                        }
                    }
                }
            }
            self.path = linePath
            
            if let cx = crossX {
                crossPath.addRect(CGRect(x: CGFloat(cx), y: yMin, width: emptyLayerWidth, height: yMax-yMin))
                self.crossLineLayer.path = crossPath
                
            }
        }
    }
    
    private func pointValue(x: Int32, y: Int32) -> CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
