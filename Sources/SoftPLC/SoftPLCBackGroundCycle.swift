// SoftPLC.BackGroundCycle.swift
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

extension SoftPLC{
	
	public actor BackGroundCycle: Loggable {
		
		// MARK: - Configuration
		public private(set) var maxCycleTime: TimeInterval = 300 // in milliseconds
		public private(set) var maxNumberOfOverruns: Int = 3
		
		// MARK: - Current State
		public private(set) var runState: RunState = .stopped(reason: .manual)
		public private(set) var cycleTimeInMiliSeconds: TimeInterval = 0
		public private(set) var numberOfOverruns: Int = 0
		
		// MARK: - Internals
		private var cycleTask: Task<Void, Never>? = nil
		
		init(ioDrivers: [IODriver]){
			
		}
		
		
		// MARK: - Cycle Control
		public func run(within plc:SoftPLC, with config: SoftPLC.PLCConfiguration) {
			
			guard case .running = runState else { return }
			resetNumberOfOverruns()
			
			cycleTask = Task { [weak self] in
				guard let self else { return }
				await self.cycleLoop(within: plc, with:config)
			}
			
			runState = .running
		}
		
		public func stop(reason: StopReason) {
			guard case .running = runState else { return }

			cycleTask?.cancel()
			cycleTask = nil
			
			runState = .stopped(reason: reason)
		}
		
		
		// MARK: - Main Loop
		// Alternative found online
//		func measure<T>(
//			_ label: String,
//			block: () async throws -> T
//		) async rethrows -> T {
//			let start = ContinuousClock.now
//			let result = try await block()
//			print("\(label): \(ContinuousClock.now - start)")
//			return result
//		}
		private func cycleLoop(within plc:SoftPLC, with config: SoftPLC.PLCConfiguration) async {
			
			self.maxNumberOfOverruns = config.maxNumberOfOverruns
			self.maxCycleTime = config.maxCycleTime

			while !Task.isCancelled, case .running = runState {
				
				let cycleStart = Timestamp.currentTimestamp
				
				await plc.readAllInputs()
				await plc.executePLCObjectsCycle()
				await plc.writeAllOutputs()
				
				let cycleEnd = Timestamp.currentTimestamp
				self.cycleTimeInMiliSeconds = cycleEnd - cycleStart
				
				let currentState = State(
					runState: self.runState,
					cycleTimeInMiliSeconds: self.cycleTimeInMiliSeconds
				)
				await plc.updateViewModel(with: currentState)
				
				monitorCycletime(self.cycleTimeInMiliSeconds)
				
				await Task.yield()
			}

		}
		
		// MARK: - Cycle Monitoring
		public func setMaxCycleTime(_ value: TimeInterval) {
			maxCycleTime = value
			resetNumberOfOverruns()
		}
		
		private func monitorCycletime(_ currentCycleTime: TimeInterval) {
			guard currentCycleTime < maxCycleTime else {
				numberOfOverruns += 1
				SoftPLC.BackGroundCycle.logger.warning("Maximum PLC cycletime exceeded")
				
				guard numberOfOverruns < maxNumberOfOverruns else {
					SoftPLC.BackGroundCycle.logger.critical("Multiple PLC overruns")
					stop(reason: .maxCycleTime)
					return
				}
				return
			}
			
			resetNumberOfOverruns()
		}
		
		public func resetNumberOfOverruns() {
			self.numberOfOverruns = 0
		}
	}
	
}

// MARK: State
// The BackGroundCycle's current state on behalf of the PLC
extension SoftPLC.BackGroundCycle {
	
	public struct State:Sendable {
		public let runState: RunState
		public let cycleTimeInMiliSeconds: TimeInterval
	}
	
}

