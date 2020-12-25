//
//  PLCVariable.swift
//  
//
//  Created by Jan Verrept on 15/08/2020.
//

import Foundation


public struct PLCVariable{
    
    public var address:[Int] // IO-variables wil recieve 3 entries, Racknumber, Modulenumber and Channelnumber
    public var symbol:SoftPLC.Symbol
    public var description:String
    
}
