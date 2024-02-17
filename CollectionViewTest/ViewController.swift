//
//  ViewController.swift
//  CollectionViewTest
//
//  Created by Marcello Morellato on 17/02/24.
//

import UIKit

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView! // Connect this to your UICollectionView in the storyboard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the collectionView's dataSource and delegate
        collectionView.dataSource = self
        collectionView.delegate = self
        
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


