//
//  QKMRZScannerView.swift
//  QKMRZScanner
//
//  Created by S on 03/10/2018.
//

import UIKit
import AVFoundation
import TesseractOCR
import QKMRZParser
import QKGPUImage2
import AudioToolbox

public protocol QKMRZScannerViewDelegate: class {
    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult)
}

@IBDesignable
public class QKMRZScannerView: UIView {
    fileprivate var tesseract: G8Tesseract!
    fileprivate let mrzParser = QKMRZParser(ocrCorrection: true)
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let videoOutput = AVCaptureVideoDataOutput()
    fileprivate let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate let ciContext = CIContext()
    fileprivate let cutoutView = QKCutoutView()
    fileprivate var isScanningPaused = false
    public weak var delegate: QKMRZScannerViewDelegate?
    
    public var isScanning: Bool {
        return captureSession.isRunning
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
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let mrzRegionHeight = (imageHeight * 0.25) // MRZ occupies roughly 25% of the document's height
        let padding = (0.04 * imageHeight) // Try to make the mrz image as small as possible
        let croppingRect = CGRect(origin: CGPoint(x: padding, y: (imageHeight - mrzRegionHeight)), size: CGSize(width: (imageWidth - padding * 2), height: (mrzRegionHeight - padding)))
        let mrzRegionImage = UIImage(cgImage: cgImage.cropping(to: croppingRect)!)
        
        tesseract.image = mrzRegionImage
        tesseract.recognize()
        
        if let mrzLines = mrzLines(from: tesseract.recognizedText) {
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
        let rect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: cutoutView.cutoutRect)
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
        setViewStyle()
        addCutoutView()
        initCaptureSession()
        initTesseract()
        addAppObservers()
    }
    
    fileprivate func setViewStyle() {
        backgroundColor = .black
    }
    
    fileprivate func addCutoutView() {
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cutoutView)
        
        NSLayoutConstraint.activate([
            cutoutView.topAnchor.constraint(equalTo: topAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cutoutView.leftAnchor.constraint(equalTo: leftAnchor),
            cutoutView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
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
        
        if captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(videoOutput) {
            captureSession.addInput(deviceInput)
            captureSession.addOutput(videoOutput)
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem))
            videoOutput.alwaysDiscardsLateVideoFrames = true
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
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    fileprivate func initTesseract() {
        let bundlePath = Bundle(for: type(of: self)).bundlePath
        let config = [
            kG8ParamLoadSystemDawg: "F",
            kG8ParamLoadFreqDawg: "F",
            kG8ParamLoadNumberDawg: "F",
            kG8ParamLoadPuncDawg: "F",
            kG8ParamLoadUnambigDawg: "F",
            kG8ParamLoadBigramDawg: "F",
            kG8ParamWordrecEnableAssoc: "F",
            kG8ParamTesseditCharWhitelist: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ<"
        ]
        
        tesseract = G8Tesseract(language: "ocrb", configDictionary: config, configFileNames: [], absoluteDataPath: bundlePath, engineMode: .tesseractOnly, copyFilesFromResources: false)!
        tesseract.pageSegmentationMode = .singleBlock
        tesseract.delegate = self
    }
    
    // MARK: Misc
    fileprivate func adjustVideoPreviewLayerFrame() {
        videoOutput.connection(with: .video)?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.frame = bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension QKMRZScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
        let documentImage = self.documentImage(from: cgImage)
        
        if let mrzResult = mrz(from: documentImage), mrzResult.allCheckDigitsValid {
            stopScanning()
            
            DispatchQueue.main.async {
                let enlargedDocumentImage = self.enlargedDocumentImage(from: cgImage)
                let scanResult = QKMRZScanResult(mrzResult: mrzResult, documentImage: enlargedDocumentImage)
                self.delegate?.mrzScannerView(self, didFind: scanResult)
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}

// MARK: - G8TesseractDelegate
extension QKMRZScannerView: G8TesseractDelegate {
    public func preprocessedImage(for tesseract: G8Tesseract, sourceImage: UIImage) -> UIImage {
        let averageColor = AverageColorExtractor()
        let exposure = ExposureAdjustment()
        let resampling = LanczosResampling()
        let adaptiveThreshold = AdaptiveThreshold()
        let sharpen = Sharpen()
        let blur = GaussianBlur()
        let scaledImageWidth = Float((sourceImage.size.width * sourceImage.scale) * 2)
        let imageSizeRatio = Float(sourceImage.size.height / sourceImage.size.width)
        
        resampling.overriddenOutputSize = Size(width: scaledImageWidth, height: (imageSizeRatio * scaledImageWidth))
        exposure.exposure = 0.5
        adaptiveThreshold.blurRadiusInPixels = 2
        sharpen.sharpness = 2
        blur.blurRadiusInPixels = 1
        
        averageColor.extractedColorCallback = { color in
            let lighting = (color.blueComponent + color.greenComponent + color.redComponent)
            
            if lighting < 2.75 {
                exposure.exposure += (2.80 - lighting) * 2
            }
            
            if lighting > 2.85 {
                exposure.exposure -= (lighting - 2.80) * 2
            }
            
            if exposure.exposure > 2 {
                exposure.exposure = 2
            }
            
            if exposure.exposure < -2 {
                exposure.exposure = -2
            }
        }
        
        let _ = sourceImage.filterWithPipeline({ $0 --> adaptiveThreshold --> averageColor --> $1 })
        
        return sourceImage.filterWithPipeline({ input, output in
            input --> exposure --> resampling --> adaptiveThreshold --> sharpen --> blur --> output
        })
    }
}
