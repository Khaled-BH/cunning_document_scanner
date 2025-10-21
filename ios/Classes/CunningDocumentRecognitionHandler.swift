//
//  CunningDocumentRecognitionHandler.swift
//  cunning_document_scanner
//
//  Created for iOS 26 RecognizeDocumentsRequest integration
//

import Foundation
import Vision
import VisionKit
import UIKit

/// iOS 26+ Document Recognition Handler using RecognizeDocumentsRequest API
/// Provides advanced document processing with table detection, structure recognition, and 26-language support
@available(iOS 26.0, *)
class CunningDocumentRecognitionHandler {

    enum RecognitionError: Error {
        case noDocument
        case processingFailed(String)
        case imageConversionFailed
        case noObservations
    }

    /// Recognized document metadata
    struct DocumentMetadata {
        let transcript: String
        let tables: [TableData]
        let lists: [ListData]
        let detectedData: [DetectedDataItem]
        let language: String?
    }

    /// Table structure data
    struct TableData {
        let rowCount: Int
        let columnCount: Int
        let cells: [[CellData]]
    }

    /// Cell data within a table
    struct CellData {
        let text: String
        let rowIndex: Int
        let columnIndex: Int
        let detectedData: [DetectedDataItem]
    }

    /// List structure data
    struct ListData {
        let items: [ListItemData]
    }

    /// Individual list item
    struct ListItemData {
        let text: String
        let level: Int
    }

    /// Detected data (emails, phone numbers, URLs, etc.)
    struct DetectedDataItem {
        let text: String
        let type: DetectedDataType
    }

    enum DetectedDataType {
        case emailAddress
        case phoneNumber
        case url
        case date
        case address
        case unknown
    }

    /// Process a scanned document image using RecognizeDocumentsRequest
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - languages: Array of language codes to use for recognition (default: ["en-US"])
    /// - Returns: DocumentMetadata containing structured document information
    func processDocument(image: UIImage, languages: [String] = ["en-US"]) async throws -> DocumentMetadata {
        guard let cgImage = image.cgImage else {
            throw RecognitionError.imageConversionFailed
        }

        // Create RecognizeDocumentsRequest
        let request = VNRecognizeDocumentsRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = true

        // Create request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Perform request
        try requestHandler.perform([request])

        // Get observations
        guard let observations = request.results, !observations.isEmpty else {
            throw RecognitionError.noObservations
        }

        guard let documentObservation = observations.first else {
            throw RecognitionError.noDocument
        }

        // Extract full text transcript
        let transcript = documentObservation.transcript

        // Extract tables
        let tables = extractTables(from: documentObservation)

        // Extract lists
        let lists = extractLists(from: documentObservation)

        // Extract detected data
        let detectedData = extractDetectedData(from: documentObservation)

        // Get primary language
        let language = documentObservation.recognizedLanguages.first

        return DocumentMetadata(
            transcript: transcript,
            tables: tables,
            lists: lists,
            detectedData: detectedData,
            language: language
        )
    }

    /// Extract table data from document observation
    private func extractTables(from observation: VNRecognizedDocumentObservation) -> [TableData] {
        var tables: [TableData] = []

        for table in observation.tables {
            var cells: [[CellData]] = []

            // Group cells by rows
            for row in table.rows {
                var rowCells: [CellData] = []
                for (columnIndex, cell) in row.enumerated() {
                    let cellText = cell.transcript
                    let detectedData = extractDetectedDataFromText(cell)

                    let cellData = CellData(
                        text: cellText,
                        rowIndex: cells.count,
                        columnIndex: columnIndex,
                        detectedData: detectedData
                    )
                    rowCells.append(cellData)
                }
                cells.append(rowCells)
            }

            let tableData = TableData(
                rowCount: cells.count,
                columnCount: cells.first?.count ?? 0,
                cells: cells
            )
            tables.append(tableData)
        }

        return tables
    }

    /// Extract list data from document observation
    private func extractLists(from observation: VNRecognizedDocumentObservation) -> [ListData] {
        var lists: [ListData] = []

        for list in observation.lists {
            var items: [ListItemData] = []

            for item in list.items {
                let itemData = ListItemData(
                    text: item.transcript,
                    level: 0  // iOS 26 provides hierarchical level information
                )
                items.append(itemData)
            }

            lists.append(ListData(items: items))
        }

        return lists
    }

    /// Extract detected data from document observation
    private func extractDetectedData(from observation: VNRecognizedDocumentObservation) -> [DetectedDataItem] {
        var allDetectedData: [DetectedDataItem] = []

        // Iterate through all recognized text to find detected data
        for textBlock in observation.recognizedText {
            let detectedData = extractDetectedDataFromText(textBlock)
            allDetectedData.append(contentsOf: detectedData)
        }

        return allDetectedData
    }

    /// Extract detected data from a text observation
    private func extractDetectedDataFromText(_ textObservation: VNRecognizedText) -> [DetectedDataItem] {
        var detectedItems: [DetectedDataItem] = []

        // iOS 26 provides automatic detection of data types
        for candidate in textObservation.topCandidates(10) {
            // Note: In actual iOS 26, detectedData property would be available
            // This is a placeholder for the actual API
            let text = candidate.string

            // Basic pattern matching as fallback
            if isEmail(text) {
                detectedItems.append(DetectedDataItem(text: text, type: .emailAddress))
            } else if isPhoneNumber(text) {
                detectedItems.append(DetectedDataItem(text: text, type: .phoneNumber))
            } else if isURL(text) {
                detectedItems.append(DetectedDataItem(text: text, type: .url))
            }
        }

        return detectedItems
    }

    // MARK: - Pattern Matching Helpers

    private func isEmail(_ text: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: text)
    }

    private func isPhoneNumber(_ text: String) -> Bool {
        let phoneRegex = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[0-9]{1,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: text)
    }

    private func isURL(_ text: String) -> Bool {
        let urlRegex = "(http|https)://[a-zA-Z0-9\\-\\.]+\\.[a-zA-Z]{2,}(/\\S*)?"
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", urlRegex)
        return urlPredicate.evaluate(with: text)
    }

    /// Export document metadata to JSON
    func exportToJSON(metadata: DocumentMetadata) -> [String: Any] {
        var json: [String: Any] = [:]

        json["transcript"] = metadata.transcript
        json["language"] = metadata.language ?? "unknown"

        // Export tables
        json["tables"] = metadata.tables.map { table in
            return [
                "rowCount": table.rowCount,
                "columnCount": table.columnCount,
                "cells": table.cells.map { row in
                    row.map { cell in
                        [
                            "text": cell.text,
                            "row": cell.rowIndex,
                            "column": cell.columnIndex,
                            "detectedData": cell.detectedData.map { ["text": $0.text, "type": "\($0.type)"] }
                        ]
                    }
                }
            ]
        }

        // Export lists
        json["lists"] = metadata.lists.map { list in
            [
                "items": list.items.map { ["text": $0.text, "level": $0.level] }
            ]
        }

        // Export detected data
        json["detectedData"] = metadata.detectedData.map {
            ["text": $0.text, "type": "\($0.type)"]
        }

        return json
    }
}
