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
	
	init(timeInterval: TimeInterval, mainLoop:@escaping ()->Void, maxCycleTimeInMiliSeconds:TimeInterval = 300){
		self.timeInterval = timeInterval
		self.mainLoop = mainLoop
		self.maxCycleTime = maxCycleTimeInMiliSeconds
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
			self?.cycleTimeInMiliSeconds = (TimeStamp.CurrentTimeStamp-cycleStart)
			
			// Stop if PLC gets slow
			if let currentCycleTime = self?.cycleTimeInMiliSeconds,  let maxCycleTime = self?.maxCycleTime, (currentCycleTime > maxCycleTime){
				print("+++++MAXcycltime exceeded!")
				self?.stop(reason: .maxCycleTime)
			}
			
		})
		return timer
	}()
	
	// MARK: - Cycle Control
	var status:Status = .stopped(reason:.manual)
	var cycleTimeInMiliSeconds:TimeInterval = 0
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
