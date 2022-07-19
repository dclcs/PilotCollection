//
//  PilotCollectionLayout.swift
//  
//
//  Created by netease on 2022/7/19.
//

import UIKit

protocol PilotCollectionLayoutCompatible {
    func didModifySection(modifiedSection: Int)
}

func UIEdgeInsetsLeadingInsetInDirection(insets: UIEdgeInsets, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical: return insets.top
    case .horizontal: return insets.left
    }
}

func UIEdgeInsetsTrailingInsetInDirection(insets: UIEdgeInsets, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical : return insets.bottom
    case .horizontal: return insets.right
    }
}

func CGPointGetCoordinateInDirection(point: CGPoint, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical : return point.y
    case .horizontal: return point.x
    @unknown default:
        fatalError()
    }
}

func CGRectGetLengthInDirection(rect: CGRect, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical: return rect.size.height
    case .horizontal: return rect.size.width
    @unknown default:
        fatalError()
    }
}

func CGRectGetMinInDirection(rect: CGRect, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical:
        return rect.minY
    case .horizontal:
        return rect.minX
    @unknown default:
        fatalError()
    }
}

func CGSizeGetLengthInDirection(size: CGSize, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical: return size.height
    case .horizontal: return size.width
    @unknown default:
        fatalError()
    }
}

func indexPathForSection(section: Int) -> IndexPath {
    return IndexPath(row: 0, section: section)
}

func PilotMergeMinimInvalidatedSection(section: Int, otherSection: Int) -> Int {
    if section < 0 && otherSection < 0 {
        return -1
    } else if section < 0 {
        return otherSection
    } else if otherSection < 0 {
        return section
    }
    return min(section, otherSection)
}

struct PilotCollectionSectionEntry {
    var bounds: CGRect
    var insets: UIEdgeInsets
    var headerBounds: CGRect
    var footerBounds: CGRect
    var itemBounds: [CGRect]
    var lastItemCoordInScrollDirection: CGFloat
    var lastItemCoordInFixedDirection: CGFloat
    var lastNextCoordInScrollDirection: CGFloat
    
    func isValid() -> Bool {
        return !__CGSizeEqualToSize(bounds.size, .zero)
    }
}

func adjustZIndexForAttributes(attributes: UICollectionViewLayoutAttributes) {
    let maxZIndexPerSection: Int = 1000
    let baseZIndex = attributes.indexPath.section * maxZIndexPerSection
    
    switch attributes.representedElementCategory {
    case .cell:
        attributes.zIndex = baseZIndex + attributes.indexPath.item
        break
    case .supplementaryView:
        attributes.zIndex = baseZIndex + maxZIndexPerSection - 1
        break
    case .decorationView:
        attributes.zIndex = baseZIndex - 1
    }
}

class PilotCollectionLayoutInvalidationContext: UICollectionViewFlowLayoutInvalidationContext {
    var pi_invalidateSupplementaryAttributes: Bool = false
    var pi_invalidateAllAttributes: Bool = false
}

public class PilotCollectionLayout: UICollectionViewLayout, PilotCollectionLayoutCompatible {
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    var stickyHeaderYOffset: CGFloat = 0.0
    var showHeaderWhenEmpty: Bool = false
    
    var stickyHeaders: Bool = false
    var topContentInset: CGFloat = .zero
    var strechToEdge: Bool = false
    
    var _sectionData: [PilotCollectionSectionEntry] = []
    var _attributesCache: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    var _minimumInvaludatedSection: Int = -1
    
    var _supplementaryAttributesCache: [String: [IndexPath: UICollectionViewLayoutAttributes]]  = [:]
    
    convenience init(stickyHeaders: Bool, topContentInset: CGFloat, stretchToEdge: Bool) {
        self.init(stickyHeaders: stickyHeaders, scrollDirection: .vertical, topContentInset: topContentInset, strechToEdge: stretchToEdge)
    }
    
    init(stickyHeaders: Bool, scrollDirection: UICollectionView.ScrollDirection, topContentInset: CGFloat, strechToEdge: Bool) {
        super.init()
        self.scrollDirection = scrollDirection
        self.stickyHeaders = stickyHeaders
        self.topContentInset = topContentInset
        self.strechToEdge = strechToEdge
        self._attributesCache = [:]
        self._supplementaryAttributesCache = [UICollectionView.elementKindSectionHeader: [:],
                                              UICollectionView.elementKindSectionFooter: [:]]
        self._minimumInvaludatedSection = -1
        
    }
    
    
    public required convenience init?(coder: NSCoder) {
        self.init(stickyHeaders: false, topContentInset: 0, stretchToEdge: false)
    }
    
    //MARK: UICollectionViewLayout
    public override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        
        return attributes
    }
    
    
    //MARK: PilotCollectionLayoutCompatible
    func didModifySection(modifiedSection: Int) {
        _minimumInvaludatedSection = PilotMergeMinimInvalidatedSection(section: _minimumInvaludatedSection, otherSection: modifiedSection)
    }
    
    
}

