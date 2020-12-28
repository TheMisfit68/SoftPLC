//
//  PlcBackgroundCycle.swift
//  
//
//  Created by Jan Verrept on 22/09/2020.
//

import Foundation
import JVCocoa

class PLCBackgroundCycle:ObservableObject {
    
    private let timeInterval: TimeInterval
    private let mainLoop:()->Void // Function-pointer to main loop
    
    init(timeInterval: TimeInterval, mainLoop:@escaping ()->Void ){
        self.timeInterval = timeInterval
        self.mainLoop = mainLoop
    }
    
    private lazy var backgroundTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating:self.timeInterval)
        timer.setEventHandler(handler: { [weak self] in
            
            AppNapController.shared.keepAlive()
            self?.mainLoop()
            
        })
        return timer
    }()
    
    
    // MARK: - Cycle Control
    @Published public var status: Status = .stopped
    
    func run() {
        if status != .running {
            backgroundTimer.resume()
            status = .running
        }
    }
    
    func stop() {
        if status != .stopped {
            backgroundTimer.suspend()
            status = .stopped
        }
    }
    
   
    
}
