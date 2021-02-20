//
//  IODriver.swift
//  
//
//  Created by Jan Verrept on 11/02/2021.
//

import Foundation
import IOTypes

// Define PLC-types
public protocol IODriver {
	
	var ioModules:[IOModule] {get set}
	var ioFailure:Bool {get}

	func readAllInputs()
	func writeAllOutputs()
	
}
public protocol IOSimulator:IODriver {}
