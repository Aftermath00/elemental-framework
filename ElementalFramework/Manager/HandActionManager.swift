//
//  HandActionManager.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import CoreML

class HandActionRecognitionManager: ObservableObject {
    @Published var currentElement: Element?
    
    private var model: DefenseElement?
    private var handPoseHistory: [MLMultiArray] = []
    private let historyLength = 90
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            model = try DefenseElement(configuration: MLModelConfiguration())
            print("Hand action recognition model loaded successfully")
        } catch {
            print("Failed to load CoreML model: \(error)")
        }
    }
    
    func processHandLandmarks(_ landmarks: MLMultiArray) {
        handPoseHistory.append(landmarks)
        
        if handPoseHistory.count > historyLength {
            handPoseHistory.removeFirst(handPoseHistory.count - historyLength)
        }
        
        if handPoseHistory.count == historyLength {
            do {
                let input = try transformInput(handPoseHistory)
                makePrediction(input)
            } catch {
                print("Failed to transform input: \(error)")
            }
        }
    }
    
    private func transformInput(_ history: [MLMultiArray]) throws -> MLMultiArray {
        let shape: [NSNumber] = [90, 3, 21]
        let transformedInput = try MLMultiArray(shape: shape, dataType: .double)
        
        for frameIndex in 0..<90 {
            let frame = history[frameIndex]
            for j in 0..<3 {
                for k in 0..<21 {
                    let sourceIndex = [0, j, k] as [NSNumber]
                    let targetIndex = [frameIndex, j, k] as [NSNumber]
                    transformedInput[targetIndex] = frame[sourceIndex]
                }
            }
        }
        
        return transformedInput
    }
    
    private func makePrediction(_ input: MLMultiArray) {
        guard let model = model else {
            print("Model not initialized")
            return
        }
        
        do {
            let prediction = try model.prediction(poses: input)
            handleClassification(label: prediction.label, confidence: prediction.labelProbabilities[prediction.label] ?? 0)
            print("Debug: Prediction live: \(prediction.label)")
        } catch {
            print("Failed to make prediction: \(error)")
        }
    }
    
    private func handleClassification(label: String, confidence: Double) {
        guard confidence > 0.7 else {
            currentElement = nil
            return
        }
        
        let newElement: Element?
        switch label {
        case "Api-Defense":
            newElement = Element(name: "Fire", emoji: "🔥", language: "Arabic", invokeWords: ["لهب النار"])
        case "Angin-Defense":
            newElement = Element(name: "Wind", emoji: "💨", language: "Italia", invokeWords: ["vento rapido"])
        case "Air-Defense":
            newElement = Element(name: "Water", emoji: "🌊", language: "Japanese", invokeWords: ["水の守り"])
        case "Tanah-Defense":
            newElement = Element(name: "Rock", emoji: "🪨", language: "German", invokeWords: ["felsen kraft"])
        default:
            newElement = nil
        }
        
        DispatchQueue.main.async {
            self.currentElement = newElement
        }
    }
    
    func reset() {
        currentElement = nil
        handPoseHistory.removeAll()
        print("Debug: HandActionRecognitionManager reset")
    }
}
