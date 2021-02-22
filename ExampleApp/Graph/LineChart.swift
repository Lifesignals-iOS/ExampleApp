//
//  LineChart.swift
//
//  Created by Mohammed Janish on 06/01/20.
//  Copyright © 2020 LifeSignals. All rights reserved.
//

import UIKit
class LineChart: UIView {

    private  var lineLayers = [GraphLineLayer]()
    private var crosslineLayer = CAShapeLayer()
     var chartTransform = [CGAffineTransform]()
    private var hScale: CGFloat = 0.0
    private var SCALE_FACTOR: CGFloat = 100
    let MAX_LIMIT = 1000
    var mHeight: Int32 = 0
    var updateInterval: Int = 100
    var widthInSeconds: CGFloat = 4
    
    private var timeDuration = 0.5
    private var timer: Timer?
    private var isTimerRunning = false
    
    
    @IBInspectable var lineColor: UIColor = UIColor.blue {
        didSet {
            for(_, layer) in lineLayers.enumerated() {
                layer.strokeColor = lineColor.cgColor
            }
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 1
    @IBInspectable var axisColor: UIColor = UIColor.white
    @IBInspectable var showInnerLines: Bool = false
    @IBInspectable var labelFontSize: CGFloat = 10
    
    var axisLineWidth: CGFloat = 1
    var deltaX: CGFloat = 50 // The change between each tick on the x axis
    var deltaY: CGFloat = 50 // and y axis
    var xMax: [Int: CGFloat] = [Int: CGFloat]()
    var yMax: [Int: CGFloat] = [Int: CGFloat]()
    var xMin: [Int: CGFloat] = [Int: CGFloat]()
    var yMin: [Int: CGFloat] = [Int: CGFloat]()
    
    var data: [CGPoint]?
    private var currentPlotCount = 0
    var lineColors = [UIColor.green, UIColor.blue, UIColor.cyan, UIColor.red, UIColor.orange, UIColor.magenta, UIColor.purple]
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        combinedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        combinedInit()
    }
    
    func combinedInit() {
        crosslineLayer.strokeColor = UIColor.red.cgColor
        layer.addSublayer(crosslineLayer)
        layer.borderWidth = 1
        layer.borderColor = axisColor.cgColor
        backgroundColor = UIColor.white
        hScale = self.frame.width / widthInSeconds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    override func draw(_ rect: CGRect) {
        // draw rect comes with a drawing context, so lets grab it.
        // Also, if there is not yet a chart transform, we will bail on performing any other drawing.
        // I like guard statements for this because it's kind of like a bouncer to a bar.
        // If you don't have your transform yet, you can't enter drawAxes.
//        guard let context = UIGraphicsGetCurrentContext(), let t = chartTransform else { return }
//        drawAxes(in: context, usingTransform: t)
    }
    
    
    func addPlot(yCenter: Int32, height: Int32, yValuePerPixel: CGFloat, spacing: Int32, graphColor: CGColor) {
        let width = Int32(frame.width)
        let graphLayer = GraphLineLayer(yCenter: yCenter, width: width, height: height, pixelPerSec: hScale, spacing: spacing, valuePerPixel: yValuePerPixel, graphColor: graphColor)
        lineLayers.append(graphLayer)
        let yMaximum = yCenter //+ height/2
//        if yMaximum > mHeight {
            mHeight = yMaximum
//        }
        layer.addSublayer(graphLayer)
        
        
    }

    //++++++++++++ Need to set range for each lineLayers
    func setAxisRange(forPoints points: [CGPoint], lineLayerIndex: Int) {
        guard !points.isEmpty else { return }
        
        let xs = points.map() { $0.x }
        let ys = points.map() { $0.y }
        
        xMax[lineLayerIndex] =  CGFloat(MAX_LIMIT)//ceil(xs.max()! / deltaX) * deltaX
        yMax[lineLayerIndex] =  (ceil(ys.max()! / deltaY) * deltaY)
        xMin[lineLayerIndex] =  0//ceil((xs.min()! - deltaX) / deltaX) * deltaX
        yMin[lineLayerIndex] =  (ceil((ys.min()! - deltaY) / deltaY) * deltaY)
        
        setTransform(minX: xMin[lineLayerIndex]!, maxX: xMax[lineLayerIndex]!, minY: yMin[lineLayerIndex]!, maxY: yMax[lineLayerIndex]!, lineLayerIndex: lineLayerIndex)
    }
    
    func setAxisRange(xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat, lineLayerIndex: Int) {
        self.xMin[lineLayerIndex] = xMin
        self.xMax[lineLayerIndex] = xMax
        self.yMin[lineLayerIndex] = yMin
        self.yMax[lineLayerIndex] = yMax
        
        setTransform(minX: xMin, maxX: xMax, minY: yMin, maxY: yMax, lineLayerIndex: lineLayerIndex)
    }

    func setTransform(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat, lineLayerIndex: Int) {
        
        let xLabelSize = "\(Int(maxX) - Int(minX))".size()
        
        let yLabelSize = "\(Int(maxY) - Int(minY))".size()
        
        let xOffset = xLabelSize.height + 2
        let yOffset = yLabelSize.width + 5

        let xScale = (bounds.width - yOffset - xLabelSize.width/2 - 2)/(maxX - minX)
        let yScale = (bounds.height - xOffset - yLabelSize.height/2 - 2)/(maxY - minY)
        
        chartTransform[lineLayerIndex] = CGAffineTransform(a: xScale, b: 0, c: 0, d: -yScale, tx: yOffset, ty: 300)
        
        setNeedsDisplay()
    }
    
    func runTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(LineChart.updateTimer), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func updateTimer() {
        if self.timeDuration > 0 {
            self.timeDuration -= 0.1
        }
        else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func resetTimer() {
        timeDuration = 0.5
    }
    

    func plot(_ points: [Int], at lineLayerIndex: Int) {
        
        guard !points.isEmpty else { return }
        if self.lineLayers.count > lineLayerIndex {
            self.lineLayers[lineLayerIndex].data = points
            self.lineLayers[lineLayerIndex].setLinePath(for: points, transform: self.chartTransform[lineLayerIndex])
        }
    }
}
