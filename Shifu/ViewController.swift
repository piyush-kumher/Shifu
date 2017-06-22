//
//  ViewController.swift
//  Shifu
//
//  Created by Shubham Kankaria on 22/06/17.
//  Copyright (c) 2017 FSociety. All rights reserved.
//

import Cocoa

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

extension NSMutableAttributedString {
    func bold(text:String) -> NSMutableAttributedString {
        let attrs:[String:AnyObject] = [NSFontAttributeName : UIFont(name: "AvenirNext-Medium", size: 12)!]
        let boldString = NSMutableAttributedString(string:"\(text)", attributes:attrs)
        self.appendAttributedString(boldString)
        return self
    }
    
    func normal(text:String)->NSMutableAttributedString {
        let normal =  NSAttributedString(string: text)
        self.appendAttributedString(normal)
        return self
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var systemConfigurationLabel: NSTextField!
    
    @IBAction func checkSystemConfigurationButtonClicked(sender: AnyObject) {
        let listDataTypes: [String] = ["SPHardwareDataType", "SPDisplaysDataType", "SPSerialATADataType"]
        var systemConfiguration: SystemConfiguration = SystemConfiguration()

        for (i, dataType) in listDataTypes.enumerate() {
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
        //TODO: Hit Oogway service
        
        //Display in label
        
        //let string = "Shubham Kankaria"
        //var attributedString = NSMutableAttributedString(string: string as String, attributes: [NSFontAttributeName: NSFont.boldSystemFontOfSize(15.0)])
        //let boldFontAttribute = [NSFontAttributeName: NSFont.boldSystemFontOfSize(15.0)]
        //attributedString.addAttributes(boldFontAttribute, range: string.rangeOfString("Shubham"))
        
        //systemConfigurationLabel.stringValue = String(attributedString)
        
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
                print(systemConfiguration.processorName!)
            } else if(x.containsString("Processor Speed: ")) {
                systemConfiguration.processorSpeed = x[x.startIndex.advancedBy(17)..<x.endIndex]
                print(systemConfiguration.processorSpeed!)
            } else if(x.containsString("Total Number of Cores: ")) {
                systemConfiguration.processorCores = Int(x[x.startIndex.advancedBy(23)..<x.endIndex])!
                print(systemConfiguration.processorCores)
            } else if(x.containsString("Memory: ")) {
                systemConfiguration.memory = x[x.startIndex.advancedBy(8)..<x.endIndex]
                print(systemConfiguration.memory!)
            } else if(x.containsString("Serial Number (system): ")) {
                systemConfiguration.serialNo = x[x.startIndex.advancedBy(24)..<x.endIndex]
                print(systemConfiguration.serialNo!)
            } else if(x.containsString("Hardware UUID: ")) {
                systemConfiguration.hardwareUuid = x[x.startIndex.advancedBy(15)..<x.endIndex]
                print(systemConfiguration.hardwareUuid!)
            }
        }
    }
    
    private func generateSPDisplaysDataType(systemConfiguration: SystemConfiguration, data: String) {
        for line in data.lines {
            let x = line.trim()
            if(x.containsString("Chipset Model: ")) {
                systemConfiguration.graphicModel = x[x.startIndex.advancedBy(15)..<x.endIndex]
                print(systemConfiguration.graphicModel!)
            } else if(x.containsString("VRAM (Dynamic, Max): ")) {
                systemConfiguration.graphicMemory = x[x.startIndex.advancedBy(21)..<x.endIndex]
                print(systemConfiguration.graphicMemory!)
            } else if(x.containsString("Resolution: ")) {
                systemConfiguration.graphicResolution = x[x.startIndex.advancedBy(12)..<x.endIndex]
                print(systemConfiguration.graphicResolution!)
            }
        }
    }
    
    private func generateSPSerialATADataType(systemConfiguration: SystemConfiguration, data: String) {
        var firstcapacity = false
        for line in data.lines {
            let x = line.trim()
            if(x.containsString("Model: ")) {
                systemConfiguration.diskModel = x[x.startIndex.advancedBy(7)..<x.endIndex]
                print(systemConfiguration.diskModel!)
            } else if(x.containsString("Capacity: ") && !firstcapacity) {
                let y = x[x.startIndex.advancedBy(10)..<x.endIndex]
                let z = y.substringToIndex(y.characters.indexOf("(")!)
                systemConfiguration.diskSize = z
                print(systemConfiguration.diskSize!)
                firstcapacity = true
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

