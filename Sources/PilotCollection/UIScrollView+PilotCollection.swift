//
//  File.swift
//  
//
//  Created by cl d on 2022/7/23.
//

import Foundation
import UIKit

extension UIScrollView {
    func pilot_contentInset() -> UIEdgeInsets {
        
        if #available(iOS 11.0, tvOS 11.0, * ) {
            return self.adjustedContentInset
        } else {
            return self.contentInset
        }        
    }
}
