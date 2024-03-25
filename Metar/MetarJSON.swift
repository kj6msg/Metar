//
//  MetarData.swift
//  Metar
//
//  Created by Ryan Clarke on 3/10/24.
//

import Foundation

struct MetarJSON: Decodable
{
    var icaoID: String = ""
    var observationTime: Date = Date()
    var temperature: Temperature = 0
    var dewPoint: Temperature?
    var windDirection: IntOrString?
    var windSpeed: Int?
    var windGust: Int?
    var visibility: DoubleOrString?
    var altimeter: Double?
    var seaLevelPressure: Double?
    var weatherString: String?
    var verticalVisibility: Int?
    var metarType: String = ""
    var rawObservation: String = ""
    var siteName: String = ""
    var clouds: [CloudLayer] = []
    
    enum CodingKeys: String, CodingKey
    {
        case icaoID = "icaoId"
        case observationTime = "obsTime"
        case temperature = "temp"
        case dewPoint = "dewp"
        case windDirection = "wdir"
        case windSpeed = "wspd"
        case windGust = "wgst"
        case visibility = "visib"
        case altimeter = "altim"
        case seaLevelPressure = "slp"
        case weatherString = "wxString"
        case verticalVisibility = "vertVis"
        case metarType
        case rawObservation = "rawOb"
        case siteName = "name"
        case clouds
    }
    
    enum IntOrString: Decodable
    {
        case int(Int)
        case string(String)
        
        init(from decoder: any Decoder) throws
        {
            self = if let int = try? decoder.singleValueContainer().decode(Int.self)
            {
                .int(int)
            }
            else if let string = try? decoder.singleValueContainer().decode(String.self)
            {
                .string(string)
            }
            else
            {
                throw IntOrStringError.unableToDecodeIntOrString
            }
        }
        
        enum IntOrStringError: Error
        {
            case unableToDecodeIntOrString
        }
    }
    
    enum DoubleOrString: Decodable
    {
        case double(Double)
        case string(String)
        
        init(from decoder: any Decoder) throws
        {
            self = if let double = try? decoder.singleValueContainer().decode(Double.self)
            {
                .double(double)
            }
            else if let string = try? decoder.singleValueContainer().decode(String.self)
            {
                .string(string)
            }
            else
            {
                throw DoubleOrStringError.unableToDecodeDoubleOrString
            }
        }
        
        enum DoubleOrStringError: Error
        {
            case unableToDecodeDoubleOrString
        }
    }
    
    struct CloudLayer: Decodable
    {
        var cover: String
        var base: Int?
    }
}
