//
//  LeftRightCircuitWithSP.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

class LeftRightCircuitWithSP:LeftRightCircuit{
    
    public var travelDuration:Int
    private var secondsTimer:Timer!
    
    public var setPoint:Float = 0.0{
        didSet{
            controlOutputs()
        }
    }
    
    public var feedbackValue:Float = 0.0{
        didSet{
            controlOutputs()
        }
    }
    
    public var externalFeedbackValue:Float? = nil{
        didSet{
            if let feedbackValue = externalFeedbackValue{
                self.feedbackValue = feedbackValue
            }
        }
    }
    
    public var deadBand:Float = 0.2
    
    private func controlOutputs(){
        
        if (feedbackValue-setPoint) > deadBand{
            close = true
        }else if  (feedbackValue-setPoint) < (deadBand * -1.0){
            open = true
        }
        
    }
    
}
