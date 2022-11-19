//
//  String + isHTML.swift
//  
//
//  Created by dex on 19/11/2022.
//

import Foundation

extension String {
    func isValidHtmlString() -> Bool {
        if self.isEmpty {
            return false
        }
        return (self.range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil)
    }
}
