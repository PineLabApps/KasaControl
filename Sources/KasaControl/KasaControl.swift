//
//  KasaControl.swift
//  KasaControl
//
//  Created by Yu Jiang Tham on 3/16/22.
//

import Foundation
import SwiftyJSON

enum KasaRequestError: Error {
    case noData
    case invalidCredentials
}

public class KasaControl {
    public static let shared = KasaControl()
    private var deviceList: Array<Device> = []
    private var token = ""
    
    private init() { }
    
    // MARK: - Device List
    public func getDeviceById(id: String) -> Device? {
        return self.deviceList.first(where: { $0.id == id })
    }
    
    public func getDeviceByName(name: String) -> Device? {
        return self.deviceList.first(where: { $0.name == name })
    }
    
    public func getDeviceList() -> Array<Device> {
        return self.deviceList
    }
    
    public func updateDeviceList() async {
        if self.token == "" {
            NSLog("Error: token is invalid")
            return
        }
        
        let command: JSON = [
            "method": "getDeviceList",
        ]
        
        do {
            let res = try await tplinkCloudRequest(command: command)
            let deviceJsonArray: Array<JSON> = res["result"]["deviceList"].array ?? []
            for deviceJson in deviceJsonArray {
                NSLog(deviceJson.description)
            }
            self.deviceList = await populateDeviceArrayAndGetState(jsonArray: deviceJsonArray)
        } catch {
            NSLog("TPLink Cloud Request Error")
        }
    }
    
    // MARK: - Login
    public func login(username: String, password: String) async throws -> String {
        let uuid = UUID().uuidString
        NSLog("Login, UUID: \(uuid)")
        let command: JSON = [
            "method": "login",
            "params": [
                "appType": "Kasa_Android",
                "cloudUserName": username,
                "cloudPassword": password,
                "terminalUUID": uuid,
            ]
        ]
        
        do {
            let commandJson = try command.rawData()
        
            let url = URL(string: "https://wap.tplinkcloud.com")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = commandJson
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      throw KasaRequestError.invalidCredentials
                  }
            
            NSLog("Login data: \(data)")
            let resultJson = try JSON(data: data)
            if let token = resultJson["result"]["token"].string {
                NSLog(token)
                self.token = token
                return token
            }
        } catch {
            NSLog("Error decoding JSON Data")
            throw KasaRequestError.noData
        }
        throw KasaRequestError.noData
    }
    
    // MARK: - Bulb
    public func getBulbState(bulb: Bulb) async -> JSON {
        let requestData: JSON = [
            "smartlife.iot.smartbulb.lightingservice": [
                "get_light_state": [],
            ],
        ]
        let command = createCommand(id: bulb.id, requestData: requestData)
        
        do {
            let res = try await tplinkCloudRequest(command: command)
            guard let err_code = res["error_code"].int else {
                NSLog("Unable to get light state")
                return JSON()
            }
            guard err_code == 0 else {
                NSLog("Error: Received error attempting to get light state")
                return JSON()
            }
            
            let state: JSON = res["result"]["responseData"]["smartlife.iot.smartbulb.lightingservice"]["get_light_state"]
            return state
        } catch {
            NSLog("TPLink Cloud Request Error")
        }
        return JSON()
    }
    
    public func setBulb(bulb: Bulb, on: Bool, brightness: Int, hue: Int, saturation: Int, colorTemp: Int) async -> Bool {
        let requestData: JSON = [
            "smartlife.iot.smartbulb.lightingservice": [
                "transition_light_state": [
                    "brightness": brightness,
                    "hue": hue,
                    "saturation": saturation,
                    "color_temp": colorTemp,
                    "on_off": on,
                ],
            ],
        ]
        let command = createCommand(id: bulb.id, requestData: requestData)
        
        do {
            let res = try await tplinkCloudRequest(command: command)
            if res["error_code"] == 0 {
                return true
            }
        } catch {
            NSLog("TPLink Cloud Request Error")
        }
        return false
    }
    
    // MARK: - Plug/Switch
    public func getPlugSwitch(plugSwitch: PlugSwitch) async -> JSON {
        let requestData: JSON = [
            "system": [
                "get_sysinfo": [
                    "relay_state": []
                ],
            ],
//            "emeter": [
//                "get_realtime": nil,
//            ],
        ]
        let command = createCommand(id: plugSwitch.id, requestData: requestData)
        NSLog("P/S ID: \(plugSwitch.id)")
        do {
            let res = try await tplinkCloudRequest(command: command)
            NSLog("getPlugSwitchRes: \(res.description)")
            guard let err_code = res["error_code"].int else {
                NSLog("Unable to get plug/switch state")
                return JSON()
            }
            NSLog("Err Code: \(err_code)")
            guard err_code == 0 else {
                NSLog("Error: Received error attempting to get plug/switch state")
                return JSON()
            }
            let state: JSON = res["result"]["responseData"]["system"]["get_sysinfo"]["relay_state"]
            return state
        } catch {
            NSLog("TPLink Cloud Request Error")
        }
        return JSON()
    }
    
    public func setPlugSwitch(plugSwitch: PlugSwitch, on: Bool) async -> Bool {
        let intValue = on ? 1 : 0
        let requestData: JSON = [
            "system": [
                "set_relay_state": [
                    "state": intValue,
                ],
            ],
        ]
        let command = createCommand(id: plugSwitch.id, requestData: requestData)
        do {
            let res = try await tplinkCloudRequest(command: command)
            if res["error_code"] == 0 {
                return true
            }
        } catch {
            NSLog("TPLink Cloud Request Error")
        }
        return false
    }
    
    // MARK: - Helpers
    func createCommand(id: String, requestData: JSON) -> JSON {
        return [
            "method": "passthrough",
            "params": [
                "deviceId": id,
                "requestData": requestData,
            ],
        ]
    }
    
    func tplinkCloudRequest(command: JSON) async throws -> JSON {
        do {
            let commandJson = try command.rawData()
            
            let url = URL(string: "https://wap.tplinkcloud.com/?token=\(self.token)")
            NSLog("URL: \(url!.absoluteString)")
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = commandJson
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      throw KasaRequestError.invalidCredentials
                  }

            do {
                let resultJson = try JSON(data: data)
                return resultJson
            } catch {
                NSLog("Error decoding result JSON")
                return JSON()
            }
        } catch {
            NSLog("Error decoding JSON data")
        }
        
        return JSON()
    }
    
    func populateDeviceArrayAndGetState(jsonArray: Array<JSON>) async -> Array<Device> {
        var deviceArray: Array<Device> = []
        for jsonDevice in jsonArray {
            let deviceType = jsonDevice["deviceType"].stringValue
            let id = jsonDevice["deviceId"].stringValue
            let status = jsonDevice["status"].intValue
            let name = jsonDevice["alias"].stringValue
            let model = jsonDevice["deviceModel"].stringValue
            let role = jsonDevice["role"].intValue
            let hwVer = jsonDevice["deviceHwVer"].stringValue
            switch deviceType {
                case DeviceTypes.bulb.rawValue:
                    NSLog("Found a bulb!")
                    let bulb = Bulb(id: id, status: status, name: name, model: model, role: role, hwVer: hwVer)
                    await bulb.getState()
                    bulb.printState()
                    deviceArray.append(bulb)
                    break
                case DeviceTypes.plugswitch.rawValue:
                    NSLog("Found a plugswitch")
                    let plugSwitch = PlugSwitch(id: id, status: status, name: name, model: model, role: role, hwVer: hwVer)
                    deviceArray.append(plugSwitch)
                    break
                default:
                    NSLog("Found a device")
                    let device = Device(id: id, status: status, name: name, model: model, role: role, hwVer: hwVer)
                    deviceArray.append(device)
                    break
            }
        }
        return deviceArray
    }
}
