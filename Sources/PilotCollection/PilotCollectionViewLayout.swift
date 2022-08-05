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

func CGRectGetMaxInDirection(rect: CGRect, direction: UICollectionView.ScrollDirection) -> CGFloat {
    switch direction {
    case .vertical:
        return rect.maxY
    case .horizontal:
        return rect.maxX
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

public class PilotCollectionViewLayout: UICollectionViewLayout, PilotCollectionLayoutCompatible {
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
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath), let collectionView = self.collectionView else { return nil }
        
        if let delegate = collectionView.delegate as? PilotCollectionViewDelegateLayout,  delegate.responds(to: #selector(PilotCollectionViewDelegateLayout.collectionView(_:layout:customizedInitalLayoutAttributes:at:))){
            return delegate.collectionView(collectionView, layout: self, customizedInitalLayoutAttributes: attributes, at: itemIndexPath)
        }
        return attributes
    }
    
    public override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath), let collectionView = self.collectionView else { return nil }
        
        if let delegate = collectionView.delegate as? PilotCollectionViewDelegateLayout, delegate.responds(to: #selector(PilotCollectionViewDelegateLayout.collectionView(_:layout:customizedFinalLayoutAttributes:at:))) {
            return delegate.collectionView(collectionView, layout: self, customizedFinalLayoutAttributes: attributes, at: itemIndexPath)
        } else {
            return attributes
        }
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        PilotAssertMainThread()
        var result: [UICollectionViewLayoutAttributes] = []
        let range = self.rangeOfSectionsInRect(rect: rect)
        if range.location == -1 { return nil }
        
        for section in range.location..<NSMaxRange(range) {
            let itemCount = _sectionData[section].itemBounds.count
            
            if itemCount > 0 || self.showHeaderWhenEmpty {
                for elementKind in _supplementaryAttributesCache.keys {
                    let indexPath = indexPathForSection(section: section)
                    if let attributes = self.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) {
                        let frame = attributes.frame
                        let intersection = frame.intersection(rect)
                        if !intersection.isEmpty && CGRectGetLengthInDirection(rect: frame, direction: self.scrollDirection) > 0.0 {
                            result.append(attributes)
                        }
                    }
                }
            }
            
            
            for itemIndex in 0..<itemCount {
                let indexPath = IndexPath(item: itemIndex, section: section)
                if let attributes = self.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.intersects(rect) {
                        result.append(attributes)
                    }
                }
            }
        }
        
        return result
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        PilotParamterAssert(condition: indexPath != nil)
        var attributes = _attributesCache[indexPath]
        
        if attributes != nil {
            return attributes
        }
        
        // avoid OOB errors
        let section = indexPath.section
        let item = indexPath.item
        if section >= _sectionData.count || item >= _sectionData[section].itemBounds.count {
            return nil
        }
        
        attributes = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
        if attributes == nil { return nil }
        attributes!.frame = _sectionData[indexPath.section].itemBounds[indexPath.item]
        adjustZIndexForAttributes(attributes: attributes!)
        _attributesCache[indexPath] = attributes!
        return attributes!
    }
    
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        PilotAssertMainThread()
        PilotParamterAssert(condition: indexPath != nil)
        
        var attributes = _supplementaryAttributesCache[elementKind]?[indexPath]
        if attributes != nil {
            return attributes
        }
        
        let section = indexPath.section
        if section >= _sectionData.count {
            return nil
        }
        
        guard let collectionView = self.collectionView else { return nil }
        let entry = _sectionData[section]
        let minOffset = CGRectGetLengthInDirection(rect: entry.bounds, direction: self.scrollDirection)
        
        var frame: CGRect = .zero
        
        if elementKind == UICollectionView.elementKindSectionHeader {
            frame = entry.headerBounds
            
            if self.stickyHeaders {
                var offset = CGPointGetCoordinateInDirection(point: collectionView.contentOffset, direction: self.scrollDirection) + self.topContentInset + self.stickyHeaderYOffset
                
                if section + 1 == _sectionData.count {
                    offset = max(minOffset, offset)
                } else {
                    let maxOffset = CGRectGetMinInDirection(rect: _sectionData[section + 1].bounds, direction: self.scrollDirection) - CGRectGetLengthInDirection(rect: frame, direction: self.scrollDirection)
                    offset = min(max(minOffset, offset), maxOffset)
                }
                
                switch self.scrollDirection {
                case .vertical:
                    frame.origin.y = offset
                    break
                case .horizontal:
                    frame.origin.x = offset
                    break
                }
            }
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            frame = entry.footerBounds
        }
        
        if frame.isEmpty {
            return nil
        } else {
            attributes = UICollectionViewLayoutAttributes.init(forSupplementaryViewOfKind: elementKind, with: indexPath)
            if attributes == nil { return nil }
            attributes!.frame = frame
            adjustZIndexForAttributes(attributes: attributes!)
            _supplementaryAttributesCache[elementKind]![indexPath] = attributes
            return attributes
        }
        
    }
    
    public override var collectionViewContentSize: CGSize {
        get {
            PilotAssertMainThread()
            let sectionCount = _sectionData.count
            
            if sectionCount == 0 {
                return .zero
            }
            
            let section = _sectionData[sectionCount - 1]
            guard let collectionView = self.collectionView else { return .zero }
            let contentInset = collectionView.pilot_contentInset()
            switch self.scrollDirection {
            case .vertical:
                let height = section.bounds.maxY + section.insets.bottom
                return CGSize(width: collectionView.bounds.width - contentInset.left - contentInset.right, height: height)
            case .horizontal:
                let width = section.bounds.maxX + section.insets.right
                return CGSize(width: width, height: collectionView.bounds.height - contentInset.top - contentInset.bottom)
            }
        }
    }
    
    func invalidateLayout(with context: PilotCollectionLayoutInvalidationContext) {
        var hasInvalidateItemIndexPaths: Bool = false
        hasInvalidateItemIndexPaths = context.invalidatedItemIndexPaths?.count ?? -1 > 0
        
        if hasInvalidateItemIndexPaths || context.invalidateEverything || context.pi_invalidateAllAttributes {
            _minimumInvaludatedSection = 0
        } else if context.invalidateDataSourceCounts && _minimumInvaludatedSection == -1 {
            _minimumInvaludatedSection = 0
        }
        
        if context.pi_invalidateSupplementaryAttributes {
            self.resetSupplementaryAttributesCache()
        }
        
        super.invalidateLayout(with: context)
    }
    
    public override class var invalidationContextClass: AnyClass {
        get {
            return PilotCollectionLayoutInvalidationContext.self
        }
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        if let oldBounds = self.collectionView?.bounds, let context = super.invalidationContext(forBoundsChange: newBounds) as? PilotCollectionLayoutInvalidationContext {
            context.pi_invalidateSupplementaryAttributes = true
            if !oldBounds.size.equalTo(newBounds.size) {
                context.pi_invalidateAllAttributes = true
            }
            return context
        }
        return UICollectionViewLayoutInvalidationContext.init()
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldBounds = self.collectionView?.bounds {
            if !oldBounds.size.equalTo(newBounds.size) {
                return true
            }
            
            if CGRectGetMinInDirection(rect: newBounds, direction: self.scrollDirection) != CGRectGetMinInDirection(rect: oldBounds, direction: self.scrollDirection) {
                return stickyHeaders
            }
            return false
        }
        return false
    }
    
    
    public override func prepare() {
        super.prepare()
        self.calculateLayoutIfNeed()
        
    }
    
    //MARK: Public method
    public func setStickyHeaderYOffset(stickyHeaderYOffset: CGFloat) {
        PilotAssertMainThread()
        
        if self.stickyHeaderYOffset != stickyHeaderYOffset {
            self.stickyHeaderYOffset = stickyHeaderYOffset
            
            let invalidationContext = PilotCollectionLayoutInvalidationContext.init()
            invalidationContext.pi_invalidateSupplementaryAttributes = true
            self.invalidateLayout(with: invalidationContext)
        }
    }
    
    
    //MARK: Private method
    
    
    private func calculateLayoutIfNeed() {
        if _minimumInvaludatedSection == -1 { return }
        
        _attributesCache.removeAll()
        self.resetSupplementaryAttributesCache()
        
        guard let collectionView = self.collectionView, let delegate = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return }
        
        let sectionCount = collectionView.numberOfSections
        let contentInset = collectionView.pilot_contentInset()
        let contentInsetAdjustedCollectionViewBounds = collectionView.bounds.inset(by: contentInset)
        
//        _sectionData.
        //!!!: resize
        var itemCoordInScrollDirection: CGFloat = 0.0
        var itemCoordInFixedDirection: CGFloat = 0.0
        var nextRowCoordInScrollDirection: CGFloat = 0.0
        var rollingSectionBounds: CGRect = .zero
        
        var lastValidSection = _minimumInvaludatedSection - 1
        
        if lastValidSection >= 0 && lastValidSection < sectionCount {
            itemCoordInScrollDirection = _sectionData[lastValidSection].lastItemCoordInScrollDirection
            itemCoordInFixedDirection = _sectionData[lastValidSection].lastItemCoordInFixedDirection
            nextRowCoordInScrollDirection = _sectionData[lastValidSection].lastNextCoordInScrollDirection
            rollingSectionBounds = _sectionData[lastValidSection].bounds
        }
        
        
        for section in _minimumInvaludatedSection..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            let itemsEmpty: Bool = itemCount == 0
            let hideHeaderWhenItesEmpty = itemsEmpty && !self.showHeaderWhenEmpty
            _sectionData[section].itemBounds = [] //!!!: 重建
            
            let headerSize = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? .zero
            let footerSize = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? .zero
            let insets = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? .zero
            let lineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) ?? .zero
            let interitemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) ?? .zero
            
            let paddedCollectionViewSize = contentInsetAdjustedCollectionViewBounds.inset(by: insets).size
            let fixedDirection: UICollectionView.ScrollDirection = self.scrollDirection == .horizontal ? .vertical : .horizontal
            let paddedLengthInFixedDirection = CGSizeGetLengthInDirection(size: paddedCollectionViewSize, direction: fixedDirection)
            let headerLengthInScrollDirection = hideHeaderWhenItesEmpty ? 0 : CGSizeGetLengthInDirection(size: headerSize, direction: self.scrollDirection)
            let footerLenghtInScrollDirection = hideHeaderWhenItesEmpty ? 0 : CGSizeGetLengthInDirection(size: footerSize, direction: self.scrollDirection)
            
            let headerExists: Bool = headerLengthInScrollDirection > 0
            let footerExists: Bool = footerLenghtInScrollDirection > 0
            
            itemCoordInScrollDirection += headerLengthInScrollDirection
            nextRowCoordInScrollDirection += headerLengthInScrollDirection
            
            itemCoordInFixedDirection += UIEdgeInsetsLeadingInsetInDirection(insets: insets, direction: fixedDirection)
            
            let maxCoordinateInFixedDirection = CGRectGetLengthInDirection(rect: contentInsetAdjustedCollectionViewBounds, direction: fixedDirection) - UIEdgeInsetsTrailingInsetInDirection(insets: insets, direction: fixedDirection)
            
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
//                PilotAssert(condition: <#T##Bool#>, message: <#T##String#>)
                var itemLengthInFixedDirection = min(CGSizeGetLengthInDirection(size: size, direction: fixedDirection), paddedLengthInFixedDirection)
                
                let epslion:CGFloat = 1.0
                
                if itemCoordInFixedDirection + itemLengthInFixedDirection > maxCoordinateInFixedDirection + epslion || (item == 0 && headerExists) {
                    itemCoordInScrollDirection = nextRowCoordInScrollDirection
                    itemCoordInFixedDirection = UIEdgeInsetsLeadingInsetInDirection(insets: insets, direction: fixedDirection)
                    
                    if item > 0 {
                        itemCoordInScrollDirection += lineSpacing
                    }
                }
                
                let distanceToEdge = paddedLengthInFixedDirection - (itemCoordInFixedDirection + itemLengthInFixedDirection)
                if self.strechToEdge && distanceToEdge > 0 && distanceToEdge <= epslion {
                    itemLengthInFixedDirection = paddedLengthInFixedDirection - itemCoordInFixedDirection
                }
                
                let rawFrame = self.scrollDirection == .vertical ?
                CGRect(x: itemCoordInFixedDirection,
                       y: itemCoordInScrollDirection + insets.top,
                       width: itemLengthInFixedDirection,
                       height: size.height) :
                CGRect(x: itemCoordInScrollDirection + insets.left,
                       y: itemCoordInFixedDirection,
                       width: size.width,
                       height: itemLengthInFixedDirection)
                let frame = PilotCollectionIntegralScaled(rect: rawFrame)
                
                _sectionData[section].itemBounds[item] = frame
                
                nextRowCoordInScrollDirection = max(CGRectGetMaxInDirection(rect: frame, direction: self.scrollDirection) - UIEdgeInsetsLeadingInsetInDirection(insets: insets, direction: self.scrollDirection), nextRowCoordInScrollDirection)
                
                itemCoordInFixedDirection += itemLengthInFixedDirection + interitemSpacing
                
                if item == 0 {
                    rollingSectionBounds = frame
                } else {
                    rollingSectionBounds = rollingSectionBounds.union(frame)
                }
            }
            let headerBounds = self.scrollDirection == .vertical ?
            CGRect(x: insets.left,
                   y: itemsEmpty ? rollingSectionBounds.maxY : rollingSectionBounds.minY,
                   width: paddedLengthInFixedDirection,
                   height: hideHeaderWhenItesEmpty ? 0 : headerSize.height):
            CGRect(x: itemsEmpty ? rollingSectionBounds.maxX : rollingSectionBounds.minX,
                   y: insets.top,
                   width: hideHeaderWhenItesEmpty ? 0 : headerSize.width,
                   height: paddedLengthInFixedDirection)
            
            _sectionData[sectionCount].headerBounds = headerBounds
            
            if itemsEmpty {
                rollingSectionBounds = headerBounds
            }
            
            let footerBounds = self.scrollDirection == .vertical ?
            CGRect(x: insets.left,
                   y: rollingSectionBounds.maxY,
                   width: paddedLengthInFixedDirection,
                   height: hideHeaderWhenItesEmpty ? 0 : footerSize.height) :
            CGRect(x: rollingSectionBounds.maxX + insets.right,
                   y: insets.top,
                   width: hideHeaderWhenItesEmpty ? 0 : footerSize.width,
                   height: paddedLengthInFixedDirection)
            _sectionData[section].footerBounds = footerBounds
            
            if headerExists {
                rollingSectionBounds = rollingSectionBounds.union(headerBounds)
            }
            
            if footerExists {
                rollingSectionBounds = rollingSectionBounds.union(footerBounds)
            }
            
            _sectionData[section].bounds = rollingSectionBounds
            _sectionData[section].insets = insets
            
            itemCoordInFixedDirection += UIEdgeInsetsTrailingInsetInDirection(insets: insets, direction: fixedDirection)
            nextRowCoordInScrollDirection = max(nextRowCoordInScrollDirection, CGRectGetMaxInDirection(rect: rollingSectionBounds, direction: self.scrollDirection) + UIEdgeInsetsTrailingInsetInDirection(insets: insets, direction: self.scrollDirection))
            
            _sectionData[section].lastItemCoordInScrollDirection = itemCoordInScrollDirection
            _sectionData[section].lastItemCoordInFixedDirection = itemCoordInFixedDirection
            _sectionData[section].lastNextCoordInScrollDirection = nextRowCoordInScrollDirection
        }
        
        _minimumInvaludatedSection = -1
        
    }
    
    private func rangeOfSectionsInRect(rect: CGRect) -> NSRange {
        var result = NSRange.init(location: -1, length: 0)
        
        let sectionCount = _sectionData.count
        for section in 0..<sectionCount {
            let entry = _sectionData[section]
            if entry.isValid() && entry.bounds.intersects(rect) {
                let sectionRange = NSRange.init(location: section, length: 1)
                if result.location == -1 {
                    result = sectionRange
                } else {
                    result = result.union(sectionRange)
                }
            }
        }
        return result
    }
    
    
    
    func resetSupplementaryAttributesCache() {
        for i in _supplementaryAttributesCache.keys {
            _supplementaryAttributesCache[i]?.removeAll()
        }
    }

    //MARK: PilotCollectionLayoutCompatible
    func didModifySection(modifiedSection: Int) {
        _minimumInvaludatedSection = PilotMergeMinimInvalidatedSection(section: _minimumInvaludatedSection, otherSection: modifiedSection)
    }
}

