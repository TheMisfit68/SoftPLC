//
//  PlcBackgroundCycle.swift
//  
//
//  Created by Jan Verrept on 22/09/2020.
//

import Foundation
import JVCocoa

class PLCBackgroundCycle{
	
	private let timeInterval: TimeInterval
	private let mainLoop:()->Void // Function-pointer to main loop
	
	init(timeInterval: TimeInterval, mainLoop:@escaping ()->Void, maxCycleTimeInMicroSeconds:TimeInterval = 300000){
		self.timeInterval = timeInterval
		self.mainLoop = mainLoop
		self.maxCycleTime = maxCycleTimeInMicroSeconds
	}
	
	private lazy var backgroundTimer: DispatchSourceTimer = {
		let timer = DispatchSource.makeTimerSource()
		timer.schedule(deadline: .now(), repeating:self.timeInterval)
		timer.setEventHandler(handler: { [weak self] in
			
			// Prevent the App from napping (and the timer from pausing)
			AppNapController.shared.keepAlive()
			
			let cycleStart = TimeStamp.CurrentTimeStamp
			self?.mainLoop()
			
			// Calculate the cycletime
			let currentCycleTime = (TimeStamp.CurrentTimeStamp-cycleStart)*1000
			// Update Swift-UI properties on the main thread
			DispatchQueue.main.async {
				self?.cycleTimeInMicroSeconds = currentCycleTime
			}
			
			// Stop if PLC gets slow
			if let maxCycleTime = self?.maxCycleTime{
				if currentCycleTime > maxCycleTime{
					self?.stop(reason: .maxCycleTime)
				}
			}
			
		})
		return timer
	}()
	
	// MARK: - Cycle Control
	var status:Status = .stopped(reason:.manual)
	var cycleTimeInMicroSeconds:TimeInterval = 0
	var maxCycleTime:TimeInterval
	
	func run() {
		if status != .running {
			status = .running
			backgroundTimer.resume()
		}
	}
	
	func stop(reason:StopReason) {
		if status == .running{
			status = .stopped(reason:reason)
			backgroundTimer.suspend()
		}
	}
	
}
