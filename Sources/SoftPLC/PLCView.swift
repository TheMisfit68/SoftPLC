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
	@ObservedObject var plc:SoftPLC // Always detect changes in the PLCs status
	
	@State private var maxCycleTime:TimeInterval = 0
	@State private var runButtonState:Bool = false // Detect button actions that originated from here
	@State private var simButtonState:Bool = false // Detect button actions that originated from here
	
	var stopReason:String{
		if case let .stopped(reason: reason) = plc.status {
			return reason.rawValue
		}
		return ""
	}
	
	let togglePLCState:(_ newState:Bool)->Void
	let toggleSimulator:(_ newState:Bool)->Void
	
	
	public var body: some View {
		
		return VStack{
			Spacer()
			RunStopView(buttonState: $runButtonState,
						plcIsRunning:(plc.status == .running),
						stopReason: stopReason,
						cycleTime:plc.cycleTimeInMicroSeconds,
						maxCycleTime: $maxCycleTime
			)
			.onAppear{
				runButtonState = (plc.status == .running)
				maxCycleTime = plc.maxCycleTime
			}
			.onChange(of: runButtonState, perform: {togglePLCState($0)})
			.onChange(of: maxCycleTime, perform: {plc.maxCycleTime = $0})

			Spacer()
			SimulatorView(buttonState: $simButtonState)
				.onAppear{simButtonState = (plc.executionType == .simulated)}
				.onChange(of: simButtonState, perform: {toggleSimulator($0)})
			Spacer()
		}
	}
}

extension PLCView{
	
	public struct RunStopView: View {
		@Binding var buttonState:Bool
		let plcIsRunning:Bool
		let stopReason:String
		let cycleTime:TimeInterval
		@Binding var maxCycleTime:TimeInterval
		@State var editMaxCycleTime:Bool = false
		
		public var body: some View {
			
			return HStack(){
				Spacer()
				Toggle(isOn:$buttonState, label:{
					Image(systemName:plcIsRunning ? "play.fill" : "stop.fill")
						.foregroundColor(plcIsRunning ? .green : .red)
				})
				.softToggleStyle(Circle(), padding: 20, pressedEffect: .hard)
				.frame(width: 80)
				
				Button{ editMaxCycleTime = true } label: {
					Image(systemName: "clock.arrow.2.circlepath")
						.foregroundColor(.secondary)
						.font(Font.body.weight(.bold))
				}
				.buttonStyle(PlainButtonStyle())
				.help("Click to adjust\nthe max. cycletime")
				.sheet(isPresented: $editMaxCycleTime) {
					
					MaxCycleTimeSheet(editMaxCycleTime: $editMaxCycleTime, maxCycleTime: $maxCycleTime)
					
				}
				VStack(){
					Text(
						plcIsRunning ? "PLC in RUN!\n[\(String(format: "%07d", locale: Locale.current, Int(cycleTime))) µs]" : "PLC in STOP!\n[\(stopReason)]")
						.fontWeight(.bold)
						.foregroundColor(.secondary)
						.frame(width: 120, alignment: .leading)
				}
				Spacer()
			}
		}

	}
}

extension PLCView.RunStopView{
	
	public struct MaxCycleTimeSheet: View {
		
		@Binding var editMaxCycleTime:Bool
		@Binding var maxCycleTime:TimeInterval
		
		@State var originalMaxCycleTime:TimeInterval!
		@State var fieldContent:TimeInterval!
		@State var fieldColor = Color.red
		
		let validationRange:ClosedRange<TimeInterval> = (3000...500000)
		
		public var body: some View {
			
			VStack{
				Text("Adjust the maximum cycle time of the PLC")
				
				TextField("", value: $fieldContent,
						  formatter: NumberFormatter(),
						  onCommit: {maxCycleTime = fieldContent}
				)
				.disableAutocorrection(true)
				.border(fieldColor)
				.frame(width:80)
				.multilineTextAlignment(.center)
				.onAppear{originalMaxCycleTime = maxCycleTime; fieldContent = originalMaxCycleTime}
				
				Text("⚠️ Low entries may cause the PLC to stop!!!")
				
				
				HStack{
					Button("Cancel"){
						// Reset to the original value
						maxCycleTime = originalMaxCycleTime
						editMaxCycleTime = false
					}
					Button("OK"){
						// Limit maxCycleTime between boundaries
						maxCycleTime = fieldContent.copyLimitedBetween(validationRange)
						editMaxCycleTime = false
					}
				}
			}
			.padding()
		}
		
	}
}

extension PLCView{
	
	public struct SimulatorView: View {
		@Binding var buttonState:Bool
		
		public var body: some View {
			
			Toggle(isOn:$buttonState, label:{
				Text("Run on simulator")
					.foregroundColor(.secondary)
			})
		}
	}
}

