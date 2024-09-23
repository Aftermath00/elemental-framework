//
//  DefenseViewModel.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation
import Vision
import Combine
import CoreImage

class DefenseViewModel: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isListening: Bool = false
    @Published var recognizedElement: Element?
    @Published var errorMessage: String?
    @Published var currentElement: Element?
    
    private var speechManager: SpeechManager
    private var handActionManager: HandActionRecognitionManager
    private var cancellables = Set<AnyCancellable>()
    private var handPoseRequest: VNDetectHumanHandPoseRequest?
    
    init() {
        self.speechManager = SpeechManager()
        self.handActionManager = HandActionRecognitionManager()
        setupManagers()
        setupHandPoseDetection()
    }
    
    private func setupManagers() {
        speechManager.onTranscript = { [weak self] transcript in
            DispatchQueue.main.async {
                self?.recognizedText = transcript
            }
        }
        
        speechManager.onElementRecognized = { [weak self] element in
            DispatchQueue.main.async {
                self?.recognizedElement = element
                self?.scheduleReset()
            }
        }
        
        speechManager.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.localizedDescription
                self?.isListening = false
            }
        }
        
        handActionManager.$currentElement
            .sink { [weak self] element in
                DispatchQueue.main.async {
                    if let element = element {
                        self?.currentElement = element
                        self?.speechManager.setCurrentElement(element)
                        self?.startListening()
                    } else {
                        self?.stopListening()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupHandPoseDetection() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest?.maximumHandCount = 1
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let request = handPoseRequest else { return }
        
        let handler = VNImageRequestHandler(ciImage: CIImage(cvPixelBuffer: pixelBuffer), orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNHumanHandPoseObservation else { return }
            try processHandPoseObservation(observation)
        } catch {
            print("Failed to perform hand pose detection: \(error)")
        }
    }
    
    private func processHandPoseObservation(_ observation: VNHumanHandPoseObservation) throws {
        let keypointsMultiArray = try observation.keypointsMultiArray()
        handActionManager.processHandLandmarks(keypointsMultiArray)
    }
    
    func startListening() {
        speechManager.startAudioTranscription()
        isListening = true
        errorMessage = nil
        recognizedText = ""
    }
    
    func stopListening() {
        speechManager.stopAudioTranscription()
        isListening = false
    }
    
    private func scheduleReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.reset()
        }
    }
    
    func reset() {
        recognizedElement = nil
        recognizedText = ""
        currentElement = nil
        stopListening()
        handActionManager.reset()
        speechManager.reset()
    }
}
