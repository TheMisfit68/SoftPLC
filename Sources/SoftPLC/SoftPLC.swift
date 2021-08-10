//
//  SoftPLC.swift
//  HAPiNest
//
//  Created by Jan Verrept on 14/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation
import ModbusDriver
import IOTypes

public enum Status:Equatable{
	case running
	case stopped(reason: StopReason)
}

public enum StopReason:String{
	case manual
	case maxCycleTime
	case ioFault
}

public enum ExecutionType{
	case normal
	case simulated(withHardware:Bool)
}

public class SoftPLC:ObservableObject{
	
	public var controlPanel:PLCView!
	@Published public var executionType:ExecutionType = .simulated(withHardware:true)
	@Published var status:Status
	@Published var cycleTimeInMiliSeconds:TimeInterval = 0
	@Published var maxCycleTime:TimeInterval{
		didSet{
			if maxCycleTime != oldValue{
				plcBackgroundCycle.maxCycleTime = maxCycleTime
			}
		}
	}
	
	
	public typealias Symbol = String
	public typealias IOList = [[[Symbol?]]]
	public typealias RackNumber = Int
	public typealias HardwareConfiguration = [RackNumber:[IOModule]]
	
	public var hardwareConfig:HardwareConfiguration = [:]
	public var ioDrivers:[IODriver] = []
	public var simulator:IOSimulator?
	public var variableList:[Symbol:PLCVariable] = [:]
	public var plcObjects:[Symbol:PLCClass] = [:]{
		didSet{
			plcObjects.forEach{key, object in
				object.plc = self
				object.instanceName = key
			}
		}
	}
	
	
	var plcBackgroundCycle:PLCBackgroundCycle! = nil
	
	public init(hardwareConfig:HardwareConfiguration, ioList:IOList, simulator:IOSimulator? = nil){
		
		self.status = .stopped(reason: .manual)
		self.executionType = .normal
		self.maxCycleTime = 750
		
		self.hardwareConfig = hardwareConfig
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
		
		self.importIO(list: ioList)
		self.plcBackgroundCycle = PLCBackgroundCycle(timeInterval: 0.250, mainLoop:{ [weak self] in self?.mainLoop() }, maxCycleTimeInMiliSeconds: self.maxCycleTime)
		self.controlPanel = PLCView(plc: self, togglePLCState: togglePLCState, toggleSimulator: toggleSimulator, toggleHardwareSimulation: toggleHardwareSimulation)
		
	}
	
	func togglePLCState(newState:Bool){
		
		if newState{
			resetIOFailures()
			run()
		}else{
			stop(reason: .manual)
			resetIOFailures()
		}
		
	}
	
	func toggleSimulator(newState:Bool){
		
		if newState{
			executionType = .simulated(withHardware:true)
		}else{
			executionType = .normal
		}
		resetIOFailures()
		
	}
	
	func toggleHardwareSimulation(newState:Bool){
			executionType = .simulated(withHardware:newState)
	}
	
	func resetIOFailures(){
		if case .simulated(_) = executionType {
			simulator?.ioFailure.reset()
		}else if case .normal = executionType {
			ioDrivers.forEach{$0.ioFailure.reset()}
		}
	}
	
	// MARK: - Main PLC Cycle
	
	func mainLoop()->Void{
		
		if case .simulated(let withHardware) = executionType, let simulator = self.simulator{
			
			simulator.readAllInputs()
			if simulator.ioFailure{ stop(reason: .ioFault) }
			
#if DEBUG
			if withHardware{
				// Overwrite PLC inputs with data of software simulated hardware,
				// before they get to be used as input parameters
				self.plcObjects.forEach { instanceName, object in
					(object as? Simulateable)?.simulateHardwareInputs()
				}
			}
			// And don't guard the Maximum Cycle Time while debugging
			plcBackgroundCycle.numberOfOverruns = 0
#endif
			
			
			if self.status == .running{
				
				self.plcObjects.forEach { instanceName, object in
					
					(object as? Parameterizable)?.assignInputParameters()
					
					(object as? CyclicRunnable)?.runCycle()
					
					(object as? Parameterizable)?.assignOutputParameters()
					
				}
			}
			
			simulator.writeAllOutputs()
			if simulator.ioFailure{ stop(reason: .ioFault) }
			
		}else if case .normal = executionType{
			
			self.ioDrivers.forEach{
				$0.readAllInputs()
				if $0.ioFailure{ stop(reason: .ioFault) }
			}
			
			
			if self.status == .running{
				
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
		plcBackgroundCycle.stop(reason:reason)
		refreshBackgroundInfo()
	}
	
	public func run() {
		plcBackgroundCycle.run()
		refreshBackgroundInfo()
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
	
	public func signal(ioSymbol:String)->IOSignal?{
		var ioSignal:IOSignal? = nil
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
	
	func refreshBackgroundInfo(){
		// At all times published variables should be changed on the main thread
		// even if they exist in the background
		DispatchQueue.main.async {
			self.status = self.plcBackgroundCycle.status
			self.cycleTimeInMiliSeconds = self.plcBackgroundCycle.cycleTimeInMiliSeconds
			self.maxCycleTime = self.plcBackgroundCycle.maxCycleTime
		}
	}
	
}

