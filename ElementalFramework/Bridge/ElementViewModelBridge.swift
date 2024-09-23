//
//  ElementViewModelBridge.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation

@objc public class ElementViewModelBridge: NSObject {
    @objc public static let shared = ElementViewModelBridge()
    
    private let gameViewModel = GameViewModel()
    
    private override init() {
        super.init()
    }
    
    @objc public func switchToDefense() {
        gameViewModel.switchToDefense()
    }
    
    @objc public func switchToAttack() {
        gameViewModel.switchToAttack()
    }
    
    @objc public func startListening() {
        if gameViewModel.gameState == .defense {
            gameViewModel.defenseViewModel.startListening()
        }
    }
    
    @objc public func stopListening() {
        if gameViewModel.gameState == .defense {
            gameViewModel.defenseViewModel.stopListening()
        }
    }
    
    @objc public func getRecognizedText() -> String {
        return gameViewModel.gameState == .defense ? gameViewModel.defenseViewModel.recognizedText : ""
    }
    
    @objc public func getIsListening() -> Bool {
        return gameViewModel.gameState == .defense ? gameViewModel.defenseViewModel.isListening : false
    }
    
    @objc public func getErrorMessages() -> String {
        switch gameViewModel.gameState {
        case .defense:
            return gameViewModel.defenseViewModel.errorMessage ?? ""
        case .attack:
            return gameViewModel.attackViewModel.errorMessage ?? ""
        }
    }
    
    @objc public func startCamera() {
        gameViewModel.startCamera()
    }
    
    @objc public func stopCamera() {
        gameViewModel.stopCamera()
    }
    
    @objc public func getCurrentElementName() -> String {
        switch gameViewModel.gameState {
        case .defense:
            return gameViewModel.defenseViewModel.currentElement?.name ?? ""
        case .attack:
            return gameViewModel.attackViewModel.currentElement?.name ?? ""
        }
    }
    
    @objc public func getRecognizedElementName() -> String {
        switch gameViewModel.gameState {
        case .defense:
            return gameViewModel.defenseViewModel.recognizedElement?.name ?? ""
        case .attack:
            return gameViewModel.attackViewModel.recognizedElement?.name ?? ""
        }
    }
}


@_cdecl("InitializeElementViewModel")
public func InitializeElementViewModel() {
    _ = ElementViewModelBridge.shared
}

@_cdecl("SwitchToDefense")
public func SwitchToDefense() {
    ElementViewModelBridge.shared.switchToDefense()
}

@_cdecl("SwitchToAttack")
public func SwitchToAttack() {
    ElementViewModelBridge.shared.switchToAttack()
}

@_cdecl("StartListening")
public func StartListening() {
    ElementViewModelBridge.shared.startListening()
}

@_cdecl("StopListening")
public func StopListening() {
    ElementViewModelBridge.shared.stopListening()
}

@_cdecl("GetRecognizedTextNative")
public func GetRecognizedTextNative() -> UnsafePointer<CChar>? {
    let text = ElementViewModelBridge.shared.getRecognizedText()
    return text.withCString { strptr in
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: text.utf8.count + 1)
        ptr.initialize(from: strptr, count: text.utf8.count + 1)
        return UnsafePointer(ptr)
    }
}

@_cdecl("GetIsListening")
public func GetIsListening() -> Bool {
    return ElementViewModelBridge.shared.getIsListening()
}

@_cdecl("GetErrorMessagesNative")
public func GetErrorMessages() -> UnsafePointer<CChar>? {
    let error = ElementViewModelBridge.shared.getErrorMessages()
    return error.withCString { strptr in
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: error.utf8.count + 1)
        ptr.initialize(from: strptr, count: error.utf8.count + 1)
        return UnsafePointer(ptr)
    }
}

@_cdecl("StartCamera")
public func StartCamera() {
    ElementViewModelBridge.shared.startCamera()
}

@_cdecl("StopCamera")
public func StopCamera() {
    ElementViewModelBridge.shared.stopCamera()
}

@_cdecl("GetCurrentElementName")
public func GetCurrentElementName() -> UnsafePointer<CChar>? {
    let name = ElementViewModelBridge.shared.getCurrentElementName()
    return name.withCString { strptr in
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: name.utf8.count + 1)
        ptr.initialize(from: strptr, count: name.utf8.count + 1)
        return UnsafePointer(ptr)
    }
}

@_cdecl("GetRecognizedElementName")
public func GetRecognizedElementName() -> UnsafePointer<CChar>? {
    let name = ElementViewModelBridge.shared.getRecognizedElementName()
    return name.withCString { strptr in
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: name.utf8.count + 1)
        ptr.initialize(from: strptr, count: name.utf8.count + 1)
        return UnsafePointer(ptr)
    }
}

@_cdecl("FreeString")
public func FreeString(_ ptr: UnsafeMutablePointer<CChar>?) {
    if let ptr = ptr {
        ptr.deallocate()
    }
}
