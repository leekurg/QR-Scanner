//
//  PanelView.swift
//  QR-scanner
//
//  Created by Ильяяя on 02.06.2022.
//

import UIKit

class PanelView: UIView
{
    func applyBlurEffect() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)
    }
}
