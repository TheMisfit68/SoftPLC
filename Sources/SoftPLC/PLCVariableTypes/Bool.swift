//
//  Bool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

// MARK: - SET/RESET
public extension Bool {
	
	mutating func set(){
		self = true
	}
	
	mutating func reset(){
		self = false
	}
	
	mutating func setConditional(_ condition:Bool){
		if condition{
			self.set()
		}
	}

	mutating func resetConditional(_ condition:Bool){
		if condition{
			self.reset()
		}
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

