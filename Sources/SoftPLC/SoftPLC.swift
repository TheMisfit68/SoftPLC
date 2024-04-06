//
//  SoftPLC.swift
//  HAPiNest
//
//  Created by Jan Verrept on 14/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import OSLog
import JVSwiftCore
import ModbusDriver
import IOTypes
import OSLog

open class SoftPLC{
	let logger = Logger(subsystem: "be.oneclick.SoftPLC", category:"SoftPLC")

    public typealias IOList = [[[IOSymbol?]]]
    public typealias RackNumber = Int
    public typealias HardwareConfiguration = [RackNumber:[IOModule]]
    
    public var controlPanel:SoftPLCView!
    
    public var hardwareConfig:HardwareConfiguration = [:]
    public var ioDrivers:[IODriver] = []
    public var simulator:IOSimulator?
    public var variableList:[IOSymbol:SoftPLCVariable] = [:]
    public var plcObjects:[String:PLCClass] = [:]{
        didSet{
            plcObjects.forEach{key, object in
                object.plc = self
                object.instanceName = key
            }
        }
    }
    
	var viewModel:SoftPLC.ViewModel
    private var backGroundCycle:SoftPLCBackGroundCycle! = nil
    
    public init(hardwareConfig:HardwareConfiguration, ioList:IOList, simulator:IOSimulator? = nil){
        
        self.viewModel = SoftPLC.ViewModel()
        self.controlPanel = SoftPLCView(
            viewModel:viewModel,
            togglePLCState: togglePLCState,
            setMaxCycleTime: setMaxCycleTime,
            toggleSimulator: toggleSimulator,
            toggleHardwareSimulation: toggleHardwareSimulation
        )
        
        
        self.hardwareConfig = hardwareConfig
        self.importIO(list: ioList)
        self.simulator = simulator
        
        self.hardwareConfig.forEach{ rack, modules in
            
            self.simulator?.ioModules.append(contentsOf: modules)
            
            // If a module has its own driver embedded,
            // add its driver to the array of drivers to execute
            modules.forEach{ module in
                if let moxaModule = module as? IOLogikE1200Series{
                    ioDrivers.append(moxaModule.driver)
                }
            }
            
            
        }
        
        
        self.backGroundCycle = SoftPLCBackGroundCycle(timeInterval: 0.250, mainLoop:{ [weak self] in self?.mainLoop() }, maxCycleTimeInMiliSeconds: self.viewModel.maxCycleTime)
    }
    
    public func togglePLCState(_ newState:Bool){
        
        if newState{
            resetIOFailures()
            run()
        }else{
            stop(reason: .manual)
            resetIOFailures()
        }
        
    }
    
    func setMaxCycleTime(_ newValue:TimeInterval){
        if newValue != viewModel.maxCycleTime{
            viewModel.maxCycleTime = newValue
            backGroundCycle.maxCycleTime = newValue
        }
    }
    
    public func toggleSimulator(_ newState:Bool){
        
        if newState{
            viewModel.executionType = .simulated(withHardware:true)
        }else{
            viewModel.executionType = .normal
        }
        resetIOFailures()
        
    }
    
    public func toggleHardwareSimulation(_ newState:Bool){
        viewModel.executionType = .simulated(withHardware:newState)
    }
    
    func resetIOFailures(){
        if case .simulated(_) = viewModel.executionType {
            simulator?.ioFailure.reset()
        }else if case .normal = viewModel.executionType {
            ioDrivers.forEach{$0.ioFailure.reset()}
        }
    }
    
    // MARK: - Main PLC Cycle
    
    func mainLoop()->Void{

        if case .simulated(let withHardware) = viewModel.executionType, let simulator = self.simulator{
            
            simulator.readAllInputs()
            if simulator.ioFailure{ stop(reason: .ioFault) }
            
#if DEBUG
            if withHardware{
                // Overwrite PLC inputs with data of software simulated hardware,
                // before they get to be used as input parameters
                logger.log("⚙️\tSimulating hardware")
                
                self.plcObjects.forEach { instanceName, object in
                    (object as? Simulateable)?.simulateHardwareInputs()
                }
            }
            // And don't guard the Maximum Cycle Time while debugging
            backGroundCycle.numberOfOverruns = 0
#endif
            
            
            if self.viewModel.runState == .running{
                
                self.plcObjects.forEach { instanceName, object in
                    
                    (object as? Parameterizable)?.assignInputParameters()
                    
                    (object as? CyclicRunnable)?.runCycle()
                    
                    (object as? Parameterizable)?.assignOutputParameters()
                    
                }
            }
            
            simulator.writeAllOutputs()
            if simulator.ioFailure{ stop(reason: .ioFault) }
            
        }else if case .normal = viewModel.executionType{
            
            self.ioDrivers.forEach{
                $0.readAllInputs()
                if $0.ioFailure{ stop(reason: .ioFault) }
            }
            
            
            if self.viewModel.runState == .running{
                
                self.plcObjects.forEach { instanceName, object in
                    
                    (object as? Parameterizable)?.assignInputParameters()
                    
                    (object as? CyclicRunnable)?.runCycle()
                    
                    (object as? Parameterizable)?.assignOutputParameters()
                    
                }
            }
            
            self.ioDrivers.forEach{
                $0.writeAllOutputs()
                if $0.ioFailure{ stop(reason: .ioFault) }
            }
            
        }
        refreshBackgroundInfo()
    }
    
    public func stop(reason:StopReason){
        backGroundCycle.stop(reason:reason)
    }
    
    public func run() {
        backGroundCycle.run()
    }
    
    
    // MARK: - IO-Symbols management
    internal func importIO(list:IOList){
        for (rackIndex, rack) in list.enumerated() {
            for (moduleIndex, module) in rack.enumerated() {
                for (channelIndex, channel) in module.enumerated(){
                    
                    if let ioSymbol = channel {
                        let ioAddress:[Int] = [rackIndex, moduleIndex,  channelIndex]
                        let ioVariable = SoftPLCVariable(address: ioAddress, symbol: ioSymbol, description: ioSymbol.description)
                        variableList[ioSymbol] = ioVariable
                    }
                    
                }
            }
        }
    }
    
    public func signal(ioSymbol:IOSymbol)->IOSignal?{
        var ioSignal:IOSignal? = nil
        if let ioVariable:SoftPLCVariable = variableList[ioSymbol]{
            
            let rackNumber = ioVariable.address[0]
            let moduleNr = ioVariable.address[1]
            let channelNumber = ioVariable.address[2]
            
            let ioRack = hardwareConfig[rackNumber]
            let ioModule = ioRack?[moduleNr]
            ioSignal = ioModule?.channels[channelNumber]
        }
        return ioSignal
    }
    
    // MARK: - Populate ViewModel
    func refreshBackgroundInfo(){
        // At all times observable variables should be changed on the main thread
        // even if they exist in the background
        DispatchQueue.main.async {
            self.viewModel.runState = self.backGroundCycle.runState
            self.viewModel.cycleTimeInMiliSeconds = self.backGroundCycle.cycleTimeInMiliSeconds
            self.viewModel.maxCycleTime = self.backGroundCycle.maxCycleTime
        }
    }
    
}
