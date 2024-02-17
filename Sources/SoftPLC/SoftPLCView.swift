//
//  SoftPLCView.swift
//
//
//  Created by Jan Verrept on 24/11/2020.
//

import Foundation
import SwiftUI
import Neumorphic
import JVSwift

public struct SoftPLCView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var viewModel:SoftPLC.Status
    
    // Local bindings
    @State private var runButtonState:Bool = false
    @State private var maxCycletime:TimeInterval = 0.0
    @State private var simButtonState:Bool = false
    @State private var hardwareSimButtonState:Bool = false
    
    private var stopReason:String?{
        if case let .stopped(reason: mainReason) = viewModel.runState {
            var stopReason:String = mainReason.rawValue
            if mainReason == .maxCycleTime {
                let maxCycleTime:String = String(format: "%04d", locale: Locale.current, Int(viewModel.cycleTimeInMiliSeconds))
                stopReason += " \(maxCycleTime) ms"
            }
            return stopReason
        }else{
            return nil
        }
    }
    
    // Resulting Actions
    let togglePLCState:(_ newState:Bool)->Void
    let setMaxCycleTime:(_ newValue:TimeInterval)->Void
    let toggleSimulator:(_ newState:Bool)->Void
    let toggleHardwareSimulation:(_ newState:Bool)->Void
    
    public var body: some View {
        
        return VStack{
            Spacer()
            RunStopView(cycleTimeInMiliSeconds:viewModel.cycleTimeInMiliSeconds, stopReason: stopReason, runButtonState: $runButtonState, maxCycleTime: $maxCycletime)
                .onAppear{
                    runButtonState = (viewModel.runState == .running)
                    maxCycletime = viewModel.maxCycleTime
                }
                .onChange(of: runButtonState, perform: {togglePLCState($0)})
                .onChange(of: maxCycletime, perform: {setMaxCycleTime($0)})
            
            
            Spacer()
            SimulatorView(simButtonState: $simButtonState, hardwareSimButtonState: $hardwareSimButtonState)
                .onAppear{
                    if case .simulated(let withHardware) = viewModel.executionType{
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
        
        let cycleTimeInMiliSeconds:TimeInterval
        let stopReason:String?
        
        @Binding var runButtonState:Bool
        @Binding var maxCycleTime:TimeInterval
        
        var spinningAngle:Double{runButtonState ? 360.0 : 0.0}
        var spinningAnimation:Animation{
            if runButtonState{
                Animation.linear(duration: 0.5)
                    .repeatForever(autoreverses: false)
            }else{
                Animation.linear(duration: 0.0)
            }
        }
        @State var editMaxCycleTime:Bool = false
        
        public var body: some View {
            
            return HStack(){
                Spacer()
                Toggle(isOn:$runButtonState, label:{
                    Image(systemName:runButtonState ? "play.fill" : "stop.fill")
                        .foregroundColor(runButtonState ? .green : .red)
                })
                .softToggleStyle(Circle(), padding: 20, pressedEffect: .hard)
                .frame(width: 80)
                
                Button{ editMaxCycleTime = true } label: {
                    
                    Image(systemName: "clock.arrow.2.circlepath")
                        .scaleEffect(x: -1, y: 1) // Flip horizontally
                        .foregroundColor(.secondary)
                        .font(Font.body.weight(.bold))
                        .rotationEffect(Angle(degrees: spinningAngle))
                        .animation(spinningAnimation, value: spinningAngle)
                    
                }
                .buttonStyle(PlainButtonStyle())
                .help( Text("Click to adjust\nthe max. cycletime", bundle: .module) )
                .sheet(isPresented: $editMaxCycleTime) {
                    
                    MaxCycleTimeSheet(maxCycleTime: $maxCycleTime, editMaxCycleTime: $editMaxCycleTime)
                    
                }
                VStack(){
                    Text(runButtonState ? 
                         "PLC in RUN!\n[\(String(format: "%04d", locale: Locale.current, Int(cycleTimeInMiliSeconds))) ms]" :
                            "PLC in STOP!\n[\(stopReason ?? "")]"
                        , bundle: .module
                    )
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
        
        @Binding var maxCycleTime:TimeInterval
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
                Text("Adjust the maximum cycle time of the PLC", bundle: .module)
                TextField("", value: $fieldContent,
                          formatter: NumberFormatter()
                )
                .disableAutocorrection(true)
                .background(fieldColor)
                .frame(width:80)
                .multilineTextAlignment(.center)
                .onAppear{originalMaxCycleTime = maxCycleTime; fieldContent = originalMaxCycleTime}
                
                Text(fieldContentIsValidated ? "⚠️ Low entries may cause the PLC to stop!!!" : "🛑 VALUE OUT OF RANGE!!!", bundle: .module)
                
                
                HStack{
                    Button{
                        // Reset to the original value
                        maxCycleTime = originalMaxCycleTime
                        editMaxCycleTime = false
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                    Button{
                        // Limit maxCycleTime between boundaries
                        maxCycleTime = fieldContent.copyLimitedBetween(validationRange)
                        editMaxCycleTime = false
                    }label: {
                        Text("OK", bundle: .module)
                    }.disabled(!fieldContentIsValidated)
                    
                }
            }
            .frame(minWidth: 350)
            .padding()
        }
    }
}

extension SoftPLCView{
    
    public struct SimulatorView: View {
        
        @Binding var simButtonState:Bool
        @Binding var hardwareSimButtonState:Bool
        
        public var body: some View {
            VStack{
                Toggle(isOn:$simButtonState, label:{
                    Text("Run on simulator", bundle: .module)
                        .foregroundColor(.secondary)
                })
                
                Toggle(isOn:$hardwareSimButtonState, label:{
                    Text("Simulate hardware", bundle: .module)
                        .foregroundColor(.secondary)
                })
                .offset(x: 50.0, y: 0.0)
                .disabled(!simButtonState)
            }
        }
    }
}


// MARK: - Previews
#Preview {
    SoftPLCView.preview
}

