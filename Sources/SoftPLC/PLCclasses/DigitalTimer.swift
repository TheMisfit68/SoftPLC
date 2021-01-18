//
//  DigitalTimer.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

open class DigitalTimer:PLCclass{
    
    private var risingEdge:Bool = false
    private var falingEdge:Bool = false
    
    public var input:Bool = false
    public let timeValue:TimeInterval
    public var output:Bool = false
    
    public init(time:TimeInterval){
        self.timeValue = time
    }
}

extension DigitalTimer{
    
    open class OnDelay:DigitalTimer{
        
        public var action:() -> Void
        
        public init(time:TimeInterval = 1.0, _ action:@escaping ()->Void = {} ){
            self.action = action
            super.init(time: time)
        }
        
        
        public override var input:Bool {
            didSet{
                risingEdge = input && !oldValue
                falingEdge = !input && oldValue
                
                if risingEdge{
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {
                        self.output = self.input
                        if self.output{
                            self.action()
                        }
                    }
                }else if falingEdge{
                    output = input
                }
            }
        }
        
    }
}


extension DigitalTimer{
    
    open class OffDelay:DigitalTimer{
        
        public override var input:Bool {
            didSet{
                risingEdge = input && !oldValue
                falingEdge = !input && oldValue
                
                if risingEdge{
                    output = input
                }else if falingEdge{
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = self.input}
                }
            }
        }
        
    }
}

extension DigitalTimer{
    
    open class PulsLimition:DigitalTimer{
        
        public override var input:Bool {
            didSet{
                risingEdge = input && !oldValue
                falingEdge = !input && oldValue 
                
                if risingEdge{
                    output = input
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {
                        self.output = false
                    }
                }else if falingEdge{
                    output = input
                }
            }
        }
        
    }
}

extension DigitalTimer{
    
    open class ExactPuls:DigitalTimer{
        
        public override var input:Bool {
            didSet{
                risingEdge = input && !oldValue
                falingEdge = !input && oldValue
                
                if risingEdge{
                    output = input
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeValue) {self.output = false}
                }else if falingEdge{
                    // Do nothing on the faling edge
                }
            }
        }
        
    }
}
