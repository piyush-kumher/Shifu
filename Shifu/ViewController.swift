//
//  ViewController.swift
//  Shifu
//
//  Created by Shubham Kankaria on 22/06/17.
//  Copyright (c) 2017 FSociety. All rights reserved.
//

import Cocoa
import Alamofire

extension String {
    var lines: [String] {
        var result: [String] = []
        enumerateLines{ result.append($0.line) }
        return result
    }
    
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var systemConfigurationLabel: NSTextField!
    
    @IBOutlet weak var requestIdLabel: NSTextField!
    
    @IBAction func checkSysConfigurationButtonClicked(sender: AnyObject) {
        let systemConfiguration: SystemConfiguration = SystemConfiguration()
        startGenerationProcess(systemConfiguration)
        saveData(systemConfiguration)
        
        let systemConfigVar = "Processor Name: " + systemConfiguration.processorName! + "\nProcessor Speed: " + systemConfiguration.processorSpeed! + "\nProcessor Cores: " + String(systemConfiguration.processorCores) + "\nGraphics Model: " + systemConfiguration.graphicModel! + "\nGraphics Memory: " + systemConfiguration.graphicMemory! + "\nDisplay Resolution: " + systemConfiguration.graphicResolution! + "\nMemory: " + systemConfiguration.memory! + "\nDisk Model: " + systemConfiguration.diskModel! + "\nDisk Size: " + systemConfiguration.diskSize! + "\nSerial Number: " + systemConfiguration.serialNo! + "\nHardware UUID: " + systemConfiguration.hardwareUuid!
        
        systemConfigurationLabel.stringValue = systemConfigVar
        
    }
    
    
    private func startGenerationProcess(systemConfiguration: SystemConfiguration){
        let listDataTypes: [String] = ["SPHardwareDataType", "SPDisplaysDataType", "SPSerialATADataType"]
        
        for (_, dataType) in listDataTypes.enumerate() {
            let task = NSTask()
            task.launchPath = "/usr/sbin/system_profiler"
            task.arguments = [dataType]
            let pipe = NSPipe()
            task.standardOutput = pipe
            task.launch()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = NSString(data: data, encoding: NSUTF8StringEncoding)
            generateSystemConfiguration(systemConfiguration, dataType: dataType, data: output as! String)
        }
        
        let result = generateDictionary(systemConfiguration)
        
        let arrJson = try! NSJSONSerialization.dataWithJSONObject(result, options: NSJSONWritingOptions.PrettyPrinted)
        let jsonString = NSString(data: arrJson, encoding: NSUTF8StringEncoding)
        //print(jsonString! as NSString)
        
        NSUserDefaults.standardUserDefaults().setObject(jsonString, forKey: "systemConfiguration")
        NSUserDefaults.standardUserDefaults().synchronize()
    
    }
    
    private func generateSystemConfiguration(systemConfiguration: SystemConfiguration, dataType: String, data: String) {
        switch dataType {
            case "SPHardwareDataType":
                generateSPHardwareDataType(systemConfiguration, data: data)
                break
            case "SPDisplaysDataType":
                generateSPDisplaysDataType(systemConfiguration, data: data)
                break
            case "SPSerialATADataType":
                generateSPSerialATADataType(systemConfiguration, data: data)
                break
            default:
                break
        }
    }
    
    private func generateSPHardwareDataType(systemConfiguration: SystemConfiguration, data: String) {
        for line in data.lines {
            let x = line.trim()
            if(x.containsString("Processor Name: ")) {
                systemConfiguration.processorName = x[x.startIndex.advancedBy(16)..<x.endIndex]
            } else if(x.containsString("Processor Speed: ")) {
                systemConfiguration.processorSpeed = x[x.startIndex.advancedBy(17)..<x.endIndex]
            } else if(x.containsString("Total Number of Cores: ")) {
                systemConfiguration.processorCores = Int(x[x.startIndex.advancedBy(23)..<x.endIndex])!
            } else if(x.containsString("Memory: ")) {
                systemConfiguration.memory = x[x.startIndex.advancedBy(8)..<x.endIndex]
            } else if(x.containsString("Serial Number (system): ")) {
                systemConfiguration.serialNo = x[x.startIndex.advancedBy(24)..<x.endIndex]
            } else if(x.containsString("Hardware UUID: ")) {
                systemConfiguration.hardwareUuid = x[x.startIndex.advancedBy(15)..<x.endIndex]
            }
        }
    }
    
    private func generateSPDisplaysDataType(systemConfiguration: SystemConfiguration, data: String) {
        for line in data.lines {
            let x = line.trim()
            if(x.containsString("Chipset Model: ")) {
                systemConfiguration.graphicModel = x[x.startIndex.advancedBy(15)..<x.endIndex]
            } else if(x.containsString("VRAM (Dynamic, Max): ")) {
                systemConfiguration.graphicMemory = x[x.startIndex.advancedBy(21)..<x.endIndex]
            } else if(x.containsString("Resolution: ")) {
                systemConfiguration.graphicResolution = x[x.startIndex.advancedBy(12)..<x.endIndex]
            }
        }
    }
    
    private func generateSPSerialATADataType(systemConfiguration: SystemConfiguration, data: String) {
        var firstcapacity = false
        for line in data.lines {
            let x = line.trim()
            if(x.containsString("Model: ")) {
                systemConfiguration.diskModel = x[x.startIndex.advancedBy(7)..<x.endIndex]
            } else if(x.containsString("Capacity: ") && !firstcapacity) {
                let y = x[x.startIndex.advancedBy(10)..<x.endIndex]
                let z = y.substringToIndex(y.characters.indexOf("(")!)
                systemConfiguration.diskSize = z[z.startIndex..<z.endIndex.advancedBy(-1)]
                firstcapacity = true
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let systemConfiguration: SystemConfiguration = SystemConfiguration()
        startGenerationProcess(systemConfiguration)
        let result = generateDictionary(systemConfiguration)
        
        let arrJson = try! NSJSONSerialization.dataWithJSONObject(result, options: NSJSONWritingOptions.PrettyPrinted)
        let jsonString = NSString(data: arrJson, encoding: NSUTF8StringEncoding)
        print(jsonString! as NSString)
        
        NSUserDefaults.standardUserDefaults().setObject(jsonString, forKey: "systemConfiguration")
        NSUserDefaults.standardUserDefaults().synchronize()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func saveData2(laptopConfigData: SystemConfiguration) {
        var requestId: String = ""
        let todosEndpoint: String = "http://172.20.161.82:63560/features"
        
        let result = generateDictionary(laptopConfigData)
        
        Alamofire.request(.POST, todosEndpoint, parameters: result, encoding: .JSON)
            .responseJSON { response in
                switch response.result{
                case .Success(let data):
                    let jsonData = data as! NSDictionary
                    requestId = jsonData.objectForKey("requestId") as! String
                    print(requestId)
                case .Failure(let error):
                    print("Request failed with error: \(error)")
                }
        }
    }
    
    private func saveData(laptopConfigData: SystemConfiguration) {
        var requestId: String? = ""
        makeCall(laptopConfigData) { responseObject, error in
            requestId = responseObject?.objectForKey("requestId") as? String
            self.requestIdLabel.stringValue = "Generated Request Id: " + requestId!
            self.requestIdLabel.selectable = true
        }
    }
    
    func makeCall(laptopConfigData: SystemConfiguration, completionHandler: (NSDictionary?, NSError?) -> ()) {
        
        let params = generateDictionary(laptopConfigData)
        let todosEndpoint: String = "http://172.20.161.82:63560/features"
        
        Alamofire.request(.POST, todosEndpoint, parameters: params, encoding: .JSON)
            .responseJSON { response in
                switch response.result {
                case .Success(let data):
                    completionHandler(data as? NSDictionary, nil)
                case .Failure(let error):
                    completionHandler(nil, error)
                }
        }
    }
    
    private func generateDictionary(systemConfiguration: SystemConfiguration) -> Dictionary<String, String>  {
        var result = Dictionary<String, String>()
        result["processorName"]=systemConfiguration.processorName
        result["processorSpeed"]=systemConfiguration.processorSpeed
        result["processorCores"]=String(systemConfiguration.processorCores)
        result["graphicModel"]=systemConfiguration.graphicModel
        result["graphicMemory"]=systemConfiguration.graphicMemory
        result["graphicResolution"]=systemConfiguration.graphicResolution
        result["memory"]=systemConfiguration.memory
        result["diskModel"]=systemConfiguration.diskModel
        result["diskSize"]=systemConfiguration.diskSize
        result["serialNo"]=systemConfiguration.serialNo
        result["hardwareUuid"]=systemConfiguration.hardwareUuid
        return result
    }


}

