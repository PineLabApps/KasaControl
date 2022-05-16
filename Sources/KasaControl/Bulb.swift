//
//  Bulb.swift
//  KasaControl
//
//  Created by Yu Jiang Tham on 3/16/22.
//

import Foundation
import SwiftyJSON

public class Bulb: Device {
    public var brightness: Int = 0
    public var hue: Int = 0
    public var saturation: Int = 0
    public var colorTemp: Int = 0
    
    override public func printState() {
        NSLog("[Bulb KasaID: \(self.id)] On: \(self.on), Hue: \(self.hue), Saturation: \(self.saturation), Brightness: \(self.brightness), Color Temp: \(self.colorTemp)")
    }
    
    public func getState() async {
        let state: JSON = await KasaControl.shared.getBulbState(bulb: self)
        self.on = state["on_off"].intValue == 0 ? false : true
        if state["dft_on_state"].dictionary != nil {
            self.brightness = state["dft_on_state"]["brightness"].intValue
            self.saturation = state["dft_on_state"]["saturation"].intValue
            self.hue = state["dft_on_state"]["hue"].intValue
            self.colorTemp = state["dft_on_state"]["color_temp"].intValue
        } else {
            self.brightness = state["brightness"].intValue
            self.saturation = state["saturation"].intValue
            self.hue = state["hue"].intValue
            self.colorTemp = state["color_temp"].intValue
        }
    }
    
    public func setValues(on: Bool, brightness: Int, hue: Int, saturation: Int, colorTemp: Int) async {
        if await KasaControl.shared.setBulb(bulb: self, on: on, brightness: brightness, hue: hue, saturation: saturation, colorTemp: colorTemp) {
            self.on = on
            self.brightness = brightness
            self.hue = hue
            self.saturation = saturation
            self.colorTemp = colorTemp
        }
    }
    
    override public func setOn(value: Bool) async {
        if await KasaControl.shared.setBulb(bulb: self, on: value, brightness: self.brightness, hue: self.hue, saturation: self.saturation, colorTemp: self.colorTemp) {
            self.on = value
        }
    }
    
    public func setBrightness(value: Int) async {
        if await KasaControl.shared.setBulb(bulb: self, on: self.on, brightness: value, hue: self.hue, saturation: self.saturation, colorTemp: self.colorTemp) {
            self.brightness = value
        }
    }
    
    public func setHue(value: Int) async {
        if await KasaControl.shared.setBulb(bulb: self, on: self.on, brightness: self.brightness, hue: value, saturation: self.saturation, colorTemp: 0) {
            self.hue = value
            self.colorTemp = 0
        }
    }
    
    public func setSaturation(value: Int) async {
        if await KasaControl.shared.setBulb(bulb: self, on: self.on, brightness: self.brightness, hue: self.hue, saturation: value, colorTemp: 0) {
            self.saturation = value
            self.colorTemp = 0
        }
    }
    
    public func setColorTemp(value: Int) async {
        if await KasaControl.shared.setBulb(bulb: self, on: self.on, brightness: value, hue: self.hue, saturation: self.saturation, colorTemp: value) {
            self.colorTemp = value
        }
    }
}
