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
	case simulated
}

public class SoftPLC{
	
	public var controlPanel:PLCView!
	
	public typealias Symbol = String
	public typealias IOList = [[[Symbol?]]]
	public typealias RackNumber = Int
	public typealias HardwareConfiguration = [RackNumber:[IOModule]]
	
	public var hardwareConfig:HardwareConfiguration = [:]
	public var ioDrivers:[IODriver] = []
	public var simulator:IOSimulator?
	public var executionType:ExecutionType = .normal
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
	
	
	public init(hardwareConfig:HardwareConfiguration, ioList:IOList, simulator:IOSimulator? = nil){
		
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
		
		self.plcBackgroundCycle = PLCBackgroundCycle(timeInterval: 0.250, mainLoop:mainLoop)
		
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
		
		if executionType == .simulated, let simulator = self.simulator{
			
			simulator.readAllInputs()
			if simulator.ioFailure{ plcBackgroundCycle.stop(reason: .ioFault) }
			
			#if DEBUG
			// Overwrite PLC inputs with simulated data,
			// before they get to be used as input parameters
			self.plcObjects.forEach { instanceName, object in
				(object as? Simulateable)?.simulateHardwareFeedback()
			}
			#endif
			
			
			if self.status == .running{
				
				self.plcObjects.forEach { instanceName, object in
					
					(object as? Parameterizable)?.assignInputParameters()
					
					(object as? Parameterizable)?.assignOutputParameters()
					
				}
			}
			
			simulator.writeAllOutputs()
			if simulator.ioFailure{ plcBackgroundCycle.stop(reason: .ioFault) }
			
		}else{
			
			self.ioDrivers.forEach{
				$0.readAllInputs()
				if $0.ioFailure{
					plcBackgroundCycle.stop(reason: .ioFault)
				}
			}

			
			if self.status == .running{
				
				self.plcObjects.forEach { instanceName, object in
					
					(object as? Parameterizable)?.assignInputParameters()
					
					(object as? Parameterizable)?.assignOutputParameters()
					
				}
			}
			
			self.ioDrivers.forEach{
				$0.writeAllOutputs()
				if $0.ioFailure{
					plcBackgroundCycle.stop(reason: .ioFault)
				}
			}
			
		}
		
	}
	
	public func stop(){
		plcBackgroundCycle.stop(reason: .manual)
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
	
}

