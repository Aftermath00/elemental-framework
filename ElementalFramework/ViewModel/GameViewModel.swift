//
//  GameViewModel.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation
import Combine

enum GameState {
    case defense
    case attack
}

class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .defense
    
    let defenseViewModel: DefenseViewModel
    let attackViewModel: AttackViewModel
    private var cameraManager: CameraManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.defenseViewModel = DefenseViewModel()
        self.attackViewModel = AttackViewModel()
        self.cameraManager = CameraManager()
        setupCamera()
    }
    
    private func setupCamera() {
        cameraManager.startCapture { [weak self] pixelBuffer in
            switch self?.gameState {
            case .defense:
                self?.defenseViewModel.processFrame(pixelBuffer)
            case .attack:
                self?.attackViewModel.processFrame(pixelBuffer)
            case .none:
                break
            }
        }
        
        cameraManager.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                switch self?.gameState {
                case .defense:
                    self?.defenseViewModel.errorMessage = error.localizedDescription
                case .attack:
                    self?.attackViewModel.errorMessage = error.localizedDescription
                case .none:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func switchToDefense() {
        gameState = .defense
        defenseViewModel.reset()
    }
    
    func switchToAttack() {
        gameState = .attack
        attackViewModel.reset()
    }
    
    func startCamera() {
        cameraManager.startCapture { [weak self] pixelBuffer in
            switch self?.gameState {
            case .defense:
                self?.defenseViewModel.processFrame(pixelBuffer)
            case .attack:
                self?.attackViewModel.processFrame(pixelBuffer)
            case .none:
                break
            }
        }
    }
    
    func stopCamera() {
        cameraManager.stopCapture()
    }
}
