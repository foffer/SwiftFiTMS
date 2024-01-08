//
//  IndoorBikeData.swift
//
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import Foundation
import BluetoothMessageProtocol
import WorkoutKit
import HealthKit

struct IndoorBike {
    let characteristicUUID = CharacteristicIndoorBikeData.uuidString
    let workoutType = HKWorkoutActivityType.cycling
    let location = HKWorkoutSessionLocationType.indoor
}
