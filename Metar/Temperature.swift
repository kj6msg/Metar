//
//  Temperature.swift
//  Metar
//
//  Created by Ryan Clarke on 3/17/24.
//

import Foundation

struct Temperature: Decodable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, CustomStringConvertible
{
    var celsius: Double = 0
    
    var fahrenheit: Double
    {
        get
        {
            1.8 * celsius + 32
        }
        set
        {
            celsius = (newValue - 32) / 1.8
        }
    }
    
    init(_ celsius: Double)
    {
        self.celsius = celsius
    }
    
    init(fahrenheit: Double)
    {
        self.fahrenheit = fahrenheit
    }
    
    init(floatLiteral value: FloatLiteralType)
    {
        self.celsius = value
    }
    
    init(integerLiteral value: IntegerLiteralType)
    {
        self.celsius = Double(value)
    }
    
    init(from decoder: any Decoder) throws
    {
        self.celsius = try decoder.singleValueContainer().decode(Double.self)
    }
    
    var description: String
    {
        let formattedCelsius = celsius.formatted(.number.precision(.fractionLength(1)))
        let formattedFahrenheit = fahrenheit.formatted(.number.precision(.fractionLength(0)))
        
        return "\(formattedCelsius)°C (\(formattedFahrenheit)°F)"
    }
    
    static func + (left: Temperature, right: Temperature) -> Temperature
    {
        Temperature(left.celsius + right.celsius)
    }
    
    static func - (left: Temperature, right: Temperature) -> Temperature
    {
        Temperature(left.celsius - right.celsius)
    }
    
    static func * (left: Double, right: Temperature) -> Temperature
    {
        Temperature(left * right.celsius)
    }
    
    static func * (left: Temperature, right: Double) -> Temperature
    {
        right * left
    }
    
    static func / (left: Temperature, right: Temperature) -> Double
    {
        left.celsius / right.celsius
    }
}
