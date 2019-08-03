//
//  Text.swift
//  Proxi
//
//  Created by Michael Flowers on 7/29/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import Foundation
import MessageKit

struct Text: Codable, MessageType {
    let message: String
    let date: Date
    
    //added these variables to go with the messageType stubs
    let senderID: String
    let displayName: String
    
    //messageType stubs
    var messageId: String
    
    //the following have return types which means I don't have to initialize them in the custom init() method
    var sender: SenderType { return Sender(senderId: senderID, displayName: displayName) }
    var sentDate: Date { return date } //this comes directly from our model's date property
    var kind: MessageKind { return .text(message) } //(message) comes from our model's property message
    
    init(message: String, sender: Sender, date: Date = Date(), messageId: String = UUID().uuidString){
        self.message = message
        self.displayName = sender.displayName
        self.date = date
        self.senderID = sender.senderId
        self.messageId = messageId
        
    }
}

extension Text: Equatable {
    static func == (lhs: Text, rhs: Text) -> Bool {
        return lhs.message == rhs.message && lhs.date == rhs.date && lhs.sentDate == rhs.sentDate
    }
}
