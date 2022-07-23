//
//  File.swift
//  
//
//  Created by cl d on 2022/7/23.
//

import Foundation
import UIKit


@objc protocol PilotCollectionDelegateLayout: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, customizedInitalLayoutAttributes attributes: UICollectionViewLayoutAttributes, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes;
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, customizedFinalLayoutAttributes attributes: UICollectionViewLayoutAttributes, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes;

}
