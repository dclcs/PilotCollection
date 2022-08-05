import UIKit


public class PilotCollectionView: UICollectionView {
    var text: String = "Test"
    //MARK: PilotCollectionLayout
    public var listLayout : PilotCollectionViewLayout? = nil
    
    
    //MARK: init
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    convenience init(frame: CGRect, listCollectionViewLayout collectionViewLayout: PilotCollectionViewLayout) {
        self.init(frame: frame, collectionViewLayout: collectionViewLayout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: overides reloads
    public override func reloadItems(at indexPaths: [IndexPath]) {
        self.didModifyIndexPaths(indexPaths: indexPaths)
        super.reloadItems(at: indexPaths)
    }
    
    public override func reloadSections(_ sections: IndexSet) {
        self.didModifySections(sections: sections)
        super.reloadSections(sections)
    }
    
    
    //MARK: overides deletes
    public override func deleteItems(at indexPaths: [IndexPath]) {
        self.didModifyIndexPaths(indexPaths: indexPaths)
        super.deleteItems(at: indexPaths)
    }
    
    public override func deleteSections(_ sections: IndexSet) {
        self.didModifySections(sections: sections)
        super.deleteSections(sections)
    }
    
    //MARK: overrids moves
    public override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        self.didModifyIndexPaths(indexPaths: [indexPath, newIndexPath])
        super.moveItem(at: indexPath, to: newIndexPath)
    }
    
    
    public override func moveSection(_ section: Int, toSection newSection: Int) {
        self.didModifySections(sections: [section, newSection])
        super.moveSection(section, toSection: newSection)
    }
    
    //MARK: modified section
    private func didModifySections(sections: IndexSet) {
        if sections.count <= 0 { return }
        self.didModifySection(section: sections.first!)
    }
    
    
    private func didModifySection(section: Int) {
        //TODO: 添加FlowLayout
        
//        self.listLayout.didModifySection(section)
        self.listLayout?.didModifySection(modifiedSection: section)
    }
    //MARK: modified index path
    private func didModifyIndexPaths(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            self.didModifySection(section: indexPath.section)
        }
    }
}


