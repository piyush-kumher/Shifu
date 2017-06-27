//
//  ValidateController.swift
//  Shifu
//
//  Created by Shubham Kankaria on 23/06/17.
//  Copyright © 2017 FSociety. All rights reserved.
//

import Cocoa
import AppKit
import Alamofire
public typealias QRColor = NSColor
public typealias QRImage = NSImage

class ValidateController: NSViewController {

    @IBOutlet weak var qrImage: NSImageView!
    
    var backgroundColor:QRColor = QRColor.whiteColor()
    var foregroundColor:QRColor = QRColor.blackColor()
    var correctionLevel:CorrectionLevel = .M
    
    enum CorrectionLevel : String {
        case L = "L"
        case M = "M"
        case Q = "Q"
        case H = "H"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let systemConfigurationString = NSUserDefaults.standardUserDefaults().stringForKey(("systemConfiguration")) {
            qrImage.image = generateBarCodeFromString1(systemConfigurationString)
        }
        // Do view setup here.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    func generateBarCodeFromString1(value:String) -> NSImage?{
        let size = CGSize(width: 250, height: 250)
        let stringData = value.dataUsingEncoding(NSISOLatin1StringEncoding, allowLossyConversion: true)
        if let qrFilter = CIFilter(name: "CIQRCodeGenerator") {
            qrFilter.setDefaults()
            qrFilter.setValue(stringData, forKey: "inputMessage")
            qrFilter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
            
            guard let filterOutputImage = qrFilter.outputImage else { return nil }
            guard let outputImage = imageWithImageFilter(filterOutputImage) else { return nil }
            return createNonInterpolatedImageFromCIImage(outputImage, size: size)
        }
        return nil
    }
    
    private func imageWithImageFilter(inputImage:CIImage) -> CIImage? {
        if let colorFilter = CIFilter(name: "CIFalseColor") {
            colorFilter.setDefaults()
            colorFilter.setValue(inputImage, forKey: "inputImage")
            colorFilter.setValue(CIColor(CGColor: foregroundColor.CGColor), forKey: "inputColor0")
            colorFilter.setValue(CIColor(CGColor: backgroundColor.CGColor), forKey: "inputColor1")
            return colorFilter.outputImage
        }
        return nil
    }
    
    private func createNonInterpolatedImageFromCIImage(image:CIImage, size:CGSize) -> QRImage? {
        let cgImage = CIContext().createCGImage(image, fromRect: image.extent)
        let newImage = QRImage(size: size)
        
        newImage.lockFocus()
        
        var context:CGContextRef?
        
        context = NSGraphicsContext.currentContext()?.CGContext
        
        guard let graphicsContext = context else { return nil }
        CGContextSetInterpolationQuality(graphicsContext, CGInterpolationQuality.None)
        CGContextDrawImage(graphicsContext, CGContextGetClipBoundingBox(graphicsContext), cgImage)
        newImage.unlockFocus()
        return newImage
    }
    
}
