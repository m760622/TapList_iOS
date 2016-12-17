//
//  ProductDetailViewController.swift
//  TapList
//
//  Created by Anthony Whitaker on 12/9/16.
//  Copyright © 2016 Anthony Whitaker. All rights reserved.
//

import UIKit
import Alamofire

class ProductDetailViewController: UIViewController, ProductView, QuantityView {

    @IBOutlet weak var productImageCollectionView: UICollectionView!
    @IBOutlet weak var specialInstructionTextView: PlaceholderTextView!
    
    @IBOutlet weak var skuLabel: UILabel!
    
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var eachLabel: UILabel!
    @IBOutlet weak var listPriceLabel: UILabel!
    @IBOutlet weak var offerPriceButton: UIButton!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cartQuantityLabel: UILabel!
    
    @IBOutlet weak var quantityButton: UIButton!
    @IBOutlet weak var quantityTextField: QuantityTextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var keyboardHandler: KeyboardHandler!
    
    var product: Product!
    var productImages = Array<UIImage>()
    
    var imageRequests = Array<DataRequest?>()
    
    var quantityInCart: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setImages()
        
        productImageCollectionView.delegate = self
        productImageCollectionView.dataSource = self
                
        keyboardHandler = KeyboardHandler(contextView: self.view, scrollView: scrollView, onlyScrollForKeyboard: true)
        keyboardHandler.startDismissingKeyboardOnTap()
        keyboardHandler.startObservingKeyboardEvents()
    }
    
    private func setImages() {
        for imageRequest in imageRequests {
            imageRequest?.cancel() // Cancel any ongoing image requests (can happen when user scrolls quickly).
        }
        self.imageRequests.removeAll()
        
        
        var imagesByDirection = Dictionary<ImageService.Direction, UIImage>()
        
        let imageDispatch = DispatchGroup()
        
        for direction in ImageService.Direction.values {
            imageDispatch.enter()
            let request = ImageService.instance.image(for: product, size: .large, direction: direction, completion: { image in
                if let image = image {
                    imagesByDirection[direction] = image
                }
                imageDispatch.leave()
            })
            
            imageRequests.append(request)
        }
        
        imageDispatch.notify(queue: .main) {
            self.productImages.removeAll()
            for direction in ImageService.Direction.values { // Provides predetermined order, vs order of fetches finishing. Filters out missing pictures.
                if let image = imagesByDirection[direction] {
                    self.productImages.append(image)
                }
            }
            self.productImageCollectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let cartItem = DataService.instance.cart.cartItems[product.sku] {
            self.quantityInCart = cartItem.quantity
        } else {
            self.quantityInCart = 0
        }
        
        configureProductView()
        skuLabel.text = "SKU:\(product.sku)"
        
        if let cartItem = DataService.instance.cart.cartItems[product.sku] {
            if let specialInstructions = cartItem.specialInstructions {
                specialInstructionTextView.text = specialInstructions
                specialInstructionTextView.refresh()
            }
        }
        
        configureQuantityView(previousQuantity: quantityInCart)
    }

    @IBAction func updateCartPressed(_ sender: UIButton) {
        var specialInstructions: String? = nil
        if let newInstructions = specialInstructionTextView.text, !newInstructions.isEmpty {
            specialInstructions = newInstructions
        }
        
        quantityInCart = quantity
        updateCartQuantityLabel()
        
        let cartItem = CartItem(sku: product.sku, quantity: quantity, specialInstructions: specialInstructions)
        DataService.instance.update(cartItem: cartItem)
        
//        navigationController?.popViewController(animated: true) //FIXME: Executes before update finishes executing, causing stale data on previous controller.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "offerPopover" {
            guard let controller = segue.destination as? SalePriceViewController else {
                print("improper controller for this segue")
                return
            }
            
            controller.product = product
            preparePopover(for: controller, sender: sender)
        } else if segue.identifier == "quantityPopover" {
            guard let controller = segue.destination as? QuantityTableViewController else {
                print("improper controller for this segue")
                return
            }
            
            controller.delegate = self
            controller.previousQuantity = quantityButton.currentTitle
            preparePopover(for: controller, sender: sender)
        }
    }
    
    func preparePopover(for controller: UIViewController, sender: Any?) {
        controller.popoverPresentationController?.delegate = self
        
        // Set bounds for arrow placement.
        if let sender = sender as? UIButton {
            controller.popoverPresentationController?.sourceView = sender
            controller.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.width, height: sender.frame.height)
        }
        
        controller.modalPresentationStyle = .popover
    }

}

extension ProductDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

}

extension ProductDetailViewController: UICollectionViewDelegate {}

extension ProductDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = productImages[indexPath.row]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "productImage", for: indexPath) as? ImageCollectionViewCell {
            cell.configureCell(image: image)
            return cell
        }
        
        return UICollectionViewCell()
    }
}

extension ProductDetailViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
