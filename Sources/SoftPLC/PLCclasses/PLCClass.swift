//
//  PLCClass.swift
//
//  Created by Jan Verrept on 16/08/2020.
//

import Foundation
import JVSwift

open class PLCClass{
    
    public var plc:SoftPLC! = nil
    public var instanceName:String = ""
    
    public init(){}
    
}

public protocol Parameterizable:PLCClass{
    
    func assignInputParameters()
    func assignOutputParameters()
    
}

public protocol Simulateable:PLCClass{
    
    func simulateHardwareInputs()
    
}

public protocol CyclicRunnable:PLCClass{
	
	func runCycle()
	
}
