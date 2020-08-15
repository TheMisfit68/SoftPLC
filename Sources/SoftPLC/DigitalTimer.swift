//
//  DigitalTimer.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

@available(OSX 10.12, *)
public class DigitalTimer{
    
    enum DelayType{
        case onDelay
        case offDelay
        case pulsLimition
        case exactPuls
    }
    
    var delayTimer:Timer!
    let delayType:DelayType
    let timeValue:TimeInterval
    
    public var input:Bool = false{
        didSet{
            let risingEdge = input && !oldValue
            let falingEdge = !input && oldValue
            
            switch delayType{
            case .onDelay:
                if risingEdge{
                    output = false
                    delayTimer = Timer(timeInterval: timeValue, repeats: false, block:{timer in self.output = self.input; self.delayTimer.invalidate()})
                    delayTimer.tolerance = 0.1 // Give the processor some slack
                }
                if !input{
                    output = false
                    delayTimer.invalidate()
                }
            case .offDelay:
                if falingEdge{
                    delayTimer = Timer(timeInterval: timeValue, repeats: false, block:{timer in self.output = self.input; self.delayTimer.invalidate()})
                    delayTimer.tolerance = 0.1 // Give the processor some slack
                }
                if input{
                    output = true
                    delayTimer.invalidate()
                }
            case .pulsLimition:
                if risingEdge{
                    output = false
                    delayTimer = Timer(timeInterval: timeValue, repeats: false, block:{timer in self.output = false; self.delayTimer.invalidate()})
                    delayTimer.tolerance = 0.1 // Give the processor some slack
                }
                if !input{
                    output = false
                    delayTimer.invalidate()
                }
            case .exactPuls:
                if risingEdge{
                    output = true
                    delayTimer = Timer(timeInterval: timeValue, repeats: false, block:{timer in self.output = false; self.delayTimer.invalidate()})
                    delayTimer.tolerance = 0.1 // Give the processor some slack
                }

            }
            
        }
        
        
    }
    
    public var output:Bool = false
    
    init(type:DelayType = .onDelay, time:TimeInterval){
        self.delayType = type
        self.timeValue = time
    }
    
}
