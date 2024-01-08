//
//  File.swift
//  
//
//  Created by Christoffer Buusmann on 19/12/2023.
//

import Foundation
import HealthKit

public enum CharacteristicActivityType: String {
    case indoorBike = "2AD2"
    
    static var fitnessDevices: [CharacteristicActivityType] = [.indoorBike]
    
    var workoutConfiguration: HKWorkoutConfiguration {
        switch self {
        case .indoorBike:
            let conf = HKWorkoutConfiguration()
            conf.activityType = .cycling
            conf.locationType = .indoor
            return conf
        }
    }
}
