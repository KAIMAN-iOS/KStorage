//
//  ViewController.swift
//  iOSExample
//
//  Created by GG on 30/09/2020.
//

import UIKit

class ViewController: UIViewController {

    private let imageId = "ljhbsdcbwsfbvquypdivbwi"
    private var saveToCameraRoll: Bool = true
    @IBOutlet weak var imageView: UIImageView!
    @IBAction func saveToCameraRollChanged(_ sender: UISwitch) {
        saveToCameraRoll = sender.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func save(_ sender: Any) {
        guard let image = imageView.image else { return }
        guard let _ = try? DataManager.save(image, saveToCamera: saveToCameraRoll) else {
            let alertController = UIAlertController(title: "Oups", message: "Impossible de sauvegarder l'image", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            }))
            present(alertController, animated: true, completion: nil)
            return
        }
        let alertController = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func load(_ sender: Any) {
        guard let image = try? DataManager.fetchImage(for: DataManagerKey.image.rawValue) else {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true, completion: nil)
            return
        }
        imageView.image = image
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
}

