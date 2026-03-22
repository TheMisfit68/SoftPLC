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
import MQTTNIO

@MainActor
open class SoftPLC: Loggable {
    
    public typealias IOList = [[[IOSymbol?]]]
    public typealias RackNumber = Int
    public typealias HardwareConfiguration = [RackNumber: [IOModule]]
    
    public var controlPanel: SoftPLCView!
    public var viewModel: SoftPLC.ViewModel
    
    public let hardwareConfig: HardwareConfiguration
    public let simulatedHardware: HardwareConfiguration?
    public var mqttClient: MQTTNIO.MQTTClient? = nil
    
    // Resolve the hardware configuration that is currently active for this cycle.
    private var simulationMode: Bool {
        if case .simulated(_) = viewModel.executionType {
            return true
        } else {
            return false
        }
    }
    private var activeHardwareConfig: HardwareConfiguration {
        if simulationMode, let simulatedHardware = self.simulatedHardware {
            return simulatedHardware
        } else {
            return hardwareConfig
        }
    }
    
    public var variableList: [IOSymbol: SoftPLCVariable] = [:]
    public var plcObjects: [String: PLCClass] = [:] {
        didSet {
            plcObjects.forEach { key, object in
                object.plc = self
                object.instanceName = key
            }
        }
    }
    
    public func addObject(_ object: PLCClass) {
        guard object.instanceName.isEmpty == false else { return }
        object.plc = self
        plcObjects[object.instanceName] = object
    }
    
    private var inputImage: [RackNumber: [PLCValues]] = [:]
    private var outputImage: [RackNumber: [PLCValues]] = [:]
    private var backGroundCycle: SoftPLC.BackGroundCycle! = nil
    
    public init(hardwareConfig: HardwareConfiguration, ioList: IOList, simulatedHardware: HardwareConfiguration? = nil) {
        self.viewModel = SoftPLC.ViewModel()
        self.hardwareConfig = hardwareConfig
        self.simulatedHardware = simulatedHardware
        self.inputImage = Self.makeInitialImage(from: hardwareConfig)
        self.outputImage = Self.makeInitialImage(from: hardwareConfig)
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
        
        do {
            try await readAllModuleInputs(from: activeHardwareConfig)
        } catch {
            await stop(reason: .ioFault)
            return
        }
        
        if simulatedHardware != nil, case .simulated(let withHardware) = viewModel.executionType {
            
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
            
        }
    }
    
    public func executePLCObjectsCycle() async {
        plcObjects.forEach { _, object in
            (object as? Parameterizable)?.assignInputParameters()
            (object as? CyclicRunnable)?.runCycle()
            (object as? Parameterizable)?.assignOutputParameters()
        }
    }
    
    public func writeAllOutputs() async {
        
        do {
            try await writeAllModuleOutputs(from: activeHardwareConfig)
        } catch {
            await stop(reason: .ioFault)
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
    
    
    // Get and Set signals in the IO-Images
    public func signal(ioSymbol: IOSymbol) -> PLCValue? {

        guard let ioVariable = variableList[ioSymbol] else { return nil }

        guard ioVariable.address.count == 3 else { return nil }

        let rackNumber = ioVariable.address[0]
        let moduleNumber = ioVariable.address[1]
        let channelNumber = ioVariable.address[2]
        let ioRack = inputImage[rackNumber]!
        let ioModuleImage = ioRack[moduleNumber]
        return ioModuleImage[channelNumber]
    }
    
    public func setOutputSignal(_ ioSignal: PLCValue, for ioSymbol: IOSymbol) {

        guard let ioVariable = variableList[ioSymbol] else { return }
        guard ioVariable.address.count == 3 else { return }
        
        let rackNumber = ioVariable.address[0]
        let moduleNumber = ioVariable.address[1]
        let channelNumber = ioVariable.address[2]
                
        var ioRack = outputImage[rackNumber]!
                
        var ioModuleImage = ioRack[moduleNumber]
        ioModuleImage[channelNumber] = ioSignal
        ioRack[moduleNumber] = ioModuleImage
        outputImage[rackNumber] = ioRack
    }
    
    // MARK: - Size the IO-Images to the correct size
    private static func makeInitialImage(from hardwareConfig: HardwareConfiguration) -> [RackNumber: [PLCValues]] {
        Dictionary(uniqueKeysWithValues: hardwareConfig.map { rackNumber, modules in
            let moduleSnapshots = modules.map { module in
                Array<PLCValue?>(repeating: nil, count: module.layout.channels.count)
            }
            return (rackNumber, moduleSnapshots)
        })
    }
    
    private func readAllModuleInputs(from hardwareConfig: HardwareConfiguration) async throws {
        for rackNumber in hardwareConfig.keys.sorted() {
            let ioRack = hardwareConfig[rackNumber]!
            
            for ioModule in ioRack {
                try await ioModule.readInputChannels()
                try await ioModule.readOutputChannels()
            }
        }
        
        await getInputImage(from: hardwareConfig)
        
    }
    
    private func writeAllModuleOutputs(from hardwareConfig: HardwareConfiguration) async throws {
        
        await setOutputImage(at: hardwareConfig)
        
        for rackNumber in hardwareConfig.keys.sorted() {
            let ioRack = hardwareConfig[rackNumber]!
            
            for ioModule in ioRack {
                try await ioModule.writeOutputChannels()
            }
        }
    }
    
    // MARK: - Get en Set resulting IO-Images from and to the hardware
    private func getInputImage(from hardwareConfig: HardwareConfiguration) async {
        var plcInputImage: [RackNumber: [PLCValues]] = [:]
        
        // Iterate through the IO-racks
        for rackNumber in hardwareConfig.keys.sorted() {
            let ioRack = hardwareConfig[rackNumber]!
            
            // Iterate through the IO-modules and append their image to the PLC's input image
            var ioRackImages: [PLCValues] = []
            for ioModule in ioRack {
                let snapshot = await ioModule.inputImage()
                ioRackImages.append(snapshot)
            }
            
            plcInputImage[rackNumber] = ioRackImages
        }
        
        self.inputImage = plcInputImage
    }
    
    private func setOutputImage(at hardwareConfig: HardwareConfiguration) async {
        
        // Iterate through the IO-racks
        for rackNumber in hardwareConfig.keys.sorted() {
            let plcOutputRack = self.outputImage[rackNumber]!
            let ioRack = hardwareConfig[rackNumber]!
            
            // Iterate through the PLC-modules and use their image as the snapshot for the IO
            for (moduleIndex, plcModule) in plcOutputRack.enumerated() {
                let snapshot = plcModule
                let ioModule = ioRack[moduleIndex]
                await ioModule.applyOutputImage(using: snapshot)
            }
        }
        
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
