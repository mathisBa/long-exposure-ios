import UIKit
import AVFoundation
import Photos

final class LongExposureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: - Camera
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Long exposure simulation
    private var isCapturing = false
    private var frameCount = 0
    private var accumulatorBuffer: [UInt8]?
    private var referenceBuffer: [UInt8]?
    private var lastFrameBuffer: [UInt8]?
    private var accumulatorWidth = 0
    private var accumulatorHeight = 0
    private let totalDuration: TimeInterval = 10.0
    private var countdownTimer: Timer?
    private var captureEndTime: Date?
    private let changeThreshold: Int = 120
    private let brightThreshold: UInt8 = 220
    private let logFormatter = ISO8601DateFormatter()
    private var captureOrientation: UIDeviceOrientation = .portrait

    // MARK: - Simple UI
    private let previewView = UIView()
    private let button = UIButton(type: .system)
    private let timerLabel = UILabel()
    private let resultImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupMinimalUI()
        checkPermissionsAndSetup()
    }

    private func setupMinimalUI() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        resultImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(previewView)
        view.addSubview(button)
        view.addSubview(timerLabel)
        previewView.addSubview(resultImageView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: 50),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            resultImageView.topAnchor.constraint(equalTo: previewView.topAnchor),
            resultImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            resultImageView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            resultImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor)
        ])

        button.setTitle("Prendre une photo", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(startCaptureTapped), for: .touchUpInside)

        timerLabel.textColor = .white
        timerLabel.font = .boldSystemFont(ofSize: 24)
        timerLabel.textAlignment = .center
        timerLabel.text = ""

        resultImageView.contentMode = .scaleAspectFill
        resultImageView.clipsToBounds = true
        resultImageView.isHidden = true
    }

    // MARK: - Permissions
    private func checkPermissionsAndSetup() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch videoStatus {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showToast("Active la caméra dans Réglages.")
                    }
                }
            }
        default:
            showToast("Active la caméra dans Réglages.")
        }
    }

    // MARK: - Camera
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showToast("Impossible d'ouvrir la caméra.")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)

        guard session.canAddOutput(videoOutput) else {
            showToast("Impossible d'ajouter la sortie vidéo.")
            session.commitConfiguration()
            return
        }
        session.addOutput(videoOutput)

        session.commitConfiguration()

        // Démarrage de la session sur une queue background
        queue.async {
            self.session.startRunning()
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = previewView.bounds
        previewView.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }

    // MARK: - Capture
    @objc private func startCaptureTapped() {
        var shouldStart = false
        queue.sync {
            if !isCapturing {
                isCapturing = true
                accumulatorBuffer = nil
                referenceBuffer = nil
                lastFrameBuffer = nil
                accumulatorWidth = 0
                accumulatorHeight = 0
                frameCount = 0
                shouldStart = true
            }
        }
        guard shouldStart else { return }
        logEvent("LongExposure: start capture")
        startCapture()
    }

    private func startCapture() {
        resultImageView.image = nil
        resultImageView.isHidden = true
        previewLayer?.isHidden = false
        captureOrientation = UIDevice.current.orientation
        captureEndTime = Date().addingTimeInterval(totalDuration)

        button.isEnabled = false
        button.alpha = 0.5

        countdownTimer?.invalidate()
        var remaining = Int(totalDuration)
        timerLabel.text = "\(remaining) s"
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            remaining -= 1
            self.timerLabel.text = remaining > 0 ? "\(remaining) s" : ""
            if remaining <= 0 {
                timer.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.logEvent("LongExposure: end capture timer")
            self?.finishCapture()
        }
    }

    private func finishCapture() {
        var bufferCopy: [UInt8]?
        var referenceCopy: [UInt8]?
        var lastFrameCopy: [UInt8]?
        var width = 0
        var height = 0
        captureEndTime = nil
        queue.sync {
            guard isCapturing else { return }
            self.logEvent("Fini fini")
            isCapturing = false
            bufferCopy = accumulatorBuffer
            referenceCopy = referenceBuffer
            lastFrameCopy = lastFrameBuffer
            width = accumulatorWidth
            height = accumulatorHeight
        }

        countdownTimer?.invalidate()
        countdownTimer = nil
        timerLabel.text = ""
        button.isEnabled = true
        button.alpha = 1.0

        queue.async { [weak self] in
            guard let self else { return }
            let image = self.buildImage(buffer: bufferCopy, width: width, height: height)
            let referenceImage = self.buildImage(buffer: referenceCopy, width: width, height: height)
            let lastFrameImage = self.buildImage(buffer: lastFrameCopy, width: width, height: height)
            self.logEvent("LongExposure: images built")
            DispatchQueue.main.async {
                self.handleFinishedImages(result: image, reference: referenceImage, lastFrame: lastFrameImage)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard isCapturing,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        if let endTime = captureEndTime, Date() >= endTime {
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }

        if accumulatorBuffer == nil || accumulatorWidth != width || accumulatorHeight != height {
            accumulatorWidth = width
            accumulatorHeight = height
            accumulatorBuffer = [UInt8](repeating: 0, count: width * height * 4)
            referenceBuffer = nil
            lastFrameBuffer = nil
        }

        guard accumulatorBuffer != nil else { return }
        let src = baseAddress.assumingMemoryBound(to: UInt8.self)

        if referenceBuffer == nil {
            var ref = [UInt8](repeating: 0, count: width * height * 4)
            ref.withUnsafeMutableBufferPointer { refBuffer in
                for y in 0..<height {
                    let row = src.advanced(by: y * bytesPerRow)
                    for x in 0..<width {
                        let srcOffset = x * 4
                        let refIndex = (y * width + x) * 4
                        refBuffer[refIndex] = row[srcOffset]
                        refBuffer[refIndex + 1] = row[srcOffset + 1]
                        refBuffer[refIndex + 2] = row[srcOffset + 2]
                        refBuffer[refIndex + 3] = row[srcOffset + 3]
                    }
                }
            }
            referenceBuffer = ref
            lastFrameBuffer = ref
            return
        }

        guard let referenceBuffer else { return }

        accumulatorBuffer!.withUnsafeMutableBufferPointer { accBuffer in
            for y in 0..<height {
                let row = src.advanced(by: y * bytesPerRow)
                for x in 0..<width {
                    let srcOffset = x * 4
                    let accIndex = (y * width + x) * 4
                    let b = row[srcOffset]
                    let g = row[srcOffset + 1]
                    let r = row[srcOffset + 2]
                    let maxChannel = max(b, max(g, r))
                    let refIndex = accIndex
                    let refB = referenceBuffer[refIndex]
                    let refG = referenceBuffer[refIndex + 1]
                    let refR = referenceBuffer[refIndex + 2]
                    if maxChannel >= brightThreshold &&
                        (abs(Int(b) - Int(refB)) >= changeThreshold ||
                        abs(Int(g) - Int(refG)) >= changeThreshold ||
                        abs(Int(r) - Int(refR)) >= changeThreshold) {
                        accBuffer[accIndex] = max(accBuffer[accIndex], b)
                        accBuffer[accIndex + 1] = max(accBuffer[accIndex + 1], g)
                        accBuffer[accIndex + 2] = max(accBuffer[accIndex + 2], r)
                    }
                }
            }
        }

        var last = [UInt8](repeating: 0, count: width * height * 4)
        last.withUnsafeMutableBufferPointer { lastBuffer in
            for y in 0..<height {
                let row = src.advanced(by: y * bytesPerRow)
                for x in 0..<width {
                    let srcOffset = x * 4
                    let idx = (y * width + x) * 4
                    lastBuffer[idx] = row[srcOffset]
                    lastBuffer[idx + 1] = row[srcOffset + 1]
                    lastBuffer[idx + 2] = row[srcOffset + 2]
                    lastBuffer[idx + 3] = row[srcOffset + 3]
                }
            }
        }
        lastFrameBuffer = last

        frameCount += 1
    }

    // MARK: - Save result
    private func buildImage(buffer: [UInt8]?, width: Int, height: Int) -> UIImage? {
        guard let accumulatorBuffer = buffer,
              width > 0,
              height > 0 else {
            return nil
        }

        let pixelCount = width * height
        var output = [UInt8](repeating: 0, count: pixelCount * 4)
        for i in 0..<pixelCount {
            let idx = i * 4
            output[idx] = accumulatorBuffer[idx]
            output[idx + 1] = accumulatorBuffer[idx + 1]
            output[idx + 2] = accumulatorBuffer[idx + 2]
            output[idx + 3] = 255
        }

        let data = Data(output) as CFData
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: data) else { return nil }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                .union(.byteOrder32Little),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }

        let orientation = imageOrientation(for: captureOrientation)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }

    private func handleFinishedImages(result: UIImage?, reference: UIImage?, lastFrame: UIImage?) {
        guard let result else {
            showToast("Aucune image capturée")
            return
        }

        resultImageView.image = result
        resultImageView.isHidden = false
        previewLayer?.isHidden = true

        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.showToast("Autorise l'accès Photos pour sauvegarder.")
                }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: result)
                if let reference {
                    PHAssetChangeRequest.creationRequestForAsset(from: reference)
                }
                if let lastFrame {
                    PHAssetChangeRequest.creationRequestForAsset(from: lastFrame)
                }
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.showToast("Photo combinée sauvegardée (\(self.frameCount) frames)")
                    } else {
                        self.showToast("Erreur sauvegarde : \(error?.localizedDescription ?? "inconnue")")
                    }
                }
            }
        }
    }

    // MARK: - UI helpers
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }

    private func logEvent(_ message: String) {
        let timestamp = logFormatter.string(from: Date())
        print("[\(timestamp)] \(message)")
    }

    private func imageOrientation(for deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
}
 
