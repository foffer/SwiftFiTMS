//
//  Field.swift
//
//
//  Created by Christoffer Buusmann on 07/10/2023.
//

import Foundation

private extension FixedWidthInteger {
    var byteWidth:Int {
        return self.bitWidth / UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth / UInt8.bitWidth
    }
}

struct Fields {
    
    var flags: UInt16 = 0

    var data: Data

    /// Offset starts at `0` and moves forwards for each read cycle
    var offset = 0

    // Init and read flags
    init(_ data: Data) {
        self.data = data
        self.flags = get()
    }

    // Read the fields. Always going forward, should be used only once per read cycle
    mutating func get<T: FixedWidthInteger>() -> T {
        let byteWidth = T.self.byteWidth

        var value: T = 0
        data.subdata(in: data.startIndex.advanced(by: offset)..<data.startIndex.advanced(by: offset + byteWidth))
        .withUnsafeBytes { bytes in
            value = bytes.load(as: T.self)
        }
        offset += T.byteWidth

        return value
    }
}
