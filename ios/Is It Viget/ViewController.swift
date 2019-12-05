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
    let needleAnimationDuration = 0.5
    let classificationCheckInterval = 0.25

    // Visible bounding box when debugging
    var boundingBox: UIView?
    var isBoundingBoxVisible = false
    let boundingBoxOffset = CGFloat(18.0)

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

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            isBoundingBoxVisible = !isBoundingBoxVisible
        }
    }

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

        let rect = CGRect(
            origin: CGPoint(x: 50, y: 50),
            size: CGSize(width: 20.0, height: 20.0)
        )

        boundingBox = UIView(frame: rect)
        boundingBox?.layer.borderColor = UIColor(red: 242/255, green: 233/255, blue: 225/255, alpha: 1).cgColor
        boundingBox?.layer.borderWidth = 2
        boundingBox?.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        boundingBox?.layer.shadowOpacity = 1
        boundingBox?.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        boundingBox?.layer.shadowRadius = 3
        boundingBox?.layer.cornerRadius = 6.0
        boundingBox?.alpha = 0.0

        view.addSubview(boundingBox!)
    }

    // MARK: - Image classification
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: VigetLogoDetector().model)
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
            var confidence = Float(0.0)
            let results = request.results

            if results == nil {
                NSLog("VNRequest failed")
                return
            }

            // TODO: Render multiple boxes instead of one?
            for observation in results! where observation is VNRecognizedObjectObservation {
                guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                }
                confidence = max(confidence, objectObservation.labels[0].confidence)

                UIView.animate(
                    withDuration: self.needleAnimationDuration,
                    delay: 0.0,
                    animations: {
                        let screenSize = UIScreen.main.bounds.size

                        let x = objectObservation.boundingBox.midX * screenSize.width

                        // TODO: Why does this value need to be reversed?
                        let y = screenSize.height - (objectObservation.boundingBox.midY * screenSize.height)

                        let height = (objectObservation.boundingBox.height * screenSize.height) + (self.boundingBoxOffset * 2)
                        let width = (objectObservation.boundingBox.width * screenSize.width) + (self.boundingBoxOffset * 2)

                        self.boundingBox!.frame = CGRect(
                            origin: CGPoint(
                                // TODO: Why does the offset need to be added here in order to make the box position realistic?
                                x: x - (width / 2) + self.boundingBoxOffset,
                                y: y - (height / 2) + self.boundingBoxOffset
                            ),
                            size: CGSize(width: width, height: height)
                        )
                    }
                )
            }

            let isGoodMatch = confidence > 0.85

            UIView.animate(
                withDuration: self.needleAnimationDuration,
                delay: 0.0,
                animations: {
                    self.needle.transform = CGAffineTransform(rotationAngle: self.getNeedleRadiansForConfidence(confidence))
                    self.needleShadow.transform = CGAffineTransform(rotationAngle: self.getNeedleRadiansForConfidence(confidence))
                    self.labelsMatchIndicator.alpha = isGoodMatch ? 1 : 0
                    self.boundingBox?.alpha = (isGoodMatch && self.isBoundingBoxVisible) ? 1 : 0
                }
            )
        }
    }

    @objc func captureImage(saveImage: Bool = false) {
        cameraController.captureImage {(image, error) in
            guard let image = image else {
                // Will throw "operation couldn't be completed" when closing/reopening app sometimes
                // (and on simulators)
                // but this error can be ignored.
                return
            }

            if saveImage {
                try? PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            } else {
                self.updateClassifications(for: image)
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
