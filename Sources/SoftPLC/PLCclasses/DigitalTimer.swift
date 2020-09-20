//
//  DigitalTimer.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

@available(OSX 10.12, *)
open class DigitalTimer:PLCclass{
    
    enum DelayType{
        case onDelay
        case offDelay
        case pulsLimition
        case exactPuls
    }
    
    let delayType:DelayType
    let timeValue:TimeInterval
    
    public var input:Bool = false{
        didSet{
            let risingEdge = input && !oldValue
            let falingEdge = !input && oldValue
            
            switch delayType{
            case .onDelay:
                if risingEdge{
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = self.input}
                }else if falingEdge{
                    output = input
                }
            case .offDelay:
                if risingEdge{
                    output = input
                }else if falingEdge{
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = self.input}
                }
            case .pulsLimition:
                if risingEdge{
                    output = input
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = false}
                }else if falingEdge{
                    output = input
                }
            case .exactPuls:
                if risingEdge{
                    output = input
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = false}
                }else if falingEdge{
                    // Do nothing on the faling edge
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
