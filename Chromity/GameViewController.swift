
import UIKit
import SpriteKit
import GameplayKit
import GameKit
import PhotosUI

class GameViewController: UIViewController, GKGameCenterControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        GameCenterManager.shared.authenticateUser(presentingViewController: self)
        ICloudSyncManager.shared.startSync()

        if let view = self.view as? SKView {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill

            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            view.showsPhysics = false
        }
        
        if AdManager.shared.isSDKInitialized {
            AdManager.shared.setupBanner(in: self)
        } else {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(adsReadyForBanner),
                                                   name: .adsReady,
                                                   object: nil)
        }
    }

    @objc private func adsReadyForBanner() {
        AdManager.shared.setupBanner(in: self)
        NotificationCenter.default.removeObserver(self, name: .adsReady, object: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
    
    
    func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension GameViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self, let uiImage = image as? UIImage else { return }
            
            DispatchQueue.main.async {
                self.saveCustomBackground(uiImage)
                
                if let skView = self.view as? SKView,
                   let scene = skView.scene as? GameScene {
                    scene.applyCustomPhotoBackground()
                }
            }
        }
    }
    
    private func saveCustomBackground(_ image: UIImage) {
        let normalizedImage: UIImage
        if image.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            normalizedImage = image
        }
        
        guard let data = normalizedImage.jpegData(compressionQuality: 0.8) else { return }
        let url = GameViewController.customBackgroundURL
        try? data.write(to: url)
        
        UserDefaults.standard.set("custom_photo", forKey: "SelectedBackground")
        ICloudSyncManager.shared.pushValue("custom_photo", forKey: "SelectedBackground")
    }
    
    static var customBackgroundURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("custom_bg.jpg")
    }
    
    static var hasCustomBackground: Bool {
        return FileManager.default.fileExists(atPath: customBackgroundURL.path)
    }
    
    static func loadCustomBackgroundImage() -> UIImage? {
        return UIImage(contentsOfFile: customBackgroundURL.path)
    }
}
