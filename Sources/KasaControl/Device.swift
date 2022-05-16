//
//  Device.swift
//  KasaControl
//
//  Created by Yu Jiang Tham on 3/16/22.
//

import Foundation

public enum DeviceTypes: String {
    case bulb = "IOT.SMARTBULB"
    case plugswitch = "IOT.SMARTPLUGSWITCH"
}

public class Device {
    public let id: String
    public var status: Int
    public let name: String
    public let model: String
    public let role: Int
    public let hwVer: String
    public var on: Bool = false
    
    init(id: String, status: Int, name: String, model: String, role: Int, hwVer: String) {
        self.id = id
        self.status = status
        self.name = name
        self.model = model
        self.role = role
        self.hwVer = hwVer
    }
    
    func printState() {
        NSLog("[Device KasaID: \(self.id)] Status: \(self.status), Name: \(self.name), Model: \(self.model), Role: \(self.role), HWVer: \(self.hwVer)")
    }
    
    public func setOn(value: Bool) async {
        NSLog("Device setOn")
    }
}
