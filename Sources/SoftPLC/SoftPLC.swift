//
//  VirtualPLC.swift
//  HAPiNest
//
//  Created by Jan Verrept on 14/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import ModbusDriver

class VirtualPLC{
    
    protocol Module {
    }

    protocol Driver {
        func readAllInputs()
        func writeAllOutputs()
    }
    typealias IOList = [[[String]]]
    
    internal var ioModules:[PLC.Module] = []
    internal var ioDrivers:[PLC.Driver] = []
    
    public var variableList:[PLCVariable] = []
    
   
    
    init(withIOmodules ioModules:[PLCModule] ioList:IOList){
        self.ioModules = ioModules
    }
    
    let plcCycle = DispatchQueue(label: "oneclick.virtualplc.cycle")
    
    func stop(){
        
    }
    
    func run() {
        
        plcCycle.async {
            self.ioDrivers.forEach{$0.readAllInputs()}
        }
        plcCycle.async {
            self.main()
        }
        plcCycle.async {
            self.ioDrivers.forEach{$0.writeAllOutputs()}
        }
        
    }
    
    func main(){
        
    }
    
    internal func import(ioList:IOList){
//        ioList.forEach(<#T##body: ([[String]]) throws -> Void##([[String]]) throws -> Void#>)
    }
    
    internal func lookup(Symbol:String)->PLCVariable{
        
    }
    
    
}

