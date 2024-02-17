//
//  Bool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

// MARK: - TIMING
public extension Bool {
	
	mutating func timed(using timer:DigitalTimer = DigitalTimer.OnDelay(time:1.0){} ) -> Bool{
		timer.input = self
		self = timer.output
		return self
	}
	
}

