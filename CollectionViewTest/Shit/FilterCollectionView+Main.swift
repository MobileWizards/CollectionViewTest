//
//  FilterCollectionView+Main.swift
//  SalesExperience
//
//  Created by Marcello Morellato on 06/02/24.
//  Copyright © 2024 ferlini. All rights reserved.
//

import Foundation

// MARK: - Collection View
extension FilterCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datasource?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let item = datasource?[section] as? [Any]
        return item?.count ?? 0
    }

    //this is fired only when collectionviewlayout is flowlayout (with composable not called)
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //print("flowLayout.itemSize : \(flowLayout.itemSize)")
        return flowLayout.itemSize
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        
        guard let rows = datasource[indexPath.section] as? [Any] else {
            return UICollectionViewCell()
        }
        
        if indexPath.row >= rows.count {
            print("<WARNING>[FilterCollectionView] cellForItemAtIndexPath index wrong>")
            // indexPath = IndexPath(row: 0, section: 0)
        }
        
        cell = makeCell(for: indexPath, in: collectionView)
        
        mainPageControl?.numberOfPages = Int(floor(mainCollectionView.contentSize.width / mainCollectionView.frame.size.width)) + 1
        mainPageControl?.isHidden = !self.hidePageIndicator || mainPageControl.numberOfPages == 1
        
        if self.enableOndemandLoad && !fetchNewDataInProgress && needLoadMoreData(indexPath: indexPath) {
            print("needReloadMoreData")
            appendData()
        }
        
        reloadingIndexPath = nil
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard cellType == cellTypeCustomer else { return UICollectionReusableView() }
        
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CustomerHeaderView", for: indexPath) as? CustomerHeaderView else {
                return UICollectionReusableView()
            }
            
            var headerTitle = ""
            
            switch indexPath.section {
            case 0:
                headerTitle = "MAP_CAMERA_ON_AGENT_CUSTOMERS".localized()
            case 1:
                headerTitle = "MAP_CAMERA_ON_OTHER_AGENTS_CUSTOMERS".localized()
            default:
                headerTitle = "MAP_CAMERA_ON_FREE_CUSTOMERS".localized()
            }
            
            headerView.label.text = headerTitle
            return headerView
        }
        
        return UICollectionReusableView()
    }

    open override func selectAll(_ sender: Any?) {
        
        let section = 0
        let collectionViewItems = mainCollectionView.numberOfItems(inSection: section)
        let selectAllMode = collectionViewItems > mainCollectionView.indexPathsForSelectedItems?.count ?? 0
        
        for row in 0..<collectionViewItems {
            let selectedIndexPath = IndexPath(row: row, section: section)
            let isSelected = mainCollectionView.indexPathsForSelectedItems?.contains(selectedIndexPath) ?? false
            
            if selectAllMode && !isSelected {
                mainCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .top)
                collectionView(mainCollectionView, didSelectItemAt: selectedIndexPath)
            } else if !selectAllMode {
                mainCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .top)
                collectionView(mainCollectionView, didSelectItemAt: selectedIndexPath)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let selectSameItem = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
        
        if selectSameItem {
            return allowSelectSameItem
        }
        
        if let delegate = delegate, delegate.responds(to: #selector(FilterCollectionViewDelegate.shouldSelectItem(at:))) {
            if let shouldSelectItem = delegate.shouldSelectItem?(at: indexPath) {
                return shouldSelectItem
            }
        }
        
        return true
    }

    func selectItemAtIndexPath(_ indexPath: IndexPath) {
        mainCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fi = filterInfoByIndexPath(indexPath)
        
        if let delegate = delegate, let value = fi?.identifier {
            if delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didSelectValue:at:))) {
                delegate.filter?(withIdentifier: identifier, didSelectValue: value, at: indexPath)
            } else if delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didSelectValue:))) {
                delegate.filter?(withIdentifier: identifier, didSelectValue: value)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return unselectEnabled
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard indexPathIsValid(indexPath) else {
            // Handle invalid index path
            return
        }
        
        let item: FilterInfo
        if let rows = datasource[indexPath.section] as? [FilterInfo], indexPath.row < rows.count {
            item = rows[indexPath.row]
            
            if let delegate = delegate, delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didUnselectValue:))) {
                delegate.filter?(withIdentifier: identifier, didUnselectValue: item.identifier)
            }
        }
    }

}

extension FilterCollectionView: UIGestureRecognizerDelegate {
    @objc func configureLongPress(){
        if enableCellLongPress {
               if longPressGesture == nil {
                   let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                   longPressGesture.delegate = self
                   longPressGesture.delaysTouchesBegan = true
                   mainCollectionView.addGestureRecognizer(longPressGesture)
                   self.longPressGesture = longPressGesture
               }
           } else {
               if let longPressGesture = longPressGesture {
                   mainCollectionView.removeGestureRecognizer(longPressGesture)
                   self.longPressGesture = nil
               }
           }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        
        let location = gestureRecognizer.location(in: mainCollectionView)
        guard let indexPath = mainCollectionView.indexPathForItem(at: location) else { return }
        
        let filterInfo = filterInfoByIndexPath(indexPath)
        
        if let delegate = delegate, let value = filterInfo?.identifier,
           delegate.responds(to: #selector(FilterCollectionViewDelegate.filter(withIdentifier:didLongPressSelectValue:))) {
            delegate.filter?(withIdentifier: identifier, didLongPressSelectValue: value)
        }
    }

}

extension FilterCollectionView {
    
    @objc func needLoadMoreData(indexPath: IndexPath) -> Bool {
        guard let rows = datasource.first as? [Any] else { return false }
        
        let rowsCount = rows.count
        let datasourceBiggerThanPageCount = rowsCount >= pageItemCount
        let pageIndex = Int(ceil(Double(rowsCount) / Double(pageItemCount)))
        let countLimitToLoadNewData = Int((Double(pageItemCount) * 0.5) * Double(pageIndex))
        let currentRowIndex = indexPath.row
        let needLoadMoreData = !allDataLoaded && currentRowIndex > countLimitToLoadNewData && rowsCount >= (Int(pageItemCount) * pageIndex)
        let loadMoreData = datasourceBiggerThanPageCount && needLoadMoreData
        
        #if DEBUG_TRACE_LOG
        print("loadMoreData currIndex \(currentRowIndex) \(datasourceBiggerThanPageCount) \(needLoadMoreData) = \(loadMoreData)")
        #endif
        
        return loadMoreData
    }

    @objc func canFetchMoreData() -> Bool {
        return !allDataLoaded
    }

    @objc func fetchMoreData() {
        if enableOndemandLoad {
            if !fetchNewDataInProgress {
                print("needReloadMoreData")
                appendData()
            }
        }
    }

    @objc func refreshData(at indexPath: IndexPath) {
        if let newFilterInfo = self.delegate?.datasourceAsync?(withFilterIdentifier:self.identifier, updateFor: indexPath) as? FilterInfo {
            var updatedSectionRows = self.datasource[indexPath.section] as? [Any]
            updatedSectionRows?[indexPath.row] = newFilterInfo
            
            var newDataSource = self.datasource
            
            newDataSource?[indexPath.section] = updatedSectionRows
            
            self.datasource = newDataSource
        }
        
        reloadCell(at: indexPath)
    }

}
