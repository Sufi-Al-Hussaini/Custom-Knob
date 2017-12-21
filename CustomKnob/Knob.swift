//
//  Knob.swift
//  CustomKnob
//
//  Created by Nikita Kukushkin on 06/08/2014.
//  Copyright (c) 2014 Nikita Kukushkin. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

@IBDesignable public class Knob: UIControl {
    
    fileprivate let renderer = Renderer()
    private var gestureRecognizer: RotationGestureRecognizer!
    
    // MARK: API
    
    /**
     Contains a Boolean value indicating whether changes in the value of the knob
     generate continuous update events. The default value is `true`.
     */
    @IBInspectable public var continuous = true
    
    /**
     The minimum value of the knob. Defaults to 0.0.
     */
    @IBInspectable public var minimumValue: Float = 0.0
    
    /**
     The maximum value of the knob. Defaults to 1.0.
     */
    @IBInspectable public var maximumValue: Float = 1.0
    
    /**
     Contains the current value.
     */
    public private(set) var value: Float = 0.0
    
    /**
     Sets the value the knob should represent, with optional animation of the change.
     */
    public func setValue(value: Float, animated: Bool = false) {
        if self.value != value {
            self.value = min(maximumValue, max(minimumValue, value))
            renderer.setCurrentAngle(angleForValue(self.value), animated: animated)
        }
    }
    
    // MARK: UIView
    
    override public func tintColorDidChange() {
        renderer.color = tintColor
    }
    
    override public func prepareForInterfaceBuilder() {
        renderUI()
    }
    
    // MARK: Lifecycle
    
    private func renderUI() {
        renderer.color = tintColor
        renderer.updateWithBounds(bounds)
        
        layer.addSublayer(renderer.trackLayer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gestureRecognizer = RotationGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)
        renderUI()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        gestureRecognizer = RotationGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)
        renderUI()
    }
    
}

// MARK: - Renderer extension

public extension Knob {
    
    // MARK: API
    
    /**
     Specifies the angle of the start of the knob control track. Defaults to -11π/8.
     */
    public var startAngle: CGFloat {
        get {
            return renderer.startAngle
        }
        set {
            renderer.startAngle = newValue
        }
    }
    
    /**
     Specifies the end angle of the knob control track. Defaults to 3π/8.
     */
    public var endAngle: CGFloat {
        get {
            return renderer.endAngle
        }
        set {
            renderer.endAngle = newValue
        }
    }
    
    /**
     Specifies the width in points of the knob control track. Defaults to 2.0.
     */
    @IBInspectable public var lineWidth: CGFloat {
        get {
            return renderer.lineWidth
        }
        set {
            renderer.lineWidth = newValue
        }
    }
    
    
    // MARK: Renderer
    
    fileprivate class Renderer {
        
        var color: UIColor = .black {
            didSet {
                trackLayer.strokeColor = color.cgColor
            }
        }
        var lineWidth: CGFloat = 2 {
            didSet {
                trackLayer.lineWidth = lineWidth
                updateTrackShape()
            }
        }
        
        // MARK: Track Layer
        
        let trackLayer: CAShapeLayer = {
            var layer = CAShapeLayer.init()
            layer.fillColor = UIColor.clear.cgColor
            return layer
            }()
        
        var startAngle = -CGFloat.pi * 11 / 8.0 {
            didSet {
                updateTrackShape()
            }
        }
        var endAngle = CGFloat.pi * 3 / 8.0 {
            didSet {
                updateTrackShape()
            }
        }
        
        var currentAngle = -CGFloat.pi * 11 / 8.0
        
        func setCurrentAngle(_ angle: CGFloat, animated: Bool = false) {
            currentAngle = angle
            updateTrackShape()
        }
        
        // MARK: Update Logic
        
        func updateTrackShape() {
            let center = CGPoint(x: trackLayer.bounds.width / 2, y: trackLayer.bounds.height / 2)
            let offset = lineWidth / 2
            let radius = min(trackLayer.bounds.width, trackLayer.bounds.height) / 2 - offset
            let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: currentAngle, clockwise: true)
            
            trackLayer.path = ring.cgPath
        }
        
        
        func updateWithBounds(_ bounds: CGRect) {
            trackLayer.bounds = bounds
            trackLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            updateTrackShape()
        }
        
        // MARK: Lifecycle
        
        init() {
            trackLayer.lineWidth = lineWidth
            trackLayer.strokeColor = color.cgColor
        }
        
    }
}

// MARK: - Rotation Gesture Recogniser extension

private extension Knob {
    
    // note the use of dynamic, because calling
    // private swift selectors(@ gestureRec target:action:!) gives an exception
    dynamic func handleGesture(_ gesture: RotationGestureRecognizer) {
        let midPointAngle = (2 * CGFloat.pi + startAngle - endAngle) / 2 + endAngle
        
        var boundedAngle = gesture.touchAngle
        if boundedAngle > midPointAngle {
            boundedAngle -= 2 * CGFloat.pi
        }
        else if boundedAngle < (midPointAngle - 2 * CGFloat.pi) {
            boundedAngle += 2 * CGFloat.pi
        }
        
        boundedAngle = min(endAngle, max(startAngle, boundedAngle))
        
        setValue(value: valueForAngle(boundedAngle))

        if continuous {
            sendActions(for: .valueChanged)
        }
        else {
            // inference didn't work for .Cancelled for some reason in Xcode 6.0.1
            if gesture.state == .ended || gesture.state == UIGestureRecognizerState.cancelled {
                sendActions(for: .valueChanged)
            }
        }
    }
    
    // Note the need of importing UIKit.UIGestureRecognizerSubclass
    class RotationGestureRecognizer: UIPanGestureRecognizer {
        
        var touchAngle: CGFloat = 0
        
        // MARK: UIGestureRecognizerSubclass

        fileprivate override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesBegan(touches, with: event)
            updateTouchAngleWithTouches(touches)
        }

        fileprivate override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesMoved(touches, with: event)
            updateTouchAngleWithTouches(touches)
        }

        func updateTouchAngleWithTouches(_ touches: Set<UITouch>) {
            let touch = touches.first!
            let touchPoint = touch.location(in: view)
            
            touchAngle = calculateAngleToPoint(touchPoint)
        }
        
        func calculateAngleToPoint(_ point: CGPoint) -> CGFloat {
            let centerOffset = CGPoint(x: point.x - view!.bounds.midX, y: point.y - view!.bounds.midY)
            return atan2(centerOffset.y, centerOffset.x)
        }
        
        // MARK: Lifecycle
        
        override init(target: Any?, action: Selector?) {
            super.init(target: target, action: action)
            maximumNumberOfTouches = 1
            minimumNumberOfTouches = 1
        }
    }
}

// MARK: - Utilities extenstion

public extension Knob {
    
    // MARK: Value/Angle conversion
    
    func valueForAngle(_ angle: CGFloat) -> Float {
        let angleRange = Float(endAngle - startAngle)
        let valueRange = maximumValue - minimumValue
        return Float(angle - startAngle) / angleRange * valueRange + minimumValue
    }
    
    func angleForValue(_ value: Float) -> CGFloat {
        let angleRange = endAngle - startAngle
        let valueRange = CGFloat(maximumValue - minimumValue)
        return CGFloat(self.value - minimumValue) / valueRange * angleRange + startAngle
    }
}
