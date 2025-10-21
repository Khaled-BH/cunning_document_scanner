import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ios_options.dart';

export 'ios_options.dart';

class CunningDocumentScanner {
  static const MethodChannel _channel =
      MethodChannel('cunning_document_scanner');

  /// Call this to start get Picture workflow.
  ///
  /// Returns a list of file paths to scanned document images.
  ///
  /// On iOS 26+ with [IosScannerOptions.useRecognizeDocumentsRequest] enabled,
  /// also generates metadata JSON files alongside each image with table data,
  /// detected information, and document structure.
  static Future<List<String>?> getPictures({
    int noOfPages = 100,
    bool isGalleryImportAllowed = false,
    IosScannerOptions? iosScannerOptions,
  }) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();
    if (statuses.containsValue(PermissionStatus.denied) ||
        statuses.containsValue(PermissionStatus.permanentlyDenied)) {
      throw Exception("Permission not granted");
    }

    final dynamic result = await _channel.invokeMethod('getPictures', {
      'noOfPages': noOfPages,
      'isGalleryImportAllowed': isGalleryImportAllowed,
      if (iosScannerOptions != null)
        'iosScannerOptions': iosScannerOptions.toMap()
    });

    // Handle both legacy List<String> and new Map response format
    if (result is List) {
      return result.map((e) => e as String).toList();
    } else if (result is Map) {
      // iOS 26+ with metadata
      final images = result['images'] as List?;
      return images?.map((e) => e as String).toList();
    }
    return null;
  }

  /// Get pictures with full iOS 26+ metadata.
  ///
  /// Returns a map containing:
  /// - 'images': List of image file paths
  /// - 'metadata': List of document metadata (tables, detected data, etc.)
  ///
  /// Only available on iOS 26+ when [IosScannerOptions.useRecognizeDocumentsRequest]
  /// is enabled. On earlier versions or when disabled, returns images only.
  static Future<Map<String, dynamic>?> getPicturesWithMetadata({
    int noOfPages = 100,
    bool isGalleryImportAllowed = false,
    IosScannerOptions? iosScannerOptions,
  }) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();
    if (statuses.containsValue(PermissionStatus.denied) ||
        statuses.containsValue(PermissionStatus.permanentlyDenied)) {
      throw Exception("Permission not granted");
    }

    final dynamic result = await _channel.invokeMethod('getPictures', {
      'noOfPages': noOfPages,
      'isGalleryImportAllowed': isGalleryImportAllowed,
      if (iosScannerOptions != null)
        'iosScannerOptions': iosScannerOptions.toMap()
    });

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    } else if (result is List) {
      // Legacy format - wrap in map
      return {
        'images': result.map((e) => e as String).toList(),
        'metadata': [],
      };
    }
    return null;
  }
}
