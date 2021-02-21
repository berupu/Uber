//
//  File.swift
//  Uber Clone
//
//  Created by be RUPU on 10/2/21.
//  Copyright © 2021 be RUPU. All rights reserved.
//

import UIKit

class ContainerController : UIViewController {
    
     private let homeController = HomeController()
     private let menuController = MenuController()
     private var isExpanded = false
    
      
      override func viewDidLoad() {
             super.viewDidLoad()
        
        view.backgroundColor = .backgroundColor
        configureHomeController()
        configureMenuController()
      }
      

    //MARK: - adding homeController down to the menuController
    
      func configureHomeController(){
          addChild(homeController)
          homeController.didMove(toParent: self)
          view.addSubview(homeController.view)  //homecontroller will be second/ under the menu


        homeController.delegate = self as HomeControllerDelegate
      }

    func configureMenuController(){
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)  //menucontroller will be first view
    }
    
    
    func animateMenu(shouldExpand: Bool){
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.view.frame.origin.x = self.view.frame.width - 80
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.view.frame.origin.x = 0
            }, completion: nil)
        }
    }
    
}


extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        isExpanded.toggle()

        print("debug: menu toggle..\(isExpanded)")
        animateMenu(shouldExpand: isExpanded)
    }

}
