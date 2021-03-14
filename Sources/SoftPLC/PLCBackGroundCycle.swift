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
	
	init(timeInterval: TimeInterval, mainLoop:@escaping ()->Void, maxCycleTimeInMiliSeconds:TimeInterval = 300, maxNumberOfOverruns:Int = 3){
		self.timeInterval = timeInterval
		self.mainLoop = mainLoop
		self.maxCycleTime = maxCycleTimeInMiliSeconds
		self.maxNumberOfOverruns = maxNumberOfOverruns
	}
	
	private lazy var backgroundTimer: DispatchSourceTimer = {
		let timer = DispatchSource.makeTimerSource()
		timer.schedule(deadline: .now(), repeating:self.timeInterval)
		timer.setEventHandler(handler: { [weak self] in
			
			// Prevent the App from napping (and the timer from pausing)
			AppNapController.shared.keepAlive()
			
			let cycleStart = TimeStamp.CurrentTimeStamp
			
			self?.mainLoop()
						
			self?.monitorCycletime(TimeStamp.CurrentTimeStamp-cycleStart)
			
		})
		return timer
	}()
	
	private func monitorCycletime(_ currentCycleTime: TimeInterval){
		
		cycleTimeInMiliSeconds = currentCycleTime

		// Stop if PLC gets to slow a number of times
		if (cycleTimeInMiliSeconds >= maxCycleTime){
			
			numberOfOverruns += 1
			guard numberOfOverruns < maxNumberOfOverruns else{
				stop(reason: .maxCycleTime)
				print("+++++MAXcycltime \(numberOfOverruns) times exceeded!")
				return
			}
			
		}else{
			numberOfOverruns = 0 // Reset cunt when the cycletime normalises again
		}
		
	}
	
	// MARK: - Cycle Control
	var status:Status = .stopped(reason:.manual)
	var cycleTimeInMiliSeconds:TimeInterval = 0
	var maxCycleTime:TimeInterval
	var numberOfOverruns:Int = 0
	var maxNumberOfOverruns:Int
	
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
