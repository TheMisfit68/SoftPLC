//
//  ImpulsRelais.swift.swift
//  
//
//  Created by Jan Verrept on 12/09/2020.
//

import Foundation

open class ImpulsRelais:StartStop{
    
    override init(){
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

