//
//  MetarApp.swift
//  Metar
//
//  Created by Ryan Clarke on 3/9/24.
//

@main
struct MetarApp
{
    static func main() async throws
    {
        var metar = Metar(station: "KPVD")
        
        do
        {
            try await metar.fetch()
        }
        catch
        {
            print("Error: \(error)")
        }
        
        print(metar.decoded)
    }
}
