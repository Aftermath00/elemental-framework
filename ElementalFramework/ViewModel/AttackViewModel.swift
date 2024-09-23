//
//  AttackViewModel.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation
import Vision
import Combine
import CoreImage

class AttackViewModel: ObservableObject {
    @Published var recognizedElement: Element?
    @Published var errorMessage: String?
    @Published var currentElement: Element?
    
    private var actionRecognitionManager: ActionRecognitionManager
    private var cancellables = Set<AnyCancellable>()
    private var actionRequest: VNDetectHumanBodyPoseRequest?
    private var recognitionTimer: Timer?
    
    init() {
        self.actionRecognitionManager = ActionRecognitionManager()
        setupManagers()
        setupActionDetection()
    }
    
    private func setupManagers() {
        actionRecognitionManager.$currentElement
            .sink { [weak self] element in
                DispatchQueue.main.async {
                    self?.handleRecognition(element)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupActionDetection() {
        actionRequest = VNDetectHumanBodyPoseRequest()
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let request = actionRequest else { return }
        
        let handler = VNImageRequestHandler(ciImage: CIImage(cvPixelBuffer: pixelBuffer), orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNHumanBodyPoseObservation else { return }
            try processActionObservation(observation)
        } catch {
            print("Failed to perform action detection: \(error)")
        }
    }
    
    private func processActionObservation(_ observation: VNHumanBodyPoseObservation) throws {
        let keypointsMultiArray = try observation.keypointsMultiArray()
        actionRecognitionManager.processActionFrame(keypointsMultiArray)
    }
    
    private func handleRecognition(_ element: Element?) {
        currentElement = element
        recognizedElement = element
        if element != nil {
            pauseRecognition()
        }
    }
    
    private func pauseRecognition() {
        recognitionTimer?.invalidate()
        recognitionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.reset()
        }
    }
    
    func reset() {
        currentElement = nil
        recognizedElement = nil
        actionRecognitionManager.reset()
    }
}
