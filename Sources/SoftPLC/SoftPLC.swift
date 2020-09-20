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
extension ModbusDriver:PLCDriver{}

@available(OSX 10.12, *)
public class SoftPLC{
    
    public typealias Symbol = String
    public typealias IOList = [[[Symbol?]]]
    public typealias HardwareConfiguration = [IOmodule]
    
    public var hardwareConfig:HardwareConfiguration = []
    public var ioDrivers:[PLCDriver] = []
    
    public var variableList:[Symbol:PLCVariable] = [:]
    public var plcObjects:[Symbol:PLCclass] = [:]{
        didSet{
            plcObjects.forEach{key, object in
                object.plc = self
                object.instanceName = key
            }
        }
    }
    
    public enum Status{
        case running
        case stopped
    }
    public var status:Status = .stopped
    
    private var runCycleTimer:Timer!
    let plcCycle = DispatchQueue(label: "oneclick.virtualplc.cycle", qos: .userInitiated)
    
    public init(hardwareConfig:HardwareConfiguration, ioList:IOList){
        self.hardwareConfig = hardwareConfig
        
        // If a module has its own driver embedded,
        // add it to the array of drivers
        self.hardwareConfig.forEach{ ioModule in
            
            switch ioModule{
            case is IOLogikE1200Series:
                if let moxaModule = ioModule as? IOLogikE1200Series{
                    ioDrivers.append(moxaModule.driver)
                }
            default:
                break
            }
            
        }
        
        self.importIO(list: ioList)
        
        runCycleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) {timer in
            print("Timer Fires")
            self.mainLoop()
        }
        runCycleTimer.tolerance = runCycleTimer.timeInterval/10.0 // Give the processor some slack with a 10% tolerance on the timeInterval
    }
    
    
    // MARK: - Main PLC Cycle
    internal func mainLoop(){
        
        plcCycle.async {
            self.ioDrivers.forEach{$0.readAllInputs()}
        }
        
        plcCycle.async {
            if self.status == .running{
                
                self.plcObjects.forEach { instanceName, object in
                    
                    (object as? Parameterizable)?.assignInputParameters()
                    
                    (object as? Parameterizable)?.assignOutputParameters()
                    
                }
            }
        }
        
        plcCycle.async {
            self.ioDrivers.forEach{$0.writeAllOutputs()}
        }
        
    }
    
    public func stop(){
        status = .stopped
    }
    
    public func run() {
        status = .running
    }
    
    
    // MARK: - IO-Symbols management
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
    
    public func signal(ioSymbol:String)->IOsignal?{
        var ioSignal:IOsignal? = nil
        if let ioVariable:PLCVariable = variableList[ioSymbol]{
            let moduleNr = ioVariable.address[1]
            let channelNumber = ioVariable.address[2]
            let ioModule = hardwareConfig[moduleNr]
            ioSignal = ioModule.channels[channelNumber]
        }
        return ioSignal
    }
    
}

