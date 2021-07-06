//
//  QKMRZScannerView.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 03/10/2018.
//

import UIKit
import AVFoundation
import SwiftyTesseract
import QKMRZParser
import AudioToolbox
import Vision

public protocol QKMRZScannerViewDelegate: AnyObject {
    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult)
    func rotateAnimationIdCard(isRotate: Bool)
}

public class QKMRZScannerView: UIView {
    fileprivate let tesseract = SwiftyTesseract(language: .custom("ocrb"), dataSource: Bundle(for: QKMRZScannerView.self), engineMode: .tesseractOnly)
    fileprivate let mrzParser = QKMRZParser(ocrCorrection: true)
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let videoOutput = AVCaptureVideoDataOutput()
    fileprivate let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate let cutoutView = QKCutoutView()
    fileprivate var isScanningPaused = false
    fileprivate var observer: NSKeyValueObservation?
    @objc public dynamic var isScanning = false
    public var vibrateOnResult = true
    public weak var delegate: QKMRZScannerViewDelegate?
    
    // my changed
    fileprivate var rotateDocumentImage: UIImage? = nil
    fileprivate let parentRect = UIScreen.main.bounds
    
    let cameraButton = UIButton()
    let showSaveImage = UIImageView()
    
    public var isScanPasssport: Bool = true
    
    private var drawings: [CAShapeLayer] = []
    
    public init(isScanPasssport: Bool) {
        super.init(frame: CGRect())
        
        self.isScanPasssport = isScanPasssport
        initialize()
    }
    
    public var cutoutRect: CGRect {
        return cutoutView.cutoutRect
    }
    
    fileprivate var interfaceOrientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
    // MARK: Initializers
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Overriden methods
    override public func prepareForInterfaceBuilder() {
        setViewStyle()
        addCutoutView()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        adjustVideoPreviewLayerFrame()
    }
    
    // MARK: Scanning
    public func startScanning() {
        guard !captureSession.inputs.isEmpty else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async { [weak self] in self?.adjustVideoPreviewLayerFrame() }
        }
    }
    
    public func stopScanning() {
        captureSession.stopRunning()
    }
    
    // MARK: MRZ
    fileprivate func mrz(from cgImage: CGImage) -> QKMRZResult? {
        let mrzTextImage = UIImage(cgImage: preprocessImage(cgImage))
        let recognizedString = try? tesseract.performOCR(on: mrzTextImage).get()
        
        if let string = recognizedString, let mrzLines = mrzLines(from: string) {
            return mrzParser.parse(mrzLines: mrzLines)
        }
        
        return nil
    }
    
    fileprivate func mrzLines(from recognizedText: String) -> [String]? {
        let mrzString = recognizedText.replacingOccurrences(of: " ", with: "")
        var mrzLines = mrzString.components(separatedBy: "\n").filter({ !$0.isEmpty })
        
        // Remove garbage strings located at the beginning and at the end of the result
        if !mrzLines.isEmpty {
            let averageLineLength = (mrzLines.reduce(0, { $0 + $1.count }) / mrzLines.count)
            mrzLines = mrzLines.filter({ $0.count >= averageLineLength })
        }
        
        return mrzLines.isEmpty ? nil : mrzLines
    }
    
    // MARK: Document Image from Photo cropping
    fileprivate func cutoutRect(for cgImage: CGImage) -> CGRect {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let rect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: cutoutRect)
        let videoOrientation = videoPreviewLayer.connection!.videoOrientation
        
        if videoOrientation == .portrait || videoOrientation == .portraitUpsideDown {
            return CGRect(x: (rect.minY * imageWidth), y: (rect.minX * imageHeight), width: (rect.height * imageWidth), height: (rect.width * imageHeight))
        }
        else {
            return CGRect(x: (rect.minX * imageWidth), y: (rect.minY * imageHeight), width: (rect.width * imageWidth), height: (rect.height * imageHeight))
        }
    }
    
    fileprivate func documentImage(from cgImage: CGImage) -> CGImage {
        let croppingRect = cutoutRect(for: cgImage)
        return cgImage.cropping(to: croppingRect) ?? cgImage
    }
    
    fileprivate func enlargedDocumentImage(from cgImage: CGImage) -> UIImage {
        var croppingRect = cutoutRect(for: cgImage)
        let margin = (0.05 * croppingRect.height) // 5% of the height
        croppingRect = CGRect(x: (croppingRect.minX - margin), y: (croppingRect.minY - margin), width: croppingRect.width + (margin * 2), height: croppingRect.height + (margin * 2))
        return UIImage(cgImage: cgImage.cropping(to: croppingRect)!)
    }
    
    // MARK: UIApplication Observers
    @objc fileprivate func appWillEnterForeground() {
        if isScanningPaused {
            isScanningPaused = false
            startScanning()
        }
    }
    
    @objc fileprivate func appDidEnterBackground() {
        if isScanning {
            isScanningPaused = true
            stopScanning()
        }
    }
    
    // MARK: Init methods
    fileprivate func initialize() {
        FilterVendor.registerFilters()
        setViewStyle()
        addCutoutView()
        initCaptureSession()
        addAppObservers()
    }
    
    fileprivate func setViewStyle() {
        backgroundColor = .black
    }
    
    fileprivate func addCutoutView() {
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        cutoutView.isScanPasssport = self.isScanPasssport
        addSubview(cutoutView)
        
        NSLayoutConstraint.activate([
            cutoutView.topAnchor.constraint(equalTo: topAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cutoutView.leftAnchor.constraint(equalTo: leftAnchor),
            cutoutView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        //my changed
        let passportLineView = CAShapeLayer()
        self.layer.addSublayer(passportLineView)
        passportLineView.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        passportLineView.lineDashPattern = [8, 5]
        passportLineView.fillColor = nil
        passportLineView.frame = self.bounds
        passportLineView.isHidden = !self.isScanPasssport
        passportLineView.path = UIBezierPath(rect: CGRect.init(
                                                x: (UIScreen.main.bounds.width - (UIScreen.main.bounds.width * 0.9)) / 2,
                                                y: UIScreen.main.bounds.height / 2 - 0.5,
                                                width: UIScreen.main.bounds.width * 0.9, height: 1)).cgPath
        
        let cameraSize: CGFloat = 60
        self.addSubview(cameraButton)
        cameraButton.setImage(UIImage.init(named: "save_camera"), for: .normal)
        cameraButton.setTitleColor(UIColor.white, for: .normal)
        cameraButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        cameraButton.layer.cornerRadius = cameraSize / 2
        cameraButton.isHidden = self.isScanPasssport
        cameraButton.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(savePhoto)))
        cameraButton.frame = CGRect.init(x: (parentRect.width / 2 - (cameraSize / 2)),
                                         y: (parentRect.height - getBottomMargin() - cameraSize - 20),
                                         width: cameraSize, height: cameraSize)
        
        let imageHeight: CGFloat = 150
        let imageWidth: CGFloat = 100
        self.addSubview(showSaveImage)
        showSaveImage.image = UIImage.init(named: "")
        showSaveImage.contentMode = .scaleAspectFit
        showSaveImage.layer.cornerRadius = 8
        showSaveImage.frame = CGRect.init(x: (parentRect.width - imageWidth - 30),
                                          y: (parentRect.height - getBottomMargin() - imageHeight - 20),
                                          width: imageWidth, height: imageHeight)
        
    }
    
    fileprivate func initCaptureSession() {
        captureSession.sessionPreset = .hd1920x1080
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Camera not accessible")
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: camera) else {
            print("Capture input could not be initialized")
            return
        }
        
        observer = captureSession.observe(\.isRunning, options: [.new]) { [unowned self] (model, change) in
            // CaptureSession is started from the global queue (background). Change the `isScanning` on the main
            // queue to avoid triggering the change handler also from the global queue as it may affect the UI.
            DispatchQueue.main.async { [weak self] in self?.isScanning = change.newValue! }
        }
        
        if captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(videoOutput) {
            captureSession.addInput(deviceInput)
            captureSession.addOutput(videoOutput)
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
            videoOutput.connection(with: .video)!.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            layer.insertSublayer(videoPreviewLayer, at: 0)
        }
        else {
            print("Input & Output could not be added to the session")
        }
        
    }
    
    fileprivate func addAppObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: Misc
    fileprivate func adjustVideoPreviewLayerFrame() {
        videoOutput.connection(with: .video)?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.frame = bounds
    }
    
    fileprivate func preprocessImage(_ image: CGImage) -> CGImage {
        var inputImage = CIImage(cgImage: image)
        let averageLuminance = inputImage.averageLuminance
        var exposure = 0.5
        let threshold = (1 - pow(1 - averageLuminance, 0.2))
        
        if averageLuminance > 0.8 {
            exposure -= ((averageLuminance - 0.5) * 2)
        }
        
        if averageLuminance < 0.35 {
            exposure += pow(2, (0.5 - averageLuminance))
        }
        
        inputImage = inputImage.applyingFilter("CIExposureAdjust", parameters: ["inputEV": exposure])
                               .applyingFilter("CILanczosScaleTransform", parameters: [kCIInputScaleKey: 2])
                               .applyingFilter("LuminanceThresholdFilter", parameters: ["inputThreshold": threshold])
        
        return CIContext.shared.createCGImage(inputImage, from: inputImage.extent)!
    }
    
    
    //my changed
    var isSaveImage = false
    @objc func savePhoto() {
        isSaveImage = true
    }
    
    //face detection
    func detectFace(in image: CVImageBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
                } else {
                    self.clearDrawings()
                }
            }
        })
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    var isFaceDetect = false
    func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
            let faceBoundingBoxOnScreen = self.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            return faceBoundingBoxShape
        })
        
        if facesBoundingBoxes.count < 1 {
            cutoutView.deActiveFaceView()
            isFaceDetect = false
        }
        
        facesBoundingBoxes.forEach({ faceBoundingBox in
            let faceX = faceBoundingBox.path?.boundingBoxOfPath.origin.x ?? 0
            let faceY = faceBoundingBox.path?.boundingBoxOfPath.origin.y ?? 0
            let faceHeight = faceBoundingBox.path?.boundingBoxOfPath.height ?? 0
            let faceWigth = faceBoundingBox.path?.boundingBoxOfPath.width ?? 0
            
            self.layer.addSublayer(faceBoundingBox)
            
            let limitX = cutoutRect.origin.x
            let limitY = cutoutRect.origin.y
            let limitHeight = cutoutRect.height
            let limitWidth = cutoutRect.width
            
            if (faceX > (limitX + (20)) && faceY > (limitY + (limitHeight / 3)) &&
                    ((faceX - limitX) + faceWigth) < (limitWidth / 3 + 20) &&
                    ((faceY - limitY) + faceHeight) < (limitHeight / 2 + 50)) {
                
                cutoutView.activeFaceView()
                isFaceDetect = true
            }else {
                cutoutView.deActiveFaceView()
                isFaceDetect = false
            }
            
            if self.isFaceDetect {
                cameraButton.isEnabled = true
            }else {
                cameraButton.isEnabled = false
            }
        })
        self.drawings = facesBoundingBoxes
    }
    
    func clearDrawings() {
        cutoutView.deActiveFaceView()
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension QKMRZScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if !isScanPasssport {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
            
            detectFace(in: imageBuffer)
        }
        
        guard let cgImage = CMSampleBufferGetImageBuffer(sampleBuffer)?.cgImage else {
            return
        }
        
        if isSaveImage {
            isSaveImage = false
            let enlargedDocumentImage = self.enlargedDocumentImage(from: cgImage)
            DispatchQueue.main.async {
                self.showSaveImage.image = enlargedDocumentImage
                self.rotateDocumentImage = enlargedDocumentImage
                self.delegate?.rotateAnimationIdCard(isRotate: true)
            }
        }
        
        
        let documentImage = self.documentImage(from: cgImage)
        let imageRequestHandler = VNImageRequestHandler(cgImage: documentImage, options: [:])
        
        let detectTextRectangles = VNDetectTextRectanglesRequest { [unowned self] request, error in
            guard error == nil else {
                return
            }
            
            guard let results = request.results as? [VNTextObservation] else {
                return
            }
            
            let imageWidth = CGFloat(documentImage.width)
            let imageHeight = CGFloat(documentImage.height)
            let transform = CGAffineTransform.identity.scaledBy(x: imageWidth, y: -imageHeight).translatedBy(x: 0, y: -1)
            let mrzTextRectangles = results.map({ $0.boundingBox.applying(transform) }).filter({ $0.width > (imageWidth * 0.8) })
            let mrzRegionRect = mrzTextRectangles.reduce(into: CGRect.null, { $0 = $0.union($1) })
            
            guard mrzRegionRect.height <= (imageHeight * 0.4) else { // Avoid processing the full image (can occur if there is a long text in the header)
                return
            }
            
            if let mrzTextImage = documentImage.cropping(to: mrzRegionRect) {
                if let mrzResult = self.mrz(from: mrzTextImage), mrzResult.allCheckDigitsValid {
                    self.stopScanning()
                    
                    DispatchQueue.main.async {
                        let enlargedDocumentImage = self.enlargedDocumentImage(from: cgImage)
                        var scanResult: QKMRZScanResult!
                        if isScanPasssport {
                            scanResult = QKMRZScanResult(mrzResult: mrzResult, documentImage: enlargedDocumentImage)
                        }else {
                            scanResult = QKMRZScanResult(mrzResult: mrzResult, documentImage: enlargedDocumentImage, rotateDocumentImage: self.rotateDocumentImage)
                        }
                        self.delegate?.mrzScannerView(self, didFind: scanResult)
                        if self.vibrateOnResult {
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                        }
                    }
                }
            }
        }
        
        try? imageRequestHandler.perform([detectTextRectangles])
    }
}
