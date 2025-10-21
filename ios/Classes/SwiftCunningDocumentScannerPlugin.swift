import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
  var resultChannel: FlutterResult?
  var presentingController: VNDocumentCameraViewController?
  var scannerOptions: CunningScannerOptions = CunningScannerOptions()

  // iOS 26 recognition handler
  @available(iOS 26.0, *)
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

                // iOS 26: Apply Liquid Glass UI workarounds for known bugs
                if #available(iOS 26.0, *) {
                    applyiOS26UIFixes()
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

  /// Apply iOS 26 UI fixes for VNDocumentCameraViewController bugs
  /// Addresses gray bar issue and invisible button problems
  @available(iOS 26.0, *)
  private func applyiOS26UIFixes() {
    guard let controller = presentingController else { return }

    // Fix 1: Force proper navigation bar appearance to fix gray bar
    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()

    // Apply translucent Liquid Glass style but with proper contrast
    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)

    // Ensure buttons are visible with proper tint
    appearance.buttonAppearance.normal.titleTextAttributes = [
        .foregroundColor: UIColor.label
    ]

    controller.navigationController?.navigationBar.standardAppearance = appearance
    controller.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    controller.navigationController?.navigationBar.compactAppearance = appearance

    // Fix 2: Ensure buttons have proper contrast for Liquid Glass
    controller.navigationController?.navigationBar.tintColor = UIColor.label

    // Fix 3: Force redraw to apply changes
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
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

            // iOS 26: Process with RecognizeDocumentsRequest if enabled
            if #available(iOS 26.0, *), scannerOptions.useRecognizeDocumentsRequest {
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
                        print("iOS 26 Document Recognition failed: \(error.localizedDescription)")
                        // Continue processing even if recognition fails
                    }
                }
            }
        }

        // Return results with metadata if iOS 26 features are enabled
        if #available(iOS 26.0, *), scannerOptions.useRecognizeDocumentsRequest {
            let result: [String: Any] = [
                "images": filenames,
                "metadata": metadataList
            ]
            resultChannel?(result)
        } else {
            resultChannel?(filenames)
        }

        presentingController?.dismiss(animated: true)
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
