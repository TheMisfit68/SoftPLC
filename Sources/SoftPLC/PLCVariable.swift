//
//  PLCVariable.swift
//  
//
//  Created by Jan Verrept on 15/08/2020.
//

import Foundation

internal struct PLCVariable{
    
    var address:[Int] // IO-variables wil recieve 3 entries, Racknumber, Modulenumber and Channelnumber
    var symbol:String
    var description:String
    
}
