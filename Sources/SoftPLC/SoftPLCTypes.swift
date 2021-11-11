//
//  SoftPLCTypes.swift
//  
//
//  Created by Jan Verrept on 10/11/2021.
//

import Foundation

extension SoftPLC{
	
	public enum RunState:Equatable{
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
	
}
