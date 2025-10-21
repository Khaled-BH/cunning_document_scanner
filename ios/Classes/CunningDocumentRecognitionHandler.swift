//
//  CunningDocumentRecognitionHandler.swift
//  cunning_document_scanner
//
//  Created for advanced document processing with Vision framework
//

import Foundation
import Vision
import VisionKit
import UIKit

/// Document Recognition Handler using Vision framework
/// Provides advanced document processing with text recognition and structure detection
@available(iOS 13.0, *)
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

    /// Process a scanned document image using Vision framework
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - languages: Array of language codes to use for recognition (default: ["en-US"])
    /// - Returns: DocumentMetadata containing structured document information
    func processDocument(image: UIImage, languages: [String] = ["en-US"]) async throws -> DocumentMetadata {
        guard let cgImage = image.cgImage else {
            throw RecognitionError.imageConversionFailed
        }

        // Create VNRecognizeTextRequest (available in iOS 13+)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        // Set languages (iOS 16+)
        if #available(iOS 16.0, *) {
            request.recognitionLanguages = languages
        }
        request.usesLanguageCorrection = true

        // Create request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Perform request
        try requestHandler.perform([request])

        // Get observations
        guard let observations = request.results, !observations.isEmpty else {
            throw RecognitionError.noObservations
        }

        // Extract full text transcript
        var fullText = ""

        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                fullText += topCandidate.string + "\n"
            }
        }

        // Extract tables (basic implementation using text positioning)
        let tables = extractTables(from: observations)

        // Extract lists (basic implementation)
        let lists = extractLists(from: observations)

        // Extract detected data
        let detectedData = extractDetectedData(from: observations)

        // Detect primary language
        let language = languages.first ?? "en-US"

        return DocumentMetadata(
            transcript: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            tables: tables,
            lists: lists,
            detectedData: detectedData,
            language: language
        )
    }

    /// Extract table data from text observations (basic implementation)
    /// Uses spatial analysis to detect table-like structures
    private func extractTables(from observations: [VNRecognizedTextObservation]) -> [TableData] {
        var tables: [TableData] = []

        // Group observations by vertical position (rows)
        let sortedByY = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

        // Detect if text is aligned in grid pattern
        if sortedByY.count >= 6 { // Minimum for a simple table
            let tolerance: CGFloat = 0.05
            var rows: [[VNRecognizedTextObservation]] = []
            var currentRow: [VNRecognizedTextObservation] = []
            var lastY: CGFloat = -1

            for obs in sortedByY {
                let currentY = obs.boundingBox.origin.y
                if lastY < 0 || abs(currentY - lastY) < tolerance {
                    currentRow.append(obs)
                } else {
                    if !currentRow.isEmpty {
                        rows.append(currentRow)
                    }
                    currentRow = [obs]
                }
                lastY = currentY
            }

            if !currentRow.isEmpty {
                rows.append(currentRow)
            }

            // If we have multiple rows with similar column counts, it might be a table
            if rows.count >= 2 {
                let columnCounts = rows.map { $0.count }
                let avgColumns = columnCounts.reduce(0, +) / columnCounts.count

                if avgColumns >= 2 {
                    var cells: [[CellData]] = []

                    for (rowIndex, row) in rows.enumerated() {
                        var rowCells: [CellData] = []
                        let sortedRow = row.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }

                        for (colIndex, obs) in sortedRow.enumerated() {
                            if let text = obs.topCandidates(1).first?.string {
                                let cellData = CellData(
                                    text: text,
                                    rowIndex: rowIndex,
                                    columnIndex: colIndex,
                                    detectedData: []
                                )
                                rowCells.append(cellData)
                            }
                        }
                        cells.append(rowCells)
                    }

                    if !cells.isEmpty {
                        tables.append(TableData(
                            rowCount: cells.count,
                            columnCount: cells.first?.count ?? 0,
                            cells: cells
                        ))
                    }
                }
            }
        }

        return tables
    }

    /// Extract list data from text observations (basic implementation)
    private func extractLists(from observations: [VNRecognizedTextObservation]) -> [ListData] {
        var lists: [ListData] = []
        var items: [ListItemData] = []

        // Detect list items (lines starting with bullets, numbers, etc.)
        let listPattern = "^[•\\-\\*\\d+\\.]\\s+"

        for obs in observations {
            if let text = obs.topCandidates(1).first?.string {
                if text.range(of: listPattern, options: .regularExpression) != nil {
                    items.append(ListItemData(text: text, level: 0))
                }
            }
        }

        if !items.isEmpty {
            lists.append(ListData(items: items))
        }

        return lists
    }

    /// Extract detected data from text observations
    private func extractDetectedData(from observations: [VNRecognizedTextObservation]) -> [DetectedDataItem] {
        var allDetectedData: [DetectedDataItem] = []

        for obs in observations {
            if let text = obs.topCandidates(1).first?.string {
                // Pattern matching for common data types
                if isEmail(text) {
                    allDetectedData.append(DetectedDataItem(text: text, type: .emailAddress))
                } else if isPhoneNumber(text) {
                    allDetectedData.append(DetectedDataItem(text: text, type: .phoneNumber))
                } else if isURL(text) {
                    allDetectedData.append(DetectedDataItem(text: text, type: .url))
                }
            }
        }

        return allDetectedData
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
