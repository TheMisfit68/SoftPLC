//
//  VirtualPLC.swift
//  HAPiNest
//
//  Created by Jan Verrept on 14/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import ModbusDriver

public protocol PLCDriver {
    func readAllInputs()
    func writeAllOutputs()
}

@available(OSX 10.12, *)
public protocol drivenIOmodule:IOmodule{
    var driver:PLCDriver{get}
}


@available(OSX 10.12, *)
open class SoftPLC{
    public typealias IOList = [[[String?]]]
    public typealias HardwareConfiguration = [IOmodule]
    
    internal var hardwareConfig:HardwareConfiguration = []
    internal var ioDrivers:[PLCDriver] = []
    
    internal var variableList:[String:PLCVariable] = [:]
    
    public init(hardwareConfig:HardwareConfiguration, ioList:IOList){
        self.hardwareConfig = hardwareConfig
        if let drivenIOmodules = hardwareConfig as? [drivenIOmodule]{
            drivenIOmodules.forEach{
                ioDrivers.append($0.driver)
            }
        }
        self.importIO(list: ioList)
    }
    
    let plcCycle = DispatchQueue(label: "oneclick.virtualplc.cycle")
    
    open func stop(){
        
    }
    
    open func run() {
        
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
    
    open func main(){
        
    }
    
    internal func importIO(list:IOList){
        for (rackIndex, rack) in list.enumerated() {
            for (moduleIndex, module) in rack.enumerated() {
                for (channelIndex, channel) in module.enumerated(){
                    
                    let ioSymbol = channel ?? ""
                    let ioAddress:[Int] = [rackIndex, moduleIndex,  channelIndex]
                    let ioVariable = PLCVariable(address: ioAddress, symbol: ioSymbol, description: ioSymbol)
                    variableList[ioSymbol] = ioVariable
                    
                }
            }
        }
    }

    
}

