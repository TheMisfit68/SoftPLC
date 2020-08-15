//
//  LeftRightCicuit.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

public class LeftRightCircuit{
    
    enum Status:Int{
        case stop
        case left
        case right
    }
    var status:Status = .stop
    private var lastDirection:Status = .stop
    
    public var endSwitchLeft:Bool? = nil
    public var endSwitchRight:Bool? = nil
    
    var left:Bool = false{
        didSet{
            if left && !(endSwitchLeft ?? false){
                status = .left
                lastDirection = .left
            }
        }
    }
    
    var right:Bool = false{
        didSet{
            if right && !(endSwitchRight ?? false){
                status = .right
                lastDirection = .right
            }
        }
    }
    
    var stop:Bool = false{
        didSet{
            if stop {
                status = .stop
            }
        }
    }
    
    // "Open" is equivalent to "Left"
    var open:Bool = false{
        didSet{
            left = open
        }
    }
    
    // "Close" is equivalent to "Right"
    var close:Bool = false{
        didSet{
            right = close
        }
    }
    
    
    
    var toggle:Bool = false{
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
    
    var outputLeft:Bool{
        return status == .left
    }
    
    var outputRight:Bool{
        return status == .right
    }
    
    // "Open" is equivalent to "Left"
    var outputOpen:Bool{
        return outputLeft
    }
    
    // "Close" is equivalent to "Right"
    var outputClose:Bool{
        return outputRight
    }
}
