import CoreML
import ImageIO
import Photos
import UIKit
import Vision

class ViewController: UIViewController {

    // Controls
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var toggleCameraButton: UIButton!

    // The camera preview that video output is sent to
    @IBOutlet var capturePreviewView: UIView!

    // Visuals for user feedback
    @IBOutlet weak var labelsMatchIndicator: UIImageView!
    @IBOutlet var flash: UIView!
    @IBOutlet var needleWrapper: UIView!
    @IBOutlet var needle: UIImageView!
    @IBOutlet var needleShadowWrapper: UIView!
    @IBOutlet var needleShadow: UIImageView!

    // Timer that runs while the app is open, classifying images from the camera
    var checkTimer: Timer?

    // Timer for randomly jittering the needle during use
    var needleJitterTimer: Timer?

    // Timing values for checks
    let jitterCheckInterval = 0.15
    let classificationCheckInterval = 1.0

    let cameraController = CameraController()

    // MARK: - Actions
    @IBAction func switchCameras(_ sender: UIButton) {
        do {
            try cameraController.switchCameras()
        }
        catch {
            fatalError("Failed to switch cameras: \(error.localizedDescription)")
        }
    }


    @IBAction func saveImage(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.05,
            delay: 0,
            animations: {
                self.flash.alpha = 0.8
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    animations: {
                        self.flash.alpha = 0
                    }
                )
            }
        )

        captureImage(saveImage: true)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        cameraController.prepare {_ in
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }

        checkTimer = Timer.scheduledTimer(
            timeInterval: classificationCheckInterval,
            target: self,
            selector: #selector(captureImage),
            userInfo: nil,
            repeats: true
        )

        needleJitterTimer = Timer.scheduledTimer(
            timeInterval: jitterCheckInterval,
            target: self,
            selector: #selector(jitterNeedle),
            userInfo: nil,
            repeats: true
        )
    }

    // MARK: - Image classification
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let configuration = MLModelConfiguration()
            let model = try VNCoreMLModel(for: VigetLogoClassifier(configuration: configuration).model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error.localizedDescription)")
        }
    }()


    func getCGOrientationFromUIImage(_ image: UIImage) -> CGImagePropertyOrientation {
        // This conversion is necessary because UIImage.imageOrientation is
        // a different enum than CGImagePropertyOrientation.
        switch image.imageOrientation {
        case .left:
            return .left
        case .right:
            return .right
        case .up:
            return .up
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        case .upMirrored:
            return .upMirrored
        default:
            return .down
        }
    }

    func updateClassifications(for image: UIImage) {
        let orientation = getCGOrientationFromUIImage(image)

        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                fatalError("Failed to preform classification: \(error.localizedDescription)")
            }
        }
    }

    func getNeedleRadiansForConfidence(_ confidence: Float) -> CGFloat {
        // `reduction` is a rough (eyeballed) divison that puts
        // the needle inside the ~40 degree range of the dial.
        let reduction = CGFloat(2.15)
        return CGFloat(confidence - 0.5) * CGFloat.pi / reduction
    }

    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            let results = request.results
            var confidence = Float(0.0)
            let classifications = results as! [VNClassificationObservation]

            // This setup allows for models with multiple "Viget" classifications, which improved
            // accuracy in some cases during testing.
            if !classifications.isEmpty {
                let vigetClassifications = classifications.filter { $0.identifier != "NotVigetLogo" }
                confidence = vigetClassifications.max { a, b in a.confidence < b.confidence }!.confidence
            }

            let showMatchIndicator = confidence > 0.85

            UIView.animate(
                withDuration: self.classificationCheckInterval / 2,
                delay: 0.0,
                animations: {
                    self.needle.transform = CGAffineTransform(rotationAngle: self.getNeedleRadiansForConfidence(confidence))
                    self.needleShadow.transform = CGAffineTransform(rotationAngle: self.getNeedleRadiansForConfidence(confidence))
                    self.labelsMatchIndicator.alpha = showMatchIndicator ? 1 : 0
                }
            )
        }
    }

    @objc func captureImage(saveImage: Bool = false) {
        cameraController.captureImage {(image, error) in
            guard let image = image else {
                // Will throw "operation couldn't be completed" when closing/reopening app sometimes
                // but this error can be ignored.
                return
            }

            self.updateClassifications(for: image)

            if saveImage {
                try? PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            }
        }
    }

    @objc func jitterNeedle() {
        let jitterRadians = CGFloat.random(in: -0.02 ... 0.02)
        let jitterDuration = Double.random(in: 0.1 ... jitterCheckInterval)

        UIView.animate(
            withDuration: jitterDuration,
            delay: 0.0,
            animations: {
                self.needleWrapper.transform = CGAffineTransform(rotationAngle: jitterRadians)
                self.needleShadowWrapper.transform = CGAffineTransform(rotationAngle: jitterRadians)
            }
        )
    }
}
