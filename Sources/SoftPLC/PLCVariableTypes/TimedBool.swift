//
//  TimedBool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

// MARK: - TIMING

/// Provide a Bool with the capability to be set or reset using a DigitalTimer of any type
public extension Bool {
	
	mutating func timed(using timer:DigitalTimer = DigitalTimer.OnDelay(time:1.0){} ) -> Bool{
		timer.input = self
		self = timer.output
		return self
	}
	
}

