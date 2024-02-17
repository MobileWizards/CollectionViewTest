//
//  FilterCollectionView+Cells.swift
//  SalesExperience
//
//  Created by Marcello Morellato on 06/02/24.
//  Copyright © 2024 ferlini. All rights reserved.
//

import Foundation

import UIKit

@objc enum FilterCollectionViewColor: Int {
    case lightBackground
    case darkBackground
    case lightBackground2
    case darkBackground2
    
    var uiColor: UIColor {
        switch self {
        case .lightBackground, .lightBackground2:
            return UIColor(hex: "#fbfbfb", alpha: 1)
        case .darkBackground, .darkBackground2:
            return UIColor(hex: "#eeeeee", alpha: 1)
        }
    }
}


extension FilterCollectionView {

    @objc func configureCellTypeProductInfo(forItemAt indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell {
        guard let mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductInfoViewCell", for: indexPath) as? ProductInfoViewCell else {
            fatalError("Unable to dequeue ProductInfoViewCell")
        }
        
        mCell.cellType = Int(cellType.rawValue)
        
        // Uncomment the lines below if you have equivalent properties in Swift
        // mCell.thumbnailImage.contentModeImage = UIView.ContentMode.scaleAspectFit
        // mCell.thumbnailImage.placeholderImageName = placeholderImageName
    
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        let rows = datasource[indexPath.section] as! [FilterInfo] // Assuming datasource is of type [[FilterInfo]]
        let fi = rows[indexPath.row]
        
        mCell.configure(filterInfo: fi)
        
        let itemSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
        mCell.isSelected = itemSelected
        
        return mCell
    }

    @objc func configureCellTypeNavigationItem(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: NavigationItemViewCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "NavigationItemViewCell", for: indexPath) as? NavigationItemViewCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        let rows = datasource[indexPath.section] as? [NavigationItemFilterInfo]
        
        var fi: NavigationItemFilterInfo? = rows?[indexPath.row]
        
        let isProduct = (fi?.itemIdentifier != nil)
        let isProductNavigation = (fi?.nextViewType.intValue == ShowroomType.productDetail.rawValue)
        
        mCell.isProductNavigation = isProductNavigation
        
        mCell.thumbnailImage.placeholderImageName = (isProduct || isProductNavigation) ? placeholderImageNameAlt : placeholderImageName
        
        if isProduct {
            mCell.entityIdentifier = fi?.itemIdentifier
            mCell.catalogueIdentifier = fi?.catalogueIdentifier
            mCell.listIdentifier = fi?.listIdentifier
        } else if isProductNavigation {
            mCell.entityIdentifier = fi?.identifier
            mCell.catalogueIdentifier = fi?.catalogueIdentifier
            mCell.listIdentifier = fi?.listIdentifier
        }
        
        mCell.descrItem = fi?.descr.capitalized
        
        if isProduct || isProductNavigation {
            mCell.badgeValue = nil
        } else {
            mCell.badgeValue = fi?.badgeText()
        }
        
        if isProduct || isProductNavigation {
            mCell.reassortmentBadgeValue = fi?.reassortmentBadgeText()
        } else {
            mCell.reassortmentBadgeValue = nil
        }
        
        mCell.textColor = UIColor.black
        
        var imagePath: String?
        
        let itemBinary = DatabaseManager.binary(byIdentifier: fi?.binaryIdentifier)
        
        imagePath = DefaultAppConfiguration.shared.defaultBinaryPathURL.appendingPathComponent(itemBinary?.thumbFileName() ?? "").path
        
        mCell.thumbnailImage.resourceData = ResourceDataFactory.shared.makeResourceData(binaryIdentifier: fi?.binaryIdentifier, resourceFilePath: imagePath, resourceType: .image)
        
        mCell.selectedTextColor = ThemeInjector.resolve().text.selectedTextColor
        
        mCell.showAddToBasketButton = isProduct || isProductNavigation
        mCell.showAddToStoryboardButton = (isProduct || isProductNavigation) && DefaultAppConfiguration.featureEnabledBy(moduleCode: Module.storyboard)
        mCell.statsValue = fi?.starsValue() ?? 0
        
        weak var weakSelf = self
        mCell.addToBasketCompletitionBlock = { [weak self] success, productInContext, offerSelection in
            guard let strongSelf = self else { return }
            
            let prodsInContext = [productInContext]
            
            guard let sourceVC = strongSelf.window?.rootViewController else { return }
            
            BasketCoordinator.tryAddToBasket(navigationItemContexts: prodsInContext, from: sourceVC, dismissCompletition: { _ in }, quantityMode: .quantityDefault, offerSelection: offerSelection)
        }
        
        mCell.addToStoryboardCompletitionBlock = { [weak self] success, productIdentifier in
            guard let strongSelf = self else { return }
            
            let productIdentifiers = (productIdentifier != nil) ? [productIdentifier!] : []
            
            StoryboardFactory.showAddToStoryboard(pageType: .product, identifiers: productIdentifiers, progress: nil,
                                                  completion: strongSelf.operationCompletition)
        }
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
    }

    @objc func configureCellTypeOrderLineList(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestCollectionViewCell", for: indexPath) as! TestCollectionViewCell
        return cell
        //TODO:cell
        
        var mCell: OrderLineOneItemViewCell!
        
        var ol: OrderLine?
        
        let rows = datasource[indexPath.section] as? [OrderLine]
        
        ol = rows?[indexPath.row]
        
        let isPackage = (ol?.packageIdentifier != nil)
        
        var package: Package?
        
        if isPackage {
            package = DatabaseManager.package(byIdentifier: ol?.packageIdentifier)
        }
        
        let nibName = isPackage ? "OrderLineViewPackageCell" : "OrderLineOneItemViewCell"
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: nibName, for: indexPath) as? OrderLineOneItemViewCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        mCell.isReadOnly = isReadOnly
        
        let addToBasketMode = (paramenters != nil) ? paramenters?[BasketVC.parameterAddToBasketMode] as? NSNumber : nil
        
        let featurePackageEnabledNumber = (paramenters != nil) ? paramenters?[BasketVC.parameterPackageEnabled] as? NSNumber : nil
        
        let featureMultiplierEnabledNumber = (paramenters != nil) ? paramenters?[BasketVC.parameterMultiplierEnabled] as? NSNumber : nil
        
        let featurePackageEnabled = featurePackageEnabledNumber?.boolValue ?? false
        
        let featureMultiplierEnabled = featureMultiplierEnabledNumber?.boolValue ?? false
        
        let isAddToBasketMode = addToBasketMode?.boolValue ?? false
        
        var productHasConfigurations = false
        if !isAddToBasketMode {
            productHasConfigurations = DatabaseManager.productHasModelOptions(byProductIdentifier: ol?.productIdentifier)
        }
        
        mCell.deleteButtonEnabled = !isReadOnly && !isAddToBasketMode
        mCell.duplicateButtonEnabled = !isReadOnly && !isAddToBasketMode
        mCell.addVariantsButtonEnabled = !isReadOnly && !isAddToBasketMode
        mCell.infoButtonEnabled = !isAddToBasketMode
        mCell.productConfigButtonEnabled = !isAddToBasketMode && productHasConfigurations
        mCell.packageButtonEnabled = featurePackageEnabled && (!isReadOnly && !isAddToBasketMode)
        mCell.multiplierButtonEnabled = featureMultiplierEnabled && (!isReadOnly && !isAddToBasketMode)
        mCell.noteButtonEnabled = true
        
        mCell.package = package
        
        mCell.orderline = ol
        
        // handlers
        weak var weakSelf = self
        mCell.didUpdatedCellHandler = { success in
            if let delegate = weakSelf?.delegate {
                delegate.filter?(withIdentifier: weakSelf?.identifier ?? 0, didUpdatedCellAt: indexPath)
            }
        }
        
        mCell.didTapActionButtonHandler = { buttonIndex in
            if let delegate = weakSelf?.delegate {
                delegate.filter?(withIdentifier: weakSelf?.identifier ?? 0,
                                         didTapActionButtonAt: buttonIndex, at: indexPath)
            }
        }
        
        mCell.actionButtonErrorHandler = { buttonIndex in
            var error: NSError?
            if let delegate = weakSelf?.delegate {
               error = delegate.filter?(withIdentifier: weakSelf?.identifier ?? 0,
                                 actionButtonErrorAt: buttonIndex, at: indexPath) as? NSError
            }
            return error
        }
        
        mCell.isReloading = reloadingIndexPath == indexPath
        
        return mCell
    }

    @objc func configureCellTypeOrderList(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: OrderViewCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "OrderViewCell", for: indexPath) as? OrderViewCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        mCell.descrItem = fi?.descr.capitalized
        
        mCell.existNote = fi?.existNote ?? false

        mCell.openOrder = NSNumber(booleanLiteral:(SessionHelper.shared.orderIdentifier?.lowercased() == fi?.identifier.lowercased()))
        
        /*
        mCell.hasDiscount = false
        if let orderDiscount1 = fi?.orderDiscount1, orderDiscount1 > 0 {
            mCell.hasDiscount = true
        }
        */
        mCell.totalPrice = fi?.price
        
        mCell.totalItems = fi?.itemCount
        
        mCell.orderDate = fi?.altDate
        
        mCell.orderNumber = fi?.code
        
        mCell.statusColor = OrderDetailVM.orderStatusColor(by: OrderStatusCode(rawValue: (fi?.statusCode.int32Value ?? 0)))
        
        let showOrderType = fi?.typeCode.intValue != OrderTypeCode.order.rawValue
        mCell.orderTypeDescr = ""
        if showOrderType {
            mCell.orderTypeDescr = fi?.isOffer == true ? "ORDER_TYPE_NAME_OFFER".localized() : fi?.type
        }
        
        mCell.numberOfPairs = fi?.numberOfPairs?.stringValue ?? "0"
        
        mCell.textColor = FFColor.black.uiColor
        
        mCell.selectedTextColor = ThemeInjector.resolve().text.selectedTextColor
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
    }

    @objc func configureCellTypeCustomer(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: CustomerViewCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomerViewCell", for: indexPath) as? CustomerViewCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        if let customerCode = fi?.code, let customerDescription = fi?.nonEmptyDescription() {
            if DefaultAppConfiguration.shared.customerSearchMode == .descriptionAndCode {
                mCell.descrItem = "\(customerCode) - \(customerDescription)"
            } else {
                mCell.descrItem = customerDescription
            }
        }
        
        mCell.avatarData = fi?.avatarData as? NSData

        mCell.initialLabelInputValue = fi?.nonEmptyDescription()
        mCell.hasIncompleteData = fi?.hasIncompleteData() ?? false
        mCell.subTitleLabelValue = (fi?.code != nil) ? "\("ORDER_INFO_LABEL_TITLE_CODE".localized()) \(fi?.code ?? "")" : "0"
        
        //selection state
        
        mCell.textColor = FFColor.black.uiColor
        
        mCell.selectedTextColor = ThemeInjector.resolve().text.selectedTextColor
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
    }

    @objc func configureCellTypeText(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: TextRowFilterCVCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextRowFilterCVCell", for: indexPath) as? TextRowFilterCVCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        mCell.descrItem = fi?.descr ?? ""
        
        //selection state
        
        mCell.textColor = FFColor.darkGray.uiColor
        
        mCell.selectedTextColor = ThemeInjector.resolve().text.selectedTextColor
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
        
    }
    
    @objc func configureCellTypeImageSmall(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: ImageSmallFilterCVCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageSmallFilterCVCell", for: indexPath) as? ImageSmallFilterCVCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.thumbnailImage.contentModeImage = .scaleAspectFit
        
        mCell.thumbnailImage.placeholderImageName = self.placeholderImageName
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        mCell.descrItem = fi?.descr ?? ""
        
        mCell.thumbnailImage.resourceData = ResourceDataFactory.shared.makeResourceData(binaryIdentifier: fi?.binaryIdentifier, resourceFilePath: fi?.imagePath, resourceType: .image)

        //selection state
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
        
    }
    
    @objc func configureCellTypeImageBig(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: ImageBigFilterCVCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageBigFilterCVCell", for: indexPath) as? ImageBigFilterCVCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.thumbnailImage.contentModeImage = .scaleAspectFit
        
        mCell.thumbnailImage.placeholderImageName = self.placeholderImageName
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        mCell.descrItem = fi?.descr ?? ""
        
        mCell.thumbnailImage.resourceData = ResourceDataFactory.shared.makeResourceData(binaryIdentifier: fi?.binaryIdentifier, resourceFilePath: fi?.imagePath, resourceType: .image)

        //selection state
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
        
    }
    
    @objc func configureCellTypeImageBigInfo(forItemAt indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        var mCell: ImageBigInfoFilterCVCell!
        
        mCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageBigInfoFilterCVCell", for: indexPath) as? ImageBigInfoFilterCVCell
        
        mCell.cellType = Int(cellType.rawValue)
        
        mCell.thumbnailImage.contentModeImage = .scaleAspectFit
        
        mCell.thumbnailImage.placeholderImageName = self.placeholderImageName
        
        mCell.backgroundColor = (indexPath.row % 2 == 0) ? FilterCollectionViewColor.lightBackground.uiColor : FilterCollectionViewColor.darkBackground.uiColor
        
        var fi: FilterInfo?
        
        let rows = datasource[indexPath.section] as? [FilterInfo]
        
        fi = rows?[indexPath.row]
        
        mCell.descrItem = fi?.descr ?? ""
        
        mCell.thumbnailImage.resourceData = ResourceDataFactory.shared.makeResourceData(binaryIdentifier: fi?.binaryIdentifier, resourceFilePath: fi?.imagePath, resourceType: .image)

        //selection state
        
        let itemSelected = (collectionView.indexPathsForSelectedItems?.count ?? 0) > 0 && collectionView.indexPathsForSelectedItems!.contains(indexPath)
        
        mCell.isSelected = itemSelected
        
        return mCell
        
    }
}

extension FilterCollectionView {
    @objc func configureCollectionView() {
        let sectionHeaderHeight = 35.0
        switch self.cellType {
        case cellTypeImageBig:
            self.flowLayout.scrollDirection = .horizontal
            self.flowLayout.minimumInteritemSpacing = 0.0
            self.flowLayout.minimumLineSpacing = 0.0
            self.registerCell(nibName: "ImageBigFilterCVCell")
            mainCollectionView.alwaysBounceHorizontal = true
        case cellTypeImageBigInfo:
            self.flowLayout.scrollDirection = .horizontal
            self.registerCell(nibName: "ImageBigInfoFilterCVCell")
            mainCollectionView.alwaysBounceHorizontal = true
        case cellTypeText:
            self.flowLayout.scrollDirection = .vertical
            self.registerCell(nibName: "TextRowFilterCVCell")
        case cellTypeImageSmall:
            self.flowLayout.scrollDirection = .vertical
            self.registerCell(nibName: "ImageSmallFilterCVCell")
        case cellTypeCustomer:
            self.flowLayout.scrollDirection = .vertical
            self.registerCell(nibName: "CustomerViewCell")
            if self.enableSectionHeader {
                self.flowLayout.headerReferenceSize = CGSize(width: mainCollectionView.frame.size.width, height: sectionHeaderHeight)
                self.registerCell(nibName: "CustomerHeaderView")
            }
        case cellTypeOrderList:
            self.flowLayout.scrollDirection = .vertical
            mainCollectionView.register(UINib(nibName: "OrderViewCell", bundle: .main), forCellWithReuseIdentifier: "OrderViewCell")
            self.registerCell(nibName: "OrderViewCell")
        case cellTypeOrderLineList:
            //self.flowLayout.scrollDirection = .vertical
            self.registerCell(nibName: "OrderLineOneItemViewCell")
            self.registerCell(nibName: "OrderLineViewPackageCell")
            //TODO:
            self.registerCell(nibName: "TestCollectionViewCell")
            
        case cellTypeNavigationItem:
            self.flowLayout.scrollDirection = .horizontal
            self.registerCell(nibName: "NavigationItemViewCell")
        case cellTypeProductInfo:
            self.flowLayout.scrollDirection = .vertical
            self.registerCell(nibName: "ProductInfoViewCell")
        case cellTypeUnknown:
            // Throw error
            break
        default:break
        }
        
        mainCollectionView.isPagingEnabled = pagingEnabled
        mainCollectionView.backgroundColor = .clear
        mainCollectionView.allowsMultipleSelection = allowMultiselection
        if self.cellType != cellTypeOrderLineList { 
            mainCollectionView.collectionViewLayout = self.flowLayout
        }

    }
    
    func registerCell(nibName: String, reuseIdentifier: String? = nil){
        let identifier = reuseIdentifier != nil ? reuseIdentifier! : nibName
        mainCollectionView.register(UINib(nibName: nibName, bundle: .main), forCellWithReuseIdentifier: identifier)
    }
    
    @objc func makeCell(for indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        
        switch cellType {
        case cellTypeImageSmall:
            cell = configureCellTypeImageSmall(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeImageBig:
            cell = configureCellTypeImageBig(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeImageBigInfo:
            cell = configureCellTypeImageBigInfo(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeText:
            cell = configureCellTypeText(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeCustomer:
            cell = configureCellTypeCustomer(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeOrderList:
            cell = configureCellTypeOrderList(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeOrderLineList:
            cell = configureCellTypeOrderLineList(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeNavigationItem:
            cell = configureCellTypeNavigationItem(forItemAt: indexPath, collectionView: collectionView)
        case cellTypeProductInfo:
            cell = configureCellTypeProductInfo(forItemAt: indexPath, in: collectionView)
        case cellTypeUnknown:
            // Handle unknown cell type
            cell = UICollectionViewCell()
        default:
            return UICollectionViewCell()
        }
        
        return cell
    }


}

