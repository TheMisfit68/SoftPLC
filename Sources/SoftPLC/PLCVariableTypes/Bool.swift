//
//  Bool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation


public extension Bool {
        
    mutating func set(){
        self = true
    }
    
    mutating func reset(){
        self = false
    }
    
    mutating func timed(using timer:DigitalTimer = DigitalTimer.OnDelay(time:1.0){} ) -> Bool{
        timer.input = self
        self = timer.output
        return self
    }
    
    func test(){
        
    }
    
}

public func set(_ boolean:inout Bool){
    boolean.set()
}

public func reset(_ boolean:inout Bool){
    boolean.reset()
}
