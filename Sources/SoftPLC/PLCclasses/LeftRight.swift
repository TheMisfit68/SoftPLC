//
//  LeftRight.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

@available(OSX 10.12, *)
open class LeftRight:PLCclass{
    
    enum Status:Int{
        case stop
        case left
        case right
    }
     
    var status:Status = .stop
    private var lastDirection:Status = .stop
    
    public var endSwitchLeft:Bool? = nil
    public var endSwitchRight:Bool? = nil
    public var isMovingLeft:Bool? = nil
    public var isMovingRight:Bool? = nil
    public var feedbackValue:Float? = nil
    
    public var left:Bool = false{
        didSet{
            if left && !(endSwitchLeft ?? false){
                status = .left
                lastDirection = .left
            }
        }
    }
    
    public var right:Bool = false{
        didSet{
            if right && !(endSwitchRight ?? false){
                status = .right
                lastDirection = .right
            }
        }
    }
    
    public var stop:Bool = false{
        didSet{
            if stop {
                status = .stop
            }
        }
    }
    
    public var toggle:Bool = false{
        didSet{
            let risingEdge = toggle && !oldValue
            if risingEdge{
                
                switch status{
                
                case .left, .right:
                    stop = true
                case .stop:
                    
                    if lastDirection == .left{
                        right = true
                    }else if lastDirection == .right{
                        left = true
                    }
                    
                }
            }
        }
    }
    
    public var outputLeft:Bool{
        return status == .left
    }
    
    public var outputRight:Bool{
        return status == .right
    }
    
    private var pulseTimerLeft:DigitalTimer? = nil
    public func pulsLeft(for pulsLength:TimeInterval)->Bool{
        
        if pulseTimerLeft == nil {
            pulseTimerLeft =  DigitalTimer(type: .pulsLimition, time: pulsLength)
        }
        pulseTimerLeft!.input = outputLeft
        let outputPuls = pulseTimerLeft!.output && !(endSwitchLeft ?? false)
        return outputPuls
        
    }
    
    private var pulseTimerRight:DigitalTimer? = nil
    public func pulsRight(for pulsLength:TimeInterval)->Bool{
        
        if pulseTimerRight == nil {
            pulseTimerRight =  DigitalTimer(type: .pulsLimition, time: pulsLength)
        }
        pulseTimerRight!.input = outputRight
        let outputPuls = pulseTimerRight!.output && !(endSwitchRight ?? false)
        return outputPuls
        
    }

}
