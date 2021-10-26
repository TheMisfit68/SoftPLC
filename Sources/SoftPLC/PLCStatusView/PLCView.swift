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
	@State private var hardwareSimButtonState:Bool = false // Detect button actions that originated from here
	
	var stopReason:(String, String){
		if case let .stopped(reason: reason) = plc.status {
			var stopReason:(String, String) = (reason.rawValue, "")
			if reason == .maxCycleTime {
				stopReason.1 = String(format: "%04d", locale: Locale.current, Int(plc.cycleTimeInMiliSeconds)) + " ms"
			}
			return stopReason
		}
		return ("", "")
	}
	
	let togglePLCState:(_ newState:Bool)->Void
	let toggleSimulator:(_ newState:Bool)->Void
	let toggleHardwareSimulation:(_ newState:Bool)->Void
	
	
	public var body: some View {
		
		return VStack{
			Spacer()
			RunStopView(buttonState: $runButtonState,
						plcIsRunning:(plc.status == .running),
						stopReason: stopReason,
						cycleTime:plc.cycleTimeInMiliSeconds,
						maxCycleTime: $maxCycleTime
			)
				.onAppear{
					runButtonState = (plc.status == .running)
					maxCycleTime = plc.maxCycleTime
				}
				.onChange(of: runButtonState, perform: {togglePLCState($0)})
				.onChange(of: maxCycleTime, perform: {plc.maxCycleTime = $0})
			
			Spacer()
			SimulatorView(simButtonState: $simButtonState, hardwareSimButtonState: $hardwareSimButtonState)
				.onAppear{
					if case .simulated(let withHardware) = plc.executionType{
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


extension PLCView{
	
	public struct RunStopView: View {
		@Binding var buttonState:Bool
		let plcIsRunning:Bool
		let stopReason:(String, String)
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
						plcIsRunning ? "PLC in RUN!\n[\(String(format: "%04d", locale: Locale.current, Int(cycleTime))) ms]" : "PLC in STOP!\n[\(stopReason.0) \(stopReason.1)]")
						.fontWeight(.bold)
						.foregroundColor(.secondary)
						.frame(width: 200, alignment: .leading)
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
					.onAppear{originalMaxCycleTime = maxCycleTime; fieldContent = originalMaxCycleTime}
				
				Text(fieldContentIsValidated ? "⚠️ Low entries may cause the PLC to stop!!!" : "🛑 VALUE OUT OF RANGE!!!")
				
				
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
					}.disabled(!fieldContentIsValidated)
					
				}
			}
			.padding()
		}
	}
}

extension PLCView{
	
	public struct SimulatorView: View {
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

