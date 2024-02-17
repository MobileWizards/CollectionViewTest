//
//  ViewController.swift
//  CollectionViewTest
//
//  Created by Marcello Morellato on 17/02/24.
//

import UIKit
import Foundation

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let cellHeight = 290.0
    @IBOutlet weak var collectionView: UICollectionView! // Connect this to your UICollectionView in the storyboard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the collectionView's dataSource and delegate
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        // Register the custom cell
        collectionView.register(UINib(nibName: "TestCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TestCollectionViewCell")
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Return the number of items in your collection view
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue a reusable cell and cast it to your custom cell class
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestCollectionViewCell", for: indexPath) as! TestCollectionViewCell
        
        // Customize the cell here if needed
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Return the size of each cell
        return CGSize(width: 1024, height: 270)
    }
}


extension ViewController {
    private func createLayout() -> UICollectionViewLayout {
        var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
        
        //TODO: weak self
        listConfig.leadingSwipeActionsConfigurationProvider = { indexPath in
            let item = self.collectionView.cellForItem(at: indexPath)
            
           
            let actionHandler1: UIContextualAction.Handler = { action, view, completion in
              completion(true)
                self.collectionView.reloadItems(at: [indexPath])
            }
            let action1 = UIContextualAction(style: .normal, title: "L", handler: actionHandler1)
            action1.backgroundColor = BasketOrderLineType.normal.colorRepresentation()

            let actionHandler2: UIContextualAction.Handler = { action, view, completion in
              completion(true)
                self.collectionView.reloadItems(at: [indexPath])
            }
            let action2 = UIContextualAction(style: .normal, title: "PZ", handler: actionHandler2)
            action2.backgroundColor = BasketOrderLineType.specialPrice.colorRepresentation()
            
            let actionHandler3: UIContextualAction.Handler = { action, view, completion in
              completion(true)
                self.collectionView.reloadItems(at: [indexPath])
            }
            let action3 = UIContextualAction(style: .normal, title: "S", handler: actionHandler3)
            action3.backgroundColor = BasketOrderLineType.discountNature.colorRepresentation()

            return UISwipeActionsConfiguration(actions: [action1, action2, action3])
        }
        
        listConfig.showsSeparators = false
        
        let listLayout = UICollectionViewCompositionalLayout.list(using: listConfig)
        
        return listLayout
    }
    
    func configSize(){
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(1024.0),
                                              heightDimension: .absolute(cellHeight))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1.0))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
    }
}

enum BasketOrderLineType: Int {
    case normal = 0, specialPrice = 1, discountNature = 2
        
    func colorRepresentation() -> UIColor {
        switch self {
        case .specialPrice:
            return UIColor.orange
        case .discountNature:
            return UIColor.red
        default:
            return UIColor.blue
        }
    }
}
