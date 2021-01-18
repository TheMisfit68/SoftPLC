//
//  PLCclass.swift
//
//  Created by Jan Verrept on 16/08/2020.
//

import Foundation
import JVCocoa



open class PLCclass{
    
    public var plc:SoftPLC! = nil
    public var instanceName:String = ""
    
    public init(){}
    
}

public protocol Parameterizable:PLCclass{
    
    func assignInputParameters()
    func assignOutputParameters()
    
}

public protocol Simulateable:PLCclass{
    
    func simulateHardwareFeedback()
    
}
