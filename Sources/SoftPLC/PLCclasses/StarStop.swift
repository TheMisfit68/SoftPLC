//
//  StartStop.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

@available(OSX 10.12, *)
open class StartStop:PLCclass{
    
    enum Status{
        case started
        case stopped
    }
    
    var status:Status = .stopped
    
    public var start:Bool = false{
        didSet{
            if start {
                status = .started
            }
        }
    }
    
    public var stop:Bool = false{
        didSet{
            if stop {
                status = .stopped
            }
        }
    }
    
    public var feedbackValue:Bool? = nil
    
    public var output:Bool{
        return (status == .started)
    }
    
    private var pulseTimer:DigitalTimer! = nil
    public func puls(for pulsLength:TimeInterval)->Bool{
        
        if pulseTimer == nil {
            pulseTimer =  DigitalTimer(type: .pulsLimition, time: pulsLength)
        }
        pulseTimer.input = output
        
        let outputPuls = pulseTimer.output && !(feedbackValue ?? false)
        return outputPuls
        
    }
    
}

