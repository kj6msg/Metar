//
//  Metar.swift
//  Metar
//
//  Created by Ryan Clarke on 3/9/24.
//

import Foundation
import Accelerate

struct Metar: CustomStringConvertible
{
    private static let awcURL = "https://aviationweather.gov/api/data/metar"
    
    let station: String
    private var metarJSON = MetarJSON()
    
    init(station: String) async throws
    {
        self.station = station
        try await update()
    }
    
    mutating func update() async throws
    {
        var urlComponents = URLComponents(string: Metar.awcURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "ids", value: station),
            URLQueryItem(name: "format", value: "json")
        ]
        let (httpData, _) = try await URLSession.shared.data(from: urlComponents.url!)
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let jsonData = try jsonDecoder.decode([MetarJSON].self, from: httpData)
        
        if jsonData.isEmpty
        {
            throw MetarError.emptyMETAR
        }
        
        metarJSON = jsonData.first!
    }
    
    enum MetarError: Error
    {
        case emptyMETAR
    }
    
    var description: String
    {
        metarJSON.rawObservation
    }
    
    var decoded: String
    {
        // METAR type and station
        let metarType = metarJSON.metarType.leftPadding(toLength: 5, withPad: " ")
        var decodedMETAR = "\(metarType) for: ".leftPadding(toLength: 22, withPad: " ")
        decodedMETAR += metarJSON.icaoID + " (\(metarJSON.siteName))\n"
        
        // raw observation
        decodedMETAR += "Text: ".leftPadding(toLength: 22, withPad: " ")
        decodedMETAR += "\(metarJSON.rawObservation)\n"
        
        // observation time
        decodedMETAR += "Conditions at: ".leftPadding(toLength: 22, withPad: " ")
        decodedMETAR += "\(observationTime)\n"
        
        // temperature
        decodedMETAR += "Temperature: ".leftPadding(toLength: 22, withPad: " ")
        decodedMETAR += "\(metarJSON.temperature)\n"
        
        // dew point and relative humidity
        if let dewPointAndRelativeHumidity = dewPointAndRelativeHumidity
        {
            decodedMETAR += "Dewpoint: ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(dewPointAndRelativeHumidity)\n"
        }
        
        // altimeter
        if let pressure = pressure
        {
            decodedMETAR += "Pressure (altimeter): ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(pressure)\n"
        }
        
        // winds
        if let winds = winds
        {
            decodedMETAR += "Winds: ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(winds)\n"
        }
        
        // visibility
        if let visibility = visibility
        {
            decodedMETAR += "Visibility: ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(visibility)\n"
        }
        
        // ceiling and clouds
        if let (ceiling, clouds) = ceilingAndClouds
        {
            decodedMETAR += "Ceiling: ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(ceiling)\n"
            
            decodedMETAR += "Clouds: ".leftPadding(toLength: 22, withPad: " ")
            decodedMETAR += "\(clouds)\n"
        }
        
        return decodedMETAR
    }
    
    private var observationTime: String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm 'UTC' dd MMM yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: metarJSON.observationTime)
    }
    
    private var dewPointAndRelativeHumidity: String?
    {
        guard let dewPoint = metarJSON.dewPoint else
        {
            return nil
        }
        
        let relativeHumidity = exp((17.625 * dewPoint) / (243.04 + dewPoint)) /
            exp((17.625 * metarJSON.temperature) / (243.04 + metarJSON.temperature))
        let formattedRH = relativeHumidity.formatted(.percent.precision(.fractionLength(0)))
        
        return "\(dewPoint) [RH = \(formattedRH)]"
    }
    
    private var pressure: String?
    {
        guard let millibars = metarJSON.altimeter else
        {
            return nil
        }
        
        let inHg = millibars * 0.0295300
        let formattedInHg = inHg.formatted(.number.precision(.fractionLength(2)))
        var str = String(format: "\(formattedInHg) inches Hg (%.1f mb)", millibars)
        
        if let seaLevelPressure = metarJSON.seaLevelPressure
        {
            str += String(format: " [Sea level pressure: %.1f mb]", seaLevelPressure)
        }
        
        return str
    }
    
    private var winds: String?
    {
        guard let windDirection = metarJSON.windDirection else
        {
            return nil
        }
        
        guard let windSpeed = metarJSON.windSpeed else
        {
            return nil
        }
        
        if windSpeed == 0
        {
            return "calm"
        }
        
        var windString = ""
        
        switch(windDirection)
        {
        case .int(let degrees):
            let compassPoints = ["N", "NNE", "NE", "ENE", "E", "ESE","SE", "SSE", "S", "SSW", "SW",
                                 "WSW", "W", "WNW", "NW", "NNW", "N"]
            let index = Int((Double(degrees) / 22.5) + 0.5)
            windString += "from the " + compassPoints[index]
                        + String(format: " (%03d degrees)", degrees)
            
        case .string:
            windString += "variable direction"
        }
        
        func mph(_ knots: Int) -> Double
        {
            Double(knots) * 1.15078
        }
        
        func mps(_ knots: Int) -> Double
        {
            Double(knots) * 0.514444
        }

        windString += String(format: " at %.0f MPH (%d knots; %.1f m/s)",
                             mph(windSpeed), windSpeed, mps(windSpeed))
                
        if let windGust = metarJSON.windGust
        {
            windString += String(format: " gusting to %.0f MPH (%d knots; %.1f m/s)",
                                 mph(windGust), windGust, mps(windGust))
        }
        
        return windString
    }
    
    private var visibility: String?
    {
        guard let visibility = metarJSON.visibility else
        {
            return nil
        }
        
        var visibilityString = ""
        
        switch(visibility)
        {
        case .double(let statuteMiles):
            let fractionLength = (statuteMiles.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
            let formattedSM = statuteMiles.formatted(.number.precision(.fractionLength(fractionLength)))
            let formattedKM = (statuteMiles * 1.60934).formatted(.number.precision(.fractionLength(fractionLength)))
            visibilityString += "\(formattedSM) sm (\(formattedKM) km)"
            
        case .string:
            visibilityString += "10 or more sm (16+ km)"
        }
        
        return visibilityString
    }
    
    private var ceilingAndClouds: (String, String)?
    {
        let clouds = metarJSON.clouds
        
        if clouds.isEmpty
        {
            return nil
        }
        
        // determine ceiling
        var ceiling = ""
        let layers = clouds.filter { $0.cover == "BKN" || $0.cover == "OVC" }
        
        if let lowestLayer = (layers.min { $0.base! < $1.base! })
        {
            ceiling = "\(lowestLayer.base!) feet AGL"
        }
        else if (clouds.contains { $0.cover == "CAVOK" })
        {
            return ("ceiling and visiblity are OK", "unknown")
        }
        else if (clouds.contains { $0.cover == "OVX" })
        {
            ceiling = "indefinite ceiling"
            
            if let vv = metarJSON.verticalVisibility
            {
                ceiling += " with vertical visibility of \(vv) feet AGL"
            }
            
            return (ceiling, "obscured sky")
        }
        else
        {
            ceiling = "at least 12,000 feet AGL"
        }
        
        // determine cloud cover
        var cloudCover: [String] = []
        
        coverLoop: for cloud in clouds
        {            
            switch cloud.cover
            {
            case "CLR":
                cloudCover = ["sky clear below 12,000 feet AGL"]
                break coverLoop
            
            case "FEW":
                cloudCover.append("few clouds at \(cloud.base!) feet AGL")
                
            case "SCT":
                cloudCover.append("scattered clouds at \(cloud.base!) feet AGL")
                
            case "BKN":
                cloudCover.append("broken clouds at \(cloud.base!) feet AGL")
                
            case "OVC":
                cloudCover.append("overcast cloud deck at \(cloud.base!) feet AGL")
                
            default:
                break
            }
        }
        
        return (ceiling, cloudCover.joined(separator: ", "))
    }
}
