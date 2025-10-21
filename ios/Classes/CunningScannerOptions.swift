//
//  ScannerOptions.swift
//  cunning_document_scanner
//
//  Created by Maurits van Beusekom on 15/10/2024.
//  Updated for iOS 26 support
//

import Foundation

enum CunningScannerImageFormat: String {
    case jpg
    case png
}

struct CunningScannerOptions {
    let imageFormat: CunningScannerImageFormat
    let jpgCompressionQuality: Double

    // iOS 26 specific options
    let useRecognizeDocumentsRequest: Bool
    let recognitionLanguages: [String]
    let enableTableDetection: Bool
    let enableListDetection: Bool
    let enableDataDetection: Bool

    init() {
        self.imageFormat = CunningScannerImageFormat.png
        self.jpgCompressionQuality = 1.0
        self.useRecognizeDocumentsRequest = false
        self.recognitionLanguages = ["en-US"]
        self.enableTableDetection = true
        self.enableListDetection = true
        self.enableDataDetection = true
    }

    init(imageFormat: CunningScannerImageFormat) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = 1.0
        self.useRecognizeDocumentsRequest = false
        self.recognitionLanguages = ["en-US"]
        self.enableTableDetection = true
        self.enableListDetection = true
        self.enableDataDetection = true
    }

    init(imageFormat: CunningScannerImageFormat, jpgCompressionQuality: Double) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = jpgCompressionQuality
        self.useRecognizeDocumentsRequest = false
        self.recognitionLanguages = ["en-US"]
        self.enableTableDetection = true
        self.enableListDetection = true
        self.enableDataDetection = true
    }

    init(
        imageFormat: CunningScannerImageFormat,
        jpgCompressionQuality: Double,
        useRecognizeDocumentsRequest: Bool,
        recognitionLanguages: [String],
        enableTableDetection: Bool,
        enableListDetection: Bool,
        enableDataDetection: Bool
    ) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = jpgCompressionQuality
        self.useRecognizeDocumentsRequest = useRecognizeDocumentsRequest
        self.recognitionLanguages = recognitionLanguages
        self.enableTableDetection = enableTableDetection
        self.enableListDetection = enableListDetection
        self.enableDataDetection = enableDataDetection
    }
    
    static func fromArguments(args: Any?) -> CunningScannerOptions {
        if (args == nil) {
            return CunningScannerOptions()
        }

        let arguments = args as? Dictionary<String, Any>

        if arguments == nil || arguments!.keys.contains("iosScannerOptions") == false {
            return CunningScannerOptions()
        }

        let scannerOptionsDict = arguments!["iosScannerOptions"] as! Dictionary<String, Any>
        let imageFormat: String = (scannerOptionsDict["imageFormat"] as? String) ?? "png"
        let jpgCompressionQuality: Double = (scannerOptionsDict["jpgCompressionQuality"] as? Double) ?? 1.0

        // iOS 26 specific options
        let useRecognizeDocumentsRequest: Bool = (scannerOptionsDict["useRecognizeDocumentsRequest"] as? Bool) ?? false
        let recognitionLanguages: [String] = (scannerOptionsDict["recognitionLanguages"] as? [String]) ?? ["en-US"]
        let enableTableDetection: Bool = (scannerOptionsDict["enableTableDetection"] as? Bool) ?? true
        let enableListDetection: Bool = (scannerOptionsDict["enableListDetection"] as? Bool) ?? true
        let enableDataDetection: Bool = (scannerOptionsDict["enableDataDetection"] as? Bool) ?? true

        return CunningScannerOptions(
            imageFormat: CunningScannerImageFormat(rawValue: imageFormat) ?? CunningScannerImageFormat.png,
            jpgCompressionQuality: jpgCompressionQuality,
            useRecognizeDocumentsRequest: useRecognizeDocumentsRequest,
            recognitionLanguages: recognitionLanguages,
            enableTableDetection: enableTableDetection,
            enableListDetection: enableListDetection,
            enableDataDetection: enableDataDetection
        )
    }
}
