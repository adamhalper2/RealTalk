//
//  Date+Additions.swift
//  RealTalk
//
//  Created by Colin James Dolese on 5/5/19.
//  Copyright © 2019 Adam Halper. All rights reserved.
//

import Foundation


extension Date {
    
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self as Date)
    }
}
