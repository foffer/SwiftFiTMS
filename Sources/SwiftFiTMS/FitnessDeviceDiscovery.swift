//
//  File.swift
//  
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import CoreBluetooth
import os.log
import BluetoothMessageProtocol

typealias FitnessDeviceStream = (stream: AsyncStream<(Characteristic)>, continuation: AsyncStream<(Characteristic)>.Continuation)
typealias CharacteristicsStream = (stream: AsyncStream<([CBCharacteristic])>, continuation: AsyncStream<([CBCharacteristic])>.Continuation)

@Observable
public class FitnessDeviceDiscovery: NSObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BluetoothService")
    public static let shared = FitnessDeviceDiscovery()
    
    private var manager: CBCentralManager
    fileprivate let centralManagerQueue = DispatchQueue(
            label: "bluetooth.central.manager",
            attributes: DispatchQueue.Attributes.concurrent
        )
    
    
    private let fitnessDeviceStreamTuple = AsyncStream.makeStream(of: (any Characteristic).self, bufferingPolicy: .bufferingNewest(1))
    private let characteristicsStreamTuple = AsyncStream.makeStream(of: [CBCharacteristic].self, bufferingPolicy: .bufferingNewest(1))
    /// Selected fitness device is any device that supports the fitness machine service protocol
    public var fitnessDeviceData: [any Characteristic] = []
    public var pastMinuteData: [any Characteristic] = []
    public var pastHourData: [any Characteristic] = []
    
    private var recordedDeviceData: [CharacteristicIndoorBikeData] = []
    /// If the bluetooth radio is currently scanning for peripherals, this bool will be true
    public var isScanning: Bool { manager.isScanning }
    
    
    /// The peripherals that was found advertising the FTMS UUID and is in range
    /// These peripherals should be shown in conjunction with a TX indicator so a user can
    /// see whether the peripheral is still in range or not.
    public var peripherals: Set<CBPeripheral> = []
    public var peripheralDistance = Dictionary<String, Double>()
    
    private var peripheralDelegate: PeripheralDelegate
    
    /// The currently connected peripheral, as chosen by the user
    private(set) public var connectedPeripheral: CBPeripheral? {
        didSet {
            
            // Stop the scan when the user selects a device
            stopScan()
        }
    }
    
    public var isPeripheralConnected: Bool { connectedPeripheral != nil }
    
    /// With the recording mode set to true the device discovery service will record the characteristic data coming from the device and save it to a JSON file
    public var isRecording: Bool = false
    
    public override init() {
        
        manager = CBCentralManager()
        peripheralDelegate = PeripheralDelegate(stream: fitnessDeviceStreamTuple, charStream: characteristicsStreamTuple)
        
        super.init()
        manager = CBCentralManager(delegate: self, queue: centralManagerQueue)
        
        logger.info("Bluetooth Service alive")
        
        Task {
            for await value in fitnessDeviceStreamTuple.stream {
                consumeFitnessDeviceData(value)
            }
        }
    }
    
    
    public func scan() {
        guard manager.state == .poweredOn else {
            logger.error("Bluetooth service not available, wrong state: \(self.manager.state.rawValue)")
            return
        }
        logger.info("Scanning for device with service \(FTMS.Service.uuid.uuidString)")
        
        manager.scanForPeripherals(withServices: [CBUUID(string: ServiceFitnessMachine.uuidString)])
    }
    
    public func stopScan() {
        logger.info("Stopping scanner...")
        manager.stopScan()
    }
    
    public func setSelectedPeripheral(_ peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
    }
    
    private func consumePeripheral(_ peripheral: CBPeripheral) {
        logger.info("Adding new peripheral \(peripheral.identifier)")
        peripherals.insert(peripheral)
//        peripheralDistance[value.peripheral.identifier.uuidString] = value.distance
    }
    
//    private func consumeCharacteristics(_ characteristics: [CBCharacteristic]) {
//        guard let peripheralID = characteristics.first?.service?.peripheral?.identifier.uuidString else {
//            logger.error("Could not find peripheral ID when updating characteristics")
//            return
//        }
//        logger.info("Updating characteristic for device: \(peripheralID)")
//        guard let p = peripherals.first(where: { $0.id.uuidString == peripheralID }) else {
//            logger.error("Could not locate peripheral with id: \(peripheralID)")
//            return
//        }
////        p.updateCharacteristics(characteristics)
////        peripherals.insert(p)
//    }
    
    private func consumeFitnessDeviceData(_ value: any Characteristic) {
        logger.info("Setting Fitness Device: \(value.name)")
        fitnessDeviceData.append(value)
        recordData(value)
    }
    
    /// Connect the peripheral chosen by the user. Once connected, the peripheral will start issuing notifications
    /// with values
    public func connect(with peripheral: CBPeripheral) {
//        logger.info("Asked to connect with peripheral \(peripheral.cbPeripheral.name ?? peripheral.cbPeripheral.identifier.uuidString)")
//        peripheral.cbPeripheral.delegate = peripheralDelegate
//        manager.connect(peripheral.cbPeripheral)
//        connectedPeripheral = peripheral.cbPeripheral
        
    }
    
    /// Starts recording incoming data from the server
    public func startRecording() {
        isRecording = true
    }
    
    /// Stops any recording of the incoming data from the server
    public func stopRecording() {
        isRecording = false
    }
    
    /// Records every record that comes in from the server is the `isRecording` flag is set to true
    private func recordData(_ value: any Characteristic) {
        guard isRecording == true else { return }
        if let value = value as? CharacteristicIndoorBikeData {
            logger.debug("Saving entry for indoor bike data")
            recordedDeviceData.append(value)
            let encoder = JSONEncoder()
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let file = fileURL?.appending(component: "\(value.name).json")
            do {
                try encoder.encode(recordedDeviceData).write(to: file!)
            } catch {
                logger.error("Could not save data: \(error.localizedDescription)")
            }
        }
    }
}

extension FitnessDeviceDiscovery: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .unknown:
                logger.info("[BluetoothManager] state: unknown")
                break
            case .resetting:
                logger.info("[BluetoothManager] state: resetting")
                break
            case .unsupported:
                logger.info("[BluetoothManager] state: not available")
                break
            case .unauthorized:
                logger.info("[BluetoothManager] state: not authorized")
                break
            case .poweredOff:
                logger.info("[BluetoothManager] state: powered off")
//                BluetoothManager.stopScanningForFTMS()
                break
            case .poweredOn:
                logger.info("[BluetoothManager] state: powered on")
                break
            @unknown default:
                logger.info("[BluetoothManager] state: unknown")
            }
        }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? Array<CBUUID> else {
            logger.error("No advertised services found")
            return
        }
        guard serviceUUIDs.contains(FTMS.Service.uuid) else {
            logger.error("No FTMS devices advertised")
            return
        }
        
        // Unused for now, with the echo bike the tx data is not available, perhaps it is with other equipment?
        let power = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Double) ?? 0
        let distance = pow(10, ((power - Double(truncating: RSSI))/20))
        consumePeripheral(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        logger.debug("\(peripheral.name ?? peripheral.identifier.uuidString) did \(event == .peerConnected ? "" : "dis")connect")
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("Requesting signal strength")
        peripheral.readRSSI()
        logger.debug("Discovering services on device...")
        peripheral.discoverServices([])
    }
}

// Test mode functions
extension FitnessDeviceDiscovery {
    private var indoorBikeSampleData: [CharacteristicIndoorBikeData]? {
        guard let resourceURL = Bundle.module.url(forResource: "indoor_bike_sample_data", withExtension: "json") else { return nil }
        logger.debug("Found test resources in bundle: \(resourceURL)")
        guard let data = try? Data(contentsOf: resourceURL) else { return nil }
        logger.debug("Extracted data from bundle")
        let decoder = JSONDecoder()
        let entries = try? decoder.decode([CharacteristicIndoorBikeData].self, from: data)
        
        return entries
    }
    
    public func testMode() async {
        guard let entries = indoorBikeSampleData else {
            fatalError("Could not find sample data")
        }
        Task {
            for entry in entries {
                await MainActor.run {
                    self.fitnessDeviceData.append(entry)
                }
                try await Task.sleep(for: .seconds(1))
            }
        }
    }
}
