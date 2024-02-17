//
//  FilterCollectionView+Utils.swift
//  SalesExperience
//
//  Created by Marcello Morellato on 06/02/24.
//  Copyright © 2024 ferlini. All rights reserved.
//

import Foundation

//MARK: Utils
extension FilterCollectionView {
    @objc func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        if indexPath.section >= mainCollectionView.numberOfSections {
            return false
        }
        if indexPath.row >= mainCollectionView.numberOfItems(inSection: indexPath.section) {
            return false
        }
        return true
    }

   @objc func filterInfoByIndexPath(_ indexPath: IndexPath) -> FilterInfo? {
        guard !datasource.isEmpty else {
            return nil
        }
        
        guard let rows = datasource[indexPath.section] as? [FilterInfo], indexPath.row < rows.count else {
            return nil
        }
        
        return rows[indexPath.row]
    }

    @objc func currentPageIndex() -> Int {
        let pageWidth = mainCollectionView.frame.size.width
        let currentPage = mainCollectionView.contentOffset.x / pageWidth
        return Int(currentPage)
    }

    @objc func gotoNextPage() {
        guard let rows = datasource.first as? [FilterInfo] else {
            return
        }
        
        if rows.isEmpty {
            return
        }
        
        if currentPageIndex() < rows.count - 1 {
            let indexPath = IndexPath(row: currentPageIndex() + 1, section: 0)
            mainCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        }
    }

    @objc func gotoPreviousPage() {
        guard let rows = datasource.first as? [FilterInfo] else {
            return
        }
        
        if rows.isEmpty {
            return
        }
        
        if currentPageIndex() > 0 {
            let indexPath = IndexPath(row: currentPageIndex() - 1, section: 0)
            mainCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        }
    }

    @objc func datasourceItemsCount() -> Int {
        let itemsCount = datasource.compactMap { $0 as? [FilterInfo] }.reduce(0) { $0 + $1.count }
        return itemsCount
    }

    @objc func scrollToLastItem() {
        guard let rows = datasource.first as? [Any] else {
            return
        }
        
        let rowIndex: Int
        
        if rows.count > 0 {
            rowIndex = rows.count - 1
        } else {
            return
        }
        
        scrollToRowIndex(rowIndex)
    }

    @objc func scrollToItemIdentifier(_ item: String) {
        guard let rows = datasource.first as? [FilterInfo] else {
            return
        }
        
        var rowIndex = -1
        
        for (index, obj) in rows.enumerated() {
            if obj.identifier == item {
                rowIndex = index
                break
            }
        }
        
        scrollToRowIndex(rowIndex)
    }

    @objc func scrollToRowIndex(_ rowIndex: Int) {
        guard rowIndex != -1 else {
            return
        }
        if self.cellType == cellTypeOrderLineList { return }
        
        let indexPath = IndexPath(row: rowIndex, section: 0)
        
        if mainCollectionView.delegate?.collectionView?(mainCollectionView, shouldSelectItemAt: indexPath) == true {
            let scrollPosition: UICollectionView.ScrollPosition = (flowLayout.scrollDirection == .vertical) ? .bottom : .right
            mainCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: scrollPosition)
        } else {
            print("<WARNING>[FilterCollectionView] selectItemIdentifier failed : shouldselectitem return NO>")
        }
    }

    @objc func resetSelection() {
        if let selectedIndexPaths = mainCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                mainCollectionView.deselectItem(at: indexPath, animated: true)
            }
        }
    }

    @objc func selectItemIdentifier(_ item: String) -> Bool {
        return selectItemIdentifier(item, section: 0)
    }

    @objc func selectItemIdentifier(_ item: String, section: Int) -> Bool {
        guard let rows = datasource[section] as? [FilterInfo] else {
            return false
        }
        
        var rowIndex = -1
        
        for (index, obj) in rows.enumerated() {
            if obj.identifier == item {
                rowIndex = index
                break
            }
        }
        
        guard rowIndex != -1 else {
            return false
        }
        
        let indexPath = IndexPath(row: rowIndex, section: section)
        
        guard indexPathIsValid(indexPath) else {
            return false
        }
        
        if let delegate = mainCollectionView.delegate as? UICollectionViewDelegateFlowLayout,
           delegate.collectionView?(mainCollectionView, shouldSelectItemAt: indexPath) == true {
            
            let scrollPosition: UICollectionView.ScrollPosition = (flowLayout.scrollDirection == .vertical) ? .bottom : .right
            mainCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: scrollPosition)
            
            collectionView(mainCollectionView, cellForItemAt: indexPath)
            return true
        } else {
            print("<WARNING>[FilterCollectionView] selectItemIdentifier failed : shouldselectitem return NO>")
            return false
        }
    }

    @objc func updateCellSize() {
        if self.cellSize == .zero { return }
        if self.cellType == cellTypeOrderLineList { return }
        
        switch self.cellType {
        default:
            if UIApplication.shared.statusBarOrientation.isLandscape {
                self.flowLayout.itemSize = (self.cellLandscapeSize == .zero) ? self.cellSize : self.cellLandscapeSize
            } else {
                self.flowLayout.itemSize = self.cellSize
            }
        }
    }
    
    @objc func autoSelectFirstItem() {
        var autoSelect = true
        autoSelect = autoSelect && self.autoSelectOnFirstLoad
        autoSelect = autoSelect && self.datasourceItemsCount() > 0
        autoSelect = autoSelect && (mainCollectionView.indexPathsForSelectedItems?.isEmpty ?? true)
        
        let selectedIdentifierExists = selectedItemIdentifierFirstLoad != nil
        
        if autoSelect && !selectedIdentifierExists {
            selectFirstItemAtIndexZero()
        } else if autoSelect && selectedIdentifierExists {
            // TODO: If an on-demand loading is performed, the selection may not work.
            selectItemIdentifier(selectedItemIdentifierFirstLoad)
        }
        
        if self.autoSelectOnFirstLoad == true { self.autoSelectOnFirstLoad = false } // TODO: Find a better solution
    }

    @objc func selectFirstItem() {
        let section = 0
        guard self.collectionView(mainCollectionView, numberOfItemsInSection: section) > 0 else {
            return
        }
        
        let firstItemIndexPath = IndexPath(row: 0, section: section)
        
        mainCollectionView.selectItem(at: firstItemIndexPath, animated: true, scrollPosition: .centeredVertically)
        
        self.collectionView(mainCollectionView, didSelectItemAt: firstItemIndexPath)

    }
    @objc func selectFirstItemAtIndexZero() {
        let section = 0
        guard self.collectionView(mainCollectionView, numberOfItemsInSection: section) > 0 else {
            return
        }
        
        let firstItemIndexPath = IndexPath(row: 0, section: section)
        
        mainCollectionView.selectItem(at: firstItemIndexPath, animated: true, scrollPosition: .centeredVertically)
        
        self.collectionView(mainCollectionView, didSelectItemAt: firstItemIndexPath)

    }


    @objc func reloadCell(at indexPath: IndexPath) {
        reloadingIndexPath = indexPath
        DispatchQueue.main.async {
            self.mainCollectionView.reloadItems(at: [indexPath])
        }
    }

    @objc func flowLayout() -> UICollectionViewFlowLayout? {
        return mainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

}

extension FilterCollectionView: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = mainCollectionView.frame.size.width
        let currentPage = mainCollectionView.contentOffset.x / pageWidth
        
        if currentPage.truncatingRemainder(dividingBy: 1.0) != 0.0 {
            mainPageControl?.currentPage = Int(currentPage + 1)
        } else {
            mainPageControl?.currentPage = Int(currentPage)
        }
        
        if let delegate = self.delegate, self.delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didChangePage:))) {
            delegate.filter?(withIdentifier: self.identifier, didChangePage: Int32(currentPage))
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let delegate = self.delegate, self.delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didChangePage:))) {
            delegate.filter?(withIdentifier: self.identifier, didChangePage: Int32(self.currentPageIndex()))
        }
    }
}
