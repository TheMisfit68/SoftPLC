//
//  StartStop.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import JVCocoa

open class StartStop:PLCclass{
    
    public var output:Bool = false
    public var feedbackValue:Bool? = nil
    
    enum Status{
        case started
        case stopped
    }
    
    var status:Status{
        output ? .started : .stopped
    }
    
    public var start:Bool = false{
        didSet{
            output.set()
        }
    }
    
    public var stop:Bool = false{
        didSet{
            output.reset()
        }
    }
    
}

