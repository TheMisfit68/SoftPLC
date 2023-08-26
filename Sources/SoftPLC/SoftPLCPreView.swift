//
//  SoftPLCPreView.swift
//  
//
//  Created by Jan Verrept on 29/12/2021.
//

import SwiftUI

extension SoftPLCView {
	
	public static let preview = SoftPLCView(
		viewModel:SoftPLC.Status(),
		togglePLCState:  {newState in },
		setMaxCycleTime: {newValue in },
		toggleSimulator: {newState in },
		toggleHardwareSimulation: {newState in }
	)
	
}

