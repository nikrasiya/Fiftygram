//
//  ViewController.swift
//  Fiftygram
//
//  Created by Nikhil  Agrawal on 6/29/20.
//  Copyright © 2020 Nikhil Agrawal. All rights reserved.
//

import UIKit

class FiftygramViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    let context = CIContext()
    var original: UIImage?
    @IBOutlet var sepiaButton: UIButton!
    @IBOutlet var noirButton: UIButton!
    @IBOutlet var vintageButton: UIButton!
    @IBOutlet var bloomButton: UIButton!
    @IBOutlet var imageActivitiyIndicator: UIActivityIndicatorView!
    let serialQueue = DispatchQueue(label: "squeue.fiftygram")

    override func viewDidLoad() {
        super.viewDidLoad()
        sepiaButton.tag = ButtonIdentifier.Sepia.rawValue
        noirButton.tag = ButtonIdentifier.Noir.rawValue
        vintageButton.tag = ButtonIdentifier.Vintage.rawValue
        bloomButton.tag = ButtonIdentifier.Bloom.rawValue
        imageActivitiyIndicator.isHidden = true
    }

    @IBAction func choosePhoto(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            navigationController?.present(picker, animated: true, completion: nil)
        }
    }

    @IBAction func applyFilter(_ sender: UIButton) {
        imageActivitiyIndicator.isHidden = false
        let filter: CIFilter?
        switch sender.tag {
        case ButtonIdentifier.Sepia.rawValue:
            filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(0.5, forKey: kCIInputIntensityKey)
        case ButtonIdentifier.Noir.rawValue:
            filter = CIFilter(name: "CIPhotoEffectNoir")
        case ButtonIdentifier.Vintage.rawValue:
            filter = CIFilter(name: "CIPhotoEffectProcess")
        case ButtonIdentifier.Bloom.rawValue:
            filter = CIFilter(name: "CIBloom")
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            filter?.setValue(10, forKey: kCIInputRadiusKey)
        default:
            filter = nil
        }
        guard let ciFilter = filter else { return }
        serialQueue.async { [unowned self] in
            self.displayFilter(for: ciFilter)
        }
    }

    func displayFilter(for filter: CIFilter) {
        guard let original = original else {
            DispatchQueue.main.async {
                self.imageActivitiyIndicator.isHidden = true
            }
            return
        }
        filter.setValue(CIImage(image: original), forKey: kCIInputImageKey)
        guard let output = filter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) else {
            return
        }

        DispatchQueue.main.async {
            self.imageActivitiyIndicator.isHidden = true
            self.imageView.image = UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        navigationController?.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageActivitiyIndicator.isHidden = true
            imageView.image = image
            original = image
        }
    }

    @IBAction func savePhoto(_ sender: UIButton) {
        guard let userImage = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(userImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error ☹️",
                                       message: error.localizedDescription,
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved 👏",
                                       message: "Your filtered image has been saved to your photos. ",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}

enum ButtonIdentifier: Int {
    case Sepia = 1
    case Noir = 2
    case Vintage = 3
    case Bloom = 4
}
