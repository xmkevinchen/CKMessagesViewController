//
//  GridViewController.swift
//  CKMessagesViewController
//
//  Created by Kevin Chen on 8/24/16.
//  Copyright © 2016 Kevin Chen. All rights reserved.
//

import UIKit
import CKMessagesKit
import Reusable

class GridViewController: UIViewController, CKMessagePresenting, Identifiable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let message = self.message {
            renderPresenting(with: message)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    public var message: CKMessageData?
    public var messageType: CKMessageData.Type = GridMessage.self
    
    public static func presentor() -> CKMessagePresenting {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let viewController: GridViewController = storyboard.instantiate()
        return viewController
    }
    
    func renderPresenting(with message: CKMessageData) {
        if let message = message as? GridMessage, let collectionView = collectionView {
            self.message = message
            collectionView.reloadData()
        }
    }

    
    
}




@IBDesignable
class GridCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    @IBInspectable var borderColor: UIColor? = nil {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
            layer.masksToBounds = borderWidth > 0
        }
    }
    
}

extension GridViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! GridCell
        
        cell.textLabel.text = String(indexPath.item + Int(message!.text)!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("====> didSelectItemAt: \(indexPath)")
        
        let alert = UIAlertController(title: "Clicked", message: "\(indexPath)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
}
