//
//  SoftPLCViewModel.swift
//  
//
//  Created by Jan Verrept on 10/11/2021.
//

import Foundation

extension SoftPLC{
	
	public class Status:ObservableObject{
		@Published public var runState:RunState = RunState.stopped(reason: .manual)
		@Published public var cycleTimeInMiliSeconds:TimeInterval = 0
		@Published public var maxCycleTime:TimeInterval = 750{
			didSet{
				if maxCycleTime != oldValue{
					//FIXME: - Reimplement this
					AppState.shared.plc.backGroundCycle.maxCycleTime = maxCycleTime
				}
			}
		}
		@Published public var executionType:ExecutionType = .normal

	}
	
}
