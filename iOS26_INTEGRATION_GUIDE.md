# iOS 26 Integration Guide

Complete guide for integrating iOS 26 features into your Flutter app using Cunning Document Scanner.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Configuration](#configuration)
3. [Basic Usage](#basic-usage)
4. [Advanced Features](#advanced-features)
5. [Metadata Processing](#metadata-processing)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Quick Start

### 1. Update iOS Deployment Target

Edit `ios/Podfile`:

```ruby
# For iOS 26 features
platform :ios, '26.0'

# Or maintain backward compatibility with conditional compilation
platform :ios, '13.0'  # Still works, iOS 26 features activate automatically
```

### 2. Install Plugin

```yaml
# pubspec.yaml
dependencies:
  cunning_document_scanner: ^2.0.0
```

### 3. Basic Implementation

```dart
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

// Simple scan (works on all iOS versions)
final images = await CunningDocumentScanner.getPictures();

// iOS 26 enhanced scan
final result = await CunningDocumentScanner.getPicturesWithMetadata(
  iosScannerOptions: IosScannerOptions(
    useRecognizeDocumentsRequest: true,
  ),
);
```

---

## Configuration

### iOS Info.plist

Required camera permission:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan documents</string>
```

### Podfile Setup

```ruby
platform :ios, '26.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        ## dart: PermissionGroup.camera
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

---

## Basic Usage

### Standard Document Scanning

```dart
class DocumentScanner {
  Future<List<String>?> scanDocuments() async {
    try {
      final images = await CunningDocumentScanner.getPictures(
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.8,
        ),
      );
      return images;
    } catch (e) {
      print('Scan error: $e');
      return null;
    }
  }
}
```

### iOS 26 Enhanced Scanning

```dart
class iOS26DocumentScanner {
  Future<Map<String, dynamic>?> scanWithMetadata() async {
    try {
      final result = await CunningDocumentScanner.getPicturesWithMetadata(
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.8,
          useRecognizeDocumentsRequest: true,
          recognitionLanguages: ['en-US'],
          enableTableDetection: true,
          enableListDetection: true,
          enableDataDetection: true,
        ),
      );
      return result;
    } catch (e) {
      print('Enhanced scan error: $e');
      return null;
    }
  }
}
```

---

## Advanced Features

### Multi-Language Document Processing

```dart
Future<void> scanMultiLanguageDocument() async {
  final result = await CunningDocumentScanner.getPicturesWithMetadata(
    iosScannerOptions: IosScannerOptions(
      useRecognizeDocumentsRequest: true,
      // Support for multilingual documents
      recognitionLanguages: [
        'en-US',  // English
        'es-ES',  // Spanish
        'fr-FR',  // French
        'de-DE',  // German
        'zh-CN',  // Chinese Simplified
        'ja-JP',  // Japanese
      ],
    ),
  );

  if (result != null) {
    final metadata = result['metadata'] as List;
    for (var doc in metadata) {
      print('Detected language: ${doc['language']}');
    }
  }
}
```

### Table Extraction

```dart
class TableExtractor {
  List<TableData> extractTables(Map<String, dynamic> metadata) {
    final tables = <TableData>[];
    final tablesJson = metadata['tables'] as List? ?? [];

    for (var tableJson in tablesJson) {
      final table = TableData(
        rowCount: tableJson['rowCount'] as int,
        columnCount: tableJson['columnCount'] as int,
        cells: _parseCells(tableJson['cells']),
      );
      tables.add(table);
    }

    return tables;
  }

  List<List<CellData>> _parseCells(dynamic cellsJson) {
    final cells = <List<CellData>>[];
    for (var row in cellsJson as List) {
      final rowCells = <CellData>[];
      for (var cell in row as List) {
        rowCells.add(CellData(
          text: cell['text'] as String,
          row: cell['row'] as int,
          column: cell['column'] as int,
        ));
      }
      cells.add(rowCells);
    }
    return cells;
  }
}

class TableData {
  final int rowCount;
  final int columnCount;
  final List<List<CellData>> cells;

  TableData({
    required this.rowCount,
    required this.columnCount,
    required this.cells,
  });
}

class CellData {
  final String text;
  final int row;
  final int column;

  CellData({
    required this.text,
    required this.row,
    required this.column,
  });
}
```

### Contact Information Extraction

```dart
class ContactExtractor {
  ContactInfo? extractContact(Map<String, dynamic> metadata) {
    final detectedData = metadata['detectedData'] as List? ?? [];

    String? email;
    String? phone;
    String? website;

    for (var data in detectedData) {
      final type = data['type'] as String;
      final text = data['text'] as String;

      switch (type) {
        case 'emailAddress':
          email ??= text;
          break;
        case 'phoneNumber':
          phone ??= text;
          break;
        case 'url':
          website ??= text;
          break;
      }
    }

    if (email != null || phone != null) {
      return ContactInfo(
        email: email,
        phone: phone,
        website: website,
      );
    }
    return null;
  }
}

class ContactInfo {
  final String? email;
  final String? phone;
  final String? website;

  ContactInfo({this.email, this.phone, this.website});
}
```

---

## Metadata Processing

### Reading Metadata Files

iOS 26 generates JSON metadata files alongside images:

```dart
import 'dart:io';
import 'dart:convert';

Future<Map<String, dynamic>?> loadMetadata(String imagePath) async {
  // Metadata files are named: originalname-metadata.json
  final metadataPath = imagePath.replaceAll(
    RegExp(r'\.(jpg|png)$'),
    '-metadata.json',
  );

  final file = File(metadataPath);
  if (!await file.exists()) {
    return null;
  }

  try {
    final jsonString = await file.readAsString();
    return jsonDecode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    print('Failed to load metadata: $e');
    return null;
  }
}
```

### Full Document Processing Pipeline

```dart
class DocumentProcessor {
  Future<ProcessedDocument?> process() async {
    // 1. Scan document
    final result = await CunningDocumentScanner.getPicturesWithMetadata(
      iosScannerOptions: IosScannerOptions(
        useRecognizeDocumentsRequest: true,
        recognitionLanguages: ['en-US'],
      ),
    );

    if (result == null) return null;

    final images = result['images'] as List<String>;
    final metadata = result['metadata'] as List<Map<String, dynamic>>;

    // 2. Process first page
    if (images.isEmpty) return null;

    final imagePath = images.first;
    final meta = metadata.isNotEmpty ? metadata.first : null;

    // 3. Extract information
    final fullText = meta?['transcript'] as String?;
    final tables = _extractTables(meta);
    final contacts = _extractContacts(meta);

    return ProcessedDocument(
      imagePath: imagePath,
      fullText: fullText ?? '',
      tables: tables,
      contacts: contacts,
    );
  }

  List<TableData> _extractTables(Map<String, dynamic>? metadata) {
    // Implementation from TableExtractor
    return [];
  }

  List<ContactInfo> _extractContacts(Map<String, dynamic>? metadata) {
    // Implementation from ContactExtractor
    return [];
  }
}

class ProcessedDocument {
  final String imagePath;
  final String fullText;
  final List<TableData> tables;
  final List<ContactInfo> contacts;

  ProcessedDocument({
    required this.imagePath,
    required this.fullText,
    required this.tables,
    required this.contacts,
  });
}
```

---

## Troubleshooting

### Issue: iOS 26 Features Not Working

**Solution:**
```dart
// Check iOS version before using iOS 26 features
if (Platform.isIOS) {
  // iOS 26 features will activate automatically
  // Fallback is handled internally
  final result = await CunningDocumentScanner.getPicturesWithMetadata(
    iosScannerOptions: IosScannerOptions(
      useRecognizeDocumentsRequest: true,  // Safe to use
    ),
  );
}
```

### Issue: Gray Bar in Scanner UI

This is fixed automatically in iOS 26+ with the plugin's UI workarounds. No action needed.

### Issue: Metadata Not Generated

**Check:**
1. `useRecognizeDocumentsRequest` is set to `true`
2. Running on iOS 26+ device or simulator
3. Check console for error messages

```dart
final result = await CunningDocumentScanner.getPicturesWithMetadata(
  iosScannerOptions: IosScannerOptions(
    useRecognizeDocumentsRequest: true,  // Must be true
  ),
);

print('Result: $result');  // Debug output
```

### Issue: Poor Recognition Accuracy

**Solutions:**
1. Ensure good lighting
2. Use appropriate language codes
3. Use PNG for better quality (if file size allows)

```dart
IosScannerOptions(
  imageFormat: IosImageFormat.png,  // Better quality
  recognitionLanguages: ['en-US'],  // Correct language
  useRecognizeDocumentsRequest: true,
)
```

---

## Best Practices

### 1. Error Handling

```dart
Future<void> scanWithErrorHandling() async {
  try {
    final result = await CunningDocumentScanner.getPicturesWithMetadata(
      iosScannerOptions: IosScannerOptions(
        useRecognizeDocumentsRequest: true,
      ),
    );

    if (result == null) {
      // User cancelled
      return;
    }

    // Process result
  } on PlatformException catch (e) {
    switch (e.code) {
      case 'UNAVAILABLE':
        print('Camera not available');
        break;
      case 'CAMERA_ERROR':
        print('Camera error: ${e.message}');
        break;
      case 'PERMISSION_DENIED':
        print('Permission denied');
        break;
      default:
        print('Unknown error: ${e.message}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```

### 2. Performance Optimization

```dart
// Use JPEG with compression for better performance
IosScannerOptions(
  imageFormat: IosImageFormat.jpg,
  jpgCompressionQuality: 0.7,  // Balance quality/size
  useRecognizeDocumentsRequest: true,
)
```

### 3. Selective Feature Enablement

```dart
// Only enable features you need
IosScannerOptions(
  useRecognizeDocumentsRequest: true,
  enableTableDetection: true,   // Only if processing tables
  enableListDetection: false,   // Disable if not needed
  enableDataDetection: true,    // Enable for contact extraction
)
```

### 4. Language Selection

```dart
// Use specific languages for better accuracy
IosScannerOptions(
  recognitionLanguages: ['en-US'],  // English only
  // vs
  recognitionLanguages: ['en-US', 'es-ES', 'fr-FR'],  // Multi-language
)
```

### 5. User Experience

```dart
// Show loading indicator during processing
bool _isScanning = false;

Future<void> scan() async {
  setState(() => _isScanning = true);

  try {
    final result = await CunningDocumentScanner.getPicturesWithMetadata(
      iosScannerOptions: IosScannerOptions(
        useRecognizeDocumentsRequest: true,
      ),
    );
    // Process result
  } finally {
    setState(() => _isScanning = false);
  }
}
```

---

## Example: Invoice Scanner

Complete example for scanning and extracting invoice data:

```dart
class InvoiceScanner {
  Future<Invoice?> scanInvoice() async {
    final result = await CunningDocumentScanner.getPicturesWithMetadata(
      iosScannerOptions: IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.8,
        useRecognizeDocumentsRequest: true,
        recognitionLanguages: ['en-US'],
        enableTableDetection: true,
        enableDataDetection: true,
      ),
    );

    if (result == null) return null;

    final images = result['images'] as List<String>;
    final metadata = result['metadata'] as List<Map<String, dynamic>>;

    if (images.isEmpty || metadata.isEmpty) return null;

    return _parseInvoice(images.first, metadata.first);
  }

  Invoice _parseInvoice(String imagePath, Map<String, dynamic> metadata) {
    final detectedData = metadata['detectedData'] as List? ?? [];
    final tables = metadata['tables'] as List? ?? [];

    String? email;
    String? phone;
    List<LineItem> items = [];

    // Extract contact info
    for (var data in detectedData) {
      if (data['type'] == 'emailAddress') {
        email = data['text'];
      } else if (data['type'] == 'phoneNumber') {
        phone = data['text'];
      }
    }

    // Extract line items from tables
    if (tables.isNotEmpty) {
      final table = tables.first;
      final cells = table['cells'] as List;

      for (var row in cells.skip(1)) {  // Skip header row
        if (row.length >= 3) {
          items.add(LineItem(
            description: row[0]['text'] as String,
            quantity: _parseNumber(row[1]['text'] as String),
            price: _parseNumber(row[2]['text'] as String),
          ));
        }
      }
    }

    return Invoice(
      imagePath: imagePath,
      vendorEmail: email,
      vendorPhone: phone,
      lineItems: items,
    );
  }

  double _parseNumber(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }
}

class Invoice {
  final String imagePath;
  final String? vendorEmail;
  final String? vendorPhone;
  final List<LineItem> lineItems;

  Invoice({
    required this.imagePath,
    this.vendorEmail,
    this.vendorPhone,
    required this.lineItems,
  });

  double get total => lineItems.fold(
    0, (sum, item) => sum + (item.quantity * item.price),
  );
}

class LineItem {
  final String description;
  final double quantity;
  final double price;

  LineItem({
    required this.description,
    required this.quantity,
    required this.price,
  });
}
```

---

## Resources

- [iOS 26 Documentation](https://support.apple.com/en-us/123075)
- [WWDC 2025 Session 272](https://developer.apple.com/videos/play/wwdc2025/272/)
- [VisionKit Documentation](https://developer.apple.com/documentation/visionkit)
- [Plugin Repository](https://github.com/Khaled-BH/cunning_document_scanner)

---

## Support

For issues and questions:
- GitHub Issues: https://github.com/Khaled-BH/cunning_document_scanner/issues
- Documentation: See README.md and CHANGELOG_iOS26.md

---

**Last Updated:** 2025
**Plugin Version:** 2.0.0
**iOS Compatibility:** 13.0+
**iOS 26 Features:** Fully Supported
