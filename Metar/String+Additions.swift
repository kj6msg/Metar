//
//  String+Additions.swift
//  Metar
//
//  Created by Ryan Clarke on 3/29/24.
//

import Foundation

extension String
{
    var containsOnlyLetters: Bool
    {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal) == nil
    }

    func leftPadding(toLength newLength: Int, withPad padCharacter: Character) -> String
    {
        if self.count < newLength
        {
            let n = newLength - self.count
            return String(repeating: padCharacter, count: n) + self
        }
        else
        {
            return String(self.suffix(newLength))
        }
    }
}
