//
//  Bool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

// MARK: - SET/RESET
public extension Bool {
	
	mutating func set(_ condition:Bool? = nil){
		self = (condition == true)
	}

	mutating func reset(_ condition:Bool? = nil){
		self = (condition == true)
	}
	
}

public func set(_ boolean:inout Bool){
	boolean.set()
}

public func reset(_ boolean:inout Bool){
	boolean.reset()
}


// MARK: - TIMING
public extension Bool {
	
	mutating func timed(using timer:DigitalTimer = DigitalTimer.OnDelay(time:1.0){} ) -> Bool{
		timer.input = self
		self = timer.output
		return self
	}
	
}

