//
//  FillResultsView.swift
//  RealTalk
//
//  Created by Adam Halper on 5/21/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import UIKit

class FillResultsView: UIView {

    private let fillView = UIView(frame: CGRect.zero)

    private var coeff:CGFloat = 0.5 {
        didSet {
            // Make sure the fillView frame is updated everytime the coeff changes
            updateFillViewFrame()
        }
    }

    // Only needed if view isn't created in xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // Only needed if view isn't created in xib or storyboard
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    override func awakeFromNib() {
        setupView()
    }

    private func setupView() {
        // Setup the layer
        layer.cornerRadius = bounds.height/2.0
        layer.masksToBounds = true

        // Setup the unfilled backgroundColor
        backgroundColor = UIColor(red: 249.0/255.0, green: 163.0/255.0, blue: 123.0/255.0, alpha: 1.0)

        // Setup filledView backgroundColor and add it as a subview
        fillView.backgroundColor = UIColor(red: 252.0/255.0, green: 95.0/255.0, blue: 95.0/255.0, alpha: 1.0)
        addSubview(fillView)

        // Update fillView frame in case coeff already has a value
        updateFillViewFrame()
    }

    private func updateFillViewFrame() {
        fillView.frame = CGRect(x: 0, y: bounds.height*(1-coeff), width: bounds.width, height: bounds.height*coeff)
    }

    // Setter function to set the coeff animated. If setting it not animated isn't necessary at all, consider removing this func and animate updateFillViewFrame() in coeff didSet
    func setCoeff(coeff: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 4.0, animations:{ () -> Void in
                self.coeff = coeff
            })
        } else {
            self.coeff = coeff
        }
    }

}

