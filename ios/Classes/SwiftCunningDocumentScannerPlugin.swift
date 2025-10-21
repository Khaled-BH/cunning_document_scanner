import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
  var resultChannel: FlutterResult?
  var presentingController: VNDocumentCameraViewController?
  var scannerOptions: CunningScannerOptions = CunningScannerOptions()

  // Document recognition handler (iOS 13+)
  private lazy var recognitionHandler = CunningDocumentRecognitionHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cunning_document_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftCunningDocumentScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPictures" {
            scannerOptions = CunningScannerOptions.fromArguments(args: call.arguments)
            let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            self.resultChannel = result
            if VNDocumentCameraViewController.isSupported {
                self.presentingController = VNDocumentCameraViewController()
                self.presentingController!.delegate = self

                // Apply UI improvements for modern iOS versions
                if #available(iOS 15.0, *) {
                    applyModernUIFixes()
                }

                presentedVC?.present(self.presentingController!, animated: true)
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "Document camera is not available on this device", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
            return
        }
  }

  /// Apply modern UI improvements for VNDocumentCameraViewController
  /// Ensures proper appearance and button visibility
  @available(iOS 15.0, *)
  private func applyModernUIFixes() {
    guard let controller = presentingController else { return }

    // Configure navigation bar appearance for better visibility
    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()

    // Apply modern translucent style with proper contrast
    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)

    // Ensure buttons are visible with proper styling
    appearance.buttonAppearance.normal.titleTextAttributes = [
        .foregroundColor: UIColor.label
    ]

    // Apply appearance to navigation controller if available
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak controller] in
        controller?.navigationController?.navigationBar.standardAppearance = appearance
        controller?.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        controller?.navigationController?.navigationBar.compactAppearance = appearance
        controller?.navigationController?.navigationBar.tintColor = UIColor.systemBlue
    }
  }


    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let tempDirPath = self.getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        var filenames: [String] = []
        var metadataList: [[String: Any]] = []

        for i in 0 ..< scan.pageCount {
            let page = scan.imageOfPage(at: i)
            let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).\(scannerOptions.imageFormat.rawValue)")

            // Save image file
            switch scannerOptions.imageFormat {
            case CunningScannerImageFormat.jpg:
                try? page.jpegData(compressionQuality: scannerOptions.jpgCompressionQuality)?.write(to: url)
                break
            case CunningScannerImageFormat.png:
                try? page.pngData()?.write(to: url)
                break
            }

            filenames.append(url.path)

            // Process with advanced recognition if enabled
            if scannerOptions.useRecognizeDocumentsRequest {
                Task {
                    do {
                        let metadata = try await recognitionHandler.processDocument(
                            image: page,
                            languages: scannerOptions.recognitionLanguages
                        )
                        let metadataJSON = recognitionHandler.exportToJSON(metadata: metadata)

                        // Save metadata to JSON file
                        let metadataURL = tempDirPath.appendingPathComponent(formattedDate + "-\(i)-metadata.json")
                        if let jsonData = try? JSONSerialization.data(withJSONObject: metadataJSON, options: .prettyPrinted) {
                            try? jsonData.write(to: metadataURL)
                            metadataList.append(metadataJSON)
                        }
                    } catch {
                        logError("Document Recognition failed", error: error)
                        // Continue processing even if recognition fails
                    }
                }
            }
        }

        // Wait a moment for async processing to complete if needed
        if scannerOptions.useRecognizeDocumentsRequest {
            // Small delay to allow metadata processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }

                // Return results with metadata if advanced features are enabled
                let result: [String: Any] = [
                    "images": filenames,
                    "metadata": metadataList
                ]
                self.resultChannel?(result)
                self.presentingController?.dismiss(animated: true)
            }
        } else {
            resultChannel?(filenames)
            presentingController?.dismiss(animated: true)
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        var errorCode = "SCAN_ERROR"
        var errorMessage = error.localizedDescription
        var errorDetails: String? = nil

        // Categorize errors for better handling
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "VNDocumentCameraViewController":
                errorCode = "CAMERA_ERROR"
                errorDetails = "VisionKit camera error: \(nsError.code)"
            case NSCocoaErrorDomain:
                errorCode = "SYSTEM_ERROR"
                errorDetails = "System error: \(nsError.code)"
            default:
                errorDetails = "Domain: \(nsError.domain), Code: \(nsError.code)"
            }
        }

        // Log error for debugging
        print("Document Scanner Error [\(errorCode)]: \(errorMessage)")
        if let details = errorDetails {
            print("Details: \(details)")
        }

        resultChannel?(FlutterError(code: errorCode, message: errorMessage, details: errorDetails))
        presentingController?.dismiss(animated: true)
    }

    /// Enhanced error logging for production debugging
    private func logError(_ message: String, error: Error? = nil) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        var logMessage = "[\(timestamp)] CunningDocumentScanner: \(message)"

        if let error = error {
            logMessage += " - Error: \(error.localizedDescription)"
        }

        print(logMessage)

        // In production, you might want to send this to a logging service
        // Example: FirebaseCrashlytics.crashlytics().log(logMessage)
    }
}
