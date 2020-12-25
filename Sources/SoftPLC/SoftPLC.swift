//
//  SoftPLC.swift
//  HAPiNest
//
//  Created by Jan Verrept on 14/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import ModbusDriver

public enum Status{
    case running
    case stopped
}

public enum ExecutionType{
    case normal
    case simulated
}

public protocol PLCDriver {
    func readAllInputs()
    func writeAllOutputs()
}

extension ModbusDriver:PLCDriver{}

public class SoftPLC{
    
    public var controlPanel:PLCView!
    
    public typealias Symbol = String
    public typealias IOList = [[[Symbol?]]]
    public typealias rackNumber = Int
    public typealias HardwareConfiguration = [rackNumber:[ModBusModule]]
    
    public var hardwareConfig:HardwareConfiguration = [:]
    public var ioDrivers:[PLCDriver] = []
    public var simulator:ModbusSimulator = ModbusSimulator()
    public var executionType:ExecutionType = .simulated //TODO: - change to normal after testing
    
    public var variableList:[Symbol:PLCVariable] = [:]
    public var plcObjects:[Symbol:PLCclass] = [:]{
        didSet{
            plcObjects.forEach{key, object in
                object.plc = self
                object.instanceName = key
            }
        }
    }
    
    
    var plcBackgroundCycle:PLCBackgroundCycle! = nil
    
    public var status:Status{
        return plcBackgroundCycle.status
    }
    
    
    public init(hardwareConfig:HardwareConfiguration, ioList:IOList){
        
        self.hardwareConfig = hardwareConfig
        
        
        self.hardwareConfig.forEach{ rack, modules in
            
            // If a module has its own driver embedded,
            // add it to the array of drivers to execute
            modules.forEach{ module in
                switch module{
                case is IOLogikE1200Series:
                    if let moxaModule = module as? IOLogikE1200Series{
                        ioDrivers.append(moxaModule.driver)
                    }
                default:
                    break
                }
                
            }
            
            // Also add all modules to the simulator-driver for testing purposes
            simulator.modbusModules = modules
        }
        
        self.importIO(list: ioList)
        
        self.plcBackgroundCycle = PLCBackgroundCycle(timeInterval: 0.3, mainLoop:mainLoop)
        
        self.controlPanel = PLCView(plcBackGroundCyle: plcBackgroundCycle, togglePLCState: togglePLCState, toggleSimulator: toggleSimulator)
        
    }
    
    func togglePLCState(newState:Bool){
        if newState{
            run()
        }else{
            stop()
        }
    }
    
    func toggleSimulator(newState:Bool){
        if newState{
            executionType = .simulated
        }else{
            executionType = .normal
        }
    }
    
    // MARK: - Main PLC Cycle
    
    func mainLoop()->Void{
        
        if executionType == .simulated{
            self.simulator.readAllInputs()
        }else{
            self.ioDrivers.forEach{$0.readAllInputs()}
        }
        
        if self.status == .running{
            
            self.plcObjects.forEach { instanceName, object in
                
                (object as? Parameterizable)?.assignInputParameters()
                
                (object as? Parameterizable)?.assignOutputParameters()
                
            }
        }
        
        if executionType == .simulated{
            self.simulator.writeAllOutputs()
        }else{
            self.ioDrivers.forEach{$0.writeAllOutputs()}
        }
        
    }
    
    public func stop(){
        plcBackgroundCycle.stop()
    }
    
    public func run() {
        plcBackgroundCycle.run()
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
            
            let rackNumber = ioVariable.address[0]
            let moduleNr = ioVariable.address[1]
            let channelNumber = ioVariable.address[2]
            
            let ioRack = hardwareConfig[rackNumber]
            let ioModule = ioRack?[moduleNr]
            ioSignal = ioModule?.channels[channelNumber]
        }
        return ioSignal
    }
    
}

