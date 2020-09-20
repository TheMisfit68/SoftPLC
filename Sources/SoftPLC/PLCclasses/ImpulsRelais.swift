//
//  ImpulsRelais.swift.swift
//  
//
//  Created by Jan Verrept on 12/09/2020.
//

import Foundation

import Foundation

@available(OSX 10.12, *)
open class ImpulsRelais:StartStop{
    
    public var toggle:Bool = false{
        didSet{
            let risingEdge = toggle && !oldValue
            if risingEdge{
                
                switch status{
                case .started:
                    status = .stopped
                case .stopped:
                    status = .started
                    
                }
            }
        }
    }
    
    
}
