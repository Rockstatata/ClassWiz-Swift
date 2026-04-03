// ClassWizError.swift
// ClassWiz

import Foundation

enum ClassWizError: LocalizedError {
    case networkError(String)
    case unauthorized
    case notFound(String)
    case validationFailed(String)
    case firestoreError(String)
    case authError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):     return "Network error: \(msg)"
        case .unauthorized:              return "You are not authorized to perform this action."
        case .notFound(let item):        return "\(item) not found."
        case .validationFailed(let msg): return "Validation failed: \(msg)"
        case .firestoreError(let msg):   return "Database error: \(msg)"
        case .authError(let msg):        return "Authentication error: \(msg)"
        case .unknown(let msg):          return msg
        }
    }
}
