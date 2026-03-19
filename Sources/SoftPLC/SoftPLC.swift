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
    public typealias HardwareConfiguration = [RackNumber: [IOModule]]
    
    public var controlPanel: SoftPLCView!
    public var viewModel: SoftPLC.ViewModel
    
    public let hardwareConfig: HardwareConfiguration
    public let simulatedHardware: HardwareConfiguration?
    public var variableList: [IOSymbol: SoftPLCVariable] = [:]
    public var plcObjects: [String: PLCClass] = [:] {
        didSet {
            plcObjects.forEach { key, object in
                object.plc = self
                object.instanceName = key
            }
        }
    }
    
    private var moduleImages: [RackNumber: [PLCValues]] = [:]
    private var backGroundCycle: SoftPLC.BackGroundCycle! = nil
    
    public init(hardwareConfig: HardwareConfiguration, ioList: IOList, simulatedHardware: HardwareConfiguration? = nil) {
        self.viewModel = SoftPLC.ViewModel()
        self.hardwareConfig = hardwareConfig
        self.simulatedHardware = simulatedHardware
        self.controlPanel = SoftPLCView(
            viewModel: viewModel,
            togglePLCState: togglePLCState,
            setMaxCycleTime: setMaxCycleTime,
            toggleSimulator: toggleSimulator,
            toggleHardwareSimulation: toggleHardwareSimulation
        )
        
        self.importIO(list: ioList)
        
        // Init the backgroundCycle
        self.backGroundCycle = SoftPLC.BackGroundCycle()
    }
    
    // MARK: - PLC Lifecycle
    public func togglePLCState(_ newState: Bool) {
        Task {
            if newState {
                await run()
            } else {
                await stop(reason: .manual)
            }
        }
    }
    
    public func run() async {
        let configuration = PLCConfiguration(
            maxNumberOfOverruns: 3,
            maxCycleTime: viewModel.maxCycleTime
        )
        await backGroundCycle.run(within: self, with: configuration)
    }
    
    public func stop(reason: StopReason) async {
        await backGroundCycle.stop(reason: reason)
    }
    
    // MARK: - Max Cycle Time
    public func setMaxCycleTime(_ newValue: TimeInterval) {
        guard newValue != viewModel.maxCycleTime else { return }
        viewModel.maxCycleTime = newValue
		Task {
			await backGroundCycle.setMaxCycleTime(newValue)
		}
    }
    
    // MARK: - simulatedHardware & IO Failures
    public func toggleSimulator(_ newState: Bool) {
        viewModel.executionType = newState ? .simulated(withHardware: true) : .normal
    }
    
    public func toggleHardwareSimulation(_ newState: Bool) {
        viewModel.executionType = .simulated(withHardware: newState)
    }
    
    
    // MARK: - Hooks for IO-handling and the main loop
    public func readAllInputs() async {
        if case .simulated(let withHardware) = viewModel.executionType, let simulatedHardware = self.simulatedHardware {
				
            do {
                try await readAllModuleInputs(from: simulatedHardware)
                await getModuleImages(from: simulatedHardware)
            } catch {
                await stop(reason: .ioFault)
                return
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
            do {
                try await readAllModuleInputs(from: hardwareConfig)
                await getModuleImages(from: hardwareConfig)
            } catch {
                await stop(reason: .ioFault)
            }
        }
    }
    
    public func executePLCObjectsCycle() async {
        guard viewModel.runState == .running else { return }
        
        plcObjects.forEach { _, object in
            (object as? Parameterizable)?.assignInputParameters()
            (object as? CyclicRunnable)?.runCycle()
            (object as? Parameterizable)?.assignOutputParameters()
        }
    }
    
    public func writeAllOutputs() async {
        if case .simulated(_) = viewModel.executionType, let simulatedHardware = simulatedHardware {
            do {
                try await writeAllModuleOutputs(from: simulatedHardware)
            } catch {
                await stop(reason: .ioFault)
            }
        } else {
            do {
                try await writeAllModuleOutputs(from: hardwareConfig)
            } catch {
                await stop(reason: .ioFault)
            }
        }
        
    }
    
    public func updateViewModel(with backgroundState: BackGroundCycle.State) {
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
    
    public func signal(ioSymbol: IOSymbol) -> PLCValue? {
        guard let ioVariable = variableList[ioSymbol] else { return nil }
        
        guard ioVariable.address.count == 3 else { return nil }
        
        let rackNumber = ioVariable.address[0]
        let moduleNr = ioVariable.address[1]
        let channelNumber = ioVariable.address[2]
        
        guard let ioRack = moduleImages[rackNumber], ioRack.indices.contains(moduleNr) else {
            return nil
        }
        
        let ioModuleImage = ioRack[moduleNr]
        guard ioModuleImage.indices.contains(channelNumber) else {
            return nil
        }
        
        return ioModuleImage[channelNumber]
    }
    
	// MARK: - Helper functions for both types of hardwareconfiguration
    private func readAllModuleInputs(from hardwareConfig: HardwareConfiguration) async throws {
        for rackNumber in hardwareConfig.keys.sorted() {
            guard let ioRack = hardwareConfig[rackNumber] else { continue }
            
            for ioModule in ioRack {
                try await ioModule.readInputChannels()
                try await ioModule.readOutputChannels()
            }
        }
    }
    
    private func writeAllModuleOutputs(from hardwareConfig: HardwareConfiguration) async throws {
        for rackNumber in hardwareConfig.keys.sorted() {
            guard let ioRack = hardwareConfig[rackNumber] else { continue }
            
            for ioModule in ioRack {
                try await ioModule.writeOutputChannels()
            }
        }
    }
    
    private func getModuleImages(from hardwareConfig: HardwareConfiguration) async {
        var updatedImages: [RackNumber: [PLCValues]] = [:]
        
        for rackNumber in hardwareConfig.keys.sorted() {
            guard let ioRack = hardwareConfig[rackNumber] else { continue }
            
            var ioRackImages: [PLCValues] = []
            for ioModule in ioRack {
                let ioModuleImage = await ioModule.image
                ioRackImages.append(ioModuleImage)
            }
            
            updatedImages[rackNumber] = ioRackImages
        }
        
        moduleImages = updatedImages
    }
}

// MARK: Sendability
// The PLC's config settings on behalf of its backgroundCycle
extension SoftPLC {
    
    public struct PLCConfiguration: Sendable {
        public let maxNumberOfOverruns: Int
        public let maxCycleTime: TimeInterval
    }
    
}

