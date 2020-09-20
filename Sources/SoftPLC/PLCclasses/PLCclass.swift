//
//  File.swift
//
//  Created by Jan Verrept on 16/08/2020.
//

import Foundation

@available(OSX 10.12, *)

public protocol Parameterizable{
    
    func assignInputParameters()
    func assignOutputParameters()
    
}

@available(OSX 10.12, *)
open class PLCclass{
    
    public var plc:SoftPLC! = nil
    public var instanceName:String = ""
    
    public init(){}
            
}
