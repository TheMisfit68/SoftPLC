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
    
    
    public enum IOSymbol:Hashable{
        
        case measurement(circuit:String)
        
        case setpoint(circuit:String)
        
        case start(circuit:String)
        case stop(circuit:String)
        case functionKey(circuit:String)
        case feedbackOn(circuit:String)
        case feedbackEnabled(circuit:String)
        case feedbackOpening(circuit:String)
        case feedbackClosing(circuit:String)
        case feedbackOpen(circuit:String)
        case feedbackClosed(circuit:String)
        case feedbackTurningLeft(circuit:String)
        case feedbackTurningRight(circuit:String)
        
        case toggle(circuit:String)
        case on(circuit:String)
        case enable(circuit:String)
        case open(circuit:String)
        case close(circuit:String)
        case left(circuit:String)
        case right(circuit:String)
        
        case custom(description:String)
        
        var description:String{
            
            switch self {
            case .measurement(let circuit):
                let symbolType = String(localized:"Measurement", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .setpoint(circuit: let circuit):
                let symbolType = String(localized:"Setpoint", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .start(circuit: let circuit):
                let symbolType = String(localized:"Start", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .stop(circuit: let circuit):
                let symbolType = String(localized:"Stop", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .functionKey(circuit: let circuit):
                let symbolType = String(localized:"Function key", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackOn(circuit: let circuit):
                let symbolType = String(localized:"Feedback On", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackEnabled(circuit: let circuit):
                let symbolType = String(localized:"Feedback Enabled", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackOpening(circuit: let circuit):
                let symbolType = String(localized:"Feedback Opening", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackClosing(circuit: let circuit):
                let symbolType = String(localized:"Feedback Closing", table: "IOSymbolTypes", bundle: .module)
                return "\(circuit) \(symbolType)"
            case .feedbackOpen(circuit: let circuit):
                let symbolType = String(localized:"Feedback Open", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackClosed(circuit: let circuit):
                let symbolType = String(localized:"Feedback Closed", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackTurningLeft(circuit: let circuit):
                let symbolType = String(localized:"Feedback Turning Left", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .feedbackTurningRight(circuit: let circuit):
                let symbolType = String(localized:"Feedback Turning Right", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .toggle(circuit: let circuit):
                let symbolType = String(localized:"Toggle", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .on(circuit: let circuit):
                let symbolType = String(localized:"On", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .enable(circuit: let circuit):
                let symbolType = String(localized:"Enable", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .open(circuit: let circuit):
                let symbolType = String(localized:"Open", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .close(circuit: let circuit):
                let symbolType = String(localized:"Close", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .left(circuit: let circuit):
                let symbolType = String(localized:"Left", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .right(circuit: let circuit):
                let symbolType = String(localized:"Right", table: "IOSymbolTypes", bundle: .module)            
                return "\(circuit) \(symbolType)"
            case .custom(description: let description):
                return description
            }
        }
        
    }
}

