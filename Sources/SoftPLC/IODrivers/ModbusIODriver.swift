//
//  ModbusIODriver.swift
//  
//
//  Created by Jan Verrept on 11/02/2021.
//

import Foundation
import ModbusDriver
import IOTypes

// Make Modbus-Types conform to PLC-Types
extension ModbusDriver:IODriver{

	public var ioModules: [IOModule] {
		get {
			return modbusModules
		}
		set {
			modbusModules = (newValue as! [ModbusModule])
		}
	}
	
	public var ioFailure:Bool {
		get{
		(connectionState != .connected) && (errorCount > maxErrorCount)
		}
		set{
			if newValue == false{
				errorCount = 0
			}
		}
	}
}
