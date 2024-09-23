//
//  SpeechManager.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation
import Speech
import AVFoundation

class SpeechManager: NSObject, SFSpeechRecognizerDelegate {
    var onTranscript: ((String) -> Void)?
    var onElementRecognized: ((Element) -> Void)?
    var onError: ((Error) -> Void)?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var currentElement: Element?
    private var isListening = false
    
    override init() {
        super.init()
    }
    
    func setCurrentElement(_ element: Element) {
        currentElement = element
        setupSpeechRecognizer(for: element.language!)
        print("Debug: Current element set to \(element.name), language: \(element.language!)")
    }
    
    private func setupSpeechRecognizer(for language: String) {
        let locale: Locale
        switch language {
        case "Arabic":
            locale = Locale(identifier: "ar-SA")
        case "Italia":
            locale = Locale(identifier: "it-IT")
        case "Japanese":
            locale = Locale(identifier: "ja-JP")
        case "German":
            locale = Locale(identifier: "de-DE")
        default:
            locale = Locale(identifier: "en-US")
        }
        
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.delegate = self
        
        if let recognizer = speechRecognizer, recognizer.isAvailable {
            print("Debug: Speech recognizer set up successfully for locale: \(locale.identifier)")
        } else {
            print("Error: Speech recognizer is not available for locale: \(locale.identifier)")
            onError?(NSError(domain: "SpeechRecognition", code: 6, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available for the selected language"]))
        }
    }
    
    func startAudioTranscription() {
        guard currentElement != nil else {
            onError?(NSError(domain: "SpeechRecognition", code: 5, userInfo: [NSLocalizedDescriptionKey: "No element selected"]))
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError?(NSError(domain: "SpeechRecognition", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
            return
        }
        
        if isListening {
            print("Debug: Already listening, ignoring start request")
            return
        }
        
        requestAuthorization { [weak self] in
            self?.setupAudioSession()
            self?.startRecognition()
        }
    }
    
    func stopAudioTranscription() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
        print("Debug: Stopped audio transcription")
    }
    
    private func requestAuthorization(completion: @escaping () -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Debug: Speech recognition authorized")
                    completion()
                } else {
                    print("Error: Speech recognition authorization denied")
                    self.onError?(NSError(domain: "SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"]))
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Debug: Audio session set up successfully")
        } catch {
            print("Error setting up audio session: \(error)")
            onError?(error)
        }
    }
    
    private func startRecognition() {
        guard let speechRecognizer = speechRecognizer else {
            print("Error: Speech recognizer not set up")
            onError?(NSError(domain: "SpeechRecognition", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not set up"]))
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Error: Unable to create recognition request")
            onError?(NSError(domain: "SpeechRecognition", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"]))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine?.inputNode
        guard let recordingFormat = inputNode?.outputFormat(forBus: 0) else {
            print("Error: Unable to get recording format")
            onError?(NSError(domain: "SpeechRecognition", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to get recording format"]))
            return
        }
        
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            try audioEngine?.start()
            print("Debug: Audio engine started")
        } catch {
            print("Error starting audio engine: \(error)")
            onError?(error)
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error in recognition task: \(error)")
                self.onError?(error)
                return
            }
            
            if let result = result {
                let transcribedString = result.bestTranscription.formattedString.lowercased()
                print("Debug: Transcribed text: \(transcribedString)")
                self.onTranscript?(transcribedString)
                self.checkForElement(in: transcribedString)
            }
        }
        
        isListening = true
        print("Debug: Started continuous listening")
    }
    
    private func checkForElement(in transcription: String) {
        guard let currentElement = currentElement else { return }
        
        if currentElement.invokeWords!.contains(where: transcription.contains) {
            print("Debug: Recognized element: \(currentElement.name)")
            onElementRecognized?(currentElement)
        }
    }
    
    func reset() {
        currentElement = nil
        stopAudioTranscription()
        print("Debug: SpeechManager reset")
    }
}

