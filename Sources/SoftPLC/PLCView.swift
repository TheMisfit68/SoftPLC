//
//  PLCView.swift
//  
//
//  Created by Jan Verrept on 24/11/2020.
//

import Foundation
import SwiftUI
import Neumorphic
import JVCocoa

public struct PLCView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var plcBackGroundCyle:PLCBackgroundCycle // Always detect changes in the PLCs status
    @State private var runButtonState:Bool = false// Detect button actions that originated from here
    @State private var simButtonState:Bool = true // TODO: - Sync with the actual state like runButtonState
    let togglePLCState:(_ newState:Bool)->Void
    let toggleSimulator:(_ newState:Bool)->Void
    
    public var body: some View {
        Neumorphic.shared.colorScheme = colorScheme
        
        return VStack{
            Spacer()
			RunStopView(buttonState: $runButtonState,
						plcIsRunning:(plcBackGroundCyle.status == .running),
						cycleTime:Int(plcBackGroundCyle.cycleTimeInMicroSeconds)
			)
			.onAppear{runButtonState = (plcBackGroundCyle.status == .running)}
			.onChange(of: runButtonState, perform: {togglePLCState($0)})
            Spacer()
            SimulatorView(buttonState: $simButtonState)
				.onAppear{runButtonState = (plcBackGroundCyle.status == .running)}
                .onChange(of: simButtonState, perform: {toggleSimulator($0)})
            Spacer()
        }
    }
}

extension PLCView{
    
    public struct RunStopView: View {
        @Binding var buttonState:Bool
        let plcIsRunning:Bool
		let cycleTime:Int
        
        public var body: some View {
            
            return HStack(){
                Spacer()
                Toggle(isOn:$buttonState, label:{
                    Image(systemName:plcIsRunning ? "play.fill" : "stop.fill")
                        .foregroundColor(plcIsRunning ? .green : .red)
                })
                .softToggleStyle(Circle(), padding: 20, pressedEffect: .hard)
                .frame(width: 80)

                Text(plcIsRunning ? "PLC in RUN!\n[\(cycleTime) µs]" : "PLC in STOP!")
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
                Spacer()
            }
            
        }
        
    }
}

extension PLCView{
    
    public struct SimulatorView: View {
        @Binding var buttonState:Bool
        
        public var body: some View {
            
            Toggle(isOn:$buttonState, label:{
                Text("Run on simulator")
            })
        }
    }
}




