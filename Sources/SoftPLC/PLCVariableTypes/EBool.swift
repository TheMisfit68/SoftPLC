//
//  EBool.swift
//  
//
//  Created by Jan Verrept on 24/12/2020.
//

import Foundation

public typealias EdgeDetection = EBool

public class EBool{
    
    init(_ booleanVariable:UnsafePointer<Bool>){
        self.booleanVariable = booleanVariable
        self.booleanValue = booleanVariable.pointee
    }
    
    private var _risingEdge:Bool = false
    private var _fallingEdge:Bool = false
    private var _anyEdge:Bool = false
    
    private var booleanVariable:UnsafePointer<Bool>
    private var booleanValue:Bool = false{
        
        didSet{
            _risingEdge = booleanValue && !oldValue
            _fallingEdge = booleanValue && !oldValue
            _anyEdge = booleanValue && !oldValue
        }
    }
    
    public var risingEdge:Bool{
        booleanValue = booleanVariable.pointee
        return _risingEdge
    }
    
    public var fallingEdge:Bool{
        booleanValue = booleanVariable.pointee
        return _fallingEdge
    }
    
    public var anyEdge:Bool{
        booleanValue = booleanVariable.pointee
        return _anyEdge
    }
    
    // MARK: - Symbolic equivalents
    public var 🔼:Bool{
        return risingEdge
    }
    
    public var 🔽:Bool{
        return fallingEdge
    }
    
    public var 🔼🔽:Bool{
        return anyEdge
    }
    
}
