//
//  CameraManager.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var error: Error?
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    let previewView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var frameProcessor: ((CVPixelBuffer) -> Void)?
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            error = NSError(domain: "CameraManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to set up video input"])
            return
        }
        
        captureSession.addInput(videoDeviceInput)
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        guard captureSession.canAddOutput(videoDataOutput) else {
            error = NSError(domain: "CameraManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to set up video output"])
            return
        }
        captureSession.addOutput(videoDataOutput)
        
        // Set the video orientation to portrait
        if let connection = videoDataOutput.connection(with: .video) {
            setPortraitOrientation(for: connection)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        if let connection = previewLayer.connection {
            setPortraitOrientation(for: connection)
        }
        previewView.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        captureSession.commitConfiguration()
    }
    
    private func setPortraitOrientation(for connection: AVCaptureConnection) {
        if #available(iOS 17.0, *) {
            connection.videoRotationAngle = 90.0 // 90 degrees for portrait
        } else {
            connection.videoOrientation = .portrait
        }
    }
    
    func startCapture(withFrameProcessor processor: @escaping (CVPixelBuffer) -> Void) {
        self.frameProcessor = processor
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopCapture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        self.frameProcessor = nil
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Ensure the connection's video orientation is set to portrait
        setPortraitOrientation(for: connection)
        
        frameProcessor?(pixelBuffer)
    }
}
