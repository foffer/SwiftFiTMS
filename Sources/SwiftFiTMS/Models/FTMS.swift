//
//  FiTMS.swift
//
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import CoreBluetooth


/// The base structure of a `Fitness Machine Service` device
public struct FTMS {
    /// The service describing the `Fitness Machine Service Protocol`
    /// Please see https://bitbucket.org/bluetooth-SIG/public/src/080066292a434e95e42107c782b8ac9618e68e2c/assigned_numbers/uuids/service_uuids.yaml#lines-140
    /// or the `Assigned Numbers` PDF from the Bluetooth SIG https://www.bluetooth.com/specifications/specs/fitness-machine-service-1-0/
    struct Service {
        static let uuid = CBUUID(string: "0x1826")
    }
    
    /// A definition of service characteristics can be found in the FTMS v1.0 Bluetooth spec in chapter 4 - Service Characteristics
    ///
    public enum Characteristic: String, CaseIterable {
        /**
         This field is mandatory
        The Fitness Machine Feature characteristic shall be used to describe the supported features of the Server.
        The Fitness Machine Feature characteristic exposes which optional features are supported by the Server implementation.
        
         When read, the Fitness Machine Feature characteristic returns a value containing two fields: Fitness
        Machine Features and Target Setting Features. Each field is a bit field that may be used by a Client to
        determine the supported features of the Server as defined below.
         */
        case fitnessMachineFeature = "0x2ACC"
        
       /**
        The Treadmill Data characteristic is used to send training-related data to the Client from a treadmill
        (Server). Included in the characteristic value is a Flags field (for showing the presence of optional fields)
        and depending upon the contents of the Flags field, it may include one or more optional fields as defined
        on the Bluetooth SIG Assigned Numbers webpage
        */
        case treadmill = "0x2ACD"
        
        /**
         The Cross Trainer Data characteristic is used to send training-related data to the Client from a cross
         trainer (Server). Included in the characteristic value is a Flags field (for showing the presence of optional
         fields and movement direction), and depending upon the contents of the Flags field, it may include one or
         more optional fields as defined on the Bluetooth SIG Assigned Numbers webpage
         */
        case crossTrainer = "0x2ACE"
        
        /**
         The Stair Climber Data characteristic is used to send training-related data to the Client from a stair
         climber (Server). Included in the characteristic value is a Flags field (for showing the presence of optional
         fields), and depending upon the contents of the Flags field, it may include one or more optional fields as
         defined on the Bluetooth SIG Assigned Numbers webpage
         */
        case stairClimber = "0x2AD0"
        
        /**
         The Rower Data characteristic is used to send training-related data to the Client from a rower (Server).
         Included in the characteristic value is a Flags field (for showing the presence of optional), and depending
         upon the contents of the Flags field, it may include one or more optional fields as defined on the Bluetooth
         SIG Assigned Numbers webpage
         */
        case rower = "0x2AD1"
        
        /**
         The Indoor Bike Data characteristic is used to send training-related data to the Client from an indoor bike
         (Server). Included in the characteristic value is a Flags field (for showing the presence of optional fields),
         and depending upon the contents of the Flags field, it may include one or more optional fields as defined
         on the Bluetooth SIG Assigned Numbers webpage
         */
        case bike = "0x2AD2"
        /**
         The Supported Power Range characteristic shall be exposed by the Server if the Power Target Setting
         feature is supported.
         
         The Supported Power Range characteristic is used to send the supported power range as well as the
         minimum power increment supported by the Server. Included in the characteristic value are a Minimum
         Power field, a Maximum Power field, and a Minimum Increment field as defined on the Bluetooth SIG
         Assigned Numbers webpage. Note that the Minimum Power field and the Maximum Power field
         represent the extreme values supported by the Server and are not related to, for example, the current
         speed of the Server.
         */
        case powerRange = "0x2AD8"
        
        /**
         When the Training Status characteristic is configured for notification via the Client Characteristic
         Configuration descriptor and a new training status is available (e.g., when there is a transition in the
         training program), this characteristic shall be notified.
         When read, the Training Status characteristic returns a value that is used by a Client to determine the
         current training status of the Server.
         
         Values of the training status field are as follows:
         0x00 Other
         0x01 Idle
         0x02 Warming Up
         0x03 Low Intensity Interval
         0x04 High Intensity Interval
         0x05 Recovery Interval
         0x06 Isometric
         0x07 Heart Rate Control
         0x08 Fitness Test
         0x09 Speed Outside of Control Region - Low (increase speed to return to controllable
         region)
         0x0A Speed Outside of Control Region - High (decrease speed to return to controllable
         region)
         0x0B Cool Down
         0x0C Watt Control
         0x0D Manual Mode (Quick Start)
         0x0E Pre-Workout
         0x0F Post-Workout
         0x10-0xFF Reserved for Future Use
         */
        case trainingStatus = "0x2AD3"
        
        /// The Core Bluetooth UUID representation of the Bluetooth [Assigned Numbers](https://www.bluetooth.com/specifications/assigned-numbers/) 16 bit UUID
        public var uuid: CBUUID { CBUUID(string: self.rawValue)}
        
        /// Cases that represents an actual fitness device, i.e. Rower, Bike, Stair Climber etc. rather than a functionality
        public static var fitnessDevices: [Characteristic] = [.bike, .crossTrainer, .stairClimber, .rower, .treadmill]
    }
}


// Human Readable fitness device names
extension FTMS.Characteristic {
    public var displayName: String {
        switch self {
        case .treadmill:
            return "Treadmill"
        case .crossTrainer:
            return "Cross Trainer"
        case .stairClimber:
            return "Stair Climber"
        case .rower:
            return "Indoor Rower"
        case .bike:
            return "Indoor Bike"
        default:
            return "Unknown Device"
        }
    }
}

// SF Symbol representations of the fitness device
extension FTMS.Characteristic {
    public var symbolName: String {
        switch self {
        
        case .treadmill:
            return "figure.run"
        case .crossTrainer:
            return "figure.cross.training"
        case .stairClimber:
            return "figure.stair.stepper"
        case .rower:
            return "figure.rower"
        case .bike:
            return "figure.indoor.cycle"
        default:
            return "xmark"
        }
    }
}
