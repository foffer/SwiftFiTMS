//
//  Peripheral.swift
//
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import Foundation
import CoreBluetooth
import HealthKit
import os.log
import BluetoothMessageProtocol

@Observable public class PeripheralService: NSObject {
    
    /// The estimated distance from the server
    public var distance: Double?
    // Will let the consumer know wether this is a rower, bike etc.
    public var fitnessDeviceCharacteristicType: FTMS.Characteristic?
    
    public var data: [any Characteristic] = []
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PeripheralService")
    private var manager: CBCentralManager!
    private let centralManagerQueue = DispatchQueue(
            label: "bluetooth.central.manager",
            attributes: DispatchQueue.Attributes.concurrent
        )

    var cbPeripheral: CBPeripheral?
    
    private(set) public var peripherals: Set<CBPeripheral> = []
    
    private(set) public var characteristics: [CBCharacteristic] = []
    
    public var services: [CBService]? {
        cbPeripheral?.services
    }
    
    public var name: String? {
        cbPeripheral?.name ?? cbPeripheral?.identifier.uuidString
    }
    
    public var isConnected: Bool {
        cbPeripheral?.state == .connected
    }
    
    override public init() {
        super.init()
        
        self.manager = CBCentralManager(delegate: self, queue: centralManagerQueue)
    }
    
    public func scan() {
        manager.scanForPeripherals(withServices: [FTMS.Service.uuid])
    }
    
    public func stopScan() {
        manager.stopScan()
    }
    
    public func connect(_ peripheral: CBPeripheral) {
        guard manager.state == .poweredOn else {
            logger.error("Bluetooth Manager is not powered on. Device connection aborted")
            return
        }
        logger.info("Connecting to peripheral \(peripheral.name ?? peripheral.identifier.uuidString)")
        cbPeripheral = peripheral
        cbPeripheral?.delegate = self
        manager.connect(peripheral)
    }
    
    public func workoutConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.locationType = .indoor
        
        switch fitnessDeviceCharacteristicType {
        
        case .treadmill:
            configuration.activityType = .running
        case .crossTrainer:
            configuration.activityType = .crossTraining
        case .stairClimber:
            configuration.activityType = .stepTraining
        case .rower:
            configuration.activityType = .rowing
        case .bike:
            configuration.activityType = .cycling
        default:
            fatalError("Not supported")
        }
        
        return configuration
    }
}

extension PeripheralService: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
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
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info("Received characteristics for peripheral \(peripheral.identifier)")
        self.characteristics = service.characteristics ?? []
        
        service.characteristics?.forEach { characteristic in
            // For now we are interested in any and all characteristics offered by the FTMS device
            // In the future this could maybe be dependent on an `OptionSet`.
            peripheral.discoverDescriptors(for: characteristic)
            logger.debug("Setting notify value `true` for characteristic \(characteristic.uuid.uuidString)")
            peripheral.setNotifyValue(true, for: characteristic)
            
            for charType in FTMS.Characteristic.fitnessDevices {
                if characteristic.uuid == charType.uuid {
                    fitnessDeviceCharacteristicType = charType
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        decodeCharacteristicsData(characteristic: characteristic)
    }
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        logger.info("Peripheral name did update: \(peripheral.name ?? "") for peripheral: \(peripheral.identifier.uuidString)")
    }
}

extension PeripheralService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("Bluetooth manager is powered on")
        case .poweredOff:
            logger.info("Bluetooth manager is powered off")
        case .resetting:
            logger.info("Bluetooth manager resetting...")
        default:
            logger.error("Bluetooth manager in unsupported state: \(central.state.rawValue)")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Peripheral connected with name/id: \(peripheral.name ?? "")/\(peripheral.identifier)")
        peripheral.discoverServices([FTMS.Service.uuid])
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Could not connect to bluetooth device: \(error?.localizedDescription ?? "")")
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.info("Found device \(peripheral.name ?? "(no name)"), signal strength: \(RSSI)")
        print(advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data])
        print(advertisementData[CBAdvertisementDataManufacturerDataKey])
        dump(advertisementData)
        
//        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
//        let manufactorerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as?
//        let
        
        peripherals.insert(peripheral)
    }
}

extension PeripheralService {
    func decodeCharacteristicsData(characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            logger.error("No data found for characteristic \(characteristic.uuid.uuidString)")
            return
        }
        let uuid = characteristic.uuid.uuidString
        
        switch uuid {
        case CharacteristicIndoorBikeData.uuidString:
            let value:Result<CharacteristicIndoorBikeData, BluetoothDecodeError> = CharacteristicIndoorBikeData.decode(with: data)
            if case let .success(deviceData) = value {
                self.data.append(deviceData)
            }
        case CharacteristicRowerData.uuidString:
            let value :Result<CharacteristicRowerData, BluetoothDecodeError> = CharacteristicRowerData.decode(with: data)
            if case let .success(deviceData) = value {
                self.data.append(deviceData)
            }
        case CharacteristicStairClimberData.uuidString:
            let value :Result<CharacteristicStairClimberData, BluetoothDecodeError> = CharacteristicStairClimberData.decode(with: data)
            if case let .success(deviceData) = value {
                self.data.append(deviceData)
            }
        case CharacteristicTreadmillData.uuidString:
            let value :Result<CharacteristicTreadmillData, BluetoothDecodeError> = CharacteristicTreadmillData.decode(with: data)
            if case let .success(deviceData) = value {
                self.data.append(deviceData)
            }
        case CharacteristicCrossTrainerData.uuidString:
            let value :Result<CharacteristicCrossTrainerData, BluetoothDecodeError> = CharacteristicCrossTrainerData.decode(with: data)
            if case let .success(deviceData) = value {
                self.data.append(deviceData)
            }
        default:
            logger.error("Missing implementation: decoding for characteristic: \(characteristic.description)/\(uuid) not supported")
            break;
        }
    }
}
