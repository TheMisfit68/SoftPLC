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
    
    public internal(set) var output:Bool = false
    public var feedbackValue:Bool? = nil
    
    public enum Status{
        case started
        case stopped
    }
    
    public var status:Status = .stopped{
        didSet{
            if status == .started{
                output.set()
            }else{
                output.reset()
            }
        }
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

