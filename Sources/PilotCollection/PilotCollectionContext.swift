//
//  PilotCollectionContext.swift
//  
//
//  Created by cl d on 2022/8/6.
//

import UIKit


protocol PilotCollectionContext: NSObject {
    var containerSize: CGSize { get set }
    var containerInset: UIEdgeInsets { get set }
    var adjustedContainerInset: UIEdgeInsets { get set }
    var insetContainerSize: CGSize { get set }
    var containerContentOffset: CGPoint { get set }
    var scrollingTraits: PilotCollectionScrollingTraits { get set }
    var experiments: PilotExperiment { get set }
    
    
    func containerSizeForSectionController(sectionController: PilotSectionController) -> CGSize;
    
    func index(forCell cell: UICollectionViewCell, sectionController: PilotSectionController) -> Int;
    func cellForItemAtIndex(index: Int, sectionController: PilotSectionController) -> UICollectionViewCell;
    func fullyVisibleCellsForSectionController(sectionController: PilotSectionController) -> [UICollectionViewCell]?;
    func visibleCellsForSectionController(sectionController: PilotSectionController) -> [UICollectionViewCell]?;
    func visibleIndexPathsForSectionController(sectionCotroller: PilotSectionController) -> [IndexPath]?;
}
