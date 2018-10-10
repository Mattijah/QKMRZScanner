//
//  QKMRZScannerView.swift
//  QKMRZScanner
//
//  Created by S on 03/10/2018.
//

import UIKit
import AVFoundation

@IBDesignable
class QKMRZScannerView: UIView {
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate let cutoutView = QKCutoutView()
    fileprivate var observer: NSKeyValueObservation?
    @objc dynamic var isScanning = false
    
    fileprivate var interfaceOrientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
        addCutoutView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCaptureSession()
        addCutoutView()
    }
    
    // MARK: Overriden methods
    override func prepareForInterfaceBuilder() {
        addCutoutView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustVideoPreviewLayerFrame()
    }
    
    // MARK: AVCaptureSession
    fileprivate func setupCaptureSession() {
        observer = captureSession.observe(\.isRunning, options: [.new]) { [unowned self] (model, change) in
            change.newValue! ? self.startScanning() : self.stopScanning()
        }
        
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Camera not accessible")
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: camera) else {
            print("Capture input could not be initialized")
            return
        }
        
        if captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(deviceInput)
            captureSession.addOutput(photoOutput)
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            layer.insertSublayer(videoPreviewLayer, at: 0)
            startCaptureSession()
        }
        else {
            print("Input & Output could not be added to the session")
        }
    }
    
    fileprivate func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.adjustVideoPreviewLayerFrame() }
        }
    }
    
    // MARK: Scanning
    fileprivate func startScanning() {
        isScanning = true
        capturePhoto()
    }
    
    fileprivate func stopScanning() {
        isScanning = false
    }
    
    fileprivate func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        photoOutput.connection(with: .video)!.videoOrientation = videoPreviewLayer.connection!.videoOrientation
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: Misc
    fileprivate func adjustVideoPreviewLayerFrame() {
        videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.frame = bounds
    }
    
    fileprivate func cropCapturedPhotoToCutout(_ image: UIImage) -> UIImage {
        let cgImage = image.cgImage!
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let rect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: cutoutView.cutoutRect)
        let croppingRect = CGRect(x: (rect.minX * imageWidth), y: (rect.minY * imageHeight), width: (rect.width * imageWidth), height: (rect.height * imageHeight))
        return UIImage(cgImage: cgImage.cropping(to: croppingRect)!, scale: 1, orientation: image.imageOrientation)
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
}

// MARK: - AVCapturePhotoCaptureDelegate
extension QKMRZScannerView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil, let photoSampleBuffer = photoSampleBuffer else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)!
        let image = cropCapturedPhotoToCutout(UIImage(data: imageData)!)
        
        // TODO: Process the captured image
    }
}
