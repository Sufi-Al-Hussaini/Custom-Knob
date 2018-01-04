//
//  ViewController.swift
//  knob
//
//  Created by Nikita Kukushkin on 05/08/2014.
//  Copyright (c) 2014 Nikita Kukushkin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var animate: UISwitch!
    
    @IBOutlet weak var knob: Knob!
    
    let knobImageView = UIImageView(image: UIImage(named: "knob")!.resizedImage(newSize: CGSize(width: 200, height: 200)))
    let knobOverlayImageView = UIImageView(image: UIImage(named: "knob-overlay")!.resizedImage(newSize: CGSize(width: 200, height: 200)))

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        knob.addTarget(self, action: #selector(knobValueChanged(_:)), for: .valueChanged)
        knob.lineWidth = 3.0
        knob.backgroundColor = UIColor.lightGray
        knob.setValue(value: 0.5)
        knobImageView.transform = makeAffine(transform: CATransform3DMakeRotation(knob.angleForValue(knob.value) - (knob.startAngle + knob.endAngle)/2, 0, 0, 1))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.backgroundColor = UIColor.lightGray
        view.addSubview(knobOverlayImageView)
        knobOverlayImageView.center = knob.center
        view.addSubview(knobImageView)
        knobImageView.center = knob.center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Actions
    
    func knobValueChanged(_ sender: Knob) {
        label.text = String(format: "%.2f", sender.value)
        slider.setValue(sender.value, animated: animate.isOn)
        knobImageView.transform = makeAffine(transform: CATransform3DMakeRotation(sender.angleForValue(sender.value) - (sender.startAngle + sender.endAngle)/2, 0, 0, 1))
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        label.text = String(format: "%.2f", sender.value)
        knob.setValue(value: sender.value, animated: animate.isOn)
    }

    @IBAction func generateRandomValue(_ sender: UIButton) {
        let randomValue = (Float((arc4random()) % 101) / 100.0)
        label.text = String(format: "%.2f", randomValue)
        slider.setValue(randomValue, animated: animate.isOn)
        knob.setValue(value: randomValue, animated: animate.isOn)
    }
    
    func makeAffine(transform: CATransform3D) -> CGAffineTransform {
        return CGAffineTransform(a: transform.m11, b: transform.m12, c: transform.m21, d: transform.m22, tx: transform.m41, ty: transform.m42)
    }
    
}

extension UIImage {
    func resizedImage(newSize: CGSize) -> UIImage {
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
}

