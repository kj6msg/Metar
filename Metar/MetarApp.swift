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
        commandName: "Metar",
        abstract: "Fetches a METAR observation.",
        discussion: "Prints a METAR observation in either raw or decoded format.",
        version: "1.0"
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
        guard let metar = try? await Metar(station: icao) else
        {
            print("Error: Unable to fetch METAR.")
            throw ExitCode.failure
        }
        
        if(decoded)
        {
            print(metar.decoded)
        }
        else
        {
            print(metar)
        }
    }
}
