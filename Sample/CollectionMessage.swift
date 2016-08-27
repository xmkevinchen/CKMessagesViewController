//
//  CollectionMessage.swift
//  CKMessagesViewController
//
//  Created by Chen Kevin on 8/27/16.
//  Copyright © 2016 Kevin Chen. All rights reserved.
//

import Foundation
import CKMessagesViewController

struct CollectionMessage: CKExtendMessageData, Hashable {
    
    public var senderId: String
    public var sender: String
    public var text: String
    public var timestamp: Date
    
    public init(senderId: String, sender: String, text: String, timestamp: Date = Date()) {
        self.senderId = sender
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
    
    public var metadata: [String: Any] = [String: Any]()
    
}
