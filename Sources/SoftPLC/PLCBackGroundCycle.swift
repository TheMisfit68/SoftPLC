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
			self!.mainLoop()
			
			// Calculate the cycletime
			let currentCycleTime = (TimeStamp.CurrentTimeStamp-cycleStart)*1000
			DispatchQueue.main.async {
				self!.cycleTimeInMicroSeconds = currentCycleTime
			}
			
			// Stop if PLC get slow
			let maxCycleTime = self!.maxCycleTime
			if currentCycleTime > maxCycleTime{
				self!.stop()
			}
			
		})
		return timer
	}()
	
	
	// MARK: - Cycle Control
	@Published public var status: Status = .stopped
	@Published var cycleTimeInMicroSeconds:TimeInterval = 0
	@Published var maxCycleTime:TimeInterval
	
	func run() {
		if status != .running {
			backgroundTimer.resume()
			DispatchQueue.main.async {
				self.status = .running // At all times published variables should be changed on the main thread
			}
		}
	}
	
	func stop() {
		if status != .stopped {
			backgroundTimer.suspend()
			DispatchQueue.main.async {
				self.status = .stopped // At all times published variables should be changed on the main thread
			}
		}
	}
	
}
