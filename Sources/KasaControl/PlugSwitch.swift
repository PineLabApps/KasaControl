//
//  PlugSwitch.swift
//  KasaControl
//
//  Created by Yu Jiang Tham on 3/16/22.
//

import Foundation
import SwiftyJSON

public class PlugSwitch: Device {    
    override public func printState() {
        NSLog("[Plug/Switch KasaID: \(self.id)] On: \(self.on)")
    }
    
    public func getState() async {
        let state: JSON = await KasaControl.shared.getPlugSwitch(plugSwitch: self)
        NSLog(state.description)
        self.on = state.intValue == 1 ? true : false
    }
    
    override public func setOn(value: Bool) async {
        if await KasaControl.shared.setPlugSwitch(plugSwitch: self, on: value) {
            self.on = value
        }
    }
}
