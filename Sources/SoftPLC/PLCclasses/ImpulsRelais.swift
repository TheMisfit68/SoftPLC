//
//  ImpulsRelais.swift.swift
//  
//
//  Created by Jan Verrept on 12/09/2020.
//

import Foundation
import JVSwiftCore

/// A PLCClass equivalent to impulsrelais,
/// as used in electrical engineering
open class ImpulsRelais:StartStop{
    
    public override init(){
        ebToggle = EBool(&toggle)
    }
    
    var ebToggle:EBool
    
    public var toggle:Bool = false{
        
        didSet{
 
            if ebToggle.🔼{
                output.toggle()
            }
            
        }
        
    }
    
}

