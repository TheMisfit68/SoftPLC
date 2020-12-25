//
//  File.swift
//
//  Created by Jan Verrept on 16/08/2020.
//

import Foundation
import JVCocoa

public protocol Parameterizable{
    
    func assignInputParameters()
    func assignOutputParameters()
    
}

open class PLCclass{
    
    public var plc:SoftPLC! = nil
    public var instanceName:String = ""
    
    public init(){}
            
}
