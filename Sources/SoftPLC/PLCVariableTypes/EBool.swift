//
//  EBool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

public struct EBool{
    
    private var previsousValue:Bool = false
    
    public init(){}
    
    public mutating func risingEdge(onBoolean boolean: Bool)->Bool{
        let edge = boolean && !previsousValue
        previsousValue = boolean
        return edge
    }
    
    public mutating func fallingEdge(onBoolean boolean: Bool)->Bool{
        let edge = previsousValue && !boolean
        previsousValue = boolean
        return edge
    }
    
    public mutating func anyEdge(onBoolean boolean: Bool)->Bool{
        let edge = boolean != previsousValue
        previsousValue = boolean
        return edge
    }
    
}
