// SoftPLC.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import Foundation
import OSLog
import JVSwiftCore
import IOTypes
import MoxaDriver

@MainActor
open class SoftPLC: Loggable {
	
	public typealias IOList = [[[IOSymbol?]]]
	public typealias RackNumber = Int
	public typealias HardwareConfiguration = [RackNumber:[IOModule]]
	
	public var controlPanel: SoftPLCView!
	public var viewModel: SoftPLC.ViewModel
	
	public let hardwareConfig: HardwareConfiguration
//	public let ioDrivers: [IODriver]
	public let simulator: IOSimulator?
	public var variableList: [IOSymbol: SoftPLCVariable] = [:]
	public var plcObjects: [String: PLCClass] = [:] {
		didSet {
			plcObjects.forEach { key, object in
				object.plc = self
				object.instanceName = key
			}
		}
	}
	
	private var backGroundCycle: SoftPLC.BackGroundCycle! = nil
	
	public init(ioDrivers: [IODriver], hardwareConfig: HardwareConfiguration, ioList: IOList, simulator: IOSimulator? = nil) {
		
//		self.ioDrivers = ioDrivers
		self.viewModel = SoftPLC.ViewModel()
		self.hardwareConfig = hardwareConfig
		self.simulator = simulator
		self.controlPanel = SoftPLCView(
			viewModel: viewModel,
			togglePLCState: togglePLCState,
			setMaxCycleTime: setMaxCycleTime,
			toggleSimulator: toggleSimulator,
			toggleHardwareSimulation: toggleHardwareSimulation
		)
		
		self.importIO(list: ioList)
		
		
		// Init the backgroundCycle
		self.backGroundCycle = SoftPLC.BackGroundCycle(ioDrivers: ioDrivers)
	}
	
	// MARK: - PLC Lifecycle
	public func togglePLCState(_ newState: Bool){
		Task{
			if newState {
				await run()
			} else {
				await stop(reason: .manual)
			}
		}
	}
	
	public func run() async{
		let configuration = PLCConfiguration(
			maxNumberOfOverruns: 3,
			maxCycleTime: viewModel.maxCycleTime
		)
		await backGroundCycle.run(within: self, with: configuration)
	}
	
	public func stop(reason: StopReason) async{
		await backGroundCycle.stop(reason: reason)
	}
	
	// MARK: - Max Cycle Time
	
	public func setMaxCycleTime(_ newValue: TimeInterval) {
		guard newValue != viewModel.maxCycleTime else { return }
		viewModel.maxCycleTime = newValue
	}
	
	// MARK: - Simulator & IO Failures
	public func toggleSimulator(_ newState: Bool) {
		viewModel.executionType = newState ? .simulated(withHardware: true) : .normal
	}
	
	public func toggleHardwareSimulation(_ newState: Bool) {
		viewModel.executionType = .simulated(withHardware: newState)
	}
	
	
	// MARK: - Hooks for IO-handling and the main loop
	public func readAllInputs() async {
		if case .simulated(let withHardware) = viewModel.executionType, let simulator = self.simulator {
			do{
				try await simulator.readAllInputs()
			}catch{
				await stop(reason: .ioFault)
			}
			
#if DEBUG
			if withHardware {
				// Overwrite PLC inputs with data of software simulated hardware,
				// before they get to be used as input parameters
				
				SoftPLC.logger.log("⚙️\tSimulating hardware")
				plcObjects.forEach { _, object in
					(object as? Simulateable)?.simulateHardwareInputs()
				}
			}
			// And don't guard the Maximum Cycle Time while debugging
			await backGroundCycle.resetNumberOfOverruns()
			
#endif
			
		} else {
//			for driver in ioDrivers {
//				do{
//					try await driver.readAllInputs()
//				}catch{
//					await stop(reason: .ioFault)
//				}
//			}
		}
	}
	
	public func executePLCObjectsCycle() async{
		guard viewModel.runState == .running else { return }
		
		plcObjects.forEach { _, object in
			(object as? Parameterizable)?.assignInputParameters()
			(object as? CyclicRunnable)?.runCycle()
			(object as? Parameterizable)?.assignOutputParameters()
		}
	}
	
	public func writeAllOutputs() async {
		if case .simulated(_) = viewModel.executionType {
			do{
				try await simulator?.writeAllOutputs()
			}catch{
				await stop(reason: .ioFault)
			}
		} else {
//			for driver in ioDrivers {
//				do{
//					try await driver.writeAllOutputs()
//				}catch{
//					await stop(reason: .ioFault)
//				}
//			}
		}
		
	}
	
	public func updateViewModel(with backgroundState:BackGroundCycle.State) {
		viewModel.runState = backgroundState.runState
		viewModel.cycleTimeInMiliSeconds = backgroundState.cycleTimeInMiliSeconds
	}
	
	// MARK: - IO-Symbols management
	
	internal func importIO(list: IOList) {
		for (rackIndex, rack) in list.enumerated() {
			for (moduleIndex, module) in rack.enumerated() {
				for (channelIndex, channel) in module.enumerated() {
					if let ioSymbol = channel {
						let ioAddress: [Int] = [rackIndex, moduleIndex, channelIndex]
						let ioVariable = SoftPLCVariable(address: ioAddress, symbol: ioSymbol, description: ioSymbol.description)
						variableList[ioSymbol] = ioVariable
					}
				}
			}
		}
	}
	
	// TODO: - Reimplement once refactor to Swift Concurrency is done
//	public func signal(ioSymbol: IOSymbol) -> IOChannel? {
//		guard let ioVariable = variableList[ioSymbol] else { return nil }
//		
//		let rackNumber = ioVariable.address[0]
//		let moduleNr = ioVariable.address[1]
//		let channelNumber = ioVariable.address[2]
//		
//		let ioRack = hardwareConfig[rackNumber]
//		let ioModule = ioRack?[moduleNr]
//		let ioChannel = ioModule?.[channelNumber].getValue()
//		return ioChannel
//	}
}

// MARK: Sendability
// The PLC's config settings on behalf of its backgroundCycle
extension SoftPLC {
	
	public struct PLCConfiguration:Sendable {
		public let maxNumberOfOverruns: Int
		public let maxCycleTime: TimeInterval
	}
	
}
