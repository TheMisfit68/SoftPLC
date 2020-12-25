//
//  ImpulsRelais.swift.swift
//  
//
//  Created by Jan Verrept on 12/09/2020.
//

import Foundation

open class ImpulsRelais:StartStop{
    
    private var edgeDetection:EBool = EBool()
    
    public var toggle:Bool = false{
        
        didSet{
                        
            let risingEdge = edgeDetection.risingEdge(onBoolean: toggle)
        
            if risingEdge{
                output.toggle()
            }
            
        }
        
    }
    
}

