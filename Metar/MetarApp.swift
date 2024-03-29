//
//  MetarApp.swift
//  Metar
//
//  Created by Ryan Clarke on 3/9/24.
//

import Foundation
import ArgumentParser

@main
struct MetarApp: AsyncParsableCommand
{
    static var configuration = CommandConfiguration(
        abstract: "Fetches a METAR observation.",
        usage: """
            Metar [--decoded] <icao>
            """,
        discussion: "Prints a METAR observation in either raw or decoded format."
    )
    
    @Flag(help: "Print decoded observation.")
    var decoded = false
    
    @Argument(help: "ICAO ID.")
    var icao: String
    
    mutating func validate() throws
    {
        guard icao.containsOnlyLetters && icao.count == 4 else
        {
            throw ValidationError("Invalid ICAO ID.")
        }
    }
    
    mutating func run() async throws
    {
        var metar = Metar(station: icao)
        
        do
        {
            try await metar.fetch()
            
            if(decoded)
            {
                print(metar.decoded)
            }
            else
            {
                print(metar)
            }
        }
        catch
        {
            print("Unexpected error: \(error).")
        }
    }
}

extension String
{
    var containsOnlyLetters: Bool
    {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal) == nil
    }
}
