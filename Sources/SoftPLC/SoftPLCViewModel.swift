//
//  SoftPLCViewModel.swift
//
//
//  Created by Jan Verrept on 22/03/2024.
//

import Foundation
import Observation

extension SoftPLC{
	
	@Observable class ViewModel{
		
		var runState:RunState = .stopped(reason: .manual)
		var cycleTimeInMiliSeconds:TimeInterval = 0
		var maxCycleTime:TimeInterval = 750
		var executionType:ExecutionType = .normal
		
	}
	
}
