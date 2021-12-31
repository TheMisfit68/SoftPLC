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
import JVCocoa

public class SoftPLC{
	
	public typealias Symbol = String
	public typealias IOList = [[[Symbol?]]]
	public typealias RackNumber = Int
	public typealias HardwareConfiguration = [RackNumber:[IOModule]]
	
	public var controlPanel:SoftPLCView!
	
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

	var status:SoftPLC.Status
	private var backGroundCycle:SoftPLCBackGroundCycle! = nil
	
	public init(hardwareConfig:HardwareConfiguration, ioList:IOList, simulator:IOSimulator? = nil){
		
		self.status = SoftPLC.Status()
		self.controlPanel = SoftPLCView(
			viewModel:status,
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
		
		
		self.backGroundCycle = SoftPLCBackGroundCycle(timeInterval: 0.250, mainLoop:{ [weak self] in self?.mainLoop() }, maxCycleTimeInMiliSeconds: self.status.maxCycleTime)
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
		if newValue != status.maxCycleTime{
			status.maxCycleTime = newValue
			backGroundCycle.maxCycleTime = newValue
		}
	}
	
	public func toggleSimulator(_ newState:Bool){
		
		if newState{
			status.executionType = .simulated(withHardware:true)
		}else{
			status.executionType = .normal
		}
		resetIOFailures()
		
	}
	
	public func toggleHardwareSimulation(_ newState:Bool){
		status.executionType = .simulated(withHardware:newState)
	}
	
	func resetIOFailures(){
		if case .simulated(_) = status.executionType {
			simulator?.ioFailure.reset()
		}else if case .normal = status.executionType {
			ioDrivers.forEach{$0.ioFailure.reset()}
		}
	}
	
	// MARK: - Main PLC Cycle
	
	func mainLoop()->Void{
		
		if case .simulated(let withHardware) = status.executionType, let simulator = self.simulator{
			
			simulator.readAllInputs()
			if simulator.ioFailure{ stop(reason: .ioFault) }
			
#if DEBUG
			if withHardware{
				// Overwrite PLC inputs with data of software simulated hardware,
				// before they get to be used as input parameters
				Debugger.shared.log(debugLevel:.Custom(icon:"⚙️"),"Simulating hardware")
				self.plcObjects.forEach { instanceName, object in
					(object as? Simulateable)?.simulateHardwareInputs()
				}
			}
			// And don't guard the Maximum Cycle Time while debugging
			backGroundCycle.numberOfOverruns = 0
#endif
			
			
			if self.status.runState == .running{
				
				self.plcObjects.forEach { instanceName, object in
					
					(object as? Parameterizable)?.assignInputParameters()
					
					(object as? CyclicRunnable)?.runCycle()
					
					(object as? Parameterizable)?.assignOutputParameters()
					
				}
			}
			
			simulator.writeAllOutputs()
			if simulator.ioFailure{ stop(reason: .ioFault) }
			
		}else if case .normal = status.executionType{
			
			self.ioDrivers.forEach{
				$0.readAllInputs()
				if $0.ioFailure{ stop(reason: .ioFault) }
			}
			
			
			if self.status.runState == .running{
				
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
		refreshBackgroundInfo()
	}
	
	public func run() {
		backGroundCycle.run()
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
	
	// MARK: - Populate ViewModel
	func refreshBackgroundInfo(){
		// At all times published variables should be changed on the main thread
		// even if they exist in the background
		DispatchQueue.main.async {
			self.status.runState = self.backGroundCycle.runState
			self.status.cycleTimeInMiliSeconds = self.backGroundCycle.cycleTimeInMiliSeconds
			self.status.maxCycleTime = self.backGroundCycle.maxCycleTime
		}
	}
	
}

// MARK: - ViewModel

extension SoftPLC{
	
	class Status:ObservableObject{
		
		@Published public var runState:SoftPLC.RunState = .stopped(reason: .manual)
		@Published public var cycleTimeInMiliSeconds:TimeInterval = 0
		@Published public var maxCycleTime:TimeInterval = 750
		@Published public var executionType:SoftPLC.ExecutionType = .normal
		
		public var stopReason:(String, String)?{
			if case let .stopped(reason: mainReason) = runState {
				var stopReason:(String, String) = (mainReason.rawValue, "")
				if mainReason == .maxCycleTime {
					stopReason.1 = String(format: "%04d", locale: Locale.current, Int(cycleTimeInMiliSeconds)) + " ms"
				}
				return stopReason
			}else{
				return nil
			}
		}
		
	}
	
}
