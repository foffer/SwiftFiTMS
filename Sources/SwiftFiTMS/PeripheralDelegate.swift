//
//  PeripheralDelegate.swift
//
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import CoreBluetooth
import os.log
import BluetoothMessageProtocol

class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PeripheralDelegate")
    private let stream: FitnessDeviceStream
    private let charStream: CharacteristicsStream
    
    init(stream: FitnessDeviceStream, charStream: CharacteristicsStream) {
        self.stream = stream
        self.charStream = charStream
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info("Did discover FTMS service \(peripheral.services ?? [])")
        guard let services = peripheral.services else {
            logger.error("Could not get services for \(peripheral.identifier)")
            return
        }
        // Once the service is discovered, fetch the characteristics
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info("Received characteristics for peripheral \(peripheral.identifier)")
        
        service.characteristics?.forEach { characteristic in
            // For now we are interested in any and all characteristics offered by the FTMS device
            // In the future this could maybe be dependent on an `OptionSet`.
            peripheral.discoverDescriptors(for: characteristic)
            logger.debug("Setting notify value `true` for characteristic \(characteristic.uuid.uuidString)")
            peripheral.setNotifyValue(true, for: characteristic)
        }
        charStream.continuation.yield(service.characteristics ?? [])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let descriptors = characteristic.descriptors {
            logger.debug("Found \(descriptors.count) descriptor for characteristic \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        logger.info("Peripheral \(peripheral.identifier) did update value for descriptor \(descriptor.description)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logger.info("RSSI: \(RSSI)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            
        guard let data = characteristic.value else {
            logger.error("No data found for characteristic \(characteristic.uuid.uuidString)")
            return
        }
        
        switch characteristic.uuid.uuidString {
        case CharacteristicIndoorBikeData.uuidString:
            let value: Result<CharacteristicIndoorBikeData, BluetoothDecodeError> = CharacteristicIndoorBikeData.decode(with: data)
            if case let .success(bikeData) = value {
                stream.continuation.yield(bikeData)
            }
            
        case FTMS.Characteristic.powerRange.uuid.uuidString:
                print("--- POWER RANGE SUPPORTED ---")
                break;
            case CharacteristicTrainingStatus.uuidString:
                print("--- TRAINING STATUS SUPPORTED ---")
                print(data.description)
                
            let status: Result<CharacteristicTrainingStatus, BluetoothDecodeError> = CharacteristicTrainingStatus.decode(with: data)
            switch status {
            case .success(let value):
                print("Training status: \(value.status)")
            case .failure(let error):
                print(error)
            }
//            let hrData: Result<CharacteristicHeartRateMeasurement, BluetoothDecodeError> = CharacteristicHeartRateMeasurement.decode(with: data)
            
                break;
            default:
                logger.error( "Error while determining characteristic \(characteristic.uuid.uuidString)")
                break;
            }
        }
}
