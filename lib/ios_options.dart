/// Enumerates the different output image formats are supported.
enum IosImageFormat {
  /// Indicates the output image should be formatted as JPEG image.
  jpg,

  /// Indicates the output image should be formatted as PNG image.
  png,
}

/// Different options that modify the behavior of the document scanner on iOS.
///
/// The [imageFormat] specifies the format of the output image file. Available
/// options are [IosImageFormat.jpeg] or [IosImageFormat.png]. Default value is
/// [IosImageFormat.png].
///
/// If [imageFormat] is set to [IosImageFormat.jpeg] the [jpgCompressionQuality]
/// can be used to control the quality of the resulting JPEG image. The value
/// 0.0 represents the maximum compression (or lowest quality) while the value
/// 1.0 represents the least compression (or best quality). Default value is 1.0.
///
/// iOS 26+ Features:
/// - [useRecognizeDocumentsRequest]: Enable iOS 26 RecognizeDocumentsRequest API
///   for advanced document processing with table detection, structure recognition,
///   and 26-language support. Requires iOS 26+.
/// - [recognitionLanguages]: List of language codes for text recognition.
///   Supports 26 languages including English, Spanish, French, German, Chinese, etc.
/// - [enableTableDetection]: Automatically detect and extract table structures.
/// - [enableListDetection]: Automatically detect and extract list structures.
/// - [enableDataDetection]: Automatically detect emails, phone numbers, URLs, etc.
final class IosScannerOptions {
  /// Creates a [IosScannerOptions].
  const IosScannerOptions({
    this.imageFormat = IosImageFormat.png,
    this.jpgCompressionQuality = 1.0,
    this.useRecognizeDocumentsRequest = false,
    this.recognitionLanguages = const ['en-US'],
    this.enableTableDetection = true,
    this.enableListDetection = true,
    this.enableDataDetection = true,
  });

  final IosImageFormat imageFormat;

  /// The quality of the resulting JPEG image, expressed as a value from 0.0 to
  /// 1.0.
  ///
  /// The value 0.0 represents the maximum compression (or lowest quality) while
  /// the value 1.0 represents the least compression (or best quality). The
  /// [jpgCompressionQuality] only has an effect if the [imageFormat] is set to
  /// [IosImageFormat.jpeg] and is ignored otherwise.
  final double jpgCompressionQuality;

  /// Enable iOS 26+ RecognizeDocumentsRequest API for advanced document processing.
  ///
  /// When enabled, scanned documents will be processed using the new Vision framework
  /// RecognizeDocumentsRequest API which provides:
  /// - Table detection and cell extraction
  /// - List structure recognition
  /// - Automatic data detection (emails, phone numbers, URLs, etc.)
  /// - Support for 26 languages
  /// - Structured document metadata in JSON format
  ///
  /// Requires iOS 26 or later. Ignored on earlier iOS versions.
  final bool useRecognizeDocumentsRequest;

  /// List of language codes for text recognition.
  ///
  /// Supported languages include: en-US, es-ES, fr-FR, de-DE, zh-CN, ja-JP,
  /// ko-KR, pt-BR, ru-RU, ar-SA, hi-IN, and many more (26 total).
  ///
  /// Default: ['en-US']
  final List<String> recognitionLanguages;

  /// Enable table detection and extraction.
  ///
  /// When enabled with [useRecognizeDocumentsRequest], tables in scanned documents
  /// will be automatically detected and their structure (rows, columns, cells)
  /// will be extracted.
  final bool enableTableDetection;

  /// Enable list detection and extraction.
  ///
  /// When enabled with [useRecognizeDocumentsRequest], lists in scanned documents
  /// will be automatically detected and their items will be extracted.
  final bool enableListDetection;

  /// Enable automatic data detection.
  ///
  /// When enabled with [useRecognizeDocumentsRequest], emails, phone numbers,
  /// URLs, dates, and other structured data will be automatically detected
  /// and extracted from scanned documents.
  final bool enableDataDetection;

  /// Converts this options object to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'imageFormat': imageFormat.name,
      'jpgCompressionQuality': jpgCompressionQuality,
      'useRecognizeDocumentsRequest': useRecognizeDocumentsRequest,
      'recognitionLanguages': recognitionLanguages,
      'enableTableDetection': enableTableDetection,
      'enableListDetection': enableListDetection,
      'enableDataDetection': enableDataDetection,
    };
  }
}
