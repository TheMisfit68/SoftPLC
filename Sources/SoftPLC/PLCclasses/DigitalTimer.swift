//
//  DigitalTimer.swift
//  HAPiNest
//
//  Created by Jan Verrept on 13/08/2020.
//  Copyright © 2020 Jan Verrept. All rights reserved.
//

import Foundation

open class DigitalTimer:PLCClass{
	
	private var workItem: DispatchWorkItem?

	private var actionToken: UUID?
	private var risingEdge:Bool = false
	private var fallingEdge:Bool = false
	
	public var input:Bool = false
	public let timeValue:TimeInterval
	public var output:Bool = false
	
	public init(time:TimeInterval){
		self.timeValue = time
	}
	
	func delayAction(_ delayedAction: @escaping () -> Void) {
		
		// Cancel the previous work item if it exists
		workItem?.cancel()
		
		// Create a new work item
		let newWorkItem = DispatchWorkItem(block: delayedAction)
		self.workItem = newWorkItem
		
		DispatchQueue.main.asyncAfter(deadline: .now() + timeValue, execute: newWorkItem)
		 
	}
	
	public func reset() {
		
		workItem?.cancel()
		self.output = false
		
	}
	
}

extension DigitalTimer{
	
	open class OnDelay:DigitalTimer{
		
		public var action:() -> Void
		
		public init(time:TimeInterval = 1.0, _ action:@escaping ()->Void = {} ){
			self.action = action
			super.init(time: time)
		}
		
		
		public override var input:Bool {
			
			didSet{
				risingEdge = input && !oldValue
				fallingEdge = !input && oldValue
				
				if risingEdge{
					
					delayAction{
						self.output = self.input
						if self.output{
							self.action()
						}
					}
					
				}else if fallingEdge{
					output = input
				}
			}
			
		}
	}
}


extension DigitalTimer{
	
	open class OffDelay:DigitalTimer{
		
		public override var input:Bool {
			
			didSet{
				risingEdge = input && !oldValue
				fallingEdge = !input && oldValue
				
				if risingEdge{
					output = input
				}else if fallingEdge{
					
					delayAction{self.output = self.input}
					
				}
				
			}
			
		}
	}
}

extension DigitalTimer{
	
	open class PulsLimition:DigitalTimer{
		
		public override var input:Bool {
			didSet{
				
				risingEdge = input && !oldValue
				fallingEdge = !input && oldValue
				
				if risingEdge{
					
					output = input
					delayAction{self.output = false}
					
				}else if fallingEdge{
					output = input
				}
				
			}
			
		}
	}
}

extension DigitalTimer{
	
	open class ExactPuls:DigitalTimer{
		
		public override var input:Bool {
			didSet{
				risingEdge = input && !oldValue
				fallingEdge = !input && oldValue
				
				if risingEdge{
					output = input
					delayAction{self.output = false}
				}else if fallingEdge{
					// Do nothing on the faling edge
				}
				
			}
		}
		
	}
}
