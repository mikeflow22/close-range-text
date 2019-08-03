//
//  User.swift
//  Proxi
//
//  Created by Michael Flowers on 7/29/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import Foundation
import MessageKit

struct User: Codable {
    let username: String //displayName
//    var texts: [Text]?
    let senderId: String
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.username == rhs.username && lhs.senderId == rhs.senderId
    }
}
