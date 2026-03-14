//
//  ChatMessage.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/20/26.
//

import Foundation
import SwiftData

/// Unified chat message model used across all chat views
@Model
final class ChatMessage {
    @Attribute(.unique) var id = UUID()
    var text: String
    var isUser: Bool
    var timestamp: Date
    var conversationId: String
    
    init(text: String, isUser: Bool, conversationId: String = UUID().uuidString) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.conversationId = conversationId
    }
}
