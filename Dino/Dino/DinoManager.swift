//
//  DinoManager.swift
//  Dino
//
//  Created by Yuhui Li on 2017-01-14.
//  Copyright © 2017 Yuhui Li. All rights reserved.
//

import Cocoa
import SwiftSocket

class DinoManager: NSObject {
    static func sendScore(score:Int) -> String {
        let client = TCPClient(address: "127.0.0.1", port: 1300)
        switch client.connect(timeout: 10) {
        case .success:
            print("Socket open success")
            
            let dic : [String:Any] = ["player_name":DinoManager.macUsername(),"player_id":DinoManager.macSerialNumber(),"player_score":score,"player_system":DinoManager.macSystemVersion()]
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
                _ = client.send(data: jsonData)
                let dataString = String(data: jsonData, encoding: .utf8)
                print(dataString!)
                
                let data = client.read(50)
                if let realData = data {
                    if let response = String(bytes: realData, encoding: .utf8) {
                        if let convertedData = response.data(using: .utf8) {
                            do {
                                let conversionResult = try JSONSerialization.jsonObject(with: convertedData, options: [])
                                if let responseDic : [String:Any] = conversionResult as? [String:Any] {
                                    if (responseDic["status"] != nil && responseDic["status"] as! Int == 0) {
                                        if (responseDic["rank"] != nil) {
                                            client.close()
                                            return String(format:"%i", (responseDic["rank"] as! Int)+1)
                                        }
                                    } else {
                                        client.close()
                                        return ""
                                    }
                                }
                            } catch {
                                client.close()
                                return ""
                            }
                        }
                    }
                }
            } catch {
                print("JSON construction error")
            }
            
            break
        case .failure(_):
            print("Socket failed")
            break
        }
        client.close()
        
        return ""
    }
    
    static func macSystemVersion() -> String {
        return ProcessInfo().operatingSystemVersionString
    }
  
    static func macUsername() -> String {
        return NSUserName()
    }
    
    static func macSerialNumber() -> String {
        
        // Get the platform expert
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
        
        // Get the serial number as a CFString ( actually as Unmanaged<AnyObject>! )
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString!, kCFAllocatorDefault, 0);
        
        // Release the platform expert (we're responsible)
        IOObjectRelease(platformExpert);
        
        // Take the unretained value of the unmanaged-any-object
        // (so we're not responsible for releasing it)
        // and pass it back as a String or, if it fails, an empty string
        return (serialNumberAsCFString!.takeUnretainedValue() as? String) ?? ""
        
    }
}
