//
//  StartStopCircuit.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

class StartStopCircuit{
    
    enum Status{
        case start
        case stop
    }
    var status:Status = .stop
        
    public var start:Bool = false{
        didSet{
            if start {
                status = .start
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
                case .start:
                    stop = true
                case .stop:
                    start = true
                
                }
            }
        }
    }
    
    public var output:Bool{
        return status == .start
    }
    
}
