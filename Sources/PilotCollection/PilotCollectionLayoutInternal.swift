//
//  File.swift
//  
//
//  Created by cl d on 2022/7/23.
//

import Foundation
import UIKit


func PilotCollectionIntegralScaled(rect: CGRect)  -> CGRect {
    let scale = UIScreen.main.scale
    return CGRect(x: floor(rect.origin.x * scale) / scale,
                  y: floor(rect.origin.y * scale) / scale,
                  width: ceil(rect.size.width * scale) / scale,
                  height: ceil(rect.size.width * scale) / scale)
}
