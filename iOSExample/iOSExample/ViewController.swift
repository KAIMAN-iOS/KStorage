//
//  ViewController.swift
//  iOSExample
//
//  Created by GG on 30/09/2020.
//

import UIKit

class ViewController: UIViewController {

    let dataManager = DataManager.instance
    private var saveToCameraRoll: Bool = true
    @IBAction func saveToCameraRollChanged(_ sender: UISwitch) {
        saveToCameraRoll = sender.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func save(_ sender: Any) {
    }
    
    @IBAction func load(_ sender: Any) {
    }
}

