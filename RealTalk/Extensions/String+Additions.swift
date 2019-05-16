//
//  String+Additions.swift
//  RealTalk
//
//  Created by Colin James Dolese on 5/4/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation

extension String {
    func isValidEmail() -> Bool {
        // here, `try!` will always succeed because the pattern is valid
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
    
    func isCollegeEmail() -> Bool {
        if self == "realtalk377@gmail.com" {return true}
        return self.hasSuffix("edu")
    }
}
