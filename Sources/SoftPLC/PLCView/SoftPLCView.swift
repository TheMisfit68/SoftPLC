//
//  SoftPLCView.swift
//
//
//  Created by Jan Verrept on 24/11/2020.
//

import Foundation
import SwiftUI
import Neumorphic
import JVCocoa

public struct SoftPLCView: View {
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	@EnvironmentObject private var plcStatus: SoftPLC.Status

 	@State private var runButtonState:Bool = false // Detect button actions that originated from here
	@State private var simButtonState:Bool = false // Detect button actions that originated from here
	@State private var hardwareSimButtonState:Bool = false // Detect button actions that originated from here
	
	let togglePLCState:(_ newState:Bool)->Void
	let toggleSimulator:(_ newState:Bool)->Void
	let toggleHardwareSimulation:(_ newState:Bool)->Void
	
	public var body: some View {
		
		return VStack{
			Spacer()
			RunStopView(runButtonState: $runButtonState)
				.onAppear{
					runButtonState = (plcStatus.runState == .running)
				}
				.onChange(of: runButtonState, perform: {togglePLCState($0)})
			
			Spacer()
			SimulatorView(simButtonState: $simButtonState, hardwareSimButtonState: $hardwareSimButtonState)
				.onAppear{
					if case .simulated(let withHardware) = plcStatus.executionType{
						simButtonState = true
						hardwareSimButtonState = withHardware
					}else{
						simButtonState = false
						hardwareSimButtonState = false
					}
				}
				.onChange(of: simButtonState, perform: {
					toggleSimulator($0)
					hardwareSimButtonState = $0
				})
				.onChange(of: hardwareSimButtonState, perform: {
					if simButtonState{
						toggleHardwareSimulation($0)
					}
				})
			Spacer()
		}
	}
}


extension SoftPLCView{
	
	public struct RunStopView: View {
		@EnvironmentObject private var plcStatus: SoftPLC.Status
		
		@Binding var runButtonState:Bool
		@State var editMaxCycleTime:Bool = false
		
		var stopReason:(String, String){
			if case let .stopped(reason: reason) = plcStatus.runState {
				var stopReason:(String, String) = (reason.rawValue, "")
				if reason == .maxCycleTime {
					stopReason.1 = String(format: "%04d", locale: Locale.current, Int(plcStatus.cycleTimeInMiliSeconds)) + " ms"
				}
				return stopReason
			}
			return ("", "")
		}
		
		public var body: some View {
			
			return HStack(){
				Spacer()
				Toggle(isOn:$runButtonState, label:{
					Image(systemName:plcStatus.runState == .running ? "play.fill" : "stop.fill")
						.foregroundColor(plcStatus.runState == .running ? .green : .red)
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
					
					MaxCycleTimeSheet(editMaxCycleTime: $editMaxCycleTime)
					
				}
				VStack(){
					Text(
						plcStatus.runState == .running ? "PLC in RUN!\n[\(String(format: "%04d", locale: Locale.current, Int(plcStatus.cycleTimeInMiliSeconds))) ms]" : "PLC in STOP!\n[\(stopReason.0) \(stopReason.1)]")
						.fontWeight(.bold)
						.foregroundColor(.secondary)
						.frame(width: 200, alignment: .leading)
				}
				Spacer()
			}
		}
		
	}
}

extension SoftPLCView.RunStopView{
	
	public struct MaxCycleTimeSheet: View {
		@EnvironmentObject private var plcStatus: SoftPLC.Status
		
		@Binding var editMaxCycleTime:Bool
		
		@State var originalMaxCycleTime:TimeInterval! = nil
		@State var fieldContent:TimeInterval = 0
		
		let validationRange:ClosedRange<TimeInterval> = (10...750)
		var fieldContentIsValidated:Bool{
			validationRange.contains(fieldContent)
		}
		var fieldColor:Color{
			fieldContentIsValidated ? Color.clear : Color.red.opacity(0.2)
		}
		
		public var body: some View {
			
			VStack{
				Text("Adjust the maximum cycle time of the PLC")
				
				// FIXME: - Add keyboardtype modifier to this textfield
				// when it bcomes available for MacOS or
				// check if binding $fieldContent updates while typing
				// currently it does not when used with a formatter due to a bug
				TextField("", value: $fieldContent,
						  formatter: NumberFormatter()
				)
					.disableAutocorrection(true)
					.background(fieldColor)
					.frame(width:80)
					.multilineTextAlignment(.center)
					.onAppear{originalMaxCycleTime = plcStatus.maxCycleTime; fieldContent = originalMaxCycleTime}
				
				Text(fieldContentIsValidated ? "⚠️ Low entries may cause the PLC to stop!!!" : "🛑 VALUE OUT OF RANGE!!!")
				
				
				HStack{
					Button("Cancel"){
						// Reset to the original value
						plcStatus.maxCycleTime = originalMaxCycleTime
						editMaxCycleTime = false
					}
					Button("OK"){
						// Limit maxCycleTime between boundaries
						plcStatus.maxCycleTime = fieldContent.copyLimitedBetween(validationRange)
						editMaxCycleTime = false
					}.disabled(!fieldContentIsValidated)
					
				}
			}
			.padding()
		}
	}
}

extension SoftPLCView{
	
	public struct SimulatorView: View {
		@EnvironmentObject private var plcStatus: SoftPLC.Status

		@Binding var simButtonState:Bool
		@Binding var hardwareSimButtonState:Bool
		
		public var body: some View {
			VStack{
				Toggle(isOn:$simButtonState, label:{
					Text("Run on simulator")
						.foregroundColor(.secondary)
				})
				
				Toggle(isOn:$hardwareSimButtonState, label:{
					Text("Simulate hardware")
						.foregroundColor(.secondary)
				})
					.padding(.leading, 50)
					.disabled(!simButtonState)
			}
		}
	}
}

