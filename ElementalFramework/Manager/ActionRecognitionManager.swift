//
//  ActionRecognitionManager.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import CoreML

class ActionRecognitionManager: ObservableObject {
    @Published var currentElement: Element?
    
    private var model: AttackElement?
    private var actionHistory: [MLMultiArray] = []
    private let historyLength = 90
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            model = try AttackElement(configuration: MLModelConfiguration())
            print("Attack element action classification model loaded successfully")
        } catch {
            print("Failed to load CoreML model: \(error)")
        }
    }
    
    func processActionFrame(_ frame: MLMultiArray) {
        actionHistory.append(frame)
        
        if actionHistory.count > historyLength {
            actionHistory.removeFirst(actionHistory.count - historyLength)
        }
        
        if actionHistory.count == historyLength {
            do {
                let input = try combineActionFrames(actionHistory)
                makePrediction(input)
            } catch {
                print("Failed to combine action frames: \(error)")
            }
        }
    }
    
    private func combineActionFrames(_ frames: [MLMultiArray]) throws -> MLMultiArray {
        let shape: [NSNumber] = [90, 3, 18] // Assuming each frame is 3x18
        let combinedInput = try MLMultiArray(shape: shape, dataType: .float32)
        
        for (frameIndex, frame) in frames.enumerated() {
            for j in 0..<3 {
                for k in 0..<18 {
                    let sourceIndex = [0, j, k] as [NSNumber]
                    let targetIndex = [frameIndex, j, k] as [NSNumber]
                    combinedInput[targetIndex] = frame[sourceIndex]
                }
            }
        }
        
        return combinedInput
    }
    
    private func makePrediction(_ input: MLMultiArray) {
        guard let model = model else {
            print("Model not initialized")
            return
        }
        
        do {
            let prediction = try model.prediction(poses: input)
            handleClassification(label: prediction.label, confidence: prediction.labelProbabilities[prediction.label] ?? 0)
            print("Debug: Action prediction: \(prediction.label)")
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
        case "Api-Attack":
            newElement = Element(name: "Fire", emoji: "🔥", language: nil , invokeWords: nil)
        case "Angin-Attack":
            newElement = Element(name: "Wind", emoji: "💨", language:nil , invokeWords: nil)
        case "Air-Attack":
            newElement = Element(name: "Water", emoji: "🌊", language: nil, invokeWords: nil)
        case "Tanah-Attack":
            newElement = Element(name: "Rock", emoji: "🪨", language: nil, invokeWords: nil)
        default:
            newElement = nil
        }
        
        DispatchQueue.main.async {
            self.currentElement = newElement
        }
    }
    
    func reset() {
        currentElement = nil
        actionHistory.removeAll()
        print("Debug: AttackElementManager reset")
    }
}
